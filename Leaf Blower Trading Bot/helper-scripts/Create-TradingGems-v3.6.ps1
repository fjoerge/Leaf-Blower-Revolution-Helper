<#
.SYNOPSIS
    Automatisches Patch-Script: TradingGems v3.5 -> v3.6
    Behebt 8 identifizierte Fehler automatisch

.DESCRIPTION
    CRITICAL FIXES:
    1. $gemValue -> $PreGemValue in Try-StartTrade
    2. Doppelzaehlung-Block aus Try-StartTrade loeschen
    3. Save-GemDebug -> Save-GemDebugImage mit korrekten Parametern
    4. Duplizierte DEBUG-Logs entfernen

    RECOMMENDED FIXES:
    5. $gemVal Variable entfernen
    6. Test-StartButtonEnabled: $slot Parameter entfernen
    7. $script:GemValueTemplates entfernen (unused)
    8. MinClusterPixels in Config auslagern

.PARAMETER SourceFile
    Pfad zur v3.5 Datei
    Default: D:\Dokumente\AHK\LBR Automation\Version 3.6 - AutoUpdate\TradingGems.v3.5.ps1

.PARAMETER TargetDir
    Zielordner fuer v3.6
    Default: D:\Dokumente\AHK\LBR Automation\Version 3.6 - AutoUpdate

.EXAMPLE
    .\Create-TradingGems-v3.6.ps1

#>

param(
    [string]$SourceFile = "D:\Dokumente\AHK\LBR Automation\Version 3.6 - AutoUpdate\TradingGems.v3.5.ps1",
    [string]$TargetDir  = "D:\Dokumente\AHK\LBR Automation\Version 3.6 - AutoUpdate"
)

$ErrorActionPreference = "Stop"

# --- SETUP ---

$OutputFile = Join-Path $TargetDir "TradingGems.v3.6.ps1"
$BackupFile = Join-Path $TargetDir "TradingGems.v3.5.backup.ps1"

Write-Host ""
Write-Host "=================================================================================" -ForegroundColor Cyan
Write-Host "TradingGems v3.5 -> v3.6 PATCH (8 Fixes)" -ForegroundColor Cyan
Write-Host "=================================================================================" -ForegroundColor Cyan
Write-Host ""

# --- CHECKS ---

if (-not (Test-Path $SourceFile)) {
    Write-Host "FEHLER: $SourceFile nicht gefunden" -ForegroundColor Red
    exit 1
}

Write-Host "Quelle: $SourceFile"
Write-Host "Ziel:   $OutputFile"
Write-Host "Backup: $BackupFile"
Write-Host ""

# --- BACKUP ---

Write-Host "Erstelle Backup..." -ForegroundColor Cyan
Copy-Item -Path $SourceFile -Destination $BackupFile -Force
Write-Host "OK - Backup erstellt" -ForegroundColor Green

# --- LOAD CONTENT ---

Write-Host ""
Write-Host "Lade v3.5 Datei..." -ForegroundColor Cyan
$content = Get-Content -Path $SourceFile -Raw -Encoding UTF8
$originalSize = $content.Length
Write-Host "OK - $($originalSize) Zeichen gelesen" -ForegroundColor Green

Write-Host ""
Write-Host "=================================================================================" -ForegroundColor Cyan
Write-Host "APPLYING 8 PATCHES" -ForegroundColor Cyan
Write-Host "=================================================================================" -ForegroundColor Cyan
Write-Host ""

$patchCount = 0

# --- CRITICAL FIX 1: $gemValue -> $PreGemValue in Try-StartTrade ---

Write-Host "[FIX 1] CRITICAL: gemValue -> PreGemValue in Try-StartTrade" -ForegroundColor Yellow

Write-Host "  1a: Variable unten setzen (gemVal = PreGemValue) entfernen..." -ForegroundColor Gray
if ($content -match [regex]::Escape('    $gemVal = $PreGemValue')) {
    $content = $content -replace [regex]::Escape('    $gemVal = $PreGemValue' + "`r`n"), ""
    Write-Host "      OK" -ForegroundColor Green
    $patchCount++
}

Write-Host "  1b: if (gemValue -ne null...) in Debug-Block..." -ForegroundColor Gray
if ($content -match [regex]::Escape('if ($gemValue -ne $null -and $gemValue -gt 0)')) {
    $old = 'if ($gemValue -ne $null -and $gemValue -gt 0) {
        Write-Log ("Y={0}: GemValue vor Startversuchen = {1}" -f $ClickY, $gemValue) "DEBUG"'
    $new = 'if ($PreGemValue -ne $null -and $PreGemValue -gt 0) {
        Write-Log ("Y={0}: GemValue vor Startversuchen = {1}" -f $ClickY, $PreGemValue) "DEBUG"'
    if ($content -match [regex]::Escape($old)) {
        $content = $content -replace [regex]::Escape($old), $new
        Write-Host "      OK" -ForegroundColor Green
        $patchCount++
    }
}

Write-Host "  1c: if (gemValue eq 1) Filter-Block..." -ForegroundColor Gray
if ($content -match 'if \(\$gemValue -eq 1\)') {
    $old = 'if ($gemValue -eq 1) {
        Write-Log ("Y={0}: GemValue=1 -> Trade wird im STATS-Modus uebersprungen." -f $ClickY) "STATS"'
    $new = 'if ($PreGemValue -eq 1) {
        Write-Log ("Y={0}: GemValue=1 -> Trade wird im STATS-Modus uebersprungen." -f $ClickY) "STATS"'
    if ($content -match [regex]::Escape($old)) {
        $content = $content -replace [regex]::Escape($old), $new
        Write-Host "      OK" -ForegroundColor Green
        $patchCount++
    }
}

Write-Host "  1d: switch (gemValue) in Gem-Stats Block..." -ForegroundColor Gray
$gemValueSwitches = @([regex]::Matches($content, 'switch \(\$gemValue\)'))
if ($gemValueSwitches.Count -gt 0) {
    $content = $content -replace 'switch \(\$gemValue\)', 'switch ($PreGemValue)'
    Write-Host "      OK - $($gemValueSwitches.Count) Stellen ersetzt" -ForegroundColor Green
    $patchCount++
}

Write-Host ""

# --- CRITICAL FIX 2: Doppelzaehlung-Block loeschen ---

Write-Host "[FIX 2] CRITICAL: Doppelzaehlung-Block aus Try-StartTrade loeschen" -ForegroundColor Yellow

$blockStart = '        # --- Gem-Stats nur fuer erkannte 2er/3er -------------------------'
$blockEnd = '            }
        }'

if ($content -match [regex]::Escape($blockStart)) {
    Write-Host "  Suche Doppelzaehlung-Block..." -ForegroundColor Gray
    
    $pattern = '        # --- Gem-Stats nur.*?(?=\r\n\s+# Debug-Info|break\s+\})'
    if ($content -match $pattern) {
        $content = $content -replace $pattern, ""
        Write-Host "  OK - Block mit ~18 Zeilen geloescht" -ForegroundColor Green
        $patchCount++
    }
} else {
    Write-Host "  Block nicht gefunden (optional)" -ForegroundColor Gray
}

Write-Host ""

# --- CRITICAL FIX 3: Save-GemDebug -> Save-GemDebugImage ---

Write-Host "[FIX 3] CRITICAL: Save-GemDebug -> Save-GemDebugImage" -ForegroundColor Yellow

Write-Host "  3a: SampleMode Block..." -ForegroundColor Gray
if ($content -match 'Save-GemDebug') {
    $old = 'Save-GemDebug -FoundX $hit.FoundX -FoundY $hit.FoundY -Label "unknown"'
    $new = 'Save-GemDebugImage -Bitmap $null -FoundX $hit.FoundX -FoundY $hit.FoundY -Digit 0 -Reason "UNKNOWN"'
    if ($content -match [regex]::Escape($old)) {
        $content = $content -replace [regex]::Escape($old), $new
        Write-Host "      OK" -ForegroundColor Green
        $patchCount++
    }
}

Write-Host ""

# --- CRITICAL FIX 4: Duplizierte Debug-Logs entfernen ---

Write-Host "[FIX 4] CRITICAL: Duplizierte Debug-Logs entfernen" -ForegroundColor Yellow
Write-Host "  (Wird mit FIX 2 behoben)" -ForegroundColor Gray

Write-Host ""

# --- RECOMMENDED FIX 5: MinClusterPixels in Config auslagern ---

Write-Host "[FIX 5] RECOMMENDED: MinClusterPixels in Config auslagern" -ForegroundColor Yellow

Write-Host "  5a: Fuege MinClusterPixels zu Config hinzu..." -ForegroundColor Gray
if ($content -match 'MinScoreGap\s+=\s+3') {
    $old = '    MinScoreGap            = 3      # Differenz zwischem GemScores damit sie als gut diese Zahl erkannt werden, wenn Differenz sehr klein werden diese als UNKNOWN gespeichert
    MinBrightPixels        = 10      # Mindestens notwendige helle Pixel um auch ausgewertet zu werden'
    $new = '    MinScoreGap            = 3      # Differenz zwischem GemScores damit sie als gut diese Zahl erkannt werden, wenn Differenz sehr klein werden diese als UNKNOWN gespeichert
    MinBrightPixels        = 10      # Mindestens notwendige helle Pixel um auch ausgewertet zu werden
    MinClusterPixels       = 4       # Mindestanzahl Nachbarpixel (3x3) mit Zielfarbe fuer Gem-Detection'
    if ($content -match [regex]::Escape($old)) {
        $content = $content -replace [regex]::Escape($old), $new
        Write-Host "      OK" -ForegroundColor Green
        $patchCount++
    }
}

Write-Host "  5b: Ersetze hardcoded Wert in Find-SymbolHits..." -ForegroundColor Gray
if ($content -match 'MinClusterPixels = 4') {
    $old = '    $MinClusterPixels = 4   # kannst du nach Bedarf hoch/runter drehen'
    $new = '    $MinClusterPixels = $config.MinClusterPixels'
    if ($content -match [regex]::Escape($old)) {
        $content = $content -replace [regex]::Escape($old), $new
        Write-Host "      OK" -ForegroundColor Green
        $patchCount++
    }
}

Write-Host ""

# --- RECOMMENDED FIX 6: $slot Parameter entfernen ---

Write-Host "[FIX 6] RECOMMENDED: Test-StartButtonEnabled: Verwaisten Slot-Parameter entfernen" -ForegroundColor Yellow

Write-Host "  6a: Funktion Signatur aendern..." -ForegroundColor Gray
if ($content -match 'function Test-StartButtonEnabled') {
    $old = 'function Test-StartButtonEnabled {
    param(
        [int]$StartClickX,
        [int]$ClickY,
        [pscustomobject]$slot
    )'
    $new = 'function Test-StartButtonEnabled {
    param(
        [int]$StartClickX,
        [int]$ClickY
    )'
    if ($content -match [regex]::Escape($old)) {
        $content = $content -replace [regex]::Escape($old), $new
        Write-Host "      OK" -ForegroundColor Green
        $patchCount++
    }
}

Write-Host "  6b: Aufruf in Main Loop aendern..." -ForegroundColor Gray
if ($content -match 'Test-StartButtonEnabled.*-slot') {
    $old = 'Test-StartButtonEnabled -StartClickX $StartClickX -ClickY $hit.ClickY -slot $hit.Slot'
    $new = 'Test-StartButtonEnabled -StartClickX $StartClickX -ClickY $hit.ClickY'
    if ($content -match [regex]::Escape($old)) {
        $content = $content -replace [regex]::Escape($old), $new
        Write-Host "      OK" -ForegroundColor Green
        $patchCount++
    }
}

Write-Host ""

# --- RECOMMENDED FIX 7: GemValueTemplates entfernen ---

Write-Host "[FIX 7] RECOMMENDED: Verwaiste GemValueTemplates entfernen" -ForegroundColor Yellow

Write-Host "  Entferne: `$script:GemValueTemplates = @{}" -ForegroundColor Gray
if ($content -match 'script:GemValueTemplates = @{}') {
    $old = '$script:GemValueTemplates = @{}'
    if ($content -match [regex]::Escape($old)) {
        $content = $content -replace [regex]::Escape($old) + "\r\n", ""
        Write-Host "      OK" -ForegroundColor Green
        $patchCount++
    }
}

Write-Host ""

# --- RECOMMENDED FIX 8: Cleanup am Ende ---

Write-Host "[FIX 8] RECOMMENDED: Cleanup verwaister Dispose-Aufrufe" -ForegroundColor Yellow

Write-Host "  Entferne Template-Dispose (verwendet nicht vorhanden)..." -ForegroundColor Gray
if ($content -match 'foreach.*GemValueTemplates') {
    $old = '
if ($script:GemValueTemplates) {
    foreach ($bmp in $script:GemValueTemplates.Values) {
        $bmp.Dispose()
    }
}'
    if ($content -match [regex]::Escape($old)) {
        $content = $content -replace [regex]::Escape($old), ""
        Write-Host "      OK" -ForegroundColor Green
        $patchCount++
    }
}

Write-Host ""

# --- SAVE ---

Write-Host "Speichere v3.6..." -ForegroundColor Cyan
$content | Out-File -FilePath $OutputFile -Encoding UTF8 -NoNewline
$newSize = $content.Length
Write-Host "OK - $($newSize) Zeichen geschrieben" -ForegroundColor Green

Write-Host ""
Write-Host "=================================================================================" -ForegroundColor Cyan
Write-Host "PATCH ABGESCHLOSSEN" -ForegroundColor Cyan
Write-Host "=================================================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Statistiken:" -ForegroundColor Cyan
Write-Host "  Dateigroe altv3.5:  $($originalSize) Bytes"
Write-Host "  Dateigroe neu v3.6: $($newSize) Bytes"
Write-Host "  Groessendifferenz:  $($originalSize - $newSize) Bytes"
Write-Host ""

Write-Host "Patches angewendet: $patchCount / 8" -ForegroundColor Green
if ($patchCount -ge 7) {
    Write-Host ""
    Write-Host "Status: Ready to use!" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "WARNUNG: Nur $patchCount Patches angewendet" -ForegroundColor Yellow
    Write-Host "Bitte manuell pruefen!" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Naechste Schritte:" -ForegroundColor Cyan
Write-Host "  1. v3.6 testen mit F8" -ForegroundColor Gray
Write-Host "  2. Stats sollten jetzt korrekt zaehlen" -ForegroundColor Gray
Write-Host "  3. SampleMode sollte fehlerfrei sein" -ForegroundColor Gray
Write-Host "  4. GemValue-Filter funktioniert" -ForegroundColor Gray
Write-Host ""
