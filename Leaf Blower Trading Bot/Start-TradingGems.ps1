# TradingGems Launcher - mit Restart-Logik + Fensterposition
# Version 2.2 - Bot laeuft UNVERAENDERT

$ErrorActionPreference = "Stop"

# ===== Fenster des Launchers nach oben rechts verschieben ====================
Add-Type @"
using System;
using System.Runtime.InteropServices;

public static class ConsoleWin {
    [DllImport("kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();

    [DllImport("user32.dll")]
    public static extern bool SetWindowPos(
        IntPtr hWnd,
        IntPtr hWndInsertAfter,
        int X,
        int Y,
        int cx,
        int cy,
        uint uFlags
    );
}
"@

function Move-LauncherWindow {
    $hWnd = [ConsoleWin]::GetConsoleWindow()
    if ($hWnd -eq [IntPtr]::Zero) {
        return
    }

    # Feste Position: oben rechts bei X=2168, Y=0
    # (Groesse bleibt unveraendert durch SWP_NOSIZE)
    $x = 2168
    $y = 0

    $HWND_TOP       = [IntPtr]::Zero
    $SWP_NOSIZE     = 0x0001
    $SWP_SHOWWINDOW = 0x0040

    [ConsoleWin]::SetWindowPos(
        $hWnd,
        $HWND_TOP,
        [int]$x,
        [int]$y,
        0,
        0,
        $SWP_NOSIZE -bor $SWP_SHOWWINDOW
    ) | Out-Null
}

Move-LauncherWindow

# ===== WinAPI fuer GUI in den Vordergrund holen =============================
Add-Type @"
using System;
using System.Runtime.InteropServices;

public static class WinAp {
    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
}
"@
# ============================================================================

# Pfade
$scriptPath = $PSScriptRoot
$botScript  = Join-Path $scriptPath "TradingGems.v4.4.ps1"
$guiScript  = Join-Path $scriptPath "TradingGems-GUI.ps1"

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   TradingGems Bot Launcher v2.2" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Pruefe ob Bot-Script existiert
if (-not (Test-Path $botScript)) {
    Write-Host "ERROR: Bot-Script nicht gefunden!" -ForegroundColor Red
    Write-Host "Erwartet: $botScript" -ForegroundColor Yellow
    Read-Host "Druecke Enter zum Beenden"
    exit 1
}

# Pruefe ob GUI-Script existiert
if (-not (Test-Path $guiScript)) {
    Write-Host "ERROR: GUI-Script nicht gefunden!" -ForegroundColor Red
    Write-Host "Erwartet: $guiScript" -ForegroundColor Yellow
    Read-Host "Druecke Enter zum Beenden"
    exit 1
}

# ===================== Haupt-Schleife =======================================
while ($true) {

    Write-Host "[1/3] Starte Botscript im Hintergrund..." -ForegroundColor Green

    # Starte ORIGINAL-Bot minimiert
    $botProcess = Start-Process powershell.exe -ArgumentList @(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-WindowStyle", "Minimized",
        "-File", "`"$botScript`""
    ) -PassThru

    Start-Sleep -Seconds 2

    if ($botProcess.HasExited) {
        Write-Host "ERROR: Bot konnte nicht gestartet werden!" -ForegroundColor Red
        Read-Host "Druecke Enter zum Beenden"
        exit 1
    }

    Write-Host "[2/3] Botscript erfolgreich gestartet (PID: $($botProcess.Id))" -ForegroundColor Green

    # Start GUI NICHT minimiert (eigener Prozess)
    Write-Host "[3/3] Starte GUI in eigenem Fenster..." -ForegroundColor Green

    $botGUIProcess = Start-Process powershell.exe -ArgumentList @(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
		"-WindowStyle", "Hidden",      # <--- wichtig
        "-File", "`"$guiScript`""
    ) -PassThru

    # Kurz warten, bis das GUI-Fenster existiert, dann in den Vordergrund holen
    try {
        $null = $botGUIProcess.WaitForInputIdle(5000)
    } catch {
        # Ignorieren, wenn Prozess keinen GUI-Message-Loop hat
    }

    $handle = [IntPtr]::Zero
    $tries  = 0

    while ($handle -eq [IntPtr]::Zero -and -not $botGUIProcess.HasExited -and $tries -lt 20) {
        $botGUIProcess.Refresh()
        $handle = $botGUIProcess.MainWindowHandle
        if ($handle -ne [IntPtr]::Zero) { break }
        Start-Sleep -Milliseconds 250
        $tries++
    }

    if ($handle -ne [IntPtr]::Zero) {
        [WinAp]::SetForegroundWindow($handle) | Out-Null
    }

    Write-Host ""
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "  Bot laeuft normal (ORIGINAL)" -ForegroundColor Green
    Write-Host "  GUI wurde gestartet (PID: $($botGUIProcess.Id))" -ForegroundColor Yellow
    Write-Host "  Druecke F8 im Bot-Fenster zum Starten!" -ForegroundColor Yellow
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host ""

    # Warten, bis EINE der beiden Instanzen beendet ist
    while (-not ($botProcess.HasExited -or $botGUIProcess.HasExited)) {
        Start-Sleep -Milliseconds 500
    }

    Write-Host ""
    Write-Host "Mindestens einer der Prozesse wurde beendet." -ForegroundColor Yellow

    # Sicherheits-Hard-Stop: falls einer noch laeuft, jetzt beenden
    if (-not $botProcess.HasExited) {
        Write-Host "Beende verbleibenden Bot-Prozess..." -ForegroundColor Yellow
        Stop-Process -Id $botProcess.Id -Force -ErrorAction SilentlyContinue
    }

    if (-not $botGUIProcess.HasExited) {
        Write-Host "Beende verbleibenden GUI-Prozess..." -ForegroundColor Yellow
        Stop-Process -Id $botGUIProcess.Id -Force -ErrorAction SilentlyContinue
    }

    Write-Host "Bot und GUI sind nun gestoppt." -ForegroundColor Green
    Write-Host ""

    $response = Read-Host "Bot neustarten (=J) oder Bot beenden (N)? (J/N) [Standard: J]"

    if ([string]::IsNullOrWhiteSpace($response) -or $response -match '^[Jj]') {
        $response = "J"
        Write-Host ""
        Write-Host "Starte Bot + GUI neu..." -ForegroundColor Green
        Write-Host ""
        continue
    }
	
    if ($response -match '^[Nn]') {
		break
    }
}

Write-Host ""
Write-Host "Launcher beendet." -ForegroundColor Cyan
Write-Host ""
