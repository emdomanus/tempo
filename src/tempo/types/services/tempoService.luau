--!strict
--!optimize 2
--!native

local DefTypes = require(script.Parent.Parent.def)
local TaskRecordTypes = require(script.Parent.Parent.components.taskRecord)
local PhaseManagerTypes = require(script.Parent.Parent.managers.phaseManager)

export type Clock = DefTypes.Clock
export type NativePhase = DefTypes.NativePhase
export type PhaseName<PhaseT> = DefTypes.PhaseName<PhaseT>
export type Phase<PhaseT> = DefTypes.Phase<PhaseT>
export type ScheduledCallback = DefTypes.ScheduledCallback
export type PhaseCallback = DefTypes.PhaseCallback
export type Options = DefTypes.Options
export type TaskRecord = TaskRecordTypes.TaskRecord
export type PhaseState = PhaseManagerTypes.PhaseState

export type PhaseMap<PhaseT> = {
	[string]: Phase<PhaseName<PhaseT>>,
	heartbeat: Phase<"heartbeat">,
}

export type PhaseInput<PhaseT> = Phase<PhaseName<PhaseT>> | PhaseName<PhaseT>

export type PhaseBinding = {
	state: PhaseState,
	localId: number,
}

export type TempoHandle<PhaseT> = {
	clock: Clock,
	protected: boolean,
	phases: PhaseMap<PhaseT>,

	addPhase: (self: TempoHandle<PhaseT>, name: PhaseT) -> Phase<PhaseName<PhaseT>>,
	getPhase: (self: TempoHandle<PhaseT>, phase: PhaseInput<PhaseT>?) -> Phase<PhaseName<PhaseT>>,
	evaluatePhase: (self: TempoHandle<PhaseT>, phase: PhaseInput<PhaseT>) -> (number) -> (),
	stepPhase: (self: TempoHandle<PhaseT>, phase: PhaseInput<PhaseT>, dt: number?, now: number?) -> (),

	bindPhase: (self: TempoHandle<PhaseT>, phase: PhaseInput<PhaseT>, callback: PhaseCallback) -> number,
	unbindPhase: (self: TempoHandle<PhaseT>, id: number) -> boolean,

	next: (self: TempoHandle<PhaseT>, callback: ScheduledCallback, phase: PhaseInput<PhaseT>?) -> number,
	at: (
		self: TempoHandle<PhaseT>,
		runAt: number,
		callback: ScheduledCallback,
		phase: PhaseInput<PhaseT>?
	) -> number,
	delay: (
		self: TempoHandle<PhaseT>,
		seconds: number,
		callback: ScheduledCallback,
		phase: PhaseInput<PhaseT>?
	) -> number,
	every: (
		self: TempoHandle<PhaseT>,
		interval: number,
		callback: ScheduledCallback,
		phase: PhaseInput<PhaseT>?
	) -> number,
	scheduleAt: (
		self: TempoHandle<PhaseT>,
		runAt: number,
		callback: ScheduledCallback,
		phase: PhaseInput<PhaseT>?
	) -> number,
	scheduleDelay: (
		self: TempoHandle<PhaseT>,
		seconds: number,
		callback: ScheduledCallback,
		phase: PhaseInput<PhaseT>?
	) -> number,

	cancel: (self: TempoHandle<PhaseT>, id: number) -> boolean,
	rescheduleAt: (
		self: TempoHandle<PhaseT>,
		id: number,
		runAt: number,
		phase: PhaseInput<PhaseT>?
	) -> boolean,
	rescheduleIn: (
		self: TempoHandle<PhaseT>,
		id: number,
		seconds: number,
		phase: PhaseInput<PhaseT>?
	) -> boolean,
	isActive: (self: TempoHandle<PhaseT>, id: number) -> boolean,

	warm: (self: TempoHandle<PhaseT>, count: number) -> (),
	clear: (self: TempoHandle<PhaseT>) -> (),
	deconstruct: (self: TempoHandle<PhaseT>) -> (),
}

export type Tempo<PhaseT> = TempoHandle<PhaseT> & {
	_phaseStates: { PhaseState },
	_phaseByName: { [string]: Phase<PhaseName<PhaseT>> },
	_bindingsById: { [number]: PhaseBinding },
	_defaultPhase: Phase<"heartbeat">,
	_recordsById: { [number]: TaskRecord },
	_freeRecords: { TaskRecord },
	_freeCount: number,
	_nextId: number,
	_nextBindingId: number,
}

return {}
