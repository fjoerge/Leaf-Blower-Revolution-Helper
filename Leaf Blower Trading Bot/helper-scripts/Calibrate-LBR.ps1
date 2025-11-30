<#
Calibrate-LBR.ps1
Einmalige Kalibrierung für Leaf Blower Revolution:
- ermittelt fensterrelative Werte für:
  - Gem-Suchbereich (SearchLeftRel/TopRel/RightRel/BottomRel)
  - StartClickXRel
  - CollectXRel / CollectYRel
  - RefreshXRel / RefreshYRel
  - ProgressCenterXRel
Die ausgegebenen Zeilen kannst du direkt in den $config-Block deines Hauptscripts kopieren.
#>

Add-Type @"
using System;
using System.Runtime.InteropServices;

public static class Win32Calib {
    [DllImport("user32.dll")]
    public static extern bool GetCursorPos(out POINT lpPoint);

    [DllImport("user32.dll")]
    public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);

    public struct POINT {
        public int X;
        public int Y;
    }

    public struct RECT {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;
    }
}
"@

function Get-GameWindowRect {
    $p = Get-Process -Name "game" -ErrorAction SilentlyContinue
    if (-not $p -or -not $p.MainWindowHandle -or $p.MainWindowHandle -eq [IntPtr]::Zero) {
        Write-Host "game.exe Fenster nicht gefunden." -ForegroundColor Red
        return $null
    }

    $rect = New-Object Win32Calib+RECT
    [Win32Calib]::GetWindowRect($p.MainWindowHandle, [ref]$rect) | Out-Null
    return $rect
}

function Get-CursorPos {
    $pt = New-Object Win32Calib+POINT
    [Win32Calib]::GetCursorPos([ref]$pt) | Out-Null
    return $pt
}

Write-Host "Stelle sicher, dass Leaf Blower Revolution geöffnet ist." -ForegroundColor Cyan
Write-Host "Fenstergröße/-position jetzt NICHT mehr verändern." -ForegroundColor Yellow
Read-Host "Enter drücken, um zu starten"

$rect = Get-GameWindowRect
if (-not $rect) { exit }

$winWidth  = $rect.Right  - $rect.Left
$winHeight = $rect.Bottom - $rect.Top

# ---------------------------------------------------------------
# 0) Gem-Suchbereich (oben links / unten rechts)
# ---------------------------------------------------------------

Write-Host ""
Write-Host "0a) Gem-Suchbereich (oben links)" -ForegroundColor Green
Write-Host "    Maus auf die OBER-LINKE Ecke der Gem-Spalte bewegen," -ForegroundColor Green
Write-Host "    da wo das erste Gem-Symbol erkannt werden soll, dann Enter." -ForegroundColor Green
Read-Host "Weiter mit Enter"
$ptSearchTL = Get-CursorPos

Write-Host ""
Write-Host "0b) Gem-Suchbereich (unten rechts)" -ForegroundColor Green
Write-Host "    Maus auf die UNTER-RECHTE Ecke des Suchbereichs bewegen" -ForegroundColor Green
Write-Host "    (unterster Trade-Slot), dann Enter." -ForegroundColor Green
Read-Host "Weiter mit Enter"
$ptSearchBR = Get-CursorPos

# ---------------------------------------------------------------
# 1) Start-Button X-Position
# ---------------------------------------------------------------

Write-Host ""
Write-Host "1) Start-Button:" -ForegroundColor Green
Write-Host "   Maus auf die X-Mitte des Start-Buttons bewegen" -ForegroundColor Green
Write-Host "   (Höhe ist egal, weil dein Script Y aus dem Gem nimmt) und Enter." -ForegroundColor Green
Read-Host "Weiter mit Enter"
$ptStart = Get-CursorPos

# ---------------------------------------------------------------
# 2) Collect-Button
# ---------------------------------------------------------------

Write-Host ""
Write-Host "2) Collect-Button:" -ForegroundColor Green
Write-Host "   Maus auf 'Collect Trades' bewegen und Enter." -ForegroundColor Green
Read-Host "Weiter mit Enter"
$ptCollect = Get-CursorPos

# ---------------------------------------------------------------
# 3) Refresh-Button
# ---------------------------------------------------------------

Write-Host ""
Write-Host "3) Refresh-Button:" -ForegroundColor Green
Write-Host "   Maus auf 'Refresh' bewegen und Enter." -ForegroundColor Green
Read-Host "Weiter mit Enter"
$ptRefresh = Get-CursorPos

# ---------------------------------------------------------------
# 4) Progress-Balken-Mitte
# ---------------------------------------------------------------

Write-Host ""
Write-Host "4) Progress-Balken:" -ForegroundColor Green
Write-Host "   Maus ungefähr auf die Mitte des roten Balkens" -ForegroundColor Green
Write-Host "   eines laufenden Trades bewegen und Enter." -ForegroundColor Green
Read-Host "Weiter mit Enter"
$ptProg = Get-CursorPos

# ---------------------------------------------------------------
# Relative Werte berechnen
# ---------------------------------------------------------------

$SearchLeftRel   = ($ptSearchTL.X - $rect.Left) / $winWidth
$SearchTopRel    = ($ptSearchTL.Y - $rect.Top)  / $winHeight
$SearchRightRel  = ($ptSearchBR.X - $rect.Left) / $winWidth
$SearchBottomRel = ($ptSearchBR.Y - $rect.Top)  / $winHeight

$StartClickXRel   = ($ptStart.X   - $rect.Left) / $winWidth

$CollectXRel      = ($ptCollect.X - $rect.Left) / $winWidth
$CollectYRel      = ($ptCollect.Y - $rect.Top)  / $winHeight

$RefreshXRel      = ($ptRefresh.X - $rect.Left) / $winWidth
$RefreshYRel      = ($ptRefresh.Y - $rect.Top)  / $winHeight

$ProgressCenterXRel = ($ptProg.X  - $rect.Left) / $winWidth

# ---------------------------------------------------------------
# Ausgabe für deinen $config-Block
# ---------------------------------------------------------------

Write-Host ""
Write-Host "===== Werte für deine Config (in `$config einfügen) =====" -ForegroundColor Cyan

"{0} = {1:N4}" -f "SearchLeftRel",    $SearchLeftRel
"{0} = {1:N4}" -f "SearchTopRel",     $SearchTopRel
"{0} = {1:N4}" -f "SearchRightRel",   $SearchRightRel
"{0} = {1:N4}" -f "SearchBottomRel",  $SearchBottomRel
Write-Host ""

"{0} = {1:N4}" -f "StartClickXRel",   $StartClickXRel
Write-Host ""

"{0} = {1:N4}" -f "CollectXRel",      $CollectXRel
"{0} = {1:N4}" -f "CollectYRel",      $CollectYRel
Write-Host ""

"{0} = {1:N4}" -f "RefreshXRel",      $RefreshXRel
"{0} = {1:N4}" -f "RefreshYRel",      $RefreshYRel
Write-Host ""

"{0} = {1:N4}" -f "ProgressCenterXRel", $ProgressCenterXRel

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "Diese Zeilen 1:1 in den `$config-Block von TradingGems übernehmen." -ForegroundColor Yellow
Write-Host "Dann bist du voll fensterrelativ kalibriert." -ForegroundColor Yellow
