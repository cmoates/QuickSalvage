-- QuickSalvage — skip the flotsam salvage gauge (open-water salvage spots).
-- Pattern: post-hook a Blueprint action → call FinishSalvageGame() after a short delay.
local config = require("config")

local MOD = "[QuickSalvage]"
local VERSION = "0.1.1"

local SALVAGE_ACTION =
    "/Game/Pal/Blueprint/Action/Common/BP_Action_FishingSalvage.BP_Action_FishingSalvage_C"

local G = _G.__QUICKSALVAGE or {}
_G.__QUICKSALVAGE = G
G.hook_registry = G.hook_registry or {}

local enabled = config.enabled == true

local function log(msg)
    print(MOD .. " " .. msg .. "\n")
end

local function debug_log(msg)
    if config.debug then
        log(msg)
    end
end

local function safe(fn, fallback)
    local ok, result = pcall(fn)
    if ok then return result end
    return fallback
end

local function delay_ms(value, fallback)
    local ms = tonumber(value) or tonumber(fallback) or 100
    ms = math.max(1, math.floor(ms + 0.5))
    return tonumber(string.format("%d", ms))
end

local function valid(obj)
    return obj ~= nil and safe(function() return obj:IsValid() end, false)
end

local function unwrap(value)
    if value == nil then return nil end
    return safe(function() return value:get() end, nil) or value
end

-- --- Reload safety (same idea as QuickCatch) ---------------------------------

local function unregister_all_tracked_hooks()
    for path, ids in pairs(G.hook_registry) do
        pcall(function()
            UnregisterHook(path, ids.pre, ids.post)
        end)
    end
    G.hook_registry = {}
end

unregister_all_tracked_hooks()
G.is_lua_reload = G.loaded_once == true
G.loaded_once = true

-- --- Core behavior -----------------------------------------------------------

local function finish_salvage(action, source)
    if not enabled then return end

    action = unwrap(action)
    if not valid(action) then return end

    local ok = safe(function()
        action:FinishSalvageGame()
        return true
    end, false)

    if config.debug then
        if ok then
            log("flotsam salvage finished (" .. source .. ")")
        else
            log("FinishSalvageGame failed (" .. source .. ")")
        end
    end
end

local function schedule_finish(action, source, ms)
    ExecuteInGameThreadWithDelay(delay_ms(ms, config.delay_ms), function()
        finish_salvage(action, source)
    end)
end

local function register_post_hook(path, label, callback)
    if G.hook_registry[path] then
        return true
    end
    local ok = safe(function()
        local pre, post = RegisterHook(path, function() end, callback)
        G.hook_registry[path] = { pre = pre, post = post }
        return true
    end, false)
    if ok then
        debug_log("hooked " .. label)
    end
    return ok
end

local HOOKS = {
    {
        label = "OnBeginAction",
        path = SALVAGE_ACTION .. ":OnBeginAction",
        fn = function(context)
            schedule_finish(context, "OnBeginAction", config.delay_ms)
        end,
    },
    {
        label = "SetupAnim",
        path = SALVAGE_ACTION .. ":SetupAnim",
        fn = function(context)
            schedule_finish(context, "SetupAnim", config.retry_delay_ms)
        end,
    },
}

local function register_all_hooks()
    local failed = {}
    for _, entry in ipairs(HOOKS) do
        if not register_post_hook(entry.path, entry.label, entry.fn) then
            failed[#failed + 1] = entry.label
        end
    end
    return failed
end

-- Blueprint classes may not exist at mod load; retry like QuickCatch.
local function retry_hooks(attempt, wait_ms)
    ExecuteInGameThreadWithDelay(delay_ms(wait_ms, 7000), function()
        local failed = register_all_hooks()
        if #failed == 0 then
            if attempt > 1 then
                log("hooks ready (attempt " .. attempt .. ")")
            end
            return
        end
        if attempt < 4 then
            retry_hooks(attempt + 1, wait_ms * 2)
        else
            log("hooks failed: " .. table.concat(failed, ", "))
        end
    end)
end

register_all_hooks()
retry_hooks(1, 7000)

RegisterKeyBind(Key.F9, { ModifierKey.ALT }, function()
    enabled = not enabled
    log("quick salvage " .. (enabled and "ON" or "OFF"))
end)

log("v" .. VERSION .. " loaded; " .. (enabled and "ON" or "OFF") .. " (Alt+F9 toggle)")
if G.is_lua_reload then
    log("Lua reload — restart Palworld if behavior looks wrong")
end
