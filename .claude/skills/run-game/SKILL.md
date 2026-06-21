---
name: run-game
description: Launch and drive the RpgSimulator Godot game to verify gameplay/simulation changes. Use when asked to run, start, or confirm a change works in the actual game (not just by reading code) — especially time/cycle, entity, weather, or combat behavior.
---

# Running RpgSimulator (Godot 4.6)

This is a **Godot 4.6** project (`project.godot` → `config/features=("4.6", ...)`).
There is no `godot` on PATH; the editor/runtime is a standalone exe.

## 1. Locate the Godot executable

Known location on this machine (prefer the **console** build — it prints
stdout, the editor exe does not):

```
C:\Users\rocke\Desktop\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe
```

If that path is gone, rediscover it:

```powershell
Get-ChildItem "$env:USERPROFILE\Desktop","$env:LOCALAPPDATA" -Recurse -Filter "Godot*console.exe" -ErrorAction SilentlyContinue -Depth 4 | Select-Object -Expand FullName
```

## 2. Launch + drive (timed run, then inspect)

The game has **no programmatic input hook** — you cannot inject the `=` / `-`
speed keys into the window. So drive it by **launching for a few seconds and
reading what it logged**, not by pressing keys.

`time_controller.gd` logs `::Starting cycle N...` once per simulation cycle.
This goes to **stdout** AND to `world_log.txt` (gitignored), each line stamped
`[YYYY-MM-DD HH:MM:SS]`. Counting cycle lines per timestamp-second gives the
actual cycle rate — the ground truth for verifying time/speed changes.

```powershell
$exe  = "C:\Users\rocke\Desktop\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe"
$proj = "C:\Users\rocke\Documents\rpg-simulator"
$out  = "$env:TEMP\godot_run_out.txt"
Remove-Item $out,"$env:TEMP\godot_run_err.txt" -Force -ErrorAction SilentlyContinue
$p = Start-Process $exe -ArgumentList @("--path",$proj) -RedirectStandardOutput $out -RedirectStandardError "$env:TEMP\godot_run_err.txt" -PassThru -WindowStyle Minimized
Start-Sleep -Seconds 7
if (-not $p.HasExited) { Stop-Process -Id $p.Id -Force }

# 1) script/parse errors surface in stderr — must be empty for a clean run
Get-Content "$env:TEMP\godot_run_err.txt" -TotalCount 40

# 2) measure cycle rate (full-second buckets are the signal; partial first/last seconds clip)
(Get-Content $out | Select-String "Starting cycle") | ForEach-Object {
  if ($_ -match '\[(.+?)\]') { $matches[1] }
} | Group-Object | ForEach-Object { "{0} -> {1} cycles" -f $_.Name, $_.Count }
```

## 3. Interpreting cycle rate

In `time_controller.gd`: `frames += delta * time_scale * frame_rate`, cycle
fires at `CYCLE_INTERVAL = 1.0`. So at multiplier 1× the rate equals
`time_scale` cycles/sec (currently **4/sec**). Multipliers scale linearly
(2× → 8/sec, 4× → 16/sec) and cap at the window frame rate (~60/sec) because
every consumer steps at most once per frame on `time_controller.cycling`.

- **Run windowed (minimized is fine), NOT `--headless`** — headless can run the
  main loop uncapped, breaking the cycles/sec measurement.
- A clean run shows steady full-second buckets matching the expected rate and
  an empty stderr.

## Notes
- `world_log.txt` is overwritten each launch; `game_log.txt` is appended (and tracked).
- Engine version is pinned to 4.6 — use a 4.6.x build to avoid import churn.
