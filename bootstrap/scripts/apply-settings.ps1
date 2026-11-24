# Put the settings this machine measured faster back into the title's own settings file.
#
#   powershell -ExecutionPolicy Bypass -File bootstrap\scripts\apply-settings.ps1 -Root D:\GTA6.Xbox.v1.0.2
#
# The title writes its settings back when it exits, which restores 3840x2160 and turns
# ray-traced dynamic shadows, motion blur, SSR and particle shadows back on - every run
# undoes the previous tuning. So this runs before each launch (play.ps1 calls it).
#
# What it sets: 1920x1080 (no measured gain below that, so no reason to go lower),
# rtDynamicShadows/rtLODLightShadows/motionBlur/waterReflectionSSR/shadowParticleShadows
# off, ssroSampleCount 1, frameRateLimit 60.
#
# The file must be written WITHOUT a BOM: the title's parser refuses one.

param(
    [string]$Root = 'D:\GTA6.Xbox.v1.0.2',
    [string]$DataDir = '',
    [switch]$Quiet
)

$ErrorActionPreference = 'Continue'
if ($DataDir -eq '') {
    # the title's persistent storage lives under the data dir in victory.toml
    $config = Join-Path $Root 'victory.toml'
    $data = 'D:\victory-data\data'
    if (Test-Path $config) {
        $line = Select-String -Path $config -Pattern "^\s*data_dir\s*=\s*'([^']+)'" | Select-Object -First 1
        if ($line) { $data = $line.Matches[0].Groups[1].Value }
    }
    $DataDir = $data
}

$settings = Get-ChildItem $DataDir -Recurse -Filter settings.xml -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $settings) { if (-not $Quiet) { Write-Host "no settings.xml under $DataDir (the game writes it on first run)" }; return }
$path = $settings.FullName
$backup = "$path.tuned-backup"
if (-not (Test-Path $backup)) { Copy-Item $path $backup -Force }

$text = [IO.File]::ReadAllText($path)
$text = $text.TrimStart([char]0xFEFF)
$text = $text -replace '(?s)(<resolutionFullscreen>\s*<width value=")\d+("\s*/>\s*<height value=")\d+(")', '${1}1920${2}1080${3}'
foreach ($swap in @(
    @('rtDynamicShadows', 'false'), @('rtLODLightShadows', 'false'), @('motionBlur', 'false'),
    @('waterReflectionSSR', 'false'), @('shadowParticleShadows', 'false'),
    @('ssroSampleCount', '1'), @('desiredFPS', '60'), @('frameRateLimit', '60')
)) {
    $name, $value = $swap
    $text = $text -replace "(<$name value=`")[^`"]+(`")", "`${1}$value`${2}"
}
[IO.File]::WriteAllText($path, $text, (New-Object System.Text.UTF8Encoding($false)))

if (-not $Quiet) {
    Select-String -Path $path -Pattern 'resolutionFullscreen' -Context 0,2 |
        ForEach-Object { $_.Line.Trim(); $_.Context.PostContext | ForEach-Object { '  ' + $_.Trim() } }
    Select-String -Path $path -Pattern '<rtDynamicShadows|<motionBlur |<waterReflectionSSR|<shadowParticleShadows' |
        ForEach-Object { '  ' + $_.Line.Trim() }
    Write-Host "written without a BOM: $path (backup: $backup)"
}
