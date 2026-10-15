# QuickSalvage

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

UE4SS Lua mod for [Palworld](https://store.steampowered.com/app/1623730/Palworld/) that skips the **flotsam salvage** circular gauge (open-water salvage spots while on a water mount with a fishing rod).

Pure Lua hooks; no LogicMod `.pak` required. Same success path as hitting the green zone — loot tables and magnet use are unchanged.

## Features

- Auto-completes the gauge via `SendResult(true)` on the salvage UI model
- Handles `SetGaugeSize` firing slightly before `OnBeginAction` (common timing on client)
- Toggle on/off in-game with **Alt+F9** (QuickCatch uses **Alt+F12**)
- Hook cleanup on Lua reload (Ctrl+R)
- Small codebase — good reference for a minimal UE4SS hook mod

## Requirements

- [UE4SS](https://github.com/UE4SS-RE/RE-UE4SS) (Palworld experimental build)
- Palworld with UE4SS Lua mods enabled

## Install (Vortex — recommended)

1. Install [Vortex](https://www.nexusmods.com/about/vortex/) and the [Palworld extension](https://www.nexusmods.com/site/mods/770).
2. Install **UE4SS** for Palworld when Vortex prompts.
3. Install **QuickSalvage** from Nexus or a [GitHub release](https://github.com/cmoates/QuickSalvage/releases) and deploy with Vortex.

## Install (manual)

Copy `QuickSalvage/` to:

```
Palworld/Pal/Binaries/Win64/ue4ss/Mods/QuickSalvage/
```

Enable with `enabled.txt` **or** one line in `mods.txt` (not both):

```txt
QuickSalvage : 1
```

Launch the game or reload Lua with **Ctrl+R** after joining a world.

## Usage

1. Start flotsam salvage as usual (water mount + rod).
2. The gauge should resolve as a success without manual timing.
3. **Alt+F9** toggles the mod.

Confirm load in `UE4SS.log`:

```txt
[QuickSalvage] v1.0.0 loaded; ON (Alt+F9 toggle)
```

## How it works

1. When salvage starts, the game runs `BP_Action_FishingSalvage`.
2. When the gauge UI initializes, it calls `PalUIMapObjectTreasureBoxSalvageGameModel:SetGaugeSize`.
3. QuickSalvage calls `SendResult(true)` on that model — the same outcome as a perfect manual hit.
4. If the gauge callback arrives before `OnBeginAction`, the mod queues it and pairs on action start.

Optional fallback: if `SendResult` never runs, the mod may call `FinishSalvageGame()` once after `fallback_finish_ms`.

## Config (`Scripts/config.lua`)

| Option | Default | Description |
|--------|---------|-------------|
| `enabled` | `true` | Load-time switch; Alt+F9 toggles at runtime. |
| `gauge_set_delay_ms` | `80` | Delay before `SendResult(true)` after `SetGaugeSize`. |
| `pending_gauge_max_age_sec` | `2` | Max wait to pair an early `SetGaugeSize` with `OnBeginAction`. |
| `use_finish_salvage_fallback` | `true` | Call `FinishSalvageGame()` if `SendResult` never succeeded. |
| `fallback_finish_ms` | `8000` | Delay before the fallback runs. |
| `debug` | `false` | Extra logging in `UE4SS.log`. |

## Files

| File | Purpose |
|------|---------|
| `Scripts/main.lua` | Hooks, gauge pairing, toggle, reload cleanup |
| `Scripts/config.lua` | User settings |

## Repository

Source and releases: [github.com/cmoates/QuickSalvage](https://github.com/cmoates/QuickSalvage)

After you create a Nexus mod page, run `tools/setup-nexus-github.ps1` with your mod/file IDs to wire release uploads (same flow as QuickCatch).

## License

MIT — see [LICENSE](LICENSE).
