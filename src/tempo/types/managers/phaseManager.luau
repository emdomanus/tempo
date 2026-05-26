--!strict
--!optimize 2
--!native

local DefTypes = require(script.Parent.Parent.def)
local TaskRecordTypes = require(script.Parent.Parent.components.taskRecord)
local AdvancedUtils = require(script.Parent.Parent.Parent.Parent.externalPackages.advancedUtils)

export type Phase = DefTypes.Phase<any>
export type PhaseCallback = DefTypes.PhaseCallback
export type TaskRecord = TaskRecordTypes.TaskRecord

export type PhaseState = {
	token: Phase,
	heap: { TaskRecord },
	heapSize: number,
	nextQueue: { TaskRecord },
	nextCount: number,
	callbacks: AdvancedUtils.HookHandle<number, number>,
	evaluator: ((number) -> ())?,
}

export type PhaseManager = {
	createState: (token: Phase) -> PhaseState,
	bind: (state: PhaseState, callback: PhaseCallback) -> number,
	unbind: (state: PhaseState, id: number) -> boolean,
	clear: (state: PhaseState) -> (),
}

return {}
