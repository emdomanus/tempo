--!strict
--!optimize 2
--!native

local TempoService = require(script.services.tempoService.shared.tempoService)
local Types = require(script.types)

export type Clock = Types.Clock
export type NativePhase = Types.NativePhase
export type PhaseName<PhaseT> = Types.PhaseName<PhaseT>
export type Phase<PhaseT> = Types.Phase<PhaseT>
export type ScheduledCallback = Types.ScheduledCallback
export type PhaseCallback = Types.PhaseCallback
export type Options = Types.Options
export type TempoHandle<PhaseT> = Types.TempoHandle<PhaseT>

return {
	new = TempoService.new :: <PhaseT>(options: Options?) -> Types.TempoHandle<PhaseT>,
}
