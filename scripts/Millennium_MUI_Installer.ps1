# ================================
#  MUI INSTALLER - MILLENNIUM CLEAN SETUP (PowerShell)
# ================================

# Make sure we run from this script's directory
Set-Location -Path $PSScriptRoot

# Banner
Write-Host ""
Write-Host "███╗░░░███╗  ██╗░░░██╗  ██╗"
Write-Host "████╗░████║  ██║░░░██║  ██║"
Write-Host "██╔████╔██║  ██║░░░██║  ██║"
Write-Host "██║╚██╔╝██║  ██║░░░██║  ██║"
Write-Host "██║░╚═╝░██║  ╚██████╔╝  ██║"
Write-Host "╚═╝░░░░░╚═╝  ░╚═════╝░  ╚═╝"
Write-Host ""

# --------- Confirmation ---------

$answer = Read-Host "This will remove your existing Millennium folder and reinstall the Millennium MUI Pack. Continue? (Y/N)"

if ($answer -notin @('Y','y','Yes','yes')) {
    Write-Host "Operation cancelled."
    Read-Host "Press Enter to exit"
    exit 0
}

# --------- Check for extraction tools (7-Zip / WinRAR) ---------

$sevenZipPaths = @(
    "$env:ProgramFiles\7-Zip\7z.exe",
    "$env:ProgramFiles(x86)\7-Zip\7z.exe"
)
$sevenZip = $sevenZipPaths | Where-Object { Test-Path $_ } | Select-Object -First 1

$winRarPaths = @(
    "$env:ProgramFiles\WinRAR\WinRAR.exe",
    "$env:ProgramFiles(x86)\WinRAR\WinRAR.exe",
    "$env:ProgramFiles\WinRAR\Rar.exe",
    "$env:ProgramFiles(x86)\WinRAR\Rar.exe"
)
$winRar = $winRarPaths | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $sevenZip -and -not $winRar) {
    Write-Host ""
    Write-Host "[ERROR] No supported archive extractor found."
    Write-Host "This script requires either 7-Zip or WinRAR to extract the pack."
    Write-Host ""
    Write-Host "Download one of the following, install it, then run this script again:"
    Write-Host "  - 7-Zip:  https://www.7-zip.org/download.html"
    Write-Host "  - WinRAR: https://www.win-rar.com/ or https://winrar.en.softonic.com"
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

# --------- Detect Steam install path from registry ---------

$steamPath = $null

# 64-bit Windows, Steam is 32-bit app -> WOW6432Node key
$steamRegPaths = @(
    'HKLM:\SOFTWARE\WOW6432Node\Valve\Steam',
    'HKLM:\SOFTWARE\Valve\Steam'
)

foreach ($regPath in $steamRegPaths) {
    if (Test-Path $regPath) {
        try {
            $installPath = (Get-ItemProperty -Path $regPath -Name InstallPath -ErrorAction Stop).InstallPath
            if ($installPath -and (Test-Path $installPath)) {
                $steamPath = $installPath
                break
            }
        } catch {
            # ignore and try next key
        }
    }
}

# Fallback if registry lookup fails
if (-not $steamPath) {
    $steamPath = "${env:ProgramFiles(x86)}\Steam"
}

# Paths and config
$millenniumDir  = Join-Path $steamPath 'steamui\skins\Millennium'
$packName       = 'Millennium_MUI_Pack_1.0.rar'
$packUrl        = 'https://github.com/Mario64MUI/MUI-Files/releases/download/v1.0.0/Millennium_MUI_Pack_1.0.rar'
$packTmp        = Join-Path $env:TEMP $packName

Write-Host "Detected / assumed Steam path: $steamPath"
Write-Host "Target Millennium folder:     $millenniumDir"
Write-Host ""

# If Steam path still doesn't exist, bail out clearly
if (-not (Test-Path $steamPath)) {
    Write-Host "[ERROR] Steam folder was not found at '$steamPath'."
    Write-Host "Steam might not be installed, or it is in a custom location."
    Write-Host "Install Steam or edit this script to point to your Steam folder."
    Read-Host "Press Enter to exit"
    exit 1
}

# --------- Close Steam if running ---------

Write-Host "Closing Steam if it is running..."
Get-Process -Name 'steam' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

# --------- Clean Millennium folder ---------

if (Test-Path -Path $millenniumDir) {
    Write-Host "Removing existing Millennium folder..."
    Remove-Item -Path $millenniumDir -Recurse -Force
}

Write-Host "Creating fresh Millennium folder..."
New-Item -ItemType Directory -Path $millenniumDir -Force | Out-Null

# --------- Download archive ---------

Write-Host ""
Write-Host "Downloading Millennium MUI Pack 1.0..."
try {
    Invoke-WebRequest -Uri $packUrl -OutFile $packTmp -UseBasicParsing
}
catch {
    Write-Host ""
    Write-Host "[ERROR] Download failed: $($_.Exception.Message)"
    Write-Host "Check your internet connection or the download URL."
    Read-Host "Press Enter to exit"
    exit 1
}

if (-not (Test-Path -Path $packTmp)) {
    Write-Host ""
    Write-Host "[ERROR] Download failed. Archive not found at $packTmp"
    Read-Host "Press Enter to exit"
    exit 1
}

# --------- Extract archive (7-Zip or WinRAR) ---------

Write-Host ""
Write-Host "Extracting pack into Millennium folder..."

if ($sevenZip) {
    Write-Host "Using 7-Zip at: $sevenZip"
    & $sevenZip 'x' $packTmp "-o$millenniumDir" '-y'
}
elseif ($winRar) {
    Write-Host "Using WinRAR at: $winRar"
    # WinRAR: x = extract with full paths, -ibck = run in background, -y = assume Yes on all queries
    & $winRar 'x' '-ibck' '-y' $packTmp $millenniumDir
}

# --------- Cleanup ---------

Write-Host ""
Write-Host "Cleanup: removing temporary archive..."
Remove-Item -Path $packTmp -Force -ErrorAction SilentlyContinue

# --------- Auto-start Steam ---------

Write-Host ""
Write-Host "Starting Steam..."

$steamExe = Join-Path $steamPath 'steam.exe'

if (Test-Path $steamExe) {
    Start-Process -FilePath $steamExe
} else {
    Write-Host "[WARNING] steam.exe was not found at '$steamExe'. Please start Steam manually."
}

Write-Host ""
Write-Host "Done. Millennium MUI Pack 1.0 has been installed."
Write-Host "You can now select the Millennium skin in Steam's interface settings."
Write-Host ""
Read-Host "Press Enter to exit"
