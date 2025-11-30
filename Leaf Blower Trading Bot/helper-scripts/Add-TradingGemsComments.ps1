param(
    [string]$Path = "TradingGems.v4.1.ps1"
)

if (-not (Test-Path $Path)) {
    Write-Host "Datei '$Path' nicht gefunden." -ForegroundColor Red
    exit 1
}

$code = Get-Content -Path $Path -Raw

# Mapping: Funktionsname -> Doc-Comment
$comments = @{
    "Get-GameWindowRect" = @"
<#
    Holt die Fenstergeometrie von game.exe über Win32Window.GetWindowRect.
    Rückgabe:
    - Win32Window.RECT bei Erfolg
    - `$null, wenn kein gültiges game.exe-Fenster gefunden wird
#>
"@

    "Write-Log" = @"
<#
    Zentrale Logging-Funktion mit drei Modi:
    - DEBUG: alle Logs
    - INFO : nur INFO
    - STATS: nur ausgewählte Status-/Start/Stop-Meldungen
    Spezielle Level:
    - HINT wird immer grün ausgegeben
#>
"@

    "Show-StatsBlock" = @"
<#
    Berechnet Kennzahlen (Laufzeit, Trades/h, Gems/h, Slots) aus `$stats
    und gibt einen formatierten Textblock als String-Array zurück.
    Wird für Live- und Final-Statistiken verwendet.
#>
"@

    "Update-StatsDisplay" = @"
<#
    Aktualisiert Laufzeit-Statistiken und zeichnet sie in die Konsole.
    Nutzt Show-StatsBlock und schreibt im STATS-Modus in einen festen
    Konsolenbereich (CursorTop wird gemerkt).
#>
"@

    "Add-ItemTypeFromSymbol" = @"
<#
    Lädt eine Item-Symboldatei (Beer, Gem, ...) aus pictures\\ItemSymbols,
    liest die mittlere Pixel-Farbe als Referenz und trägt sie mit Toleranz
    in `$script:ItemTypes ein.
#>
"@

    "Test-ColorEqual" = @"
<#
    Vergleicht zwei System.Drawing.Color-Werte per RGB-Abstand.
    Liefert `$true, wenn alle Kanal-Differenzen <= Tolerance sind.
#>
"@

    "Get-ScreenColor" = @"
<#
    Liest die Bildschirmfarbe an einem absoluten Screen-Punkt (X,Y),
    indem ein 1x1-Bitmap vom Screen kopiert wird.
#>
"@

    "Test-StartButtonEnabled" = @"
<#
    Prüft, ob der Start-Button an der Slot-Y-Position visuell „enabled“ ist.
    Misst dazu den Farb-Abstand zum konfigurierten StartEnabledColor und
    vergleicht ihn mit StartEnabledTolerance.
#>
"@

    "Invoke-SingleClick" = @"
<#
    Führt einen einzelnen Mausklick via externer AHK-Exe an Position (X,Y) aus.
    Nutzt das im Config gesetzte SingleClickExe und wartet auf Prozessende.
#>
"@

    "Invoke-DoubleClick" = @"
<#
    Führt einen Doppelklick via externer AHK-Exe an Position (X,Y) aus.
    Nutzt DoubleClickExe und wartet auf Prozessende.
#>
"@

    "Auto-CalibrateStartOffset" = @"
<#
    Versucht bei gehäuften Fehlstarts den vertikalen StartOffsetRel automatisch
    zu kalibrieren. Sucht um ClickY herum nach einem roten Fortschrittsbalken
    und mittelt den gefundenen Offset in die Config ein.
#>
"@

    "Test-SlotRunning" = @"
<#
    Prüft, ob an der ClickY-Position bereits ein Trade läuft.
    Scannt ein schmales Rechteck um die Progress-Bar-Position und zählt
    „rote“ Pixel; ab MinRedPixelsForRunning gilt der Slot als laufend.
#>
"@

    "Save-GemDebugImage" = @"
<#
    Speichert einen 16x16-Screenshot der Gem-Wert-Box zu Debugzwecken.
    Respektiert StatsGemScreenshotMode: OFF / ALL / UNKNOWN und baut den
    Dateinamen aus Reason, erkannter Ziffer und Position.
#>
"@

    "Get-GemValue" = @"
<#
    Liest den Gem-Wert (1–4) an FoundX/FoundY:
    - schneidet 16x16-Box aus dem Screen
    - baut eine bool[,]-Maske aus „hellen“ Pixeln
    - vergleicht mit allen GemMasken inkl. optionalem Horizontal-Shift
    Liefert:
    - beste Ziffer oder `$null
    - BrightPixelCount
    - bestScore und secondBestScore zur Qualitätsbewertung
#>
"@

    "Test-BeerValueIsBig" = @"
<#
    Prüft, ob der Beer-Wert optisch „groß“ ist (mehrere Ziffern).
    Zählt Spalten mit hellen Pixeln in der Value-Box und vergleicht sie
    mit BeerMinActiveColumns (z.B. kurze „1“ vs. langer Wert).
#>
"@

    "Should-StartItemTrade" = @"
<#
    Wendet die Policy für einen Item-Typ an (Gem, Beer, ...):
    - prüft Start-Flag
    - bei NeedsGemValue optional MinValue-Grenze
    Liefert `$true, wenn ein Trade für diesen Item-Typ gestartet werden darf.
#>
"@

    "Try-StartTrade" = @"
<#
    Führt bis zu drei Start-Versuche für einen Slot durch (Doppelklicks),
    prüft jeweils per Test-SlotRunning, ob ein roter Balken auftaucht.
    Bei Misserfolg wird ggf. Auto-CalibrateStartOffset ausgelöst.
    Aktualisiert Start-/Fail-Statistiken.
#>
"@

    "Invoke-CollectRefresh" = @"
<#
    Führt die Collect- und Refresh-AHK-Makros aus und aktualisiert
    Refresh-Statistiken. Danach kurze Pause (PostCollectDelayMs).
#>
"@

    "Invoke-RefreshOnly" = @"
<#
    Führt nur das Refresh-Makro aus (kein Collect) und erhöht RefreshCount.
    Wird genutzt, wenn Slots nicht voll sind oder Collect noch nicht fällig ist.
#>
"@

    "Save-SearchAreaSnapshot" = @"
<#
    Speichert einmalig pro Scriptlauf einen Screenshot des Suchbereichs
    (SearchRect) als SearchArea.png unter pictures\\ zur visuellen Kontrolle.
#>
"@

    "Find-SymbolHits" = @"
<#
    Scannt den Suchbereich einmal als Bitmap und sucht nach Item-Symbolen.
    Für jeden Pixel:
    - nächstliegenden ItemType nach Farbdistanz bestimmen
    - im 3x3-Umfeld Cluster gleicher Farbe zählen
    - bei genügend Clustern einen Hit mit FoundX/FoundY/ClickY anlegen
    Anschließend werden nahe Hits zu Zeilen zusammengefasst (Row-Gap).
#>
"@
}

# Für jede Funktion den Kommentar vor "function Name {" einfügen,
# falls dort nicht schon ein <# ... #>-Block steht.
foreach ($name in $comments.Keys) {
    $comment = $comments[$name]

    $pattern = "(?ms)(\r?\n)(\s*)function\s+$name\s*\{"
    if ($code -notmatch $pattern) { continue }

    # Prüfen, ob direkt davor schon ein <# ... #>-Kommentar steht
    $before = $code.Substring(0, [regex]::Match($code, $pattern).Index)
    if ($before -match "<#([^#]|\r?\n)*#>\s*$") {
        continue
    }

    $replacement = "`$1`$2$comment`$2function $name {"
    $code = [regex]::Replace($code, $pattern, $replacement, 1)
}

$backup = "$Path.bak"
Copy-Item -Path $Path -Destination $backup -Force
Set-Content -Path $Path -Value $code -Encoding UTF8

Write-Host "Kommentare eingefügt. Backup: $backup" -ForegroundColor Green
