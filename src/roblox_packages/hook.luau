--!strict
--!optimize 2
--!native

local main = require(script.Parent.Parent.Parent["hook"])

export type Callback<T...> = main.Callback<T...>
export type Hook<T...> = main.Hook<T...>
export type HookHandle<T...> = main.HookHandle<T...>

return main
