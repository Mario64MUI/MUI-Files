# ================================
#  MUI INSTALLER - MILLENNIUM CLEAN SETUP (PowerShell)
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

$answer = Read-Host "This will reinstall the Millennium MUI Pack into your Steam folder. Continue? (Y/N)"

if ($answer -notin @('Y','y','Yes','yes')) {
    Write-Host "Operation cancelled."
    Read-Host "Press Enter to exit"
    exit 0
}

# --------- Check for extraction tools ---------

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

# IMPORTANT: Millennium pack installs into the main Steam folder
$targetDir    = $steamPath

$packName     = 'Millennium_MUI_Pack_1.0.rar'
$packUrl      = 'https://github.com/Mario64MUI/MUI-Files/releases/download/v1.0.0/Millennium_MUI_Pack_1.0.rar'
$packTmp      = Join-Path $env:TEMP $packName

# Temp folder we extract into before copying
$extractTmp   = Join-Path $env:TEMP 'MUI_Extract_Temp'

Write-Host "Steam path      : $steamPath"
Write-Host "Target dir      : $targetDir"
Write-Host ""

if (-not (Test-Path $steamPath)) {
    Write-Host "[ERROR] Steam folder not found at '$steamPath'."
    Read-Host "Press Enter to exit"
    exit 1
}

# --------- Close Steam ---------

Write-Host "Closing Steam if running..."
Get-Process -Name 'steam' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

# --------- Clean and create temp extraction folder ---------

if (Test-Path $extractTmp) { Remove-Item -Path $extractTmp -Recurse -Force }
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

# --------- Extract to temp folder first ---------

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

# If there is exactly one item and it is a folder, treat it as the content root
if ($extractedItems.Count -eq 1 -and $extractedItems[0].PSIsContainer) {
    $contentRoot = $extractedItems[0].FullName
    Write-Host "Detected single root folder in RAR: '$($extractedItems[0].Name)' — using its contents."
} else {
    $contentRoot = $extractTmp
    Write-Host "RAR contents are at root level — copying directly."
}

Write-Host "Content source  : $contentRoot"
Write-Host "Copying into    : $targetDir"

# --------- Robocopy content into the Steam folder ---------

robocopy $contentRoot $targetDir /E /NFL /NDL /NJH /NJS
$roboExit = $LASTEXITCODE

if ($roboExit -ge 8) {
    Write-Host "[ERROR] Robocopy failed with exit code $roboExit."
    Write-Host "Please manually copy the contents of '$contentRoot' into '$targetDir'."
    Read-Host "Press Enter to exit"
    exit 1
}

# Basic verification: check for millennium subfolder under Steam

$millenniumRoot = Join-Path $steamPath 'millennium'
if (-not (Test-Path $millenniumRoot)) {
    Write-Host "[WARNING] 'millennium' folder not found directly under '$steamPath'."
    Write-Host "Check '$targetDir' and '$contentRoot' to ensure files were copied correctly."
} else {
    $finalItems = Get-ChildItem -Path $millenniumRoot -ErrorAction SilentlyContinue
    Write-Host "Install complete: $($finalItems.Count) item(s) inside '$millenniumRoot'."
}

# --------- Cleanup ---------

Write-Host ""
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
Write-Host "Done. Millennium MUI Pack 1.0 has been installed."
Write-Host "Check your Steam folder for the 'millennium' directory and the MUI files."
Write-Host ""
Read-Host "Press Enter to exit"
