--!strict
--!optimize 2

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Tempo = require(ReplicatedStorage.packages.tempo)

local tempo: Tempo.TempoHandle<"preRender"> = Tempo.new({
	protected = true,
})

local heartbeat = tempo.phases.heartbeat
local preRender = tempo:addPhase("preRender")

tempo:warm(128)

RunService.Heartbeat:Connect(tempo:evaluatePhase(heartbeat))
RunService.PreRender:Connect(tempo:evaluatePhase(preRender))

local started = os.clock()
local complete = false

local completeBinding = tempo:bindPhase(heartbeat, function(_dt, now)
	if not complete and now - started > 5 then
		complete = true
		tempo:unbindPhase(completeBinding)
		print("[TempoDev] complete")
	end
end)

tempo:delay(0.25, function(now)
	print(("[TempoDev] heartbeat delay %.3f"):format(now - started))
end)

local rescheduled = tempo:delay(2, function(now)
	print(("[TempoDev] rescheduled delay %.3f"):format(now - started))
end, preRender)

tempo:rescheduleIn(rescheduled, 0.5)

local count = 0
local everyId = 0
everyId = tempo:every(0.5, function(now)
	count += 1
	print(("[TempoDev] every %d at %.3f"):format(count, now - started))
	if count >= 3 then
		tempo:cancel(everyId)
	end
end)
