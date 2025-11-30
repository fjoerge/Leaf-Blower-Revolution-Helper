Add-Type @"
using System;
using System.Runtime.InteropServices;

public static class Win32WindowTools {
    [DllImport("user32.dll")]
    public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SetWindowPos(
        IntPtr hWnd,
        IntPtr hWndInsertAfter,
        int X,
        int Y,
        int cx,
        int cy,
        uint uFlags
    );

    public struct RECT {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;
    }
}
"@

# Konstanten für SetWindowPos
$SWP_NOSIZE     = 0x0001
$SWP_NOMOVE     = 0x0002
$SWP_NOZORDER   = 0x0004
$SWP_NOACTIVATE = 0x0010

# Zielgröße
$targetW = 1280
$targetH = 720

# Zielposition (Desktop-Koordinaten!)
# Beispiel: Spiel-Fenster oben links auf Monitor 2 mit Breite 2560:
$targetX = 2167   # anpassen!
$targetY = 678    # anpassen!

# game.exe suchen
$proc = Get-Process -Name "game" -ErrorAction SilentlyContinue
if (-not $proc -or -not $proc.MainWindowHandle -or $proc.MainWindowHandle -eq 0) {
    Write-Host "game.exe mit sichtbarem Fenster nicht gefunden."
    return
}

$hwnd = $proc.MainWindowHandle

# RECT holen
$rect = New-Object Win32WindowTools+RECT
[Win32WindowTools]::GetWindowRect($hwnd, [ref]$rect) | Out-Null

$left   = $rect.Left
$top    = $rect.Top
$right  = $rect.Right
$bottom = $rect.Bottom

$width  = $right  - $left
$height = $bottom - $top

Write-Host ("Aktuelle Fensterposition: X={0}, Y={1}, Breite={2}, Höhe={3}" -f `
            $left, $top, $width, $height)
# Fensterposition + Größe in einem Rutsch setzen
[Win32WindowTools]::SetWindowPos(
    $hwnd,
    [IntPtr]::Zero,
    $targetX,
    $targetY,
    $targetW,
    $targetH,
    $SWP_NOZORDER -bor $SWP_NOACTIVATE
) | Out-Null

Write-Host ("game.exe-Fenster auf {0}x{1} verschoben: X={2}, Y={3}" -f `
            $targetW, $targetH, $targetX, $targetY)
