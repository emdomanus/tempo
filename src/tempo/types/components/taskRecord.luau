--!strict
--!optimize 2
--!native

local DefTypes = require(script.Parent.Parent.def)

export type ScheduledCallback = DefTypes.ScheduledCallback
export type TaskKind = DefTypes.TaskKind

export type TaskRecord = {
	id: number,
	phaseId: number,
	runAt: number,
	interval: number,
	callback: ScheduledCallback?,
	kind: TaskKind,
	active: boolean,
	heapIndex: number,
	nextQueued: boolean,
	running: boolean,
}

export type RecordPoolOwner = {
	_freeRecords: { TaskRecord },
	_freeCount: number,
}

return {}
