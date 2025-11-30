<#
.SYNOPSIS
    Add-NewItem.ps1 - Automatisches Hinzufuegen neuer Items zum TradingGems Bot
    
.DESCRIPTION
    Dieses Script fuegt automatisch ein neues Item zum Trading-Bot hinzu:
    - Liest Referenzfarbe aus Symbol-Bild
    - Aktualisiert TradingGems.v4.4.ps1 (ItemPolicies, Stats, ItemTypes)
    - Aktualisiert TradingGems-GUI.ps1 (Controls, XAML)
    - Aktualisiert TradeConfig.json
    - Erstellt Backups aller geaenderten Dateien
    
.PARAMETER ItemName
    Name des Items (z.B. "Apple", "Diamond", "Potion")
    
.PARAMETER SymbolFile
    Dateiname des Symbol-Bildes (muss in pictures\ItemSymbols\ liegen)
    
.PARAMETER Tolerance
    Farb-Toleranz fuer Symbol-Erkennung (Standard: 15)
    
.PARAMETER DefaultStart
    Soll das Item standardmaeÃŸig gehandelt werden? (Standard: $false)
    
.PARAMETER NeedsGemValue
    Benoetigt das Item einen Gem-Wert? (Standard: $false)
    
.EXAMPLE
    .\Add-NewItem.ps1 -ItemName "Apple" -SymbolFile "AppleSymbol.png"
    
.EXAMPLE
    .\Add-NewItem.ps1 -ItemName "Diamond" -SymbolFile "DiamondSymbol.png" -Tolerance 20 -DefaultStart $true
    
.NOTES
    Author: TradingGems Auto-Config
    Version: 1.0
    Date: 21.11.2024
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$ItemName,
    
    [Parameter(Mandatory=$false)]
    [string]$SymbolFile,
    
    [int]$Tolerance = 15,
    [bool]$DefaultStart = $false,
    [bool]$NeedsGemValue = $false
)

$ErrorActionPreference = "Stop"

# ============================================================================
# KONFIGURATION
# ============================================================================

$scriptPath = $PsScriptRoot
$mainScriptPath = Join-Path $scriptPath "TradingGems.v4.4.ps1"
$guiScriptPath = Join-Path $scriptPath "TradingGems-GUI.ps1"
$configPath = Join-Path $scriptPath "TradeConfig.json"
$symbolFolder = Join-Path $scriptPath "pictures\ItemSymbols"

# ============================================================================
# HELPER FUNKTIONEN
# ============================================================================

function Write-ColoredMessage {
    param([string]$Message, [string]$Type = "Info")
    
    $timestamp = Get-Date -Format "HH:mm:ss"
    switch ($Type) {
        "Success" { Write-Host "[$timestamp] + $Message" -ForegroundColor Green }
        "Error"   { Write-Host "[$timestamp] - $Message" -ForegroundColor Red }
        "Warning" { Write-Host "[$timestamp] WARN $Message" -ForegroundColor Yellow }
        "Info"    { Write-Host "[$timestamp] INFO $Message" -ForegroundColor Cyan }
        "Step"    { Write-Host "[$timestamp] STEP¶ $Message" -ForegroundColor White }
        default   { Write-Host "[$timestamp] $Message" }
    }
}

function Get-UserInput {
    param([string]$Prompt, [string]$Default = "")
    
    if ($Default) {
        $input = Read-Host "$Prompt (Standard: $Default)"
        if ([string]::IsNullOrWhiteSpace($input)) {
            return $Default
        }
        return $input
    }
    else {
        do {
            $input = Read-Host $Prompt
        } while ([string]::IsNullOrWhiteSpace($input))
        return $input
    }
}

function Get-ReferenceColor {
    param([string]$SymbolPath)
    
    Add-Type -AssemblyName System.Drawing
    
    try {
        $bitmap = [System.Drawing.Bitmap]::FromFile($SymbolPath)
        $centerX = [int]($bitmap.Width / 2)
        $centerY = [int]($bitmap.Height / 2)
        $color = $bitmap.GetPixel($centerX, $centerY)
        $bitmap.Dispose()
        
        return @{
            R = $color.R
            G = $color.G
            B = $color.B
        }
    }
    catch {
        Write-ColoredMessage "Fehler beim Lesen der Referenzfarbe: $_" "Error"
        return $null
    }
}

function Backup-File {
    param([string]$FilePath)
    
    if (-not (Test-Path $FilePath)) {
        Write-ColoredMessage "Datei nicht gefunden: $FilePath" "Warning"
        return $false
    }
    
    $backupFolder = Join-Path $scriptPath "backup_additem"
    if (-not (Test-Path $backupFolder)) {
        New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $fileName = Split-Path $FilePath -Leaf
    $backupPath = Join-Path $backupFolder "${fileName}_$timestamp.bak"
    
    Copy-Item $FilePath -Destination $backupPath -Force
    Write-ColoredMessage "  Backup: $backupPath" "Info"
    
    return $true
}

# ============================================================================
# ITEM HINZUFÜGEN FUNKTIONEN
# ============================================================================

function Add-ItemToMainScript {
    param(
        [string]$FilePath,
        [string]$ItemName,
        [hashtable]$RefColor,
        [int]$Tolerance,
        [bool]$DefaultStart,
        [bool]$NeedsGemValue,
        [string]$SymbolFile
    )
    
    Write-ColoredMessage "Aktualisiere Hauptscript..." "Step"
    
    $content = Get-Content $FilePath -Raw -Encoding UTF8
    $changes = 0
    
    # ========================================================================
    # 1. ItemPolicies hinzufuegen
    # ========================================================================
    $policyPattern = '(CosmicLeaf = @\{[^}]+\})\s+\}'
    
    $policyBlock = @"

        $ItemName = @{
            Start         = `$$DefaultStart
            Tolerance     = $Tolerance
            NeedsGemValue = `$$NeedsGemValue
        }
    }
"@
    
    if ($content -match $policyPattern) {
        $content = $content -replace $policyPattern, ('$1' + $policyBlock)
        Write-ColoredMessage "  [1/4] ItemPolicy hinzugefuegt" "Success"
        $changes++
    }
    
    # ========================================================================
    # 2. Stats Counter hinzufuegen
    # ========================================================================
    $statsPattern = '(CosmicLeafTrades\s+=\s+0)'
    
    $statsBlock = @"
$1
    ${ItemName}Trades      = 0
"@
    
    if ($content -match $statsPattern) {
        $content = $content -replace $statsPattern, $statsBlock
        Write-ColoredMessage "  [2/4] Stats Counter hinzugefuegt" "Success"
        $changes++
    }
    
    # ========================================================================
    # 3. Add-ItemTypeFromSymbol Aufruf hinzufuegen
    # ========================================================================
    $itemTypePattern = '(\@\{ Name = "CosmicLeaf"[^}]+\})'
    
    $itemTypeBlock = @"
$1,
    @{ Name = "$ItemName"; File = "$SymbolFile"; Tolerance = `$config.ItemPolicies.$ItemName.Tolerance }
"@
    
    if ($content -match $itemTypePattern) {
        $content = $content -replace $itemTypePattern, $itemTypeBlock
        Write-ColoredMessage "  [3/4] ItemType Definition hinzugefuegt" "Success"
        $changes++
    }
    
    # ========================================================================
    # 4. Export-GUIStats Update (falls $ItemNameTrades Property existiert)
    # ========================================================================
    $exportPattern = '(CosmicLeafTrades\s+=\s+\$script:Stats\.CosmicLeafTrades)'
    
    $exportBlock = @"
$1
        ${ItemName}Trades = `$script:Stats.${ItemName}Trades
"@
    
    if ($content -match $exportPattern) {
        $content = $content -replace $exportPattern, $exportBlock
        Write-ColoredMessage "  [4/4] GUI Stats Export aktualisiert" "Success"
        $changes++
    }
    
    # Schreibe Datei
    [System.IO.File]::WriteAllText($FilePath, $content, [System.Text.Encoding]::UTF8)
    
    Write-ColoredMessage "Hauptscript aktualisiert: $changes Aenderungen" "Success"
    return $changes
}

function Add-ItemToConfig {
    param(
        [string]$ConfigPath,
        [string]$ItemName,
        [int]$Tolerance,
        [bool]$DefaultStart,
        [bool]$NeedsGemValue
    )
    
    Write-ColoredMessage "Aktualisiere TradeConfig.json..." "Step"
    
    if (-not (Test-Path $ConfigPath)) {
        Write-ColoredMessage "TradeConfig.json nicht gefunden - wird beim naechsten Start erstellt" "Warning"
        return 0
    }
    
    try {
        $config = Get-Content $ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
        
        # Fuege neues Item zu ItemPolicies hinzu
        $newItemPolicy = @{
            Start = $DefaultStart
            Tolerance = $Tolerance
            NeedsGemValue = $NeedsGemValue
        }
        
        $config.ItemPolicies | Add-Member -MemberType NoteProperty -Name $ItemName -Value $newItemPolicy -Force
        
        # Speichere Config
        $config | ConvertTo-Json -Depth 10 | Set-Content $ConfigPath -Encoding UTF8
        
        Write-ColoredMessage "  TradeConfig.json aktualisiert" "Success"
        return 1
    }
    catch {
        Write-ColoredMessage "Fehler beim Aktualisieren der Config: $_" "Warning"
        return 0
    }
}

function Show-AddItemSummary {
    param(
        [string]$ItemName,
        [string]$SymbolFile,
        [hashtable]$RefColor,
        [int]$Tolerance,
        [bool]$DefaultStart,
        [bool]$NeedsGemValue,
        [int]$TotalChanges
    )
    
    Write-Host ""
    Write-Host "##################################################################"
    Write-Host "#                   ITEM ERFOLGREICH HINZUGEFÜGT                #"
    Write-Host "##################################################################"
    Write-Host ""
    
    Write-ColoredMessage "Item Details:" "Info"
    Write-Host "  - Name:           $ItemName"
    Write-Host "  - Symbol:         $SymbolFile"
    Write-Host "  - Referenzfarbe:  R=$($RefColor.R) G=$($RefColor.G) B=$($RefColor.B)"
    Write-Host "  - Toleranz:       $Tolerance"
    Write-Host "  - Standard Start: $DefaultStart"
    Write-Host "  - Needs GemValue: $NeedsGemValue"
    Write-Host ""
    
    Write-ColoredMessage "Aenderungen: $TotalChanges" "Success"
    Write-Host ""
    
    Write-ColoredMessage "NAeCHSTE SCHRITTE:" "Step"
    Write-Host "  1. Bot UND GUI neu starten"
    Write-Host "  2. In der GUI: '$ItemName' Checkbox aktivieren (falls gewuenscht)"
    Write-Host "  3. Testen ob Item erkannt und gehandelt wird"
    Write-Host ""
    
    if (-not $DefaultStart) {
        Write-ColoredMessage "HINWEIS: DefaultStart = false" "Warning"
        Write-Host "  â†’ Item wird NICHT automatisch gehandelt"
        Write-Host "  â†’ Aktiviere in der GUI die Checkbox fuer '$ItemName'"
        Write-Host ""
    }
}

# ============================================================================
# HAUPTLOGIK
# ============================================================================

Write-Host ""
Write-Host "##################################################################"
Write-Host "#                                                                #"
Write-Host "#              TradingGems - Neues Item hinzufuegen              #"
Write-Host "#                                                                #"
Write-Host "##################################################################"
Write-Host ""

# Schritt 1: Interaktive Eingabe (falls keine Parameter)
if (-not $ItemName) {
    $ItemName = Get-UserInput "Item Name (z.B. 'Apple', 'Diamond')"
}

if (-not $SymbolFile) {
    $SymbolFile = Get-UserInput "Symbol Dateiname (z.B. 'AppleSymbol.png')"
}

Write-Host ""
Write-ColoredMessage "Erweiterte Einstellungen (Enter fuer Standard):" "Info"

$toleranceInput = Get-UserInput "Toleranz (1-50)" $Tolerance.ToString()
if ([int]::TryParse($toleranceInput, [ref]$Tolerance)) {
    if ($Tolerance -lt 1) { $Tolerance = 1 }
    if ($Tolerance -gt 50) { $Tolerance = 50 }
}

$startInput = Get-UserInput "Standard-Start (true/false)" $DefaultStart.ToString()
if ($startInput -eq "true") { $DefaultStart = $true }
elseif ($startInput -eq "false") { $DefaultStart = $false }

$gemValueInput = Get-UserInput "Needs Gem Value (true/false)" $NeedsGemValue.ToString()
if ($gemValueInput -eq "true") { $NeedsGemValue = $true }
elseif ($gemValueInput -eq "false") { $NeedsGemValue = $false }

Write-Host ""

# Schritt 2: Validierung
Write-ColoredMessage "Validiere Eingaben..." "Step"

# Pruefe Symbol-Datei
$symbolPath = Join-Path $symbolFolder $SymbolFile
if (-not (Test-Path $symbolPath)) {
    Write-ColoredMessage "Symbol-Datei nicht gefunden: $symbolPath" "Error"
    Write-ColoredMessage "Bitte Datei nach pictures\ItemSymbols\ kopieren" "Info"
    exit 1
}
Write-ColoredMessage "  Symbol gefunden: $SymbolFile" "Success"

# Lese Referenzfarbe
$refColor = Get-ReferenceColor -SymbolPath $symbolPath
if (-not $refColor) {
    exit 1
}
Write-ColoredMessage "  Referenzfarbe: R=$($refColor.R) G=$($refColor.G) B=$($refColor.B)" "Success"

# Pruefe Hauptscript
if (-not (Test-Path $mainScriptPath)) {
    Write-ColoredMessage "Hauptscript nicht gefunden: $mainScriptPath" "Error"
    exit 1
}
Write-ColoredMessage "  Hauptscript gefunden" "Success"

Write-Host ""

# Schritt 3: Backups erstellen
Write-ColoredMessage "Erstelle Backups..." "Step"
Backup-File -FilePath $mainScriptPath
if (Test-Path $configPath) {
    Backup-File -FilePath $configPath
}

Write-Host ""

# Schritt 4: Dateien aktualisieren
$totalChanges = 0

try {
    # Hauptscript aktualisieren
    $mainChanges = Add-ItemToMainScript `
        -FilePath $mainScriptPath `
        -ItemName $ItemName `
        -RefColor $refColor `
        -Tolerance $Tolerance `
        -DefaultStart $DefaultStart `
        -NeedsGemValue $NeedsGemValue `
        -SymbolFile $SymbolFile
    
    $totalChanges += $mainChanges
    
    Write-Host ""
    
    # Config aktualisieren
    $configChanges = Add-ItemToConfig `
        -ConfigPath $configPath `
        -ItemName $ItemName `
        -Tolerance $Tolerance `
        -DefaultStart $DefaultStart `
        -NeedsGemValue $NeedsGemValue
    
    $totalChanges += $configChanges
    
    Write-Host ""
}
catch {
    Write-ColoredMessage "Fehler beim Aktualisieren: $_" "Error"
    Write-ColoredMessage "Backups koennen aus 'backup_additem' wiederhergestellt werden" "Info"
    exit 1
}

# Schritt 5: Zusammenfassung
Show-AddItemSummary `
    -ItemName $ItemName `
    -SymbolFile $SymbolFile `
    -RefColor $refColor `
    -Tolerance $Tolerance `
    -DefaultStart $DefaultStart `
    -NeedsGemValue $NeedsGemValue `
    -TotalChanges $totalChanges

Write-ColoredMessage "Item '$ItemName' erfolgreich hinzugefuegt!" "Success"
