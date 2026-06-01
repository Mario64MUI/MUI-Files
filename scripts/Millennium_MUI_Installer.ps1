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

# --------- Check for extraction tools (WinRAR CLI / UnRAR / 7-Zip) ---------

# Prefer Rar.exe / UnRAR.exe for reliable headless CLI extraction.
# WinRAR.exe is the GUI and can open a window instead of extracting silently.
$rarCliPaths = @(
    "$env:ProgramFiles\WinRAR\Rar.exe",
    "$env:ProgramFiles(x86)\WinRAR\Rar.exe",
    "$env:ProgramFiles\WinRAR\UnRAR.exe",
    "$env:ProgramFiles(x86)\WinRAR\UnRAR.exe"
)
$rarCli = $rarCliPaths | Where-Object { Test-Path $_ } | Select-Object -First 1

# Fall back to 7-Zip if no WinRAR CLI tool found
$sevenZipPaths = @(
    "$env:ProgramFiles\7-Zip\7z.exe",
    "${env:ProgramFiles(x86)}\7-Zip\7z.exe"
)
$sevenZip = $sevenZipPaths | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $rarCli -and -not $sevenZip) {
    Write-Host ""
    Write-Host "[ERROR] No supported archive extractor found."
    Write-Host "This script requires WinRAR (Rar.exe) or 7-Zip to extract the pack."
    Write-Host ""
    Write-Host "Download one of the following, install it, then run this script again:"
    Write-Host "  - 7-Zip:  https://www.7-zip.org/download.html"
    Write-Host "  - WinRAR: https://www.win-rar.com/"
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

# --------- Detect Steam install path from registry ---------

$steamPath = $null

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
        } catch { }
    }
}

if (-not $steamPath) {
    $steamPath = "${env:ProgramFiles(x86)}\Steam"
}

$millenniumDir = Join-Path $steamPath 'steamui\skins\Millennium'
$packName      = 'Millennium_MUI_Pack_1.0.rar'
$packUrl       = 'https://github.com/Mario64MUI/MUI-Files/releases/download/v1.0.0/Millennium_MUI_Pack_1.0.rar'
$packTmp       = Join-Path $env:TEMP $packName

Write-Host "Detected / assumed Steam path: $steamPath"
Write-Host "Target Millennium folder:     $millenniumDir"
Write-Host ""

if (-not (Test-Path $steamPath)) {
    Write-Host "[ERROR] Steam folder was not found at '$steamPath'."
    Write-Host "Steam might not be installed, or it is in a custom location."
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
} catch {
    Write-Host ""
    Write-Host "[ERROR] Download failed: $($_.Exception.Message)"
    Read-Host "Press Enter to exit"
    exit 1
}

if (-not (Test-Path -Path $packTmp)) {
    Write-Host "[ERROR] Download failed. Archive not found at $packTmp"
    Read-Host "Press Enter to exit"
    exit 1
}

# --------- Extract archive ---------
#
# KEY FIX: Do NOT pre-quote paths when using & with an array.
# PowerShell handles quoting automatically — adding your own quotes
# causes double-quoting and WinRAR/7-Zip silently fail to find the file.
#
# Also: trailing backslash on the destination is required by WinRAR CLI.

Write-Host ""
Write-Host "Extracting pack into Millennium folder..."

$exitCode = 0

if ($rarCli) {
    Write-Host "Using WinRAR CLI at: $rarCli"

    # Destination must end with a backslash for Rar.exe / UnRAR.exe
    $dest = "$millenniumDir\"

    # Pass raw (unquoted) strings — PowerShell quotes them correctly
    & $rarCli x -y $packTmp $dest
    $exitCode = $LASTEXITCODE

} elseif ($sevenZip) {
    Write-Host "Using 7-Zip at: $sevenZip"

    # -o must be joined directly to the path (no space) for 7z.exe
    & $sevenZip x $packTmp "-o$millenniumDir" -y
    $exitCode = $LASTEXITCODE
}

if ($exitCode -ne 0) {
    Write-Host ""
    Write-Host "[ERROR] Extraction failed (exit code $exitCode)."
    Write-Host "The archive may be corrupt. Try deleting '$packTmp' and running the script again."
    Read-Host "Press Enter to exit"
    exit 1
}

# Verify something was actually extracted
$extractedItems = Get-ChildItem -Path $millenniumDir -ErrorAction SilentlyContinue
if (-not $extractedItems) {
    Write-Host ""
    Write-Host "[WARNING] Extraction reported success but the Millennium folder is empty."
    Write-Host "Please extract '$packTmp' manually into '$millenniumDir'."
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "Extraction complete. $($extractedItems.Count) item(s) placed in Millennium folder."

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
    Write-Host "[WARNING] steam.exe not found at '$steamExe'. Please start Steam manually."
}

Write-Host ""
Write-Host "Done. Millennium MUI Pack 1.0 has been installed."
Write-Host "You can now select the Millennium skin in Steam's interface settings."
Write-Host ""
Read-Host "Press Enter to exit"
