--!strict
--!optimize 2
--!native

local Types = require(script.Parent.Parent.Parent.Parent.types)
local TempoServiceTypes = require(script.Parent.Parent.Parent.Parent.types.services.tempoService)

local TaskRecord = require(script.Parent.Parent.Parent.Parent.components.taskRecord.shared.taskRecord)
local HeapManager = require(script.Parent.Parent.Parent.Parent.managers.heapManager.shared.heapManager)
local PhaseManager = require(script.Parent.Parent.Parent.Parent.managers.phaseManager.shared.phaseManager)

type Clock = Types.Clock
type Options = Types.Options
type PhaseName<PhaseT> = Types.PhaseName<PhaseT>
type Phase<PhaseT> = Types.Phase<PhaseT>
type PhaseInput<PhaseT> = TempoServiceTypes.PhaseInput<PhaseT>
type PhaseCallback = Types.PhaseCallback
type ScheduledCallback = Types.ScheduledCallback
type TaskKind = Types.TaskKind
type TaskRecord = Types.TaskRecord
type PhaseState = Types.PhaseState
type TempoHandle<PhaseT> = Types.TempoHandle<PhaseT>
type Tempo<PhaseT> = TempoServiceTypes.Tempo<PhaseT>

local heapPush = HeapManager.push
local heapRemove = HeapManager.remove
local heapRepair = HeapManager.repair
local heapPeek = HeapManager.peek
local heapPop = HeapManager.pop

local takeRecord = TaskRecord.take
local recycleRecord = TaskRecord.recycle
local warmRecords = TaskRecord.warm
local configureRecord = TaskRecord.configure

local createPhaseState = PhaseManager.createState
local bindPhaseCallback = PhaseManager.bind
local unbindPhaseCallback = PhaseManager.unbind
local clearPhaseCallbacks = PhaseManager.clear

local TempoService = {}
TempoService.__index = TempoService

--// cast pcall cuz its lowk not typed right (we have to lie cuz luau doesnt allow full anotation of a tuple return or string)
type PseudoPCall = <P..., R...>((P...) -> R..., P...) -> (true, any)
local pcall : PseudoPCall = pcall :: any

local function defaultClock(): number
	return os.clock()
end

local function runCallback<PhaseT>(self: Tempo<PhaseT>, callback: ScheduledCallback, now: number)
	if self.protected then
		local ok, err = pcall(callback, now)
		if not ok then
			warn(("[Tempo] callback error: %s"):format(tostring(err)))
		end
	else
		callback(now)
	end
end

local function finishRecord<PhaseT>(self: Tempo<PhaseT>, record: TaskRecord)
	self._recordsById[record.id] = nil
	recycleRecord(self, record)
end

local function runRecord<PhaseT>(
	self: Tempo<PhaseT>,
	state: PhaseState,
	record: TaskRecord,
	now: number
)
	if not record.active then
		finishRecord(self, record)
		return
	end

	local callback = record.callback
	if callback == nil then
		finishRecord(self, record)
		return
	end

	record.running = true
	runCallback(self, callback, now)
	record.running = false

	if not record.active then
		finishRecord(self, record)
		return
	end

	if record.heapIndex > 0 or record.nextQueued then
		return
	end

	if record.kind == "every" then
		record.runAt = now + record.interval
		heapPush(state, record)
	else
		finishRecord(self, record)
	end
end

local function drainDue<PhaseT>(self: Tempo<PhaseT>, state: PhaseState, now: number)
	while true do
		local record = heapPeek(state)
		if record == nil or record.runAt > now then
			return
		end

		heapPop(state)
		runRecord(self, state, record, now)
	end
end

local function drainNext<PhaseT>(self: Tempo<PhaseT>, state: PhaseState, now: number)
	local queue = state.nextQueue
	local count = state.nextCount
	if count == 0 then
		return
	end

	state.nextCount = 0

	for i = 1, count do
		local record = queue[i]
		queue[i] = nil :: any

		if record.nextQueued then
			record.nextQueued = false
			runRecord(self, state, record, now)
		end
	end
end

function TempoService.new<PhaseT>(options: Options?): TempoHandle<PhaseT>
	local self: Tempo<PhaseT> = setmetatable({}, TempoService) :: any

	self.clock = options and options.clock or defaultClock
	self.protected = options ~= nil and options.protected == true
	self.phases = {} :: any
	self._phaseStates = {}
	self._phaseByName = {}
	self._bindingsById = {}
	self._recordsById = {}
	self._freeRecords = {}
	self._freeCount = 0
	self._nextId = 0
	self._nextBindingId = 0

	local heartbeat: Phase<"heartbeat"> = {
		id = 1,
		name = "heartbeat",
	}

	self.phases.heartbeat = heartbeat
	self._phaseByName.heartbeat = heartbeat :: Phase<PhaseName<PhaseT>>
	self._phaseStates[1] = createPhaseState(heartbeat)
	self._defaultPhase = heartbeat

	return self
end

function TempoService.addPhase<PhaseT>(
	self: Tempo<PhaseT>,
	name: PhaseT
): Phase<PhaseName<PhaseT>>
	local phaseName = name :: any
	assert(phaseName ~= "heartbeat", 'Tempo phase "heartbeat" is native and already registered')

	local existing = self._phaseByName[phaseName]
	if existing ~= nil then
		return existing
	end

	local id = #self._phaseStates + 1
	local token: Phase<PhaseName<PhaseT>> = {
		id = id,
		name = name,
	}

	self.phases[phaseName] = token
	self._phaseByName[phaseName] = token
	self._phaseStates[id] = createPhaseState(token)

	return token
end

function TempoService.getPhase<PhaseT>(
	self: Tempo<PhaseT>,
	phase: PhaseInput<PhaseT>?
): Phase<PhaseName<PhaseT>>
	if phase == nil then
		return self._defaultPhase :: Phase<PhaseName<PhaseT>>
	end

	if type(phase) == "table" then
		return phase :: Phase<PhaseName<PhaseT>>
	end

	local phaseName = phase :: any
	local token = self._phaseByName[phaseName]
	assert(token ~= nil, `Tempo phase "{phaseName}" does not exist`)
	return token
end

function TempoService.bindPhase<PhaseT>(
	self: Tempo<PhaseT>,
	phase: PhaseInput<PhaseT>,
	callback: PhaseCallback
): number
	local token = self:getPhase(phase)
	local state = self._phaseStates[token.id]
	local phaseCallback = callback

	if self.protected then
		phaseCallback = function(dt: number, now: number)
			local ok, err = pcall(callback, dt, now)
			if not ok then
				warn(("[Tempo] phase callback error: %s"):format(tostring(err)))
			end
		end
	end

	local localId = bindPhaseCallback(state, phaseCallback)

	self._nextBindingId += 1
	local id = self._nextBindingId
	self._bindingsById[id] = {
		state = state,
		localId = localId,
	}

	return id
end

function TempoService.unbindPhase<PhaseT>(self: Tempo<PhaseT>, id: number): boolean
	local binding = self._bindingsById[id]
	if binding == nil then
		return false
	end

	self._bindingsById[id] = nil
	return unbindPhaseCallback(binding.state, binding.localId)
end

function TempoService.stepPhase<PhaseT>(
	self: Tempo<PhaseT>,
	phase: PhaseInput<PhaseT>,
	dt: number?,
	now: number?
)
	local token = self:getPhase(phase)
	local state = self._phaseStates[token.id]
	local resolvedNow = now or self.clock()
	local resolvedDt = dt or 0

	drainNext(self, state, resolvedNow)
	drainDue(self, state, resolvedNow)

	state.callbacks:fire(resolvedDt, resolvedNow)

	drainDue(self, state, resolvedNow)
end

function TempoService.evaluatePhase<PhaseT>(
	self: Tempo<PhaseT>,
	phase: PhaseInput<PhaseT>
): (number) -> ()
	local token = self:getPhase(phase)
	local state = self._phaseStates[token.id]

	if state.evaluator ~= nil then
		return state.evaluator :: (number) -> ()
	end

	local function evaluator(dt: number)
		self:stepPhase(token, dt)
	end

	state.evaluator = evaluator
	return evaluator
end

local function scheduleRecord<PhaseT>(
	self: Tempo<PhaseT>,
	phase: PhaseInput<PhaseT>?,
	runAt: number,
	callback: ScheduledCallback,
	kind: TaskKind,
	interval: number
): number
	local token = self:getPhase(phase)
	local record = takeRecord(self)

	self._nextId += 1
	local id = self._nextId

	configureRecord(record, id, token.id, runAt, callback, kind, interval, false)

	self._recordsById[id] = record
	heapPush(self._phaseStates[token.id], record)

	return id
end

function TempoService.next<PhaseT>(
	self: Tempo<PhaseT>,
	callback: ScheduledCallback,
	phase: PhaseInput<PhaseT>?
): number
	local token = self:getPhase(phase)
	local state = self._phaseStates[token.id]
	local record = takeRecord(self)

	self._nextId += 1
	local id = self._nextId

	configureRecord(record, id, token.id, 0, callback, "once", 0, true)
	self._recordsById[id] = record

	local index = state.nextCount + 1
	state.nextCount = index
	state.nextQueue[index] = record

	return id
end

function TempoService.at<PhaseT>(
	self: Tempo<PhaseT>,
	runAt: number,
	callback: ScheduledCallback,
	phase: PhaseInput<PhaseT>?
): number
	return scheduleRecord(self, phase, runAt, callback, "once", 0)
end

function TempoService.delay<PhaseT>(
	self: Tempo<PhaseT>,
	seconds: number,
	callback: ScheduledCallback,
	phase: PhaseInput<PhaseT>?
): number
	if seconds < 0 then
		seconds = 0
	end
	return scheduleRecord(self, phase, self.clock() + seconds, callback, "once", 0)
end

function TempoService.every<PhaseT>(
	self: Tempo<PhaseT>,
	interval: number,
	callback: ScheduledCallback,
	phase: PhaseInput<PhaseT>?
): number
	assert(interval > 0, "Tempo.every interval must be greater than 0")
	return scheduleRecord(self, phase, self.clock() + interval, callback, "every", interval)
end

TempoService.scheduleAt = TempoService.at
TempoService.scheduleDelay = TempoService.delay

function TempoService.cancel<PhaseT>(self: Tempo<PhaseT>, id: number): boolean
	local record = self._recordsById[id]
	if record == nil or not record.active then
		return false
	end

	record.active = false
	self._recordsById[id] = nil

	if record.heapIndex > 0 then
		heapRemove(self._phaseStates[record.phaseId], record)
		if not record.running then
			recycleRecord(self, record)
		end
	elseif not record.nextQueued and not record.running then
		recycleRecord(self, record)
	end

	return true
end

function TempoService.rescheduleAt<PhaseT>(
	self: Tempo<PhaseT>,
	id: number,
	runAt: number,
	phase: PhaseInput<PhaseT>?
): boolean
	local record = self._recordsById[id]
	if record == nil or not record.active then
		return false
	end

	local nextPhase = if phase ~= nil then self:getPhase(phase) else self._phaseStates[record.phaseId].token
	local oldState = self._phaseStates[record.phaseId]
	local newState = self._phaseStates[nextPhase.id]

	record.runAt = runAt

	if record.nextQueued then
		record.nextQueued = false
		record.phaseId = nextPhase.id
		heapPush(newState, record)
		return true
	end

	if record.heapIndex > 0 and oldState ~= newState then
		heapRemove(oldState, record)
		record.phaseId = nextPhase.id
		heapPush(newState, record)
	elseif record.heapIndex > 0 then
		heapRepair(oldState, record)
	else
		record.phaseId = nextPhase.id
		heapPush(newState, record)
	end

	return true
end

function TempoService.rescheduleIn<PhaseT>(
	self: Tempo<PhaseT>,
	id: number,
	seconds: number,
	phase: PhaseInput<PhaseT>?
): boolean
	if seconds < 0 then
		seconds = 0
	end
	return self:rescheduleAt(id, self.clock() + seconds, phase)
end

function TempoService.isActive<PhaseT>(self: Tempo<PhaseT>, id: number): boolean
	local record = self._recordsById[id]
	return record ~= nil and record.active
end

function TempoService.warm<PhaseT>(self: Tempo<PhaseT>, count: number)
	warmRecords(self, count)
end

function TempoService.clear<PhaseT>(self: Tempo<PhaseT>)
	for _, state in self._phaseStates do
		for i = 1, state.heapSize do
			local record = state.heap[i]
			if record ~= nil then
				self._recordsById[record.id] = nil
				recycleRecord(self, record)
				state.heap[i] = nil :: any
			end
		end
		state.heapSize = 0

		for i = 1, state.nextCount do
			local record = state.nextQueue[i]
			if record ~= nil then
				if record.nextQueued then
					self._recordsById[record.id] = nil
					recycleRecord(self, record)
				end
				state.nextQueue[i] = nil :: any
			end
		end
		state.nextCount = 0

		clearPhaseCallbacks(state)
	end
end

function TempoService.deconstruct<PhaseT>(self: Tempo<PhaseT>)
	self:clear()
	table.clear(self._phaseStates)
	table.clear(self._phaseByName)
	table.clear(self.phases)
	table.clear(self._recordsById)
	table.clear(self._freeRecords)
	self._freeCount = 0
end

return TempoService
