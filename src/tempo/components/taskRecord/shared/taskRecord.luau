--!strict
--!optimize 2
--!native

local Types = require(script.Parent.Parent.Parent.Parent.types)

type TaskKind = Types.TaskKind
type TaskRecord = Types.TaskRecord
type RecordPoolOwner = Types.RecordPoolOwner
type ScheduledCallback = Types.ScheduledCallback

local TaskRecord = {}

local function create(): TaskRecord
	return {
		id = 0,
		phaseId = 0,
		runAt = 0,
		interval = 0,
		callback = nil,
		kind = "once",
		active = false,
		heapIndex = 0,
		nextQueued = false,
		running = false,
	}
end

local function reset(record: TaskRecord)
	record.id = 0
	record.phaseId = 0
	record.runAt = 0
	record.interval = 0
	record.callback = nil
	record.kind = "once"
	record.active = false
	record.heapIndex = 0
	record.nextQueued = false
	record.running = false
end

function TaskRecord.take(owner: RecordPoolOwner): TaskRecord
	local freeCount = owner._freeCount
	if freeCount > 0 then
		local record = owner._freeRecords[freeCount]
		owner._freeRecords[freeCount] = nil :: any
		owner._freeCount = freeCount - 1
		return record
	end
	return create()
end

function TaskRecord.recycle(owner: RecordPoolOwner, record: TaskRecord)
	reset(record)

	local index = owner._freeCount + 1
	owner._freeCount = index
	owner._freeRecords[index] = record
end

function TaskRecord.warm(owner: RecordPoolOwner, count: number)
	for _ = 1, math.max(math.floor(count), 0) do
		local index = owner._freeCount + 1
		owner._freeCount = index
		owner._freeRecords[index] = create()
	end
end

function TaskRecord.configure(
	record: TaskRecord,
	id: number,
	phaseId: number,
	runAt: number,
	callback: ScheduledCallback,
	kind: TaskKind,
	interval: number,
	nextQueued: boolean
)
	record.id = id
	record.phaseId = phaseId
	record.runAt = runAt
	record.interval = interval
	record.callback = callback
	record.kind = kind
	record.active = true
	record.heapIndex = 0
	record.nextQueued = nextQueued
	record.running = false
end

return TaskRecord
