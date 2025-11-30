Add-Type @"
using System;
using System.Runtime.InteropServices;

public static class Win32WindowTools {
    [DllImport("user32.dll")]
    public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);

    public struct RECT {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;
    }
}
"@

$proc = Get-Process -Name "game" -ErrorAction SilentlyContinue
if (-not $proc -or -not $proc.MainWindowHandle -or $proc.MainWindowHandle -eq 0) {
    Write-Host "game.exe mit sichtbarem Fenster nicht gefunden."
    return
}

$hwnd = $proc.MainWindowHandle

$rect = New-Object Win32WindowTools+RECT
[Win32WindowTools]::GetWindowRect($hwnd, [ref]$rect) | Out-Null

$left   = $rect.Left
$top    = $rect.Top
$width  = $rect.Right  - $rect.Left
$height = $rect.Bottom - $rect.Top

Write-Host "game.exe-Fenster:"
Write-Host ("  Left   = {0}" -f $left)
Write-Host ("  Top    = {0}" -f $top)
Write-Host ("  Width  = {0}" -f $width)
Write-Host ("  Height = {0}" -f $height)
