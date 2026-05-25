--!strict
--!optimize 2
--!native

export type Clock = () -> number

export type NativePhase = "heartbeat"
export type PhaseName<PhaseT> = NativePhase | PhaseT

export type Phase<PhaseT> = {
	id: number,
	name: PhaseT,
}

export type ScheduledCallback = (now: number) -> ()
export type PhaseCallback = (dt: number, now: number) -> ()

export type Options = {
	clock: Clock?,
	protected: boolean?,
}

export type TaskKind = "once" | "every"

return {}
