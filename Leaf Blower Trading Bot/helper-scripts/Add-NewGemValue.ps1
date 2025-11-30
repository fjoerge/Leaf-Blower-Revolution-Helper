<#
.SYNOPSIS
    Fügt automatisch einen neuen Gem-Wert (Ziffer) zum TradingGems-Projekt hinzu

.DESCRIPTION
    Dieses Script:
    - Generiert GemMask_X.ps1 aus Training-Bildern
    - Fügt den neuen Gem-Wert in TradingGems.v4.2.ps1 hinzu
    - Aktualisiert TradingGems-GUI.ps1 mit Stats-Tracking
    - Aktualisiert TradeStats.json

.PARAMETER GemValue
    Ziffer des neuen Gem-Werts (z.B. 5, 6, 7)

.PARAMETER TrainingFolder
    Pfad zum Ordner mit Training-Bildern (z.B. "pictures/Mask Training/5/")

.PARAMETER ThresholdPercent
    Schwellwert in Prozent (Standard: 60). Pixel wird gesetzt, wenn er in mindestens X% der Bilder hell ist.

.EXAMPLE
    .\Add-NewGemValue.ps1 -GemValue 5 -TrainingFolder "pictures/Mask Training/5/"
    
.EXAMPLE
    .\Add-NewGemValue.ps1 -GemValue 7 -TrainingFolder "pictures/Mask Training/7/" -ThresholdPercent 55
#>

param(
    [Parameter(Mandatory=$true)]
    [int]$GemValue,
    
    [Parameter(Mandatory=$true)]
    [string]$TrainingFolder,
    
    [Parameter(Mandatory=$false)]
    [int]$ThresholdPercent = 60
)

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

# Pfade definieren
$scriptPath = $PSScriptRoot
$mainScript = Join-Path $scriptPath "TradingGems.v4.2.ps1"
$guiScript = Join-Path $scriptPath "TradingGems-GUI.ps1"
$statsFile = Join-Path $scriptPath "TradeStats.json"
$maskOutputFile = Join-Path $scriptPath "GemMask_$GemValue.ps1"
$backupFolder = Join-Path $scriptPath "Backups"

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   Add New Gem Value: $GemValue" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Training-Ordner prüfen
Write-Host "[1/6] Prüfe Training-Ordner..." -ForegroundColor Yellow
$fullTrainingPath = Join-Path $scriptPath $TrainingFolder
if (-not (Test-Path $fullTrainingPath)) {
    Write-Host "      ✗ FEHLER: Training-Ordner nicht gefunden: $fullTrainingPath" -ForegroundColor Red
    exit 1
}

$trainingImages = Get-ChildItem -Path $fullTrainingPath -Filter "*.png"
if ($trainingImages.Count -eq 0) {
    Write-Host "      ✗ FEHLER: Keine PNG-Dateien im Training-Ordner gefunden" -ForegroundColor Red
    exit 1
}

Write-Host "      ✓ $($trainingImages.Count) Training-Bilder gefunden" -ForegroundColor Green

# Backup erstellen
if (-not (Test-Path $backupFolder)) {
    New-Item -ItemType Directory -Path $backupFolder | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupSuffix = "_backup_$timestamp"

Write-Host "[2/6] Erstelle Backups..." -ForegroundColor Yellow
Copy-Item $mainScript "$mainScript$backupSuffix"
Copy-Item $guiScript "$guiScript$backupSuffix"
if (Test-Path $statsFile) {
    Copy-Item $statsFile "$statsFile$backupSuffix"
}
Write-Host "      ✓ Backups erstellt" -ForegroundColor Green

# Maske generieren
Write-Host "[3/6] Generiere GemMask_$GemValue.ps1..." -ForegroundColor Yellow

$width = 16
$height = 16
$pixelCount = New-Object 'int[,]' $width, $height
$totalImages = $trainingImages.Count

# Alle Bilder durchgehen und helle Pixel zählen
foreach ($imgFile in $trainingImages) {
    $bmp = [System.Drawing.Bitmap]::FromFile($imgFile.FullName)
    
    if ($bmp.Width -ne $width -or $bmp.Height -ne $height) {
        Write-Host "      ✗ WARNUNG: $($imgFile.Name) hat falsche Größe ($($bmp.Width)x$($bmp.Height)), erwarte ${width}x${height}" -ForegroundColor Yellow
        $bmp.Dispose()
        continue
    }
    
    for ($y = 0; $y -lt $height; $y++) {
        for ($x = 0; $x -lt $width; $x++) {
            $pixel = $bmp.GetPixel($x, $y)
            $brightness = ($pixel.R + $pixel.G + $pixel.B) / 3
            
            if ($brightness -gt 128) {
                $pixelCount[$x,$y]++
            }
        }
    }
    
    $bmp.Dispose()
}

# Schwellwert berechnen
$threshold = [math]::Ceiling($totalImages * ($ThresholdPercent / 100.0))
Write-Host "      Schwellwert: $threshold von $totalImages Bildern" -ForegroundColor Cyan

# Maske erstellen
$maskScript = @"
`$mask$GemValue = New-Object 'bool[,]' $width, $height

"@

$setPixels = 0
for ($y = 0; $y -lt $height; $y++) {
    for ($x = 0; $x -lt $width; $x++) {
        if ($pixelCount[$x,$y] -ge $threshold) {
            $maskScript += "`$mask$GemValue[$x,$y] = `$true`n"
            $setPixels++
        }
    }
}

$maskScript += "`$script:GemValueMasks[`"$GemValue`"] = `$mask$GemValue`n"

# Maske speichern
Set-Content -Path $maskOutputFile -Value $maskScript -Encoding UTF8
Write-Host "      ✓ GemMask_$GemValue.ps1 erstellt ($setPixels Pixel gesetzt)" -ForegroundColor Green
Write-Host "      ✓ Datei: $maskOutputFile" -ForegroundColor Green

# TradingGems.v4.2.ps1 aktualisieren
Write-Host "[4/6] Aktualisiere TradingGems.v4.2.ps1..." -ForegroundColor Yellow
$mainContent = Get-Content $mainScript -Raw

# 1. Masken-Script einbinden (nach letztem GemMask_X.ps1)
$maskIncludePattern = '(?s)(Join-Path \$config\.BasePath "GemMask_\d+\.ps1"\))'
if ($mainContent -match $maskIncludePattern) {
    $maskIncludeInsert = "`n. (Join-Path `$config.BasePath `"GemMask_$GemValue.ps1`")"
    $mainContent = $mainContent -replace "($maskIncludePattern)", "`$1$maskIncludeInsert"
    Write-Host "      ✓ Masken-Include hinzugefügt" -ForegroundColor Green
} else {
    Write-Host "      ✗ WARNUNG: Masken-Include-Position nicht gefunden" -ForegroundColor Yellow
}

# 2. Stats-Objekt erweitern (nach letztem GemValueXCount)
$statsPattern = '(?s)(\$stats\s*=\s*@\{.*?GemValue\d+Count\s*=\s*\d+)'
if ($mainContent -match $statsPattern) {
    $statsInsert = "`n    GemValue${GemValue}Count = 0"
    $mainContent = $mainContent -replace $statsPattern, "`$1$statsInsert"
    Write-Host "      ✓ Stats-Objekt erweitert" -ForegroundColor Green
} else {
    Write-Host "      ✗ WARNUNG: Stats-Objekt nicht gefunden" -ForegroundColor Yellow
}

# 3. Stats-Tracking in Try-StartTrade erweitern (Gem-Wert Tracking)
$gemTrackingPattern = "(?s)(switch\s*\(\`$gemValue\)\s*\{.*?)(\s+default\s*\{)"
if ($mainContent -match $gemTrackingPattern) {
    $gemTrackingInsert = "`n            $GemValue { `$stats.GemValue${GemValue}Count++ }"
    $mainContent = $mainContent -replace $gemTrackingPattern, "`$1$gemTrackingInsert`$2"
    Write-Host "      ✓ Gem-Value Tracking hinzugefügt" -ForegroundColor Green
} else {
    Write-Host "      ✗ WARNUNG: Gem-Value Tracking nicht gefunden" -ForegroundColor Yellow
}

# Hauptscript speichern
Set-Content -Path $mainScript -Value $mainContent -Encoding UTF8
Write-Host "      ✓ TradingGems.v4.2.ps1 gespeichert" -ForegroundColor Green

# TradingGems-GUI.ps1 aktualisieren
Write-Host "[5/6] Aktualisiere TradingGems-GUI.ps1..." -ForegroundColor Yellow
$guiContent = Get-Content $guiScript -Raw

# 1. Stats-Objekt in GUI erweitern
$guiStatsPattern = "(?s)(\`$script:stats\s*=\s*@\{.*?GemValue\d+Count\s*=\s*\d+)"
if ($guiContent -match $guiStatsPattern) {
    $guiStatsInsert = "`n    GemValue${GemValue}Count = 0"
    $guiContent = $guiContent -replace $guiStatsPattern, "`$1$guiStatsInsert"
    Write-Host "      ✓ GUI Stats-Objekt erweitert" -ForegroundColor Green
} else {
    Write-Host "      ✗ WARNUNG: GUI Stats-Objekt nicht gefunden" -ForegroundColor Yellow
}

# 2. High-Value Calculation erweitern
$highValuePattern = "(?s)(\`$highValue\s*=.*?GemValue\d+Count)"
if ($guiContent -match $highValuePattern) {
    $guiContent = $guiContent -replace $highValuePattern, "`$1 + `$script:stats.GemValue${GemValue}Count"
    Write-Host "      ✓ High-Value Calculation erweitert" -ForegroundColor Green
} else {
    Write-Host "      ✗ WARNUNG: High-Value Calculation nicht gefunden" -ForegroundColor Yellow
}

# GUI-Script speichern
Set-Content -Path $guiScript -Value $guiContent -Encoding UTF8
Write-Host "      ✓ TradingGems-GUI.ps1 gespeichert" -ForegroundColor Green

# TradeStats.json aktualisieren (falls vorhanden)
Write-Host "[6/6] Aktualisiere TradeStats.json..." -ForegroundColor Yellow
if (Test-Path $statsFile) {
    $stats = Get-Content $statsFile -Raw | ConvertFrom-Json
    $stats | Add-Member -MemberType NoteProperty -Name "GemValue${GemValue}Count" -Value 0 -Force
    $stats | ConvertTo-Json -Depth 10 | Set-Content $statsFile -Encoding UTF8
    Write-Host "      ✓ TradeStats.json aktualisiert" -ForegroundColor Green
} else {
    Write-Host "      ⊙ TradeStats.json nicht gefunden (wird beim ersten Start erstellt)" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   ✓ Gem-Wert '$GemValue' erfolgreich hinzugefügt!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Details:" -ForegroundColor Yellow
Write-Host "  • Training-Bilder: $totalImages"
Write-Host "  • Schwellwert: $threshold Bilder ($ThresholdPercent%)"
Write-Host "  • Maske: $setPixels von $($width * $height) Pixeln gesetzt"
Write-Host "  • Maske-Datei: GemMask_$GemValue.ps1"
Write-Host ""
Write-Host "Nächste Schritte:" -ForegroundColor Yellow
Write-Host "  1. Bot neu starten"
Write-Host "  2. Gem-Erkennung in der GUI überwachen"
Write-Host "  3. Bei Bedarf ThresholdPercent anpassen und Script erneut ausführen"
Write-Host ""
Write-Host "Backups wurden erstellt mit Suffix: $backupSuffix" -ForegroundColor Cyan
