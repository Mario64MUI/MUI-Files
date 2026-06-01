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

$answer = Read-Host "This will remove your existing Millennium folder and reinstall the Millennium MUI Pack. Continue? (Y/N)"

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

$millenniumDir = Join-Path $steamPath 'steamui\skins\Millennium'
$packName      = 'Millennium_MUI_Pack_1.0.rar'
$packUrl       = 'https://github.com/Mario64MUI/MUI-Files/releases/download/v1.0.0/Millennium_MUI_Pack_1.0.rar'
$packTmp       = Join-Path $env:TEMP $packName

# Temp folder we extract into before copying — avoids all path/nesting issues
$extractTmp    = Join-Path $env:TEMP 'MUI_Extract_Temp'

Write-Host "Steam path      : $steamPath"
Write-Host "Millennium dir  : $millenniumDir"
Write-Host ""

if (-not (Test-Path $steamPath)) {
    Write-Host "[ERROR] Steam folder not found at '$steamPath'."
    Read-Host "Press Enter to exit"
    exit 1
}

# --------- Close Steam ---------

Write-Host "Closing Steam if running..."
Get-Process -Name 'steam' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

# --------- Clean Millennium folder ---------

if (Test-Path $millenniumDir) {
    Write-Host "Removing existing Millennium folder..."
    Remove-Item -Path $millenniumDir -Recurse -Force
}
Write-Host "Creating fresh Millennium folder..."
New-Item -ItemType Directory -Path $millenniumDir -Force | Out-Null

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
#
# We extract into a neutral temp directory rather than directly into the
# Steam skin folder. This avoids two problems:
#   1. WinRAR path/quoting issues with deep Steam install paths.
#   2. A hidden root subfolder inside the RAR landing as a nested folder.
# After extraction we find the actual content root and robocopy it over.

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

# --------- Find the actual content root inside the extracted temp folder ---------
#
# If the RAR was created with a root subfolder (e.g. Millennium_MUI_Pack_1.0\)
# we detect it here and use that subfolder as the source, not the temp root.
# This means the script works correctly whether or not the RAR has a wrapper folder.

$extractedItems = Get-ChildItem -Path $extractTmp
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
Write-Host "Copying into    : $millenniumDir"

# --------- Robocopy content into the Millennium skin folder ---------
#
# /E   = copy all subdirectories including empty ones
# /NFL = no file list (less noisy output)
# /NDL = no directory list
# /NJH = no job header
# /NJS = no job summary
# Robocopy exit codes 0-7 are all considered success (>=8 = real error)

robocopy $contentRoot $millenniumDir /E /NFL /NDL /NJH /NJS
$roboExit = $LASTEXITCODE

if ($roboExit -ge 8) {
    Write-Host "[ERROR] Robocopy failed with exit code $roboExit."
    Write-Host "Please manually copy the contents of '$contentRoot' into '$millenniumDir'."
    Read-Host "Press Enter to exit"
    exit 1
}

# Verify
$finalItems = Get-ChildItem -Path $millenniumDir -ErrorAction SilentlyContinue
if (-not $finalItems) {
    Write-Host "[WARNING] Millennium folder is still empty after copy."
    Write-Host "Please manually copy from '$contentRoot' into '$millenniumDir'."
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "Install complete: $($finalItems.Count) item(s) in Millennium folder."

# --------- Cleanup ---------

Write-Host ""
Write-Host "Cleaning up temp files..."
Remove-Item -Path $packTmp   -Force -ErrorAction SilentlyContinue
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
Write-Host "You can now select the Millennium skin in Steam's interface settings."
Write-Host ""
Read-Host "Press Enter to exit"
