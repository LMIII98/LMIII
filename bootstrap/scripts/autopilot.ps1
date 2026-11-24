# Auto-skip: launch the title, keep its window in front, tap Enter/Esc so the loading
# screens and the opening cutscenes pass on their own; stop tapping after a while so the
# game is left to the player.
#
#   powershell -ExecutionPolicy Bypass -File bootstrap\scripts\autopilot.ps1 -Root D:\GTA6.Xbox.v1.0.2
#
# The taps are real keyboard events (keybd_event), so they work with the release build
# too; the window has to be in front, which this script takes care of every few seconds.

param(
    [string]$Root = 'D:\GTA6.Xbox.v1.0.2',
    [string]$Exe = '',
    [int]$Minutes = 30,
    [int]$KeysForMinutes = 6,
    [int]$EnterEvery = 3,
    [int]$EscEvery = 45
)

$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
if ($Exe -eq '') { $Exe = Join-Path $Root 'victory-gta6\target\diag\victory.exe' }

if (-not ('VictoryKeys' -as [type])) {
    Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class VictoryKeys {
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")] public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);
    public static void Tap(byte vk) {
        keybd_event(vk, 0, 0, UIntPtr.Zero);
        System.Threading.Thread.Sleep(60);
        keybd_event(vk, 0, 2, UIntPtr.Zero);
    }
}
'@
}

$env:VICTORY_CONFIG              = Join-Path $Root 'victory.toml'
$env:VICTORY_LOG                 = 'info'
$env:VICTORY_SKIP_PIPELINES      = '2561af9577c47289'
$env:VICTORY_GPU_TIMING          = '1'
$env:VICTORY_CARD_BUFFERS_MIN_MB = '1'
$env:VICTORY_CARD_BUFFERS_MB     = '1024'
$env:VICTORY_WINDOW_KB           = '1024'
$env:VICTORY_WINDOW_TAILS        = '1'

Write-Host "launching $Exe" -ForegroundColor Cyan
$log = Join-Path $Root 'victory-run.log'
$game = Start-Process -PassThru -FilePath $Exe `
    -ArgumentList 'run', (Join-Path $Root 'game_scarlett_master.exe'), '--execute', '--console', 'series-x' `
    -WorkingDirectory $Root -RedirectStandardOutput $log -RedirectStandardError "$log.err"

$deadline  = (Get-Date).AddMinutes($Minutes)
$keysUntil = (Get-Date).AddMinutes($KeysForMinutes)
$nextEnter = (Get-Date).AddSeconds(20)
$nextEsc   = (Get-Date).AddSeconds($EscEvery + 20)
$lastFocus = [datetime]::MinValue

while ((Get-Date) -lt $deadline -and -not $game.HasExited) {
    if (((Get-Date) - $lastFocus).TotalSeconds -ge 4) {
        $window = Get-Process -Name victory, game_scarlett_master -ErrorAction SilentlyContinue |
            Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
        if ($window) {
            [VictoryKeys]::ShowWindow($window.MainWindowHandle, 9) | Out-Null
            [VictoryKeys]::SetForegroundWindow($window.MainWindowHandle) | Out-Null
            $lastFocus = Get-Date
        }
    }
    $send = (Get-Date) -lt $keysUntil
    if ($send -and (Get-Date) -ge $nextEnter) {
        [VictoryKeys]::Tap(0x0D)
        Write-Host ("{0:HH:mm:ss}  Enter" -f (Get-Date))
        $nextEnter = (Get-Date).AddSeconds($EnterEvery)
    }
    if ($send -and (Get-Date) -ge $nextEsc) {
        [VictoryKeys]::Tap(0x1B)
        Write-Host ("{0:HH:mm:ss}  Esc" -f (Get-Date))
        $nextEsc = (Get-Date).AddSeconds($EscEvery)
    }
    Start-Sleep -Milliseconds 500
}

if (-not $game.HasExited) { Stop-Process -Id $game.Id -Force -ErrorAction SilentlyContinue }
Stop-Process -Name game_scarlett_master -Force -ErrorAction SilentlyContinue
Write-Host 'done' -ForegroundColor Green
