# This branch: running the 1.0.2.1 Scarlett build on one Windows PC

This is a working branch on top of [VIctory](README.md) `main` (`ffe310e`) with
one goal: getting the leaked-dec-2026 Xbox Series build (1.0.2.1) to run, and
recording what actually happens on a real machine. Source only — no game
files, no assets, as `docs/asset-policy.md` requires.

Tested machine: Windows 11, Ryzen 7 9800X3D, 32 GB, GeForce RTX 5070 12 GB.
Toolchain: Rust 1.100 MSVC (VS Build Tools 14.44 + Windows SDK 26100); the
GNU toolchain also builds it except for the Agility SDK exports.

## What works

| Stage | State |
|---|---|
| Boot, first-boot screens, menus | 30 fps, keyboard drives it |
| Loading into the world | ~50 s |
| The world | **loads and runs**, 1-2 fps, dark: most draws drop for want of a pipeline |

## Commits here, on top of `main`

| Commit | What |
|---|---|
| `3a75a95` | `SetEventOnCompletion(v, NULL)` blocks on a condvar; `DispatchMeshX` runs its indirect arguments; the 1.0.2.1 build is identified |
| `7e3f33c` | `image_sample_*_cl`; the descriptor a constant-buffer load reads through is named for what it is |
| `e41c91a` | the copies of title memory outside buffers get a 512 MiB LRU budget (this was the 50-second crash: unbounded 4 MiB windows) |
| `2c7d588` | a refused compute pipeline says which wave it needed (all 313 want 64 lanes, the host has 32) |
| `0d2c409` | `VICTORY_SHADER_WAVE_RUN=1` leaves the wave requirement out (diagnostics): compute pipelines 1,128 → 1,440, wrong pixels as expected |
| `28c6588` | overlapping refreshes of one title buffer are merged at submission |
| `daabcdb` | a test for the target shapes the world asks for, and what the PC refuses |
| `44e16ab` | when a texture cannot be made, ask the device which part it objects to |
| `66d7c7f` | ship the DirectX 12 Agility SDK with the front end (exports in `victory.def`) |
| merges | upstream PRs #305 (64-bit image atomics), #704 (unknown-stride buffers), #1084 (untracked-mask select): vertex/pixel programs emitted 12,231 → 12,751 |

`docs/progress-2026-11-25.md` has the full log: measurements, logs, what each
attempt changed, and what stayed broken.

## Findings worth keeping

* The world's 2560x1440 colour targets are **3D textures with
  `ALLOW_RENDER_TARGET`**, which D3D12 on PC refuses outright; the same
  texture without that flag is accepted. Rendering into one needs emulation.
* Every compute pipeline the world cannot make wants a **64-lane wave**; the
  host's widest is 32. Fragments of wave64 emulation are not worth it: the
  programs use swizzles, lane reads and masks together.
* Frame time in the world is dominated by **copies of title memory** (~9 GB a
  frame here): the big pools are section-mapped, so they cannot be
  write-watched and are copied whole. One address space (#407) is the fix.
* The **Agility SDK runtime loads** if the executable exports
  `D3D12SDKVersion` and `D3D12SDKPath` — the path as a `const char *`
  (a pointer), not the characters inline, which crashes `d3d12.dll` in its
  init. The debug layer still does not come up through it.

## Where the picture is

The fork [fxceless/victory-gta6](https://github.com/fxceless/victory-gta6)
(based on the same `ffe310e`) solves the 3D-target problem with colour twins
and renders the prologue. On this machine it runs the world at 0.6–1.9 fps
and **lost the device after ~150 s**; skipping one compute pipeline
(`VICTORY_SKIP_PIPELINES=2561af9577c47289`) plus per-list submission
(`VICTORY_GPU_TIMING=1`) made it survive more than 280 s with the slowest list
down from 5,038 ms to ~100 ms. `docs/gta6-fork-agility-and-probe.patch` carries
this branch's two pieces over to that fork (the Agility SDK exports and the
texture probe).

## Running it (your own files)

```powershell
$env:RUSTUP_TOOLCHAIN='stable-x86_64-pc-windows-msvc'
cargo build --release -p victory
target\release\victory.exe run <game dir>\game_scarlett_master.exe --execute
```

`victory.toml` points at your dump and at cache/data folders outside the
repository (see `victory.example.toml`). Put `D3D12Core.dll` and
`d3d12SDKLayers.dll` in `D3D12\` beside the executable if you want the Agility
runtime; the binary works without them.
