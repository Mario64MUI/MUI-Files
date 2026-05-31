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

# --------- Extract with 7-Zip ---------

Write-Host ""
Write-Host "Extracting pack into Millennium folder..."

$sevenZipPaths = @(
    "$env:ProgramFiles\7-Zip\7z.exe",
    "$env:ProgramFiles(x86)\7-Zip\7z.exe"
)

$sevenZip = $sevenZipPaths | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $sevenZip) {
    Write-Host ""
    Write-Host "[ERROR] 7-Zip not found in `"C:\Program Files\7-Zip`" or `"C:\Program Files (x86)\7-Zip`"."
    Write-Host "Please install 7-Zip or add it to PATH, then run this script again."
    Read-Host "Press Enter to exit"
    exit 1
}

& $sevenZip 'x' $packTmp "-o$millenniumDir" '-y'

# --------- Cleanup ---------

Write-Host ""
Write-Host "Cleanup: removing temporary archive..."
Remove-Item -Path $packTmp -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "Done. Millennium MUI Pack 1.0 has been installed."
Write-Host "You can now start Steam and select the Millennium skin."
Write-Host ""
Read-Host "Press Enter to exit"
