--!strict
--!optimize 2
--!native

local AdvancedUtils = require(script.Parent.Parent.Parent.roblox_packages.advancedUtils)

export type HookCallback<T...> = AdvancedUtils.HookCallback<T...>
export type HookHandle<T...> = AdvancedUtils.HookHandle<T...>

return AdvancedUtils
