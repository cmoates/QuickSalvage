return {
    -- Master switch at load; Alt+F9 toggles in-game.
    enabled = true,

    -- Wait before calling FinishSalvageGame (lets the gauge UI initialize).
    delay_ms = 200,

    -- Second attempt after SetupAnim (backup if OnBeginAction was too early).
    retry_delay_ms = 120,

    -- Extra log lines in UE4SS.log (hook registration, each auto-finish).
    debug = false,
}
