# ================================
#  MUI INSTALLER - MILLENNIUM CLEAN SETUP (PowerShell)
#  Safe version:
#   - If Steam\millennium exists: reinstall MUI pack into it
#   - If Steam\millennium is missing: download & run Millennium installer EXE
# ================================

Set-Location -Path $PSScriptRoot

# Banner
Write-Host ""
Write-Host "███╗░░░███╗  ██╗░░░██╗  ██╗"
Write-Host "████╗░████║  ██║░░░██║  ██║"
Write-Host "██╔████╔██║  ██║░░░██║  ██║"
Write-Host "██║╚██╔╝██║  ██║░░░██║  ██║"
Write-Host "██║░╚═╝░██║  ╚██████╔╝  ██║"
Write-Host "╚═╝░░░░░╚═╝  ░╚═════╝░  ╚═╝"
Write-Host ""

# --------- Detect Steam path ---------

$steamPath = $null
foreach ($regPath in @('HKLM:\SOFTWARE\WOW6432Node\Valve\Steam','HKLM:\SOFTWARE\Valve\Steam')) {
    if (Test-Path $regPath) {
        try {
            $p = (Get-ItemProperty -Path $regPath -Name InstallPath -ErrorAction Stop).InstallPath
            if ($p -and (Test-Path $p)) { $steamPath = $p; break }
        } catch { }
    }
}
if (-not $steamPath) { $steamPath = "${env:ProgramFiles(x86)}\Steam" }

Write-Host "Detected / assumed Steam path : $steamPath"
Write-Host ""

if (-not (Test-Path $steamPath)) {
    Write-Host "[ERROR] Steam folder not found at '$steamPath'."
    Read-Host "Press Enter to exit"
    exit 1
}

$millenniumDir = Join-Path $steamPath 'millennium'
Write-Host "Millennium path                : $millenniumDir"
Write-Host ""

# --------- If Millennium is missing, download & run its installer, then exit ---------

if (-not (Test-Path $millenniumDir)) {
    Write-Host "Millennium is NOT installed in your Steam folder."
    Write-Host ""
    Write-Host "This script will now download and launch the official Millennium installer for Windows."
    Write-Host "After completing that installer and restarting Steam, run this script again to install the MUI pack."
    Write-Host ""

    $confirm = Read-Host "Download and run Millennium installer now? (Y/N)"
    if ($confirm -notin @('Y','y','Yes','yes')) {
        Write-Host "Operation cancelled."
        Read-Host "Press Enter to exit"
        exit 0
    }

    # Official Millennium Windows installer (adjust if you prefer a different source)
    $installerName = 'MillenniumInstaller-Windows.exe'
    $installerUrl  = 'https://github.com/SteamClientHomebrew/Millennium/releases/latest/download/MillenniumInstaller-Windows.exe'
    $installerPath = Join-Path $env:TEMP $installerName

    Write-Host ""
    Write-Host "Downloading Millennium installer..."
    Write-Host "From: $installerUrl"
    Write-Host "To  : $installerPath"

    try {
        Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath -UseBasicParsing
    } catch {
        Write-Host "[ERROR] Download failed: $($_.Exception.Message)"
        Write-Host "You can also manually download it from https://steambrew.app/ or the Millennium GitHub releases page."
        Read-Host "Press Enter to exit"
        exit 1
    }

    if (-not (Test-Path $installerPath)) {
        Write-Host "[ERROR] Installer file not found at '$installerPath' after download."
        Read-Host "Press Enter to exit"
        exit 1
    }

    Write-Host ""
    Write-Host "Launching Millennium installer..."
    Write-Host "Follow its steps to install Millennium into your Steam folder, then re-run this script."
    Start-Process -FilePath $installerPath

    Write-Host ""
    Write-Host "Installer started. This script will now exit."
    Read-Host "Press Enter to exit"
    exit 0
}

# --------- From here on: Millennium exists, so we reinstall your MUI pack ---------

Write-Host "Millennium is installed. Proceeding to reinstall the Millennium MUI Pack into Steam\\millennium."
Write-Host ""

$answer = Read-Host "This will DELETE your existing Steam\\millennium folder and reinstall the Millennium MUI Pack there. Continue? (Y/N)"
if ($answer -notin @('Y','y','Yes','yes')) {
    Write-Host "Operation cancelled."
    Read-Host "Press Enter to exit"
    exit 0
}

# --------- Check for extraction tools (WinRAR CLI or 7-Zip) ---------

$rarCliPaths = @(
    "$env:ProgramFiles\WinRAR\Rar.exe",
    "${env:ProgramFiles(x86)}\WinRAR\Rar.exe",
    "$env:ProgramFiles\WinRAR\UnRAR.exe",
    "${env:ProgramFiles(x86)}\WinRAR\UnRAR.exe"
)
$rarCli = $rarCliPaths | Where-Object { Test-Path $_ } | Select-Object -First 1

$sevenZipPaths = @(
    "$env:ProgramFiles\7-Zip\7z.exe",
    "${env:ProgramFiles(x86)}\7-Zip\7z.exe"
)
$sevenZip = $sevenZipPaths | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $rarCli -and -not $sevenZip) {
    Write-Host ""
    Write-Host "[ERROR] No supported archive extractor found."
    Write-Host "  - 7-Zip:  https://www.7-zip.org/download.html"
    Write-Host "  - WinRAR: https://www.win-rar.com/"
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

# --------- Paths for MUI pack ---------

$packName   = 'Millennium_MUI_Pack_1.0.rar'
$packUrl    = 'https://github.com/Mario64MUI/MUI-Files/releases/download/v1.0.0/Millennium_MUI_Pack_1.0.rar'
$packTmp    = Join-Path $env:TEMP $packName

$extractTmp = Join-Path $env:TEMP 'MUI_Extract_Temp'

Write-Host "MUI pack URL                 : $packUrl"
Write-Host "Temp archive path            : $packTmp"
Write-Host "Temp extract folder          : $extractTmp"
Write-Host ""

# --------- Close Steam ---------

Write-Host "Closing Steam if running..."
Get-Process -Name 'steam' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

# --------- Remove ONLY Steam\millennium ---------

if (Test-Path $millenniumDir) {
    Write-Host "Removing existing Steam\\millennium folder..."
    try {
        Remove-Item -Path $millenniumDir -Recurse -Force
    } catch {
        Write-Host "[ERROR] Failed to remove '$millenniumDir': $($_.Exception.Message)"
        Read-Host "Press Enter to exit"
        exit 1
    }
} else {
    Write-Host "No existing Steam\\millennium folder found. Fresh MUI install."
}

# --------- Clean and create temp extraction folder ---------

if (Test-Path $extractTmp) {
    Write-Host "Cleaning previous temp extraction folder..."
    Remove-Item -Path $extractTmp -Recurse -Force
}
New-Item -ItemType Directory -Path $extractTmp -Force | Out-Null

# --------- Download MUI pack ---------

Write-Host ""
Write-Host "Downloading Millennium MUI Pack 1.0..."
try {
    Invoke-WebRequest -Uri $packUrl -OutFile $packTmp -UseBasicParsing
} catch {
    Write-Host "[ERROR] Download failed: $($_.Exception.Message)"
    Read-Host "Press Enter to exit"
    exit 1
}

if (-not (Test-Path $packTmp)) {
    Write-Host "[ERROR] Archive not found after download at $packTmp"
    Read-Host "Press Enter to exit"
    exit 1
}

# --------- Extract MUI pack to temp folder ---------

Write-Host ""
Write-Host "Extracting MUI pack to temp folder: $extractTmp"

if ($rarCli) {
    Write-Host "Using WinRAR CLI: $rarCli"
    & $rarCli x -y $packTmp "$extractTmp\"
    $exitCode = $LASTEXITCODE
} else {
    Write-Host "Using 7-Zip: $sevenZip"
    & $sevenZip x $packTmp "-o$extractTmp" -y
    $exitCode = $LASTEXITCODE
}

if ($exitCode -ne 0) {
    Write-Host "[ERROR] Extraction failed (exit code $exitCode)."
    Read-Host "Press Enter to exit"
    exit 1
}

# --------- Inspect extracted temp folder ---------

$extractedItems = Get-ChildItem -Path $extractTmp
Write-Host ""
Write-Host "Items in extract temp:"
if ($extractedItems) {
    $extractedItems | ForEach-Object { Write-Host " - $($_.FullName)" }
} else {
    Write-Host " (none)"
}

if (-not $extractedItems) {
    Write-Host "[ERROR] Extraction succeeded but temp folder is empty. The RAR may be corrupt."
    Read-Host "Press Enter to exit"
    exit 1
}

# We expect a top-level 'millennium' folder in the extracted temp
$millenniumExtracted = $extractedItems | Where-Object { $_.PSIsContainer -and $_.Name -ieq 'millennium' } | Select-Object -First 1

if (-not $millenniumExtracted) {
    Write-Host "[ERROR] No 'millennium' folder found in extracted temp contents."
    Write-Host "Expected something like '$extractTmp\\millennium\\config', 'bin', 'lib', 'themes', 'plugins'."
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "Found extracted 'millennium' folder at: $($millenniumExtracted.FullName)"

# --------- Copy the millennium folder itself into Steam ---------

Write-Host ""
Write-Host "Copying 'millennium' into '$steamPath' as a fresh MUI install..."

# Ensure Steam\millennium does not already exist (should be removed earlier)
if (Test-Path $millenniumDir) {
    Write-Host "[WARNING] '$millenniumDir' already exists, removing again before copy..."
    Remove-Item -Path $millenniumDir -Recurse -Force -ErrorAction SilentlyContinue
}

# Use robocopy from the extracted 'millennium' to Steam\millennium
robocopy $millenniumExtracted.FullName $millenniumDir /E /NFL /NDL /NJH /NJS
$roboExit = $LASTEXITCODE

if ($roboExit -ge 8) {
    Write-Host "[ERROR] Robocopy failed with exit code $roboExit."
    Write-Host "Please manually copy '$($millenniumExtracted.FullName)' into '$millenniumDir'."
    Read-Host "Press Enter to exit"
    exit 1
}

# Verify structure

if (-not (Test-Path $millenniumDir)) {
    Write-Host "[ERROR] Steam\\millennium folder does not exist after copy."
    Read-Host "Press Enter to exit"
    exit 1
}

$finalItems = Get-ChildItem -Path $millenniumDir -ErrorAction SilentlyContinue
Write-Host ""
Write-Host "Contents of Steam\\millennium after install:"
if ($finalItems) {
    $finalItems | ForEach-Object { Write-Host " - $($_.Name)" }
} else {
    Write-Host " (empty)"
}

Write-Host ""
Write-Host "Expected to see: config, bin, lib, themes, plugins"
Write-Host ""

# --------- Cleanup ---------

Write-Host "Cleaning up temp files..."
Remove-Item -Path $packTmp    -Force -ErrorAction SilentlyContinue
Remove-Item -Path $extractTmp -Recurse -Force -ErrorAction SilentlyContinue

# --------- Do NOT start Steam here ---------
# Millennium’s own installer will restart Steam when it runs.
# For MUI-only reinstall, you can choose to start Steam if you want.

$startSteam = Read-Host "MUI pack install complete. Start Steam now? (Y/N)"
if ($startSteam -in @('Y','y','Yes','yes')) {
    $steamExe = Join-Path $steamPath 'steam.exe'
    if (Test-Path $steamExe) {
        Write-Host "Starting Steam..."
        Start-Process -FilePath $steamExe
    } else {
        Write-Host "[WARNING] steam.exe not found at '$steamExe'. Start Steam manually."
    }
}

Write-Host ""
Write-Host "Done. If Millennium was missing, you should have run its installer first."
Write-Host "If Millennium was present, the MUI pack is now installed into Steam\\millennium."
Write-Host ""
Read-Host "Press Enter to exit"
