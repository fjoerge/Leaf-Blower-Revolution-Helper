# GUI-Integration Patch - AUTOMATISCHE INSTALLATION v2
# UTF-8 kompatibel - Fügt GUI-Integration in TradingGems.v4.2.ps1 ein

$scriptPath = $PSScriptRoot
$botScript = Join-Path $scriptPath "TradingGems.v4.2.ps1"
$botBackup = Join-Path $scriptPath "TradingGems.v4.2.ps1.backup"

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   GUI-Integration Auto-Installer v2" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $botScript)) {
    Write-Host "[ERROR] Bot-Script nicht gefunden!" -ForegroundColor Red
    Read-Host "Druecke Enter zum Beenden"
    exit 1
}

# Backup erstellen
if (-not (Test-Path $botBackup)) {
    Write-Host "[1/4] Erstelle Backup..." -ForegroundColor Yellow
    Copy-Item $botScript $botBackup -Force
    Write-Host "       Backup erstellt: $botBackup" -ForegroundColor Green
}
else {
    Write-Host "[1/4] Backup existiert bereits" -ForegroundColor Gray
}

# Bot-Script laden mit UTF-8-BOM Support
Write-Host "[2/4] Lade Bot-Script..." -ForegroundColor Yellow
$botContent = Get-Content $botScript -Raw -Encoding UTF8

# Prüfe ob bereits gepatched
if ($botContent -match "GUI-INTEGRATION PATCH") {
    Write-Host "[INFO] Bot ist bereits gepatched!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Keine Aenderungen noetig." -ForegroundColor Cyan
    Read-Host "Druecke Enter zum Beenden"
    exit 0
}

Write-Host "[3/4] Fuege GUI-Integration ein..." -ForegroundColor Yellow

# Patch-Code (kompakt)
$patchCode = @'

# =============================================================================
# GUI-INTEGRATION PATCH v2.0
# =============================================================================
$script:guiStatsFile = Join-Path $PSScriptRoot "TradeStats.json"
$script:guiConfigFile = Join-Path $PSScriptRoot "TradeConfig.json"
$script:lastConfigCheck = [DateTime]::MinValue
$script:statsCounter = 0
$script:botIsRunning = $false

function Load-GUIConfig {
    if (Test-Path $script:guiConfigFile) {
        try {
            $guiConfig = Get-Content $script:guiConfigFile -Raw -Encoding UTF8 | ConvertFrom-Json
            foreach ($item in @('Gem', 'Beer', 'Mulch', 'Cheese', 'GoldLeaf', 'CosmicLeaf')) {
                if ($guiConfig.ItemPolicies.$item) {
                    $ItemPolicies[$item].Start = $guiConfig.ItemPolicies.$item.Start
                    if ($item -eq 'Gem' -and $guiConfig.ItemPolicies.Gem.MinValue) {
                        $ItemPolicies.Gem.MinValue = $guiConfig.ItemPolicies.Gem.MinValue
                    }
                }
            }
            if ($guiConfig.CollectIntervalSeconds) { $config.CollectIntervalSeconds = $guiConfig.CollectIntervalSeconds }
            if ($guiConfig.MaxTrades) { $config.MaxTrades = $guiConfig.MaxTrades }
            if ($guiConfig.RefreshIntervalRowsFull) { $config.RefreshIntervalRowsFull = $guiConfig.RefreshIntervalRowsFull }
            Write-Log "GUI-Config geladen und uebernommen" "INFO"
        } catch { }
    }
}

function Export-GUIStats {
    $statsExport = @{
        StartedTrades = $script:Stats.StartedTrades
        RefreshCount = $script:Stats.RefreshCount
        GemTrades = $script:Stats.GemTrades
        BeerTrades = $script:Stats.BeerTrades
        MulchTrades = $script:Stats.MulchTrades
        CheeseTrades = $script:Stats.CheeseTrades
        GoldLeafTrades = $script:Stats.GoldLeafTrades
        CosmicLeafTrades = $script:Stats.CosmicLeafTrades
        GemsTotal = $script:Stats.GemsTotal
        GemValue1Count = $script:Stats.GemValue1Count
        GemValue2Count = $script:Stats.GemValue2Count
        GemValue3Count = $script:Stats.GemValue3Count
        GemValue4Count = $script:Stats.GemValue4Count
        GemValue5Count = $script:Stats.GemValue5Count
        GemValue6Count = $script:Stats.GemValue6Count
        SuccessfulStarts = $script:Stats.SuccessfulStarts
        FailedStarts = $script:Stats.FailedStarts
        StartAttempts = $script:Stats.StartAttempts
        LastActiveSlots = $script:Stats.LastActiveSlots
        ScriptStartTime = $script:Stats.ScriptStartTime.ToString("o")
        IsRunning = $script:botIsRunning
    }
    try {
        $statsExport | ConvertTo-Json -Depth 10 | Set-Content $script:guiStatsFile -Encoding UTF8 -Force
    } catch { }
}

function Update-GUIIntegration {
    param([bool]$IsRunning = $false)
    $script:botIsRunning = $IsRunning
    $script:statsCounter++
    if ($script:statsCounter -ge 3) {
        Export-GUIStats
        $script:statsCounter = 0
    }
    if (((Get-Date) - $script:lastConfigCheck).TotalSeconds -gt 5) {
        if (Test-Path $script:guiConfigFile) {
            $fileInfo = Get-Item $script:guiConfigFile
            if ($fileInfo.LastWriteTime -gt $script:lastConfigCheck) {
                Load-GUIConfig
            }
        }
        $script:lastConfigCheck = Get-Date
    }
}
# =============================================================================

'@

# Finde $script:StatsTopRow = $null und füge DAVOR ein
$insertMarker = '$script:StatsTopRow = $null'
$insertPos = $botContent.IndexOf($insertMarker)

if ($insertPos -lt 0) {
    Write-Host "[ERROR] Konnte Einfuegepunkt nicht finden!" -ForegroundColor Red
    Write-Host "        Suche nach: $insertMarker" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Dein Bot ist moeglicherweise eine andere Version." -ForegroundColor Yellow
    Write-Host "Bitte kontaktiere Support." -ForegroundColor Yellow
    Read-Host "Druecke Enter zum Beenden"
    exit 1
}

# Füge VOR der Zeile ein
$botContent = $botContent.Insert($insertPos, $patchCode + "`r`n")
Write-Host "       GUI-Functions eingefuegt" -ForegroundColor Green

# Jetzt finde die While-Schleife und füge den Hook ein
# Suche nach: while ($true) {
$whilePos = $botContent.IndexOf('while ($true) {')
if ($whilePos -gt 0) {
    # Suche das Ende der While-Schleife (vor dem letzten Start-Sleep)
    # Finde alle Start-Sleep Positionen nach while
    $searchStart = $whilePos
    $lastSleepPos = -1
    
    while ($true) {
        $sleepPos = $botContent.IndexOf('Start-Sleep', $searchStart)
        if ($sleepPos -lt 0) { break }
        $lastSleepPos = $sleepPos
        $searchStart = $sleepPos + 1
    }
    
    if ($lastSleepPos -gt 0) {
        # Füge VOR dem letzten Start-Sleep ein
        $hookCode = "`r`n        # GUI Integration Hook`r`n        Update-GUIIntegration -IsRunning `$true`r`n`r`n        "
        $botContent = $botContent.Insert($lastSleepPos, $hookCode)
        Write-Host "       GUI-Update Hook in Hauptschleife eingefuegt" -ForegroundColor Green
    }
}

# Füge auch einen Hook für den Pause-Zustand ein (wenn isRunning false ist)
# Suche nach Wait-Event Pattern
if ($botContent -match 'Wait-Event') {
    $waitPos = $botContent.IndexOf('Wait-Event')
    if ($waitPos -gt 0) {
        # Füge nach Wait-Event ein
        $nextLinePos = $botContent.IndexOf("`n", $waitPos) + 1
        $pauseHook = "        Update-GUIIntegration -IsRunning `$false`r`n"
        $botContent = $botContent.Insert($nextLinePos, $pauseHook)
        Write-Host "       GUI-Update Hook fuer Pause-Status eingefuegt" -ForegroundColor Green
    }
}

Write-Host "[4/4] Speichere gepatchten Bot..." -ForegroundColor Yellow
$botContent | Set-Content $botScript -Encoding UTF8 -Force

Write-Host ""
Write-Host "================================================" -ForegroundColor Green
Write-Host "   Installation erfolgreich!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Der Bot schreibt jetzt:" -ForegroundColor Cyan
Write-Host "  - Stats nach TradeStats.json (alle ~1.5 Sek)" -ForegroundColor White
Write-Host "  - Liest Config aus TradeConfig.json (alle 5 Sek)" -ForegroundColor White
Write-Host "  - Config wird LIVE uebernommen!" -ForegroundColor Yellow
Write-Host ""
Write-Host "Naechster Schritt:" -ForegroundColor Cyan
Write-Host "  1. START_HERE.bat ausfuehren" -ForegroundColor White
Write-Host "  2. F8 druecken zum Starten" -ForegroundColor White
Write-Host "  3. GUI zeigt Live-Stats!" -ForegroundColor Green
Write-Host ""
Write-Host "Backup gespeichert:" -ForegroundColor Gray
Write-Host "  $botBackup" -ForegroundColor Gray
Write-Host ""

Read-Host "Druecke Enter zum Beenden"
