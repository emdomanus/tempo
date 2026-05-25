--!strict
--!optimize 2
--!native

local Tempo = require(script.tempo)

export type Clock = Tempo.Clock
export type NativePhase = Tempo.NativePhase
export type PhaseName<PhaseT> = Tempo.PhaseName<PhaseT>
export type Phase<PhaseT> = Tempo.Phase<PhaseT>
export type ScheduledCallback = Tempo.ScheduledCallback
export type PhaseCallback = Tempo.PhaseCallback
export type Options = Tempo.Options
export type TempoHandle<PhaseT> = Tempo.TempoHandle<PhaseT>

return Tempo
