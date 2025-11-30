# =============================================================================
# GUI-INTEGRATION PATCH fÃ¼r TradingGems.v4.2.ps1
# =============================================================================
# 
# INSTALLATION:
# 1. Ã–ffne TradingGems.v4.2.ps1
# 2. Suche nach der Zeile: $script:isRunning = $false
# 3. FÃ¼ge DIREKT DARUNTER diesen kompletten Block ein
# 4. Speichern & Fertig!
#
# Was dieser Patch macht:
# - Schreibt Stats in TradeStats.json (fÃ¼r GUI)
# - Liest Config aus TradeConfig.json (von GUI)
# - Synchronisiert Start/Stop Status
# =============================================================================

# --- GUI Integration: Pfade ---
$script:guiStatsFile = Join-Path $PSScriptRoot "TradeStats.json"
$script:guiConfigFile = Join-Path $PSScriptRoot "TradeConfig.json"
$script:guiStateFile = Join-Path $PSScriptRoot "TradeState.json"
$script:lastConfigCheck = [DateTime]::MinValue
$script:statsCounter = 0

# --- GUI Integration: Config laden ---
function Load-GUIConfig {
    if (Test-Path $script:guiConfigFile) {
        try {
            $guiConfig = Get-Content $script:guiConfigFile -Raw -Encoding UTF8 | ConvertFrom-Json
            
            # ItemPolicies Ã¼berschreiben
            foreach ($item in @('Gem', 'Beer', 'Mulch', 'Cheese', 'GoldLeaf', 'CosmicLeaf')) {
                if ($guiConfig.ItemPolicies.$item) {
                    $ItemPolicies[$item].Start = $guiConfig.ItemPolicies.$item.Start
                    if ($item -eq 'Gem' -and $guiConfig.ItemPolicies.Gem.MinValue) {
                        $ItemPolicies.Gem.MinValue = $guiConfig.ItemPolicies.Gem.MinValue
                    }
                }
            }
            
            # Andere Settings
            if ($guiConfig.CollectIntervalSeconds) {
                $config.CollectIntervalSeconds = $guiConfig.CollectIntervalSeconds
            }
            if ($guiConfig.MaxTrades) {
                $config.MaxTrades = $guiConfig.MaxTrades
            }
            if ($guiConfig.RefreshIntervalRowsFull) {
                $config.RefreshIntervalRowsFull = $guiConfig.RefreshIntervalRowsFull
            }
            
            Write-Log "GUI-Config geladen und Ã¼bernommen" "INFO"
            return $true
        }
        catch {
            Write-Log "Fehler beim Laden der GUI-Config: $_" "DEBUG"
            return $false
        }
    }
    return $false
}

# --- GUI Integration: Stats exportieren ---
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
        IsRunning = $script:isRunning
    }
    
    try {
        $statsExport | ConvertTo-Json -Depth 10 | Set-Content $script:guiStatsFile -Encoding UTF8 -Force
    }
    catch {
        # Ignore errors
    }
}

# --- GUI Integration: Status synchronisieren ---
function Sync-GUIState {
    try {
        $state = @{
            IsRunning = $script:isRunning
            LastUpdate = (Get-Date).ToString("o")
        }
        $state | ConvertTo-Json | Set-Content $script:guiStateFile -Encoding UTF8 -Force
    }
    catch {
        # Ignore
    }
}

# --- GUI Integration: In Hauptschleife einbauen ---
# Diese Funktion wird in der While-Schleife aufgerufen
function Update-GUIIntegration {
    $script:statsCounter++
    
    # Stats alle 5 Iterationen exportieren
    if ($script:statsCounter -ge 5) {
        Export-GUIStats
        Sync-GUIState
        $script:statsCounter = 0
    }
    
    # Config alle 10 Sekunden prÃ¼fen
    if (((Get-Date) - $script:lastConfigCheck).TotalSeconds -gt 10) {
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
# ENDE GUI-INTEGRATION PATCH
# =============================================================================
# 
# NÃ„CHSTER SCHRITT:
# Suche nach deiner Hauptschleife:
#   while ($true) {
#       ...
#       Start-Sleep -Milliseconds ...
#   }
#
# FÃ¼ge VOR dem "Start-Sleep" diese Zeile ein:
#   Update-GUIIntegration
#
# FERTIG! Der Bot schreibt jetzt Stats fÃ¼r die GUI!
# =============================================================================
