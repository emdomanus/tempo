--!strict
--!optimize 2
--!native

local DefTypes = require(script.Parent.Parent.def)
local TaskRecordTypes = require(script.Parent.Parent.components.taskRecord)
local Hook = require(script.Parent.Parent.Parent.Parent.roblox_packages.hook)

export type Phase = DefTypes.Phase<any>
export type PhaseCallback = DefTypes.PhaseCallback
export type TaskRecord = TaskRecordTypes.TaskRecord

export type PhaseState = {
	token: Phase,
	heap: { TaskRecord },
	heapSize: number,
	nextQueue: { TaskRecord },
	nextCount: number,
	callbacks: Hook.HookHandle<number, number>,
	evaluator: ((number) -> ())?,
}

export type PhaseManager = {
	createState: (token: Phase) -> PhaseState,
	bind: (state: PhaseState, callback: PhaseCallback) -> number,
	unbind: (state: PhaseState, id: number) -> boolean,
	clear: (state: PhaseState) -> (),
}

return {}
