--!strict
--!optimize 2
--!native

local AdvancedUtils = require(game.ReplicatedStorage.packages.roblox_packages.advancedUtils)

export type HookCallback<T...> = AdvancedUtils.HookCallback<T...>
export type HookHandle<T...> = AdvancedUtils.HookHandle<T...>

return AdvancedUtils
