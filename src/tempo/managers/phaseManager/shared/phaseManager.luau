--!strict
--!optimize 2
--!native

local Types = require(script.Parent.Parent.Parent.Parent.types)
local AdvancedUtils = require(script.Parent.Parent.Parent.Parent.Parent.externalPackages.advancedUtils)

type Phase = Types.Phase<any>
type PhaseCallback = Types.PhaseCallback
type PhaseState = Types.PhaseState

local PhaseManager = {}

function PhaseManager.createState(token: Phase): PhaseState
	return {
		token = token,
		heap = {},
		heapSize = 0,
		nextQueue = {},
		nextCount = 0,
		callbacks = AdvancedUtils.core.hook.new(),
		evaluator = nil,
	}
end

function PhaseManager.bind(state: PhaseState, callback: PhaseCallback): number
	return state.callbacks:add(callback)
end

function PhaseManager.unbind(state: PhaseState, id: number): boolean
	return state.callbacks:remove(id)
end

function PhaseManager.clear(state: PhaseState)
	state.callbacks:clear()
end

return PhaseManager
