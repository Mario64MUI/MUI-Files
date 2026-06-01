# ================================
#  MUI INSTALLER - MILLENNIUM CLEAN SETUP (PowerShell)
#  Safe version: only touches Steam\millennium
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

# --------- Confirmation ---------

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

$millenniumDir = Join-Path $steamPath 'millennium'

$packName     = 'Millennium_MUI_Pack_1.0.rar'
$packUrl      = 'https://github.com/Mario64MUI/MUI-Files/releases/download/v1.0.0/Millennium_MUI_Pack_1.0.rar'
$packTmp      = Join-Path $env:TEMP $packName

# Temp folder we extract into
$extractTmp   = Join-Path $env:TEMP 'MUI_Extract_Temp'

Write-Host "Steam path      : $steamPath"
Write-Host "Millennium path : $millenniumDir"
Write-Host ""

if (-not (Test-Path $steamPath)) {
    Write-Host "[ERROR] Steam folder not found at '$steamPath'."
    Read-Host "Press Enter to exit"
    exit 1
}

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
    Write-Host "No existing Steam\\millennium folder found. Fresh install."
}

# --------- Clean and create temp extraction folder ---------

if (Test-Path $extractTmp) {
    Write-Host "Cleaning previous temp extraction folder..."
    Remove-Item -Path $extractTmp -Recurse -Force
}
New-Item -ItemType Directory -Path $extractTmp -Force | Out-Null

# --------- Download ---------

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

# --------- Extract to temp folder ---------

Write-Host ""
Write-Host "Extracting to temp folder: $extractTmp"

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

Write-Host "Copying 'millennium' into '$steamPath'..."

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

# --------- Start Steam ---------

Write-Host ""
Write-Host "Starting Steam..."
$steamExe = Join-Path $steamPath 'steam.exe'
if (Test-Path $steamExe) {
    Start-Process -FilePath $steamExe
} else {
    Write-Host "[WARNING] steam.exe not found at '$steamExe'. Start Steam manually."
}

Write-Host ""
Write-Host "Done. Millennium MUI Pack 1.0 has been installed into Steam\\millennium."
Write-Host "Structure should be: config, bin, lib, themes, plugins under Steam\\millennium."
Write-Host ""
Read-Host "Press Enter to exit"
