# Millennium + LuaTools Auto-Installer (MUI)
# Hosted on GitHub, runnable via:
# irm "https://raw.githubusercontent.com/Mario64MUI/MUI-Files/main/scripts/install-millennium-luatools.ps1" | iex

$ErrorActionPreference = "Stop"

Write-Host "=== Millennium + LuaTools Auto-Installer (MUI) ===" -ForegroundColor Cyan
Write-Host "This will:" -ForegroundColor Yellow
Write-Host " - Close Steam if it's running" -ForegroundColor White
Write-Host " - Remove your current Millennium install" -ForegroundColor White
Write-Host " - Ask you to reinstall Millennium from the official installer" -ForegroundColor White
Write-Host " - Download and install LuaTools into Millennium" -ForegroundColor White
Write-Host ""
$confirm = Read-Host "Are you sure you want to proceed? There is no going back automatically. (y/n)"

if ($confirm.ToLower() -ne "y") {
    Write-Host "Operation cancelled by user." -ForegroundColor Red
    exit 0
}

$steamPath = "C:\Program Files (x86)\Steam"
$millenniumPath = "$steamPath\millennium"
$pluginsPath = "$millenniumPath\plugins"
$luatoolsRarUrl = "https://github.com/Mario64MUI/MUI-Files/releases/download/v2.7.3/luatools.rar"
$tempRar = "$env:TEMP\luatools.rar"

Write-Host "`n[1/6] Checking Steam installation..." -ForegroundColor Yellow

if (-not (Test-Path $steamPath)) {
    Write-Error "Steam not found at $steamPath. Make sure Steam is installed."
    exit 1
}

Write-Host "`n[2/6] Stopping Steam..." -ForegroundColor Yellow
Get-Process -Name "Steam" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

Write-Host "`n[3/6] Removing old Millennium..." -ForegroundColor Yellow

if (Test-Path $millenniumPath) {
    Write-Host "Removing Millennium folder..." -ForegroundColor Gray
    Remove-Item -Recurse -Force $millenniumPath -ErrorAction SilentlyContinue
    Write-Host "Old Millennium removed." -ForegroundColor Green
} else {
    Write-Host "No existing Millennium found, skipping removal." -ForegroundColor Gray
}

Write-Host "`n[4/6] Installing fresh Millennium..." -ForegroundColor Yellow

$installerUrl = "https://docs.steambrew.app/users/getting-started/installation"
Write-Host "Open the Millennium installer manually and complete the install:" -ForegroundColor Cyan
Write-Host "  $installerUrl" -ForegroundColor White
Write-Host "`nClick 'Install' and finish the setup, then press ENTER here to continue..." -ForegroundColor Cyan
Read-Host

if (-not (Test-Path $pluginsPath)) {
    Write-Error "Millennium plugins folder not found at $pluginsPath.`nMake sure you completed the Millennium install."
    exit 1
}
Write-Host "Millennium installed successfully." -ForegroundColor Green

Write-Host "`n[5/6] Downloading LuaTools..." -ForegroundColor Yellow

try {
    Invoke-WebRequest -Uri $luatoolsRarUrl -OutFile $tempRar -UseBasicParsing
    Write-Host "LuaTools downloaded to $tempRar" -ForegroundColor Green
} catch {
    Write-Error "Failed to download LuaTools.`nURL: $luatoolsRarUrl`nError: $_"
    exit 1
}

Write-Host "`n[6/6] Extracting LuaTools to plugins folder..." -ForegroundColor Yellow

$luatoolsDir = "$pluginsPath\luatools"

if (Test-Path $luatoolsDir) {
    Remove-Item -Recurse -Force $luatoolsDir -ErrorAction SilentlyContinue
}

$sevenZip = "C:\Program Files\7-Zip\7z.exe"
if (-not (Test-Path $sevenZip)) {
    $sevenZip = "C:\Program Files (x86)\7-Zip\7z.exe"
}

if (Test-Path $sevenZip) {
    Write-Host "Using 7-Zip to extract..." -ForegroundColor Gray
    & $sevenZip x -o"$pluginsPath" -y $tempRar
} else {
    $winRar = "C:\Program Files\WinRAR\RAR.exe"
    if (-not (Test-Path $winRar)) {
        Write-Error "7-Zip or WinRAR not found.`nInstall one of them to extract RAR files."
        exit 1
    }
    Write-Host "Using WinRAR to extract..." -ForegroundColor Gray
    & $winRar x -o+ -y $tempRar $luatoolsDir
}

Write-Host "LuaTools extracted to: $luatoolsDir" -ForegroundColor Green

Remove-Item $tempRar -ErrorAction SilentlyContinue

Write-Host "`n=== Installation Complete ===" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "1. Reopen Steam." -ForegroundColor White
Write-Host "2. Go to: Steam → Millennium → Plugins." -ForegroundColor White
Write-Host "3. Enable/check 'LuaTools' and click 'Save Changes'." -ForegroundColor White
Write-Host "`nIf LuaTools doesn't show up, make sure the 'luatools' folder is directly inside 'plugins' and restart Steam again." -ForegroundColor Yellow
Write-Host "`nYou're done. You can now use Millennium and LuaTools like before." -ForegroundColor Green
