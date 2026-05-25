--!strict
--!optimize 2
--!native

local Types = require(script.Parent.Parent.Parent.Parent.types)

type TaskRecord = Types.TaskRecord
type PhaseState = Types.PhaseState

local HeapManager = {}

local function less(a: TaskRecord, b: TaskRecord): boolean
	if a.runAt ~= b.runAt then
		return a.runAt < b.runAt
	end
	return a.id < b.id
end

local function swap(heap: { TaskRecord }, a: number, b: number)
	local av = heap[a]
	local bv = heap[b]
	heap[a] = bv
	heap[b] = av
	av.heapIndex = b
	bv.heapIndex = a
end

local function up(state: PhaseState, index: number)
	local heap = state.heap
	while index > 1 do
		local parent = index // 2
		if less(heap[parent], heap[index]) then
			break
		end
		swap(heap, parent, index)
		index = parent
	end
end

local function down(state: PhaseState, index: number)
	local heap = state.heap
	local count = state.heapSize
	while true do
		local left = index * 2
		if left > count then
			break
		end

		local right = left + 1
		local smallest = left
		if right <= count and less(heap[right], heap[left]) then
			smallest = right
		end
		if less(heap[index], heap[smallest]) then
			break
		end

		swap(heap, index, smallest)
		index = smallest
	end
end

function HeapManager.push(state: PhaseState, record: TaskRecord)
	local index = state.heapSize + 1
	state.heapSize = index
	state.heap[index] = record
	record.heapIndex = index
	up(state, index)
end

function HeapManager.remove(state: PhaseState, record: TaskRecord)
	local index = record.heapIndex
	if index <= 0 then
		return
	end

	local heap = state.heap
	local last = state.heapSize
	local moved = heap[last]
	heap[last] = nil :: any
	state.heapSize = last - 1
	record.heapIndex = 0

	if index ~= last and moved then
		heap[index] = moved
		moved.heapIndex = index
		down(state, index)
		up(state, index)
	end
end

function HeapManager.repair(state: PhaseState, record: TaskRecord)
	local index = record.heapIndex
	if index <= 0 then
		return
	end
	down(state, index)
	up(state, index)
end

function HeapManager.peek(state: PhaseState): TaskRecord?
	if state.heapSize == 0 then
		return nil
	end
	return state.heap[1]
end

function HeapManager.pop(state: PhaseState): TaskRecord?
	local top = HeapManager.peek(state)
	if top == nil then
		return nil
	end
	HeapManager.remove(state, top)
	return top
end

return HeapManager
