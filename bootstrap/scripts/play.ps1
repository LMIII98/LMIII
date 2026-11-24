# Play: apply the faster title settings, then launch with auto-skip, on the diag build.
#
#   powershell -ExecutionPolicy Bypass -File bootstrap\scripts\play.ps1 -Root D:\GTA6.Xbox.v1.0.2
#
# -Root is the folder that holds the game dump (game_scarlett_master.exe) and the
# victory-gta6 clone (the fork checked out at `newer`).
#
# The diag build is not optional: VICTORY_SKIP_PIPELINES and VICTORY_GPU_TIMING live
# behind #[cfg(feature = "diagnostics")], so a release build ignores them and loses the
# device (0x887A0006) about 40 seconds into the world.

param(
    [string]$Root = 'D:\GTA6.Xbox.v1.0.2',
    [int]$Minutes = 30,
    [int]$KeysForMinutes = 6,
    [string]$Exe = ''
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
if ($Exe -eq '') { $Exe = Join-Path $Root 'victory-gta6\target\diag\victory.exe' }
if (-not (Test-Path $Exe)) { throw "no build at $Exe - run cargo build --profile diag -p victory --features diagnostics" }

# 1. the title rewrites its own settings on exit; put the faster ones back
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'apply-settings.ps1') -Root $Root -Quiet

# 2. the switches that keep the world alive, and the ones that make it faster
$env:VICTORY_CONFIG              = Join-Path $Root 'victory.toml'
$env:VICTORY_LOG                 = 'info'
$env:VICTORY_SKIP_PIPELINES      = '2561af9577c47289'
$env:VICTORY_GPU_TIMING          = '1'
$env:VICTORY_CARD_BUFFERS_MIN_MB = '1'
$env:VICTORY_CARD_BUFFERS_MB     = '1024'
$env:VICTORY_WINDOW_KB           = '1024'
$env:VICTORY_WINDOW_TAILS        = '1'

Write-Host @'
Grand Theft Auto VI, Xbox 1.0.2.1 - 3 fps in the world, the prologue renders
  Enter    confirm / skip loading and cutscenes (pad A)
  Esc      back / skip a cutscene (pad B)
  WASD move, IJKL look, X Y actions, arrows d-pad, Q E shoulders, Z C triggers,
  Tab camera, Esc menu
  Enter keeps being pressed for the first few minutes, then stops so it does not
  disturb the game.

'@

$autopilot = Join-Path $PSScriptRoot 'autopilot.ps1'
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $autopilot -Exe $Exe -Root $Root -Minutes $Minutes -KeysForMinutes $KeysForMinutes
