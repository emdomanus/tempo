--!strict
--!optimize 2
--!native

local TaskRecordTypes = require(script.Parent.Parent.components.taskRecord)

export type TaskRecord = TaskRecordTypes.TaskRecord

export type HeapState = {
	heap: { TaskRecord },
	heapSize: number,
}

export type HeapManager = {
	push: (state: HeapState, record: TaskRecord) -> (),
	remove: (state: HeapState, record: TaskRecord) -> (),
	repair: (state: HeapState, record: TaskRecord) -> (),
	peek: (state: HeapState) -> TaskRecord?,
	pop: (state: HeapState) -> TaskRecord?,
}

return {}
