# Install everything a fresh Windows machine needs to build and run this branch.
#
#   powershell -ExecutionPolicy Bypass -File bootstrap\scripts\install-toolchain.ps1
#
# Installs, each only if it is missing:
#   - Visual Studio Build Tools 2022, the C++ workload (MSVC 14.44 + Windows SDK)
#   - the Rust MSVC toolchain (via rustup; the MSVC one, not the GNU one)
#   - the DirectX 12 Agility SDK DLLs, into D:\_toolchain\agility
#   - the GitHub CLI, into D:\_toolchain\gh
# Nothing here needs a game; the game dump is the user's own.

$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ProgressPreference = 'SilentlyContinue'

$tools = 'D:\_toolchain'
$vsPath = "$tools\VS"
New-Item -ItemType Directory -Force $tools | Out-Null

function Have($path) { Test-Path $path }
function Say($text) { Write-Host "`n== $text" -ForegroundColor Cyan }

# 1. Visual Studio Build Tools: MSVC and the Windows SDK, which rustc needs as a linker.
Say 'Visual Studio Build Tools (C++ workload)'
$link = Get-ChildItem "$vsPath\VC\Tools\MSVC\*\bin\Hostx64\x64\link.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($link) {
    Write-Host "   already there: $($link.FullName)"
} else {
    $bootstrapper = "$tools\vs_buildtools.exe"
    if (-not (Have $bootstrapper)) {
        Write-Host '   downloading the bootstrapper'
        Invoke-WebRequest -UseBasicParsing -Uri 'https://aka.ms/vs/17/release/vs_buildtools.exe' -OutFile $bootstrapper
    }
    Write-Host '   installing (a few GB; this takes a while)'
    Start-Process -FilePath $bootstrapper -Wait -ArgumentList `
        '--quiet', '--wait', '--norestart', '--nocache', '--installPath', $vsPath, `
        '--add', 'Microsoft.VisualStudio.Workload.VCTools', '--includeRecommended'
    $link = Get-ChildItem "$vsPath\VC\Tools\MSVC\*\bin\Hostx64\x64\link.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($link) { Write-Host "   installed: $($link.FullName)" } else { Write-Host '   INSTALL DID NOT LAND: run the bootstrapper by hand' -ForegroundColor Red }
}

# 2. Rust: the MSVC toolchain (the GNU one cannot export the data symbols the loader reads).
Say 'Rust MSVC toolchain'
$cargo = "$env:USERPROFILE\.cargo\bin\cargo.exe"
$rustup = "$env:USERPROFILE\.cargo\bin\rustup.exe"
if (-not (Have $rustup)) {
    Write-Host '   downloading rustup'
    Invoke-WebRequest -UseBasicParsing -Uri 'https://win.rustup.rs/x86_64' -OutFile "$tools\rustup-init.exe"
    & "$tools\rustup-init.exe" -y --default-toolchain none --profile minimal
}
if (Have $rustup) {
    # a mirror keeps this quick where the default host is slow
    $env:RUSTUP_DIST_SERVER = 'https://mirrors.tuna.tsinghua.edu.cn/rustup'
    & $rustup toolchain install stable-x86_64-pc-windows-msvc --profile minimal --no-self-update
    & $rustup default stable-x86_64-pc-windows-msvc
    Write-Host ('   ' + ((& $cargo --version) -join ' '))
}

# 3. The Agility SDK: the newer Direct3D 12 runtime, and the only way to have a debug
#    layer on an install whose graphics tools are missing. victory.exe exports the two
#    names the loader reads (apps/victory/victory.def), so the DLLs only have to sit
#    in D3D12\ beside it.
Say 'DirectX 12 Agility SDK'
$agility = "$tools\agility"
if (Have "$agility\D3D12Core.dll") {
    Write-Host "   already there: $agility"
} else {
    $pkg = "$tools\d3d12.nupkg"
    try {
        Invoke-WebRequest -UseBasicParsing -Uri 'https://www.nuget.org/api/v2/package/Microsoft.DirectX.D3D12/1.620.2' -OutFile $pkg
        $zip = "$tools\d3d12.zip"
        Copy-Item $pkg $zip -Force
        Expand-Archive -Path $zip -DestinationPath "$tools\d3d12-pkg" -Force
        New-Item -ItemType Directory -Force $agility | Out-Null
        Copy-Item "$tools\d3d12-pkg\build\native\bin\x64\*" $agility -Force
        Write-Host "   installed: $agility"
    } catch {
        Write-Host "   could not fetch the Agility SDK: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host '   the layer still works on the system runtime, without a debug layer'
    }
}

# 4. gh: for pushing this branch, and for its credential helper.
Say 'GitHub CLI'
if (-not (Have "$tools\gh\bin\gh.exe")) {
    $rel = Invoke-RestMethod -Uri 'https://api.github.com/repos/cli/cli/releases/latest'
    $asset = $rel.assets | Where-Object { $_.name -match 'windows_amd64\.zip$' } | Select-Object -First 1
    Invoke-WebRequest -UseBasicParsing -Uri $asset.browser_download_url -OutFile "$tools\gh.zip"
    Expand-Archive -Path "$tools\gh.zip" -DestinationPath "$tools\gh" -Force
}
Write-Host '   ' + ((& "$tools\gh\bin\gh.exe" --version) -join ' ')

Say 'done'
Write-Host @'
   put the MSVC compiler first on PATH when building:

     $env:PATH = 'D:\_toolchain\VS\VC\Tools\MSVC\14.44.35207\bin\Hostx64\x64;' + $env:PATH
     $env:INCLUDE = 'D:\_toolchain\VS\VC\Tools\MSVC\14.44.35207\include;C:\Program Files (x86)\Windows Kits\10\Include\10.0.26100.0\ucrt;C:\Program Files (x86)\Windows Kits\10\Include\10.0.26100.0\um;C:\Program Files (x86)\Windows Kits\10\Include\10.0.26100.0\shared'
     $env:LIB = 'D:\_toolchain\VS\VC\Tools\MSVC\14.44.35207\lib\x64;C:\Program Files (x86)\Windows Kits\10\Lib\10.0.26100.0\ucrt\x64;C:\Program Files (x86)\Windows Kits\10\Lib\10.0.26100.0\um\x64'

  or open a "x64 Native Tools Command Prompt for VS" and run cargo there.
'@
