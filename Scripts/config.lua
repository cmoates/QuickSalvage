return {
    -- Master switch at load; Alt+F9 toggles in-game.
    enabled = true,

    -- Delay after SetGaugeSize before SendResult(true).
    gauge_set_delay_ms = 80,

    -- SetGaugeSize can fire a few ms before OnBeginAction; pair within this window.
    pending_gauge_max_age_sec = 2,

    -- FinishSalvageGame if SendResult never ran (unusual; leave on for safety).
    use_finish_salvage_fallback = true,
    fallback_finish_ms = 8000,

    -- Verbose UE4SS.log lines (hook registration, each auto-finish).
    debug = false,
}
