# QuickSalvage

Small UE4SS Lua mod for [Palworld](https://store.steampowered.com/app/1623730/Palworld/) **flotsam salvage**: the circular gauge on open-water salvage spots (water mount + fishing rod).

Good reference if you want a **minimal hook mod** without QuickCatch-level complexity.

## Behavior

1. When salvage starts, the game runs `BP_Action_FishingSalvage`.
2. QuickSalvage post-hooks `OnBeginAction` and `SetupAnim`.
3. After a short delay it calls `FinishSalvageGame()` — the same success path as hitting the green zone.
4. Loot tables and magnet use are unchanged.

## Install

Copy `QuickSalvage/` to:

`Palworld/Pal/Binaries/Win64/ue4ss/Mods/QuickSalvage/`

Enable with `enabled.txt` **or** one line in `mods.txt` (not both):

```txt
QuickSalvage : 1
```

## Usage

1. Start flotsam salvage as usual.
2. **Alt+F9** toggles the mod (QuickCatch uses **Alt+F12**).

Log line: `[QuickSalvage] v0.1.1 loaded; ON (Alt+F9 toggle)`.

## Config (`Scripts/config.lua`)

| Option | Default | Description |
|--------|---------|-------------|
| `enabled` | `true` | Load-time switch; Alt+F9 toggles at runtime. |
| `delay_ms` | `200` | Delay before `FinishSalvageGame` on `OnBeginAction`. |
| `retry_delay_ms` | `120` | Delay on `SetupAnim` (backup timing). |
| `debug` | `false` | Extra logging. |

## Files to read

| File | Purpose |
|------|---------|
| `Scripts/main.lua` | Hooks, delay, toggle, reload cleanup |
| `Scripts/config.lua` | User settings |

## Repository

Source and releases: [github.com/cmoates/QuickSalvage](https://github.com/cmoates/QuickSalvage)

After you create a Nexus mod page, run `tools/setup-nexus-github.ps1` with your mod/file IDs to wire release uploads (same flow as QuickCatch).

## License

MIT — see [LICENSE](LICENSE).
