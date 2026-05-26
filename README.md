# Tempo

Tempo is a phase-aware scheduler for Roblox.

It is built around explicit phase tokens, numeric task ids, pooled records, `advancedUtils` Hook-backed phase subscribers, and per-phase heaps. The library does not connect itself to `RunService`; callers bind phases to whatever driver they want.

Tempo uses pesde for dependencies, including the public `advanced_utils` package through the `advancedUtils` alias. Run this after cloning:

```sh
pesde install
```

The dev Rojo project mounts the generated `roblox_packages` folder beside Tempo under `ReplicatedStorage.packages`.

```lua
local RunService = game:GetService("RunService")
local Tempo = require(ReplicatedStorage.packages.tempo)

type VmmoPhase = "preRender"

local tempo: Tempo.TempoHandle<VmmoPhase> = Tempo.new()
local heartbeat = tempo.phases.heartbeat
local preRender = tempo:addPhase("preRender")

RunService.Heartbeat:Connect(tempo:evaluatePhase(heartbeat))
RunService.PreRender:Connect(tempo:evaluatePhase(preRender))

local id = tempo:delay(0.25, function(now)
	print("ran", now)
end, preRender)

tempo:rescheduleIn(id, 0.1)
tempo:cancel(id)
```

`heartbeat` is the only native phase. Custom phases are supplied by the caller through the `TempoHandle<PhaseT>` type.

Use phase tokens in hot paths. String phase names are accepted for convenience, but tokens avoid repeated name lookup.
