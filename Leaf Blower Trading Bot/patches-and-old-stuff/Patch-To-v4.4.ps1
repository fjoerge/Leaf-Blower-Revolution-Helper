<#
.SYNOPSIS
    TradingGems v4.3 ‚Üí v4.4 Patch Script
    
.DESCRIPTION
    Automatisches Patchen der TradingGems Dateien von Version 4.3 auf 4.4
    
    Fixes:
    1. Active Slots Zaehlung korrigiert
    2. LogMode live-Update aus GUI
    3. Debug-Zeile entfernt
    
.NOTES
    Author: Auto-Patch System
    Date: 21.11.2024
    Version: 4.4
#>

param(
    [switch]$DryRun,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

# ============================================================================
# KONFIGURATION
# ============================================================================

$scriptPath = $PSScriptRoot
$mainScriptFile = Join-Path $scriptPath "TradingGems.v4.3.ps1"
$guiScriptFile = Join-Path $scriptPath "TradingGems-GUI.ps1"

$patchedMainScript = Join-Path $scriptPath "TradingGems.v4.4.ps1"
$patchedGuiScript = Join-Path $scriptPath "TradingGems-GUI.v1.5.ps1"

$backupFolder = Join-Path $scriptPath "backup_v4.3"

# ============================================================================
# HELPER FUNKTIONEN
# ============================================================================

function Write-ColoredMessage {
    param(
        [string]$Message,
        [string]$Type = "Info"
    )
    
    $timestamp = Get-Date -Format "HH:mm:ss"
    
    switch ($Type) {
        "Success" { Write-Host "[$timestamp] + $Message" -ForegroundColor Green }
        "Error"   { Write-Host "[$timestamp] - $Message" -ForegroundColor Red }
        "Warning" { Write-Host "[$timestamp] -† $Message" -ForegroundColor Yellow }
        "Info"    { Write-Host "[$timestamp] o $Message" -ForegroundColor Cyan }
        "Step"    { Write-Host "[$timestamp] - $Message" -ForegroundColor White }
        default   { Write-Host "[$timestamp] $Message" }
    }
}

function Test-Prerequisites {
    Write-ColoredMessage "Pruefe Voraussetzungen..." "Step"
    
    $allOk = $true
    
    # Pruefe ob Hauptscript existiert
    if (-not (Test-Path $mainScriptFile)) {
        Write-ColoredMessage "TradingGems.v4.3.ps1 nicht gefunden!" "Error"
        Write-ColoredMessage "Pfad: $mainScriptFile" "Error"
        $allOk = $false
    } else {
        Write-ColoredMessage "TradingGems.v4.3.ps1 gefunden" "Success"
    }
    
    # Pruefe ob GUI Script existiert
    if (-not (Test-Path $guiScriptFile)) {
        Write-ColoredMessage "TradingGems-GUI.ps1 nicht gefunden!" "Error"
        Write-ColoredMessage "Pfad: $guiScriptFile" "Error"
        $allOk = $false
    } else {
        Write-ColoredMessage "TradingGems-GUI.ps1 gefunden" "Success"
    }
    
    # Pruefe ob v4.4 bereits existiert
    if ((Test-Path $patchedMainScript) -and -not $Force) {
        Write-ColoredMessage "TradingGems.v4.4.ps1 existiert bereits!" "Warning"
        Write-ColoredMessage "Nutze -Force zum √úberschreiben" "Info"
        $allOk = $false
    }
    
    return $allOk
}

function Backup-Files {
    Write-ColoredMessage "Erstelle Backup..." "Step"
    
    if (-not (Test-Path $backupFolder)) {
        New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null
        Write-ColoredMessage "Backup-Ordner erstellt: $backupFolder" "Info"
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    
    # Backup Hauptscript
    $backupMain = Join-Path $backupFolder "TradingGems.v4.3_$timestamp.ps1"
    Copy-Item $mainScriptFile -Destination $backupMain -Force
    Write-ColoredMessage "Backup: $backupMain" "Success"
    
    # Backup GUI Script
    $backupGui = Join-Path $backupFolder "TradingGems-GUI_$timestamp.ps1"
    Copy-Item $guiScriptFile -Destination $backupGui -Force
    Write-ColoredMessage "Backup: $backupGui" "Success"
}

# ============================================================================
# PATCH FUNKTIONEN
# ============================================================================

function Patch-MainScript {
    param([string]$FilePath, [string]$OutputPath)
    
    Write-ColoredMessage "Patche TradingGems Hauptscript..." "Step"
    
    $content = Get-Content $FilePath -Raw -Encoding UTF8
    $patchCount = 0
    
    # ========================================================================
    # PATCH 1: Version in Header aendern
    # ========================================================================
    if ($content -match "Leaf Blower Revolution - Trade Automation Version 4\.2") {
        $content = $content -replace "Leaf Blower Revolution - Trade Automation Version 4\.2", "Leaf Blower Revolution - Trade Automation Version 4.4"
        Write-ColoredMessage "  [1/4] Version Header aktualisiert" "Success"
        $patchCount++
    }
    
    # ========================================================================
    # PATCH 2: Debug-Zeile "Line 1158" entfernen
    # ========================================================================
    # Suche nach: write-host "Line 1158" -ForegroundColor Red
    if ($content -match 'write-host\s+"Line\s+1158"\s+-ForegroundColor\s+Red') {
        $content = $content -replace 'write-host\s+"Line\s+1158"\s+-ForegroundColor\s+Red\r?\n', ''
        Write-ColoredMessage "  [2/4] Debug-Zeile 'Line 1158' entfernt" "Success"
        $patchCount++
    }
    
    # ========================================================================
    # PATCH 3: Active Slots Zaehlung korrigieren - Gem Trade
    # ========================================================================
    # Suche nach dem Block in der Gem-Behandlung:
    #   if ($tradeStarted) {
    #       $activeSlotCount++
    #       $startedThisRound = $true
    $pattern1 = '(?ms)(# Gem Statistik aktualisieren bei erfolgreichem Try-StartTrade.*?if\s+\(\$tradeStarted\)\s+\{)\s+\$activeSlotCount\+\+\s+(\$startedThisRound\s+=\s+\$true)'
    
    if ($content -match $pattern1) {
        $content = $content -replace $pattern1, '$1$2'
        Write-ColoredMessage "  [3/4] Active Slots Fix - Gem Trade Block" "Success"
        $patchCount++
    } else {
        Write-ColoredMessage "  [3/4] WARNUNG: Gem Trade Block Pattern nicht gefunden!" "Warning"
    }
    
    # ========================================================================
    # PATCH 4: Active Slots Zaehlung korrigieren - Item Trade
    # ========================================================================
    # aehnlicher Block fuer andere Items:
    #   if ($tradeStarted) {
    #       $activeSlotCount++
    #       $startedThisRound = $true
    #       # Item-spezifischen Trade-Zaehler erhˆhen
    $pattern2 = '(?ms)(# Item-spezifischen Trade-Zaehler erhˆhen.*?if\s+\(\$tradeStarted\)\s+\{)\s+\$activeSlotCount\+\+\s+(\$startedThisRound\s+=\s+\$true)'
    
    if ($content -match $pattern2) {
        $content = $content -replace $pattern2, '$1$2'
        Write-ColoredMessage "  [4/4] Active Slots Fix - Item Trade Block" "Success"
        $patchCount++
    } else {
        # Alternative: Suche ohne vorherigen Kommentar
        $pattern2alt = '(?ms)(if\s+\(\$tradeStarted\)\s+\{\s+)\$activeSlotCount\+\+(\s+\$startedThisRound\s+=\s+\$true\s+# Item-spezifischen Trade-Zaehler)'
        
        if ($content -match $pattern2alt) {
            $content = $content -replace $pattern2alt, '$1$2'
            Write-ColoredMessage "  [4/4] Active Slots Fix - Item Trade Block (Alt)" "Success"
            $patchCount++
        } else {
            Write-ColoredMessage "  [4/4] WARNUNG: Item Trade Block Pattern nicht gefunden!" "Warning"
        }
    }
    
    # ========================================================================
    # PATCH 5: LogMode in Load-GUIConfig hinzufuegen
    # ========================================================================
    # Suche nach der Stelle wo RefreshIntervalRowsFull geladen wird
    # und fuege LogMode darunter ein
    $pattern3 = '(?ms)(if\s+\(\$guiConfig\.RefreshIntervalRowsFull.*?\$configChanged\s+=\s+\$true\s+\})'
    
    if ($content -match $pattern3) {
        $logModeCode = @'

        # LogMode updaten (NEU in v4.4)
        if ($guiConfig.LogMode -and $guiConfig.LogMode -ne $config.LogMode) {
            $config.LogMode = $guiConfig.LogMode
            $configChanged = $true
        }
'@
        $content = $content -replace $pattern3, ('$1' + $logModeCode)
        Write-ColoredMessage "  [5/4] LogMode Live-Update hinzugefuegt" "Success"
        $patchCount++
    } else {
        Write-ColoredMessage "  [5/4] WARNUNG: Load-GUIConfig Pattern nicht gefunden!" "Warning"
    }
    
    # Schreibe gepatchte Datei
    if (-not $DryRun) {
        [System.IO.File]::WriteAllText($OutputPath, $content, [System.Text.Encoding]::UTF8)
    }
    
    Write-ColoredMessage "Hauptscript gepatcht: $patchCount aenderungen" "Success"
    return $patchCount
}

function Patch-GuiScript {
    param([string]$FilePath, [string]$OutputPath)
    
    Write-ColoredMessage "Patche GUI Script..." "Step"
    
    $content = Get-Content $FilePath -Raw -Encoding UTF8
    $patchCount = 0
    
    # ========================================================================
    # GUI PATCH 1: Version in Kommentar aendern
    # ========================================================================
    if ($content -match "# TradingGems GUI Controller v1\.4") {
        $content = $content -replace "# TradingGems GUI Controller v1\.4", "# TradingGems GUI Controller v1.5"
        Write-ColoredMessage "  [1/3] GUI Version aktualisiert" "Success"
        $patchCount++
    }
    
    # ========================================================================
    # GUI PATCH 2: Activity Log Toggle - CheckBox zur Control-Liste
    # ========================================================================
    # Finde die Control-Liste und fuege chkShowActivityLog hinzu
    $pattern1 = "('txtSlotUtilPerHour')"
    
    if ($content -match $pattern1) {
        $content = $content -replace $pattern1, '$1,' + "`n'chkShowActivityLog'"
        Write-ColoredMessage "  [2/3] CheckBox 'chkShowActivityLog' hinzugefuegt" "Success"
        $patchCount++
    }
    
    # ========================================================================
    # GUI PATCH 3: Activity Log Toggle - Event Handler
    # ========================================================================
    # Fuege Event Handler nach den Auto-Save ComboBox Handlern ein
    $pattern2 = "(@\('cmbLogMode','cmbScreenshotMode'\).*?Add_SelectionChanged.*?\})"
    
    if ($content -match $pattern2) {
        $toggleCode = @'

# Activity Log Toggle (NEU in v4.4)
$controls['chkShowActivityLog'].Add_Checked({
    $logRow = $window.FindName('LogRow')
    if ($logRow) {
        $logRow.Height = [Double]::NaN  # Auto
        Write-GuiLog "Activity Log eingeblendet" "Cyan"
    }
})

$controls['chkShowActivityLog'].Add_Unchecked({
    $logRow = $window.FindName('LogRow')
    if ($logRow) {
        $logRow.Height = 0
        Write-GuiLog "Activity Log ausgeblendet" "Cyan"
    }
})
'@
        $content = $content -replace $pattern2, ('$1' + $toggleCode)
        Write-ColoredMessage "  [3/3] Activity Log Toggle Event Handler hinzugefuegt" "Success"
        $patchCount++
    }
    
    # Schreibe gepatchte Datei
    if (-not $DryRun) {
        [System.IO.File]::WriteAllText($OutputPath, $content, [System.Text.Encoding]::UTF8)
    }
    
    Write-ColoredMessage "GUI Script gepatcht: $patchCount aenderungen" "Success"
    return $patchCount
}

# ============================================================================
# HAUPTLOGIK
# ============================================================================

Write-Host ""
Write-Host "##ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ó"
Write-Host "#ë                                                                #ë"
Write-Host "#ë           TradingGems v4.3 ‚Üí v4.4 Patch Script                #ë"
Write-Host "#ë                                                                #ë"
Write-Host "#ö#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ù"
Write-Host ""

if ($DryRun) {
    Write-ColoredMessage "DRY RUN Modus - Es werden keine Dateien veraendert!" "Warning"
    Write-Host ""
}

# Schritt 1: Voraussetzungen pruefen
if (-not (Test-Prerequisites)) {
    Write-ColoredMessage "Voraussetzungen nicht erfuellt. Abbruch." "Error"
    exit 1
}

Write-Host ""

# Schritt 2: Backup erstellen
if (-not $DryRun) {
    try {
        Backup-Files
    }
    catch {
        Write-ColoredMessage "Fehler beim Backup: $_" "Error"
        exit 1
    }
}

Write-Host ""

# Schritt 3: Hauptscript patchen
try {
    $mainPatches = Patch-MainScript -FilePath $mainScriptFile -OutputPath $patchedMainScript
}
catch {
    Write-ColoredMessage "Fehler beim Patchen des Hauptscripts: $_" "Error"
    Write-ColoredMessage $_.ScriptStackTrace "Error"
    exit 1
}

Write-Host ""

# Schritt 4: GUI Script patchen
try {
    $guiPatches = Patch-GuiScript -FilePath $guiScriptFile -OutputPath $patchedGuiScript
}
catch {
    Write-ColoredMessage "Fehler beim Patchen des GUI Scripts: $_" "Error"
    Write-ColoredMessage $_.ScriptStackTrace "Error"
    exit 1
}

Write-Host ""

# ============================================================================
# ZUSAMMENFASSUNG
# ============================================================================

Write-Host "##ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ó"
Write-Host "#ë                     PATCH ABGESCHLOSSEN                        #ë"
Write-Host "#ö#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ê#ù"
Write-Host ""

Write-ColoredMessage "Hauptscript: $mainPatches Patches angewendet" "Success"
Write-ColoredMessage "GUI Script: $guiPatches Patches angewendet" "Success"
Write-Host ""

if (-not $DryRun) {
    Write-ColoredMessage "Neue Dateien erstellt:" "Info"
    Write-ColoredMessage "  ‚Ä¢ $patchedMainScript" "Info"
    Write-ColoredMessage "  ‚Ä¢ $patchedGuiScript" "Info"
    Write-Host ""
    Write-ColoredMessage "Backups gespeichert in: $backupFolder" "Info"
    Write-Host ""
    
    Write-ColoredMessage "NaeCHSTE SCHRITTE:" "Step"
    Write-Host "  1. Start-TradingGems.ps1 bearbeiten:"
    Write-Host "     aendere 'TradingGems.v4.3.ps1' ‚Üí 'TradingGems.v4.4.ps1'"
    Write-Host ""
    Write-Host "  2. Bot + GUI neu starten:"
    Write-Host "     .\START_HERE.bat"
    Write-Host ""
    Write-Host "  3. Fixes testen (siehe VERSION_4.4_CHANGELOG.md)"
    Write-Host ""
}

Write-Host ""
Write-ColoredMessage "Patch erfolgreich abgeschlossen!" "Success"
