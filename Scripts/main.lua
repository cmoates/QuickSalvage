-- QuickSalvage — skip the flotsam salvage gauge (open-water salvage spots).
local config = require("config")

local MOD = "[QuickSalvage]"
local VERSION = "1.0.0"

local SALVAGE_ACTION =
    "/Game/Pal/Blueprint/Action/Common/BP_Action_FishingSalvage.BP_Action_FishingSalvage_C"

local GAUGE_MODEL =
    "/Script/Pal.PalUIMapObjectTreasureBoxSalvageGameModel:SetGaugeSize"

local G = _G.__QUICKSALVAGE or {}
_G.__QUICKSALVAGE = G
G.hook_registry = G.hook_registry or {}

local enabled = config.enabled == true
local attempt_id = 0
local salvage_active = false
local result_sent_for_attempt = 0
local fallback_generation = 0

local pending_gauge_model = nil
local pending_gauge_at = 0

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

local function resolve_action(...)
    local argc = select("#", ...)
    for i = 1, argc do
        local candidate = unwrap(select(i, ...))
        if not valid(candidate) then
            goto continue
        end
        local name = safe(function()
            local cls = candidate:GetClass()
            if not cls or not cls:IsValid() then return "" end
            return cls:GetFName():ToString()
        end, "")
        if name:find("FishingSalvage", 1, true) then
            return candidate
        end
        ::continue::
    end
    return unwrap(select(1, ...))
end

local function unregister_all_tracked_hooks()
    for path, ids in pairs(G.hook_registry) do
        pcall(function()
            UnregisterHook(path, ids.pre, ids.post)
        end)
    end
    G.hook_registry = {}
end

unregister_all_tracked_hooks()
attempt_id = 0
salvage_active = false
result_sent_for_attempt = 0
fallback_generation = fallback_generation + 1
pending_gauge_model = nil
pending_gauge_at = 0
G.is_lua_reload = G.loaded_once == true
G.loaded_once = true

local function cancel_fallback()
    fallback_generation = fallback_generation + 1
end

local function clear_pending_gauge()
    pending_gauge_model = nil
    pending_gauge_at = 0
end

local function send_gauge_success(model, source, for_attempt)
    if not enabled then return false end
    if for_attempt ~= nil and result_sent_for_attempt == for_attempt then
        return true
    end

    model = unwrap(model)
    if not valid(model) then
        debug_log("SendResult skipped — invalid model (" .. source .. ")")
        return false
    end

    local ok, err = pcall(function()
        model:SendResult(true)
    end)

    if ok then
        if for_attempt ~= nil then
            result_sent_for_attempt = for_attempt
        end
        cancel_fallback()
        debug_log("SendResult(true) (" .. source .. ")")
        return true
    end

    log("SendResult failed (" .. source .. "): " .. tostring(err))
    return false
end

local function schedule_gauge_success(model, source, for_attempt)
    local token = for_attempt or attempt_id
    ExecuteInGameThreadWithDelay(delay_ms(config.gauge_set_delay_ms, 80), function()
        if not enabled or not salvage_active then return end
        if token ~= attempt_id then return end
        send_gauge_success(model, source, token)
    end)
end

local function consume_pending_gauge(for_attempt)
    if pending_gauge_model == nil then return false end
    local age = os.clock() - pending_gauge_at
    if age > (tonumber(config.pending_gauge_max_age_sec) or 2) then
        clear_pending_gauge()
        return false
    end

    local model = pending_gauge_model
    clear_pending_gauge()
    schedule_gauge_success(model, "pending+OnBeginAction", for_attempt)
    return true
end

local function finish_salvage_fallback(action, source, for_attempt)
    if config.use_finish_salvage_fallback ~= true then return end
    if for_attempt ~= attempt_id or result_sent_for_attempt == for_attempt then return end

    action = resolve_action(action)
    if not valid(action) then return end

    safe(function()
        action:FinishSalvageGame()
        debug_log("FinishSalvageGame fallback (" .. source .. ")")
    end)
end

local function schedule_fallback_finish(action, for_attempt)
    if config.use_finish_salvage_fallback ~= true then return end

    fallback_generation = fallback_generation + 1
    local fb_gen = fallback_generation

    ExecuteInGameThreadWithDelay(delay_ms(config.fallback_finish_ms, 8000), function()
        if fb_gen ~= fallback_generation or not enabled then return end
        if for_attempt ~= attempt_id or not salvage_active then return end
        if result_sent_for_attempt == for_attempt then return end
        finish_salvage_fallback(action, "no-SendResult", for_attempt)
    end)
end

local function on_salvage_begin(...)
    local action = resolve_action(...)
    if not valid(action) then return end

    attempt_id = attempt_id + 1
    local this_attempt = attempt_id
    salvage_active = true
    cancel_fallback()

    debug_log("salvage started (#" .. this_attempt .. ")")
    consume_pending_gauge(this_attempt)
    schedule_fallback_finish(action, this_attempt)
end

local function on_salvage_end()
    salvage_active = false
    cancel_fallback()
    clear_pending_gauge()
end

local function on_gauge_size(context)
    if not enabled then return end

    local model = unwrap(context)
    debug_log("SetGaugeSize")

    if salvage_active and attempt_id > 0 then
        schedule_gauge_success(model, "SetGaugeSize", attempt_id)
        return
    end

    pending_gauge_model = model
    pending_gauge_at = os.clock()
    debug_log("SetGaugeSize queued (before OnBeginAction)")
end

local function register_hook(path, label, callback)
    if G.hook_registry[path] then
        return true
    end

    local pre, post
    local ok = safe(function()
        if path:sub(1, 8) == "/Script/" then
            pre, post = RegisterHook(path, function() end, callback)
        else
            pre, post = RegisterHook(path, callback)
        end
        return pre ~= nil or post ~= nil
    end, false)

    if ok then
        G.hook_registry[path] = { pre = pre, post = post }
        debug_log("hooked " .. label)
        return true
    end

    return false
end

local HOOKS = {
    {
        label = "BP_Action_FishingSalvage.OnBeginAction",
        path = SALVAGE_ACTION .. ":OnBeginAction",
        fn = on_salvage_begin,
    },
    {
        label = "BP_Action_FishingSalvage.OnEndAction",
        path = SALVAGE_ACTION .. ":OnEndAction",
        fn = on_salvage_end,
    },
    {
        label = "PalUIMapObjectTreasureBoxSalvageGameModel.SetGaugeSize",
        path = GAUGE_MODEL,
        fn = on_gauge_size,
    },
}

local function register_all_hooks()
    local failed = {}
    for _, entry in ipairs(HOOKS) do
        if not register_hook(entry.path, entry.label, entry.fn) then
            failed[#failed + 1] = entry.label
        end
    end
    return failed
end

local function retry_hooks(attempt, wait_ms)
    ExecuteInGameThreadWithDelay(delay_ms(wait_ms, 7000), function()
        local failed = register_all_hooks()
        if #failed == 0 then
            return
        end
        if attempt < 4 then
            retry_hooks(attempt + 1, wait_ms * 2)
        else
            log("hooks failed: " .. table.concat(failed, ", "))
        end
    end)
end

local failed_now = register_all_hooks()
if #failed_now > 0 then
    retry_hooks(1, 7000)
elseif config.debug then
    log("hooks ready")
end

RegisterKeyBind(Key.F9, { ModifierKey.ALT }, function()
    enabled = not enabled
    if not enabled then
        on_salvage_end()
    end
    log("quick salvage " .. (enabled and "ON" or "OFF"))
end)

log("v" .. VERSION .. " loaded; " .. (enabled and "ON" or "OFF") .. " (Alt+F9 toggle)")
if G.is_lua_reload then
    log("Lua reload — restart Palworld if behavior looks wrong")
end
