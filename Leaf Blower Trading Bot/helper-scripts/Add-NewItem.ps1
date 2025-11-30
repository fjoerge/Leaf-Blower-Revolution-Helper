<#
.SYNOPSIS
    Fügt automatisch ein neues Trade-Item zum TradingGems-Projekt hinzu

.DESCRIPTION
    Dieses Script:
    - Liest vorhandene Config-Dateien ein
    - Fügt das neue Item in TradingGems.v4.2.ps1 hinzu
    - Aktualisiert TradingGems-GUI.ps1 mit neuen UI-Elementen
    - Aktualisiert TradeConfig.json

.PARAMETER ItemName
    Name des neuen Items (z.B. "Emerald", "Ruby")

.PARAMETER SymbolPath
    Pfad zum Symbol-Screenshot (z.B. "pictures/ItemSymbols/Emerald.png")

.PARAMETER NeedsGemValue
    Gibt an, ob das Item einen Gem-Wert benötigt ($true/$false)

.EXAMPLE
    .\Add-NewItem.ps1 -ItemName "Emerald" -SymbolPath "pictures/ItemSymbols/Emerald.png" -NeedsGemValue $false
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$ItemName,
    
    [Parameter(Mandatory=$true)]
    [string]$SymbolPath,
    
    [Parameter(Mandatory=$false)]
    [bool]$NeedsGemValue = $false
)

$ErrorActionPreference = "Stop"

# Pfade definieren
$scriptPath = $PSScriptRoot
$mainScript = Join-Path $scriptPath "TradingGems.v4.2.ps1"
$guiScript = Join-Path $scriptPath "TradingGems-GUI.ps1"
$configFile = Join-Path $scriptPath "TradeConfig.json"
$backupFolder = Join-Path $scriptPath "Backups"

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   Add New Item: $ItemName" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Backup erstellen
if (-not (Test-Path $backupFolder)) {
    New-Item -ItemType Directory -Path $backupFolder | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupSuffix = "_backup_$timestamp"

Write-Host "[1/5] Erstelle Backups..." -ForegroundColor Yellow
Copy-Item $mainScript "$mainScript$backupSuffix"
Copy-Item $guiScript "$guiScript$backupSuffix"
Copy-Item $configFile "$configFile$backupSuffix"
Write-Host "      ✓ Backups erstellt in: $backupFolder" -ForegroundColor Green

# Symbol-Datei prüfen
Write-Host "[2/5] Prüfe Symbol-Datei..." -ForegroundColor Yellow
$fullSymbolPath = Join-Path $scriptPath $SymbolPath
if (-not (Test-Path $fullSymbolPath)) {
    Write-Host "      ✗ FEHLER: Symbol-Datei nicht gefunden: $fullSymbolPath" -ForegroundColor Red
    exit 1
}
Write-Host "      ✓ Symbol-Datei gefunden" -ForegroundColor Green

# Toleranzwert aus vorhandenen Items ermitteln
Write-Host "[3/5] Ermittle Standard-Toleranzwert..." -ForegroundColor Yellow
$config = Get-Content $configFile -Raw | ConvertFrom-Json
$existingTolerances = @()
$config.ItemPolicies.PSObject.Properties | ForEach-Object {
    $existingTolerances += $_.Value.Tolerance
}
$defaultTolerance = ($existingTolerances | Measure-Object -Average).Average
if ($defaultTolerance -eq $null -or $defaultTolerance -eq 0) {
    $defaultTolerance = 10
}
$defaultTolerance = [math]::Round($defaultTolerance)
Write-Host "      ✓ Standard-Toleranz: $defaultTolerance" -ForegroundColor Green

# TradingGems.v4.2.ps1 aktualisieren
Write-Host "[4/5] Aktualisiere TradingGems.v4.2.ps1..." -ForegroundColor Yellow
$mainContent = Get-Content $mainScript -Raw

# 1. Config-Section erweitern (nach letztem Item in ItemPolicies)
$configPattern = '(?s)(ItemPolicies\s*=\s*@\{.*?)(\s+\})'
if ($mainContent -match $configPattern) {
    $configInsert = @"
        $ItemName = @{
            Start         = `$false
            Tolerance     = $defaultTolerance
            NeedsGemValue = `$$NeedsGemValue
        }
"@
    $mainContent = $mainContent -replace $configPattern, "`$1`n$configInsert`$2"
    Write-Host "      ✓ Config-Section erweitert" -ForegroundColor Green
} else {
    Write-Host "      ✗ WARNUNG: Config-Section nicht gefunden" -ForegroundColor Yellow
}

# 2. Stats-Objekt erweitern (nach letztem XxxTrades)
$statsPattern = '(?s)(\$stats\s*=\s*@\{.*?)(Trades\s*=\s*\d+)'
if ($mainContent -match $statsPattern) {
    $statsInsert = "`n    ${ItemName}Trades = 0"
    $mainContent = $mainContent -replace "($statsPattern)", "`$1$statsInsert"
    Write-Host "      ✓ Stats-Objekt erweitert" -ForegroundColor Green
} else {
    Write-Host "      ✗ WARNUNG: Stats-Objekt nicht gefunden" -ForegroundColor Yellow
}

# 3. ItemTypes-Array erweitern (nach letztem ItemType)
$itemTypesPattern = '(?s)(\$itemTypes\s*=\s*@\(.*?)(\s+\))'
if ($mainContent -match $itemTypesPattern) {
    $itemTypeInsert = @"
    ,
    [pscustomobject]@{
        Name       = "$ItemName"
        Color      = @{ R = 0; G = 0; B = 0 }  # Wird automatisch ermittelt
        Tolerance  = `$config.ItemPolicies.$ItemName.Tolerance
    }
"@
    $mainContent = $mainContent -replace $itemTypesPattern, "`$1$itemTypeInsert`$2"
    Write-Host "      ✓ ItemTypes-Array erweitert" -ForegroundColor Green
} else {
    Write-Host "      ✗ WARNUNG: ItemTypes-Array nicht gefunden" -ForegroundColor Yellow
}

# 4. Stats-Tracking in Try-StartTrade erweitern
$trackingPattern = '(?s)(switch\s*\(\$itemName\)\s*\{.*?)(default\s*\{)'
if ($mainContent -match $trackingPattern) {
    $trackingInsert = "        `"$ItemName`" { `$stats.${ItemName}Trades++ }`n        "
    $mainContent = $mainContent -replace $trackingPattern, "`$1$trackingInsert`$2"
    Write-Host "      ✓ Stats-Tracking erweitert" -ForegroundColor Green
} else {
    Write-Host "      ✗ WARNUNG: Stats-Tracking nicht gefunden" -ForegroundColor Yellow
}

# Hauptscript speichern
Set-Content -Path $mainScript -Value $mainContent -Encoding UTF8
Write-Host "      ✓ TradingGems.v4.2.ps1 gespeichert" -ForegroundColor Green

# TradingGems-GUI.ps1 aktualisieren
Write-Host "[5/5] Aktualisiere TradingGems-GUI.ps1..." -ForegroundColor Yellow
$guiContent = Get-Content $guiScript -Raw

# 1. XAML erweitern - Checkbox
$xamlCheckboxPattern = '(?s)(<CheckBox x:Name="chkCosmicLeaf".*?<\/CheckBox>)'
if ($guiContent -match $xamlCheckboxPattern) {
    $xamlCheckboxInsert = @"
`n                                <CheckBox x:Name="chk$ItemName" Content="$ItemName" Margin="0,5,0,0"/>
"@
    $guiContent = $guiContent -replace $xamlCheckboxPattern, "`$1$xamlCheckboxInsert"
    Write-Host "      ✓ XAML Checkbox hinzugefügt" -ForegroundColor Green
} else {
    Write-Host "      ✗ WARNUNG: XAML Checkbox-Position nicht gefunden" -ForegroundColor Yellow
}

# 2. XAML erweitern - ProgressBar
$xamlProgressPattern = '(?s)(<ProgressBar x:Name="barCosmicLeaf".*?<\/Grid>)'
if ($guiContent -match $xamlProgressPattern) {
    $xamlProgressInsert = @"
`n
                            <Grid Margin="0,5,0,0">
                                <ProgressBar x:Name="bar$ItemName" Height="20" Background="#1F2121" BorderBrush="#626C71" BorderThickness="1"/>
                                <TextBlock x:Name="txt${ItemName}Percent" Text="0%" HorizontalAlignment="Center" VerticalAlignment="Center" Foreground="White" FontWeight="Bold"/>
                            </Grid>
"@
    $guiContent = $guiContent -replace $xamlProgressPattern, "`$1$xamlProgressInsert"
    Write-Host "      ✓ XAML ProgressBar hinzugefügt" -ForegroundColor Green
} else {
    Write-Host "      ✗ WARNUNG: XAML ProgressBar-Position nicht gefunden" -ForegroundColor Yellow
}

# 3. Controls-Array erweitern
$controlsPattern = "(?s)('chkCosmicLeaf')"
if ($guiContent -match $controlsPattern) {
    $controlsInsert = ",'chk$ItemName','bar$ItemName','txt${ItemName}Percent'"
    $guiContent = $guiContent -replace $controlsPattern, "`$1$controlsInsert"
    Write-Host "      ✓ Controls-Array erweitert" -ForegroundColor Green
} else {
    Write-Host "      ✗ WARNUNG: Controls-Array nicht gefunden" -ForegroundColor Yellow
}

# 4. Stats-Objekt in GUI erweitern
$guiStatsPattern = '(?s)(\$script:stats\s*=\s*@\{.*?CosmicLeafTrades\s*=\s*0)'
if ($guiContent -match $guiStatsPattern) {
    $guiStatsInsert = "`n    ${ItemName}Trades = 0"
    $guiContent = $guiContent -replace $guiStatsPattern, "`$1$guiStatsInsert"
    Write-Host "      ✓ GUI Stats-Objekt erweitert" -ForegroundColor Green
} else {
    Write-Host "      ✗ WARNUNG: GUI Stats-Objekt nicht gefunden" -ForegroundColor Yellow
}

# 5. Save-Configuration erweitern
$saveConfigPattern = "(?s)(CosmicLeaf\s*=\s*@\{.*?\})"
if ($guiContent -match $saveConfigPattern) {
    $saveConfigInsert = @"
`n            $ItemName = @{
                Start = `$controls['chk$ItemName'].IsChecked
                Tolerance = $defaultTolerance
                NeedsGemValue = `$$NeedsGemValue
            }
"@
    $guiContent = $guiContent -replace $saveConfigPattern, "`$1$saveConfigInsert"
    Write-Host "      ✓ Save-Configuration erweitert" -ForegroundColor Green
} else {
    Write-Host "      ✗ WARNUNG: Save-Configuration nicht gefunden" -ForegroundColor Yellow
}

# 6. Update-Statistics erweitern (ProgressBars)
$updateStatsPattern = "(?s)(if \(\`$stats\.CosmicLeafTrades -gt 0\).*?\})"
if ($guiContent -match $updateStatsPattern) {
    $updateStatsInsert = @"
`n
    if (`$stats.${ItemName}Trades -gt 0) {
        `$${ItemName}Pct = [math]::Round((`$stats.${ItemName}Trades / `$totalTrades) * 100, 1)
        `$controls['bar$ItemName'].Value = `$${ItemName}Pct
        `$controls['txt${ItemName}Percent'].Text = "`$${ItemName}Pct%"
    }
"@
    $guiContent = $guiContent -replace $updateStatsPattern, "`$1$updateStatsInsert"
    Write-Host "      ✓ Update-Statistics erweitert" -ForegroundColor Green
} else {
    Write-Host "      ✗ WARNUNG: Update-Statistics nicht gefunden" -ForegroundColor Yellow
}

# GUI-Script speichern
Set-Content -Path $guiScript -Value $guiContent -Encoding UTF8
Write-Host "      ✓ TradingGems-GUI.ps1 gespeichert" -ForegroundColor Green

# TradeConfig.json aktualisieren
Write-Host "" -ForegroundColor Yellow
Write-Host "Aktualisiere TradeConfig.json..." -ForegroundColor Yellow
$config.ItemPolicies | Add-Member -MemberType NoteProperty -Name $ItemName -Value @{
    Start = $false
    Tolerance = $defaultTolerance
    NeedsGemValue = $NeedsGemValue
} -Force
$config | ConvertTo-Json -Depth 10 | Set-Content $configFile -Encoding UTF8
Write-Host "✓ TradeConfig.json gespeichert" -ForegroundColor Green

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   ✓ Item '$ItemName' erfolgreich hinzugefügt!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Nächste Schritte:" -ForegroundColor Yellow
Write-Host "  1. Symbol-Datei sollte hier liegen: $SymbolPath"
Write-Host "  2. Bot neu starten, damit Referenzfarbe automatisch erkannt wird"
Write-Host "  3. In der GUI kann der Toleranzwert bei Bedarf angepasst werden"
Write-Host ""
Write-Host "Backups wurden erstellt mit Suffix: $backupSuffix" -ForegroundColor Cyan
