<#
Leaf Blower Revolution - Trade Automation Version 4.4
#>

Add-Type -AssemblyName System.Drawing

# --- Win32: Fenstergeometrie fuer game.exe ------------------------------------
# Liest die Außenmaße des game.exe-Fensters (fuer fensterrelative Koordinaten).

if (-not ('Win32Window' -as [type])) {
    Add-Type @"
using System;
using System.Runtime.InteropServices;

public static class Win32Window {
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
}

<#
    Holt die Fenstergeometrie von game.exe ueber Win32Window.GetWindowRect.
    Rueckgabe:
    - Win32Window.RECT bei Erfolg
    - $null, wenn kein gueltiges game.exe-Fenster gefunden wird
#>
function Get-GameWindowRect {
    # Liefert RECT fuer das game.exe-Hauptfenster oder $null, wenn nicht gefunden.
    $gameProcess = Get-Process -Name "game" -ErrorAction SilentlyContinue
    if (-not $gameProcess -or -not $gameProcess.MainWindowHandle -or $gameProcess.MainWindowHandle -eq [IntPtr]::Zero) {
        return $null
    }

    $gameWindowRect = New-Object Win32Window+RECT
    [Win32Window]::GetWindowRect($gameProcess.MainWindowHandle, [ref]$gameWindowRect) | Out-Null
    return $gameWindowRect
}

# --- Global Hotkeys (F8/F9) via user32.dll -----------------------------------
# Registriert F8/F9 global und verarbeitet WM_HOTKEY mittels PeekMessage.

if (-not ('HotKey' -as [type])) {
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public static class HotKey {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool RegisterHotKey(IntPtr hWnd, int id, uint fsModifiers, uint vk);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool UnregisterHotKey(IntPtr hWnd, int id);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool PeekMessage(out MSG lpMsg, IntPtr hWnd,
        uint wMsgFilterMin, uint wMsgFilterMax, uint wRemoveMsg);

    public const int WM_HOTKEY  = 0x0312;
    public const uint MOD_NONE  = 0x0000;
    public const uint VK_F8     = 0x77;
    public const uint VK_F9     = 0x78;
    public const uint PM_REMOVE = 0x0001;

    public struct MSG {
        public IntPtr hWnd;
        public uint message;
        public IntPtr wParam;
        public IntPtr lParam;
        public uint time;
        public int pt_x;
        public int pt_y;
    }
}
"@
}

# --- Zentrale Konfiguration ---------------------------------------------------

$basePath = $PSScriptRoot
. "$PSScriptRoot\ocr\GemValueOCR.ps1"

$config = [pscustomobject]@{
    # --- Basis / Pfade ------------------------------------------------------
    BasePath        = $basePath
    SymbolFolder    = Join-Path $basePath "pictures\ItemSymbols"
    SingleClickExe  = Join-Path $basePath "ahk\SingleClick.exe"
    DoubleClickExe  = Join-Path $basePath "ahk\DoubleClick.exe"

    # --- Manuelle Tuning-Parameter -----------------------------------------
    LogMode                = "STATS"

    CollectIntervalSeconds  = 15
    RefreshIntervalRowsFull = 5
    MaxTrades           = 9
    MinGemValueToStart     = 2
    GetGemNumberSampleMode = 0
    StatsGemScreenshotMode = "UNKNOWN" #ALL / UNKNOWN / OFF

    # --- Item-Policies: steuern, welche Items getradet werden --------------
    ItemPolicies = @{
        Gem = @{
            Start         = $false
            Tolerance     = 20
            NeedsGemValue = $true
            MinValue      = 1
        }

        Beer = @{
            Start         = $false
            Tolerance     = 15
            NeedsGemValue = $false
        }

        Mulch = @{
            Start         = $false
            Tolerance     = 10
            NeedsGemValue = $false
        }

        Cheese = @{
            Start         = $false
            Tolerance     = 10
            NeedsGemValue = $false
        }
        
        GoldLeaf = @{
            Start         = $false  # zentrales Ausschluss-Flag
            Tolerance     = 15      # Startwert, bei Bedarf nachjustieren
            NeedsGemValue = $false
        }

        CosmicLeaf = @{
            Start         = $false  # zentrales Ausschluss-Flag
            Tolerance     = 8      # Startwert, bei Bedarf nachjustieren
            NeedsGemValue = $false
        }
        Borb = @{
            Start         = $False
            Tolerance     = 15
            NeedsGemValue = $False
        }
    }

    # Erkennung / Toleranzen
    Tolerance              = 20
    MinRedPixelsForRunning = 4
    GemValueRelConfFactor  = 0.85
    #GemValueAbsConfMin     = 2
    #GemValueMargin3        = 4
    #GemValueAlignShiftX    = 0 # Verschiebt Zahlen der Gems aus der Maske, besser nicht nehmen, weil viele Fehler dann -.-
    #GemMaskCompareMaxAllowedScore = 30

    #MinScoreGap            = 1 #4 alt
    MinBrightPixels        = 5 #5 alt

    StartCheckOffsetX      = -5
    StartCheckOffsetY      =  0
    StartEnabledColor      = @{ R = 247; G = 236; B = 202 }
    StartEnabledTolerance  = 45  # Erkennungswert für StartButtonCheck -> 0-45 weiß (=startbar), ~70-200 = grau(=NICHT startbar) 
	ratioThreshold         = 0.4   # 40% der Pixel muessen innerhalb der Toleranz liegen
    minDistOverride        = 10.0  # Wenn ein Pixel < 10 Distanz hat, gilt der Button als aktiv
	
    AutoCalibEnabled       = $true
    AutoCalibMinAttempts   = 3
    AutoCalibMinFailRate   = 0.2
    AutoCalibSearchRange   = 40
    AutoCalibStep          = 2

    BaseWindowWidth      = 1280
    BaseWindowHeight     = 720
    WindowSizeTolerance  = 0.03
    EnableGemStats       = $true

    PostCollectDelayMs           = 1
	PostRefreshDelayMs			 = 5
    MultipleHitsWaitMilliseconds = 1
    VerifyStartDelayMs           = 5
    StatsUpdateIntervalSeconds   = 1

    SearchLeftRel   = 0.4773
    SearchTopRel    = 0.2986
    SearchRightRel  = 0.4992
    SearchBottomRel = 0.7528

    StartClickXRel = 0.8094

    CollectXRel = 0.8055
    CollectYRel = 0.8028

    RefreshXRel = 0.2320
    RefreshYRel = 0.8028

    ProgressCenterXRel = 0.6930

    StartYOffset   = 10
    StartOffsetRel = 0.0136

    # Gem Value Box + Offset
    GemValueOffsetX      = 12
    GemValueOffsetY      = -11
    GemValueBoxWidth     = 28
    GemValueBoxHeight    = 20

    # --- Beer-Value: kurzer vs. langer Wert -------------------------------
    BeerValueOffsetX      = 25    # Startwert: wie Gem
    BeerValueOffsetY      = -7
    BeerValueBoxWidth     = 32
    BeerValueBoxHeight    = 32
    BeerMinActiveColumns  = 5     # ab wie vielen Spalten "lange Zahl"

    RowStep          = 40
    ProgressHalfWidth = 40
    ProgressHeight    = 5
}

# --- Statistik-Objekt --------------------------------------------------------

$stats = [pscustomobject]@{
    StartedTrades      = 0
    RefreshCount       = 0
    LoopCount          = 0
    LastActiveSlots    = 0
    LastGemRows        = 0
    ActiveSlotsSum     = 0
    ScriptStartTime    = Get-Date
    LastResumeTime     = $null
    LastStatsWrite     = Get-Date

    StartAttempts      = 0
    SuccessfulStarts   = 0
    FailedStarts       = 0

    LastCollectTime    = (Get-Date).AddSeconds(-5)

    AutoCalibCalls     = 0
    AutoCalibSuccess   = 0

    GemsTotal          = 0
    GemTrades          = 0
    GemValue1Count     = 0
    GemValue2Count     = 0
    GemValue3Count     = 0
    GemValue4Count     = 0
    GemValue5Count     = 0
    GemValue6Count     = 0
    GemValue7Count     = 0
    GemValue8Count     = 0
    GemValue9Count     = 0
    GemValue10Count     = 0
    GemValue11Count     = 0
    GemValue12Count     = 0
    GemValue13Count     = 0
    GemValue14Count     = 0
    GemValue15Count     = 0
    GemValue16Count     = 0
    GemValue17Count     = 0
    GemValue18Count     = 0
    GemValue19Count     = 0
    GemValue20Count     = 0

    # neue Item-spezifische Trade-Zaehler
    BeerTrades         = 0
    MulchTrades        = 0
    CheeseTrades       = 0
    BorbTrades         = 0
    GoldLeafTrades     = 0

    avgGemsPerHourStr  = 0
    avgGemsPerTradeStr = 0
	slotUtilPerHour    = 0.0
}

# --- Logging -----------------------------------------------------------------

<#
    Zentrale Logging-Funktion mit drei Modi:
    - DEBUG: alle Logs
    - INFO : nur INFO
    - STATS: nur ausgewaehlte Status-/Start/Stop-Meldungen
    Spezielle Level:
    - HINT wird immer gruen ausgegeben
#>
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )

    # HINT-Logs werden immer ausgegeben
    if ($Level -eq "HINT") {
        $timestamp = (Get-Date).ToString("HH:mm:ss")
        Write-Host ("[{0}] [INFO] {1}" -f $timestamp, $Message) -ForegroundColor Green
        return
    }

    switch ($config.LogMode) {
        "DEBUG" {
            $timestamp = (Get-Date).ToString("HH:mm:ss")
            Write-Host ("[{0}] [{1}] {2}" -f $timestamp, $Level, $Message) -ForegroundColor White
        }
        "INFO" {
            if ($Level -ne "INFO") { return }
            $timestamp = (Get-Date).ToString("HH:mm:ss")
            Write-Host ("[{0}] [INFO] {1}" -f $timestamp, $Message) -ForegroundColor White
        }
        "STATS" {
            if ($Level -eq "INFO" -and ($Message -like "*Automation gestartet*" -or
                                        $Message -like "*Automation pausiert*"  -or
                                        $Message -like "*Script per F9 beendet*")) {
                $timestamp = (Get-Date).ToString("HH:mm:ss")
                Write-Host ("[{0}] [INFO] {1}" -f $timestamp, $Message) -ForegroundColor Green
            }
        }
    }
}

# =============================================================================
# GUI-INTEGRATION PATCH v2.0
# =============================================================================
# --- GUI Integration Start ---
$script:guiStatsFile = Join-Path $PSScriptRoot "TradeStats.json"
$script:guiConfigFile = Join-Path $PSScriptRoot "TradeConfig.json"
$script:lastConfigCheck = [DateTime]::MinValue
$script:statsExportCounter = 0

function Export-GUIStats {
    param([bool]$BotIsRunning = $false)
    
    $statsData = @{
        StartedTrades = $script:Stats.StartedTrades
        RefreshCount = $script:Stats.RefreshCount
        GemTrades = $script:Stats.GemTrades
        BeerTrades = $script:Stats.BeerTrades
        MulchTrades = $script:Stats.MulchTrades
        CheeseTrades = $script:Stats.CheeseTrades
        GoldLeafTrades = $script:Stats.GoldLeafTrades
        BorbTrades = $script:Stats.BorbTrades
		
        GemsTotal = $script:Stats.GemsTotal
        GemValue1Count = $script:Stats.GemValue1Count
        GemValue2Count = $script:Stats.GemValue2Count
        GemValue3Count = $script:Stats.GemValue3Count
        GemValue4Count = $script:Stats.GemValue4Count
        GemValue5Count = $script:Stats.GemValue5Count
        GemValue6Count = $script:Stats.GemValue6Count
        GemValue7Count = $script:Stats.GemValue7Count
        GemValue8Count = $script:Stats.GemValue8Count
        GemValue9Count = $script:Stats.GemValue9Count
        GemValue10Count = $script:Stats.GemValue10Count
        GemValue11Count = $script:Stats.GemValue11Count
        GemValue12Count = $script:Stats.GemValue12Count
        GemValue13Count = $script:Stats.GemValue13Count
        GemValue14Count = $script:Stats.GemValue14Count
        GemValue15Count = $script:Stats.GemValue15Count
        GemValue16Count = $script:Stats.GemValue16Count
        GemValue17Count = $script:Stats.GemValue17Count
        GemValue18Count = $script:Stats.GemValue18Count
        GemValue19Count = $script:Stats.GemValue19Count
        GemValue20Count = $script:Stats.GemValue20Count
        SuccessfulStarts = $script:Stats.SuccessfulStarts
        FailedStarts = $script:Stats.FailedStarts
        StartAttempts = $script:Stats.StartAttempts
        LastActiveSlots = $script:Stats.LastActiveSlots
		SlotUtilPerHour        = $script:Stats.slotUtilPerHour
        ScriptStartTime = $script:Stats.ScriptStartTime.ToString("o")
        IsRunning = $BotIsRunning
    }
    
    try {
        $json = $statsData | ConvertTo-Json -Depth 10
        [System.IO.File]::WriteAllText($script:guiStatsFile, $json, [System.Text.Encoding]::UTF8)
    }
    catch {
        # Fehler ignorieren
    }
}

function Load-GUIConfig {
    if (-not (Test-Path $script:guiConfigFile)) {
        return
    }
    
    try {
        $guiConfig = Get-Content $script:guiConfigFile -Raw -Encoding UTF8 | ConvertFrom-Json
        
        $configChanged = $false
        
        # ItemPolicies updaten (nur wenn sich Werte geaendert haben)
        if ($guiConfig.ItemPolicies.Gem.Start -ne $config.ItemPolicies.Gem.Start) {
            $config.ItemPolicies.Gem.Start = $guiConfig.ItemPolicies.Gem.Start
            $configChanged = $true
        }
        if ($guiConfig.ItemPolicies.Gem.MinValue -ne $config.ItemPolicies.Gem.MinValue) {
            $config.ItemPolicies.Gem.MinValue = $guiConfig.ItemPolicies.Gem.MinValue
            $configChanged = $true
        }
        
        if ($guiConfig.ItemPolicies.Beer.Start -ne $config.ItemPolicies.Beer.Start) {
            $config.ItemPolicies.Beer.Start = $guiConfig.ItemPolicies.Beer.Start
            $configChanged = $true
        }
        if ($guiConfig.ItemPolicies.Borb.Start -ne $config.ItemPolicies.Borb.Start) {
            $config.ItemPolicies.Borb.Start = $guiConfig.ItemPolicies.Borb.Start
            $configChanged = $true
        }
        if ($guiConfig.ItemPolicies.Mulch.Start -ne $config.ItemPolicies.Mulch.Start) {
            $config.ItemPolicies.Mulch.Start = $guiConfig.ItemPolicies.Mulch.Start
            $configChanged = $true
        }
        if ($guiConfig.ItemPolicies.Cheese.Start -ne $config.ItemPolicies.Cheese.Start) {
            $config.ItemPolicies.Cheese.Start = $guiConfig.ItemPolicies.Cheese.Start
            $configChanged = $true
        }
        if ($guiConfig.ItemPolicies.GoldLeaf.Start -ne $config.ItemPolicies.GoldLeaf.Start) {
            $config.ItemPolicies.GoldLeaf.Start = $guiConfig.ItemPolicies.GoldLeaf.Start
            $configChanged = $true
        }
        if ($guiConfig.ItemPolicies.CosmicLeaf.Start -ne $config.ItemPolicies.CosmicLeaf.Start) {
            $config.ItemPolicies.CosmicLeaf.Start = $guiConfig.ItemPolicies.CosmicLeaf.Start
            $configChanged = $true
        }
        
        # Config-Settings updaten
        if ($guiConfig.CollectIntervalSeconds -and $guiConfig.CollectIntervalSeconds -ne $config.CollectIntervalSeconds) {
            $config.CollectIntervalSeconds = $guiConfig.CollectIntervalSeconds
            $configChanged = $true
        }
        if ($guiConfig.MaxTrades -and $guiConfig.MaxTrades -ne $config.MaxTrades) {
            $config.MaxTrades = $guiConfig.MaxTrades
            $configChanged = $true
        }
        if ($guiConfig.RefreshIntervalRowsFull -and $guiConfig.RefreshIntervalRowsFull -ne $config.RefreshIntervalRowsFull) {
            $config.RefreshIntervalRowsFull = $guiConfig.RefreshIntervalRowsFull
            $configChanged = $true
        }
        # === NEU: LogMode Live-Update (v4.4) ===
        if ($guiConfig.LogMode -and $guiConfig.LogMode -ne $config.LogMode) {
            $config.LogMode = $guiConfig.LogMode
            $configChanged = $true
        }

        if ($configChanged) {
            Write-Log "GUI-Config live geladen und angewendet!" "INFO"
        }
    }
    catch {
        Write-Log "Fehler beim Laden der GUI-Config: $_" "DEBUG"
    }
}

Write-Log "GUI-Integration geladen" "INFO"
# --- GUI Integration Ende ---
# =============================================================================

$script:StatsTopRow = $null

# Pictures-/ Symbol-/ ... Ordner sicherstellen
$picturesPath = Join-Path $config.BasePath "pictures"
if (-not (Test-Path $picturesPath)) {
    New-Item -ItemType Directory -Path $picturesPath -Force | Out-Null
    Write-Log "Erstelle Pictures-Ordner: $picturesPath" "DEBUG"
}

$itemSymbolFolder = $config.SymbolFolder
if (-not (Test-Path $itemSymbolFolder)) {
    New-Item -ItemType Directory -Path $itemSymbolFolder -Force | Out-Null
    Write-Log ("Erstelle ItemSymbols-Ordner: {0}" -f $itemSymbolFolder) "DEBUG"
}



<#
    Berechnet Kennzahlen (Laufzeit, Trades/h, Gems/h, Slots usw fuer alle Trades
	die gestartet werden sollen) aus $stats
    und gibt einen formatierten Textblock als String-Array zurueck.
    Wird fuer Live- und Final-Statistiken verwendet.
#>

function Show-StatsBlock {
    param(
        [string]$Title
    )

    $now      = Get-Date
    $duration = $now - $stats.ScriptStartTime
    $hours    = [math]::Max($duration.TotalHours, 0.0001)

    $start       = $stats.ScriptStartTime.ToString("HH:mm:ss")
    $resume      = if ($stats.LastResumeTime) { $stats.LastResumeTime.ToString("HH:mm:ss") } else { "-" }
    $durationStr = "{0:hh\:mm\:ss}" -f $duration

    # --- Globale Zahlen vorbereiten ----------------------------------------

    $totalTrades    = $stats.StartedTrades
    $totalRefreshes = $stats.RefreshCount

    $tradesPerHour    = $totalTrades    / $hours
    $refreshesPerHour = $totalRefreshes / $hours

    if ($totalRefreshes -gt 0) {
        $tradesPerRefresh = $totalTrades / [double]$totalRefreshes
    } else {
        $tradesPerRefresh = 0.0
    }

    $tradesPerHourStr     = "{0:N0}" -f $tradesPerHour
    $refreshesPerHourStr  = "{0:N0}" -f $refreshesPerHour
    $tradesPerRefreshStr  = "{0:N3}" -f $tradesPerRefresh

    # --- Gem-Zahlen --------------------------------------------------------

    $totalGems = $stats.GemsTotal
    $gemTrades = $stats.GemTrades

    if ($gemTrades -gt 0) {
        $avgGemsPerTrade = [double]$totalGems / $gemTrades
    } else {
        $avgGemsPerTrade = 0.0
    }

    $gemsPerHour = [double]$totalGems / $hours

    $avgGemsPerTradeStr = "{0:N2}" -f $avgGemsPerTrade
    $gemsPerHourStr     = "{0:N2}" -f $gemsPerHour

    $highValueTrades = $stats.GemValue3Count + $stats.GemValue4Count + $stats.GemValue5Count + $stats.GemValue6Count
    if ($gemTrades -gt 0) {
        $highValueShare = 100.0 * $highValueTrades / [double]$gemTrades
    } else {
        $highValueShare = 0.0
    }
    $highValueShareStr = "{0:N1} %" -f $highValueShare

    # --- Slots -------------------------------------------------------------

    if ($stats.LoopCount -gt 0) {
        $avgActive = $stats.ActiveSlotsSum / [double]$stats.LoopCount
    } else {
        $avgActive = 0.0
    }
    $avgActiveStr = "{0:N2}" -f $avgActive

    if ($config.MaxTrades -gt 0) {
        $slotUtil = 100.0 * $avgActive / [double]$config.MaxTrades
    } else {
        $slotUtil = 0.0
    }
	$stats.slotUtilPerHour = $slotUtil
    $slotUtilStr = "{0:N1} %" -f $slotUtil

    # --- Start-Qualitaet / Auto-Calib --------------------------------------

    if ($stats.StartAttempts -gt 0) {
        $failsPer100 = 100.0 * $stats.FailedStarts / [double]$stats.StartAttempts
        $successRateStr = "{0:P0}" -f ($stats.SuccessfulStarts / [double]$stats.StartAttempts)
    } else {
        $failsPer100 = 0.0
        $successRateStr = "n/a"
    }


    $autoCalls   = $stats.AutoCalibCalls
    $autoSuccess = $stats.AutoCalibSuccess
    
    $StartAttemptsStr = "{0:N0}" -f $stats.StartAttempts
    $SuccessfulStartsStr = "{0:N0}" -f $stats.SuccessfulStarts 
    $FailedStartsStr = "{0:N0}" -f $stats.FailedStarts
    $autoCallsStr = "{0:N0}" -f $autoCalls
    $autoSuccessStr = "{0:N0}" -f $autoSuccess
    $failsPer100Str = "{0:N2}" -f $failsPer100

    if ($autoCalls -gt 0) {
        $autoRate = $autoSuccess / [double]$autoCalls
        $autoRateStr = "{0:P0}" -f $autoRate
    } else {
        $autoRateStr = "n/a"
    }

    
    

    # --- Item-Tabelle vorbereiten -----------------------------------------

    $wName   = -8
    $wTrades = 6
    $wTh     = 11
    $wTr     = 11
    $wShare  = 11

    $itemLines = @()

    foreach ($kvp in $config.ItemPolicies.GetEnumerator() | Sort-Object Key) {
        $itemName = $kvp.Key
        $policy   = $kvp.Value
        if (-not $policy.Start) { continue }

        $tradePropName = ($itemName + "Trades")
        $prop          = $stats.PSObject.Properties[$tradePropName]
        $itemTrades    = if ($prop) { [int]$prop.Value } else { 0 }

        if ($hours -gt 0) {
            $itemTph = $itemTrades / $hours
        } else {
            $itemTph = 0.0
        }

        if ($totalRefreshes -gt 0) {
            $itemTr = $itemTrades / [double]$totalRefreshes
        } else {
            $itemTr = 0.0
        }

        if ($totalTrades -gt 0) {
            $itemShare = 100.0 * $itemTrades / [double]$totalTrades
        } else {
            $itemShare = 0.0
        }

        $itemTphStr   = "{0:N0}" -f $itemTph
        $itemTrStr    = "{0:N1}" -f $itemTr
        $itemShareStr = "{0:N1} %" -f $itemShare
    }

    # --- Ausgabezeilen -----------------------------------------------------

    $lines = @()

    $lines += ""
    $lines += "[STATS] $Title"
    $lines += ""
    # Einheitliches 3-Spalten-Raster (Col1 / Col2 / Col3)
    $lines += ("  Session  : {0,18} | {1,18} | {2,18}" -f `
              ("Start " + $start),
              ("Last "  + $resume),
              ("Duration "   + $durationStr))
    $lines += ("  ---------: {0,18}|{1,18}|{2,18}" -f "-------------------", "--------------------", "-------------------")
    $lines += ("  Global   : {0,18} | {1,18} | {2,18}" -f `
              ($tradesPerHourStr + " Trades/h"),
              ("Trades " + $totalTrades),
              ("Refreshes " + $totalRefreshes))

    $lines += ("  Starts   : {0,18} | {1,18} | {2,18}" -f `
            ("Attempts " + $StartAttemptsStr),
            ("OK " + $SuccessfulStartsStr),
            ("Success " + $successRateStr),
            "")
                
    $lines += ("  Slots    : {0,18} | {1,18} | {2,18}" -f `
              ("Current " + $stats.LastActiveSlots),
              ("Avg "     + $avgActiveStr),
              ("Util "    + $slotUtilStr))

    $lines += ("  Quality  : {0,18} | {1,18} | {2,18}" -f `
            "",
            ("Failed " + $FailedStartsStr),
            ("Fails/100 " + $failsPer100Str))

    $lines += ("  AutoCalib: {0,18} | {1,18} | {2,18}" -f `
            ("Calls " + $autoCallsStr),
            ("Success " + $autoSuccessStr),
            ("HitRate " + $autoRateStr))

    $lines += ""
    $lines += ""

        # --- Items: kompakte Tabelle (Trades / Trades/h / Share) ---------------

    # Item-Statistiken vorbereiten
    $itemStats = @()

    foreach ($kvp in $config.ItemPolicies.GetEnumerator() | Sort-Object Key) {
        $itemName = $kvp.Key
        $policy   = $kvp.Value
        if (-not $policy.Start) { continue }

        $tradePropName = ($itemName + "Trades")
        $prop          = $stats.PSObject.Properties[$tradePropName]
        $itemTrades    = if ($prop) { [int]$prop.Value } else { 0 }

        if ($hours -gt 0) {
            $itemTph = $itemTrades / $hours
        } else {
            $itemTph = 0.0
        }

        if ($totalTrades -gt 0) {
            $itemShare = 100.0 * $itemTrades / [double]$totalTrades
        } else {
            $itemShare = 0.0
        }

        $itemStats += [pscustomobject]@{
            Name      = $itemName
            Trades    = $itemTrades
            TradesPerH= "{0:N0}" -f $itemTph
            ShareStr  = "{0:N1} %" -f $itemShare
        }
    }

    if ($itemStats.Count -gt 0) {
        # Kopfzeile im eigenen, stabilen Raster
        $lines += ""
        $lines += ("           : {0,18} | {1,18} | {2,18}" -f "Trades", "Trades/h", "Share")
        $lines += ("  ---------: {0,18}|{1,18}|{2,18}" -f "-------------------", "--------------------", "-------------------")

        foreach ($it in $itemStats) {
            $lines += ("  {0,-8} : {1,18} | {2,18} | {3,18}" -f `
                       $it.Name,
                       $it.Trades,
                       $it.TradesPerH,
                       $it.ShareStr)
        }
        $lines += ("  ---------: {0,18}|{1,18}|{2,18}" -f "-------------------", "--------------------", "-------------------")
    }
    
    $lines += ("  Gems     : {0,18} | {1,18} | {2,18}" -f `
              ("Total Gems "     + $totalGems),
              ($gemsPerHourStr + " Gems/h"),
              ( $avgGemsPerTradeStr + " Gems/Trade"))

    $lines += ("           : {0,18} | {1,18} | {2,18}" -f `
              ("1 Gem  = " + $stats.GemValue1Count),
              ("2 Gems = " + $stats.GemValue2Count),
              ("3 Gems = " + $stats.GemValue3Count))

    $lines += ("           : {0,18} | {1,18} | {2,18}" -f `
              ("4 Gems = " + $stats.GemValue4Count),
              ("5 Gems = " + $stats.GemValue5Count),
              ("6 Gems = " + $stats.GemValue6Count))

    $lines += ("           : {0,18} | {1,18} | {2,18}" -f `
              ("7 Gems = " + $stats.GemValue7Count),
              ("8 Gems = " + $stats.GemValue8Count),
              ("9 Gems = " + $stats.GemValue9Count))

    $lines += ("           : {0,18} | {1,18} | {2,18}" -f `
              ("10 Gems = " + $stats.GemValue10Count),
              ("11 Gems = " + $stats.GemValue11Count),
              ("12 Gems = " + $stats.GemValue12Count))

    $lines += ("           : {0,18} | {1,18} | {2,18}" -f `
              ("13 Gems = " + $stats.GemValue13Count),
              ("14 Gems = " + $stats.GemValue14Count),
              ("15 Gems = " + $stats.GemValue15Count))
			  
    $lines += ("           : {0,18} | {1,18} | {2,18}" -f `
              ("16 Gems = " + $stats.GemValue16Count),
              ("17 Gems = " + $stats.GemValue17Count),
              ("18 Gems = " + $stats.GemValue18Count))
			  
    $lines += ("           : {0,18} | {1,18} | {2,18}" -f `
              ("19 Gems = " + $stats.GemValue19Count),
              ("20 Gems = " + $stats.GemValue20Count))

    return $lines
}

<#
    Aktualisiert Laufzeit-Statistiken und zeichnet sie in die Konsole.
    Nutzt Show-StatsBlock und schreibt im STATS-Modus in einen festen
    Konsolenbereich (CursorTop wird gemerkt).
#>
function Update-StatsDisplay {
    param(
        [int]$GemRows,
        [int]$ActiveSlots
    )

    $stats.LoopCount++
    $stats.LastGemRows     = $GemRows
    $stats.LastActiveSlots = $ActiveSlots
    $stats.ActiveSlotsSum += $ActiveSlots

    if ($config.LogMode -ne "STATS") { return }

    $now = Get-Date
    if ((($now - $stats.LastStatsWrite).TotalSeconds) -lt $config.StatsUpdateIntervalSeconds) {
        return
    }
    $stats.LastStatsWrite = $now

    $lines = Show-StatsBlock -Title "Live"

    $isConsoleHost = ($Host.Name -eq 'ConsoleHost')

    if ($isConsoleHost -and -not [System.Console]::IsOutputRedirected) {
        try {
            if ($script:StatsTopRow -eq $null) {
                $script:StatsTopRow = [System.Console]::CursorTop
            }

            $width = [System.Console]::BufferWidth
            if ($width -lt 2) {
                throw "ConsoleTooSmall"
            }

            [System.Console]::SetCursorPosition(0, $script:StatsTopRow)

            foreach ($line in $lines) {
                $text = if ($line.Length -lt $width) {
                    $line + (' ' * ($width - $line.Length - 1))
                }
                else {
                    $line
                }
                [System.Console]::WriteLine($text)
            }

            $afterRow     = $script:StatsTopRow + $lines.Count
            $bufferHeight = [System.Console]::BufferHeight
            if ($afterRow -ge $bufferHeight) {
                $afterRow = $bufferHeight - 1
            }
            [System.Console]::SetCursorPosition(0, $afterRow)
            return
        }
        catch {
            # Fallback
        }
    }

    Write-Host ""
    foreach ($line in $lines) {
        Write-Host $line
    }
}


# --- Hilfsfunktion: ItemType aus Symboldatei hinzufuegen ----------------------

<#
    Laedt eine Item-Symboldatei (Beer, Gem, ...) aus pictures\\ItemSymbols,
    liest die mittlere Pixel-Farbe als Referenz und traegt sie mit Toleranz
    in $script:ItemTypes ein.
#>
function Add-ItemTypeFromSymbol {
    param(
        [string]$Name,            # "Gem", "Beer", "Mulch", ...
        [string]$FileName,        # "GemSymbol.png" etc.
        [int]   $Tolerance
    )

    $symbolPath = Join-Path $config.SymbolFolder $FileName

    if (-not (Test-Path $symbolPath)) {
        Write-Log ("Item-Symbol '{0}' nicht gefunden, ueberspringe. Pfad={1}" -f $Name, $symbolPath) "INFO"
        return
    }

    $symbolBitmap = [System.Drawing.Bitmap]::FromFile($symbolPath)
    try {
        $centerX    = [int]($symbolBitmap.Width  / 2)
        $centerY    = [int]($symbolBitmap.Height / 2)
        $centerColor = $symbolBitmap.GetPixel($centerX, $centerY)

        Write-Log ("ItemType={0}: CenterColor R={1} G={2} B={3}" -f `
                   $Name, $centerColor.R, $centerColor.G, $centerColor.B) "DEBUG"

        $script:ItemTypes += [pscustomobject]@{
            Name      = $Name
            Color     = $centerColor
            Tolerance = $Tolerance
        }
    }
    finally {
        $symbolBitmap.Dispose()
    }
}


# --- Hilfsfunktionen: Farben / Screen / Klicks -------------------------------

<#
    Vergleicht zwei System.Drawing.Color-Werte per RGB-Abstand.
    Liefert $true, wenn alle Kanal-Differenzen <= Tolerance sind.
#>
function Test-ColorEqual {
    param(
        [System.Drawing.Color]$c1,
        [System.Drawing.Color]$c2,
        [int]$Tolerance
    )

    return (
        [math]::Abs($c1.R - $c2.R) -le $Tolerance -and
        [math]::Abs($c1.G - $c2.G) -le $Tolerance -and
        [math]::Abs($c1.B - $c2.B) -le $Tolerance
    )
}

<#
    Liest die Bildschirmfarbe an einem absoluten Screen-Punkt (X,Y),
    indem ein 1x1-Bitmap vom Screen kopiert wird.
#>

function Get-ScreenColor {
    param(
        [int]$X,
        [int]$Y
    )
    $bmp = New-Object System.Drawing.Bitmap 1,1
    $g   = [System.Drawing.Graphics]::FromImage($bmp)
    $g.CopyFromScreen($X, $Y, 0, 0, $bmp.Size)
    $color = $bmp.GetPixel(0,0)
    $g.Dispose()
    $bmp.Dispose()
    return $color
}

<#
    Prueft, ob der Start-Button an der Slot-Y-Position visuell „enabled“ ist.
    Misst dazu den Farb-Abstand zum konfigurierten StartEnabledColor und
    vergleicht ihn mit StartEnabledTolerance.
#>
<# OLD 1 Pixel prüfen
function Test-StartButtonEnabled {
    param(
        [int]$StartClickX,
        [int]$ClickY
    )

    $checkX = $StartClickX + $config.StartCheckOffsetX
    $checkY = $ClickY      + $config.StartCheckOffsetY
	

    $c = Get-ScreenColor -X $checkX -Y $checkY
    if (-not $c) { return $false }

    $target = $config.StartEnabledColor
    $tol    = $config.StartEnabledTolerance

    if (-not $tol -or $tol -le 0) {
        $tol = 80
    }

    $dr = [int]$c.R - [int]$target.R
    $dg = [int]$c.G - [int]$target.G
    $db = [int]$c.B - [int]$target.B

    $dist = [math]::Sqrt($dr*$dr + $dg*$dg + $db*$db)

    if ($config.LogMode -eq "DEBUG") {
        Write-Log ("StartButtonCheck Y={0}: RGB=({1},{2},{3}) Dist={4:N2} Tol={5}" -f `
                   $ClickY, $c.R, $c.G, $c.B, $dist, $tol) "DEBUG"
    }

    return ($dist -le $tol)
}
#>

# Neu Start Button, Pixel 3x3 prüfen
function Test-StartButtonEnabled {
    param(
        [int]$StartClickX,
        [int]$ClickY
    )

    $checkCenterX = $StartClickX + $config.StartCheckOffsetX
    $checkCenterY = $ClickY      + $config.StartCheckOffsetY

    $target = $config.StartEnabledColor
    $tol    = $config.StartEnabledTolerance
    if (-not $tol -or $tol -le 0) { $tol = 80 }
	
	# Entscheidungsregeln
    #$ratioThreshold   = 0.4   # 40% der Pixel muessen innerhalb der Toleranz liegen
    #$minDistOverride  = 10.0  # Wenn ein Pixel < 10 Distanz hat, gilt der Button als aktiv
	
    # Groesse des zu pruefenden Bereichs (HalfSize=2 => 5x5 Pixel)
    $halfSize = 1

    $totalPixels   = 0
    $withinTol     = 0
    $minDist       = [double]::PositiveInfinity
    $sumDist       = 0.0

    for ($dy = -$halfSize; $dy -le $halfSize; $dy++) {
        for ($dx = -$halfSize; $dx -le $halfSize; $dx++) {

            $x = $checkCenterX + $dx
            $y = $checkCenterY + $dy

            $c = Get-ScreenColor -X $x -Y $y
            if (-not $c) { continue }

            $dr = [int]$c.R - [int]$target.R
            $dg = [int]$c.G - [int]$target.G
            $db = [int]$c.B - [int]$target.B

            $dist = [math]::Sqrt($dr*$dr + $dg*$dg + $db*$db)

            $totalPixels++
            $sumDist += $dist
            if ($dist -lt $minDist) { $minDist = $dist }
            if ($dist -le $tol)     { $withinTol++ }
        }
    }

    if ($totalPixels -eq 0) { return $false }

    $avgDist = $sumDist / $totalPixels
    $ratio   = $withinTol / $totalPixels


    $isActive = $false

    if ($ratio -ge $config.ratioThreshold) {
        $isActive = $true
    }
    elseif ($minDist -le $config.minDistOverride) {
        # Sicherheitsnetz: mind. ein Pixel ist quasi perfekte Start-Button-Farbe
        $isActive = $true
    }

    if ($config.LogMode -eq "DEBUG") {
        Write-Log ("StartButtonAreaCheck Y={0}: Center=({1},{2}) Pixels={3} Inside={4} " +
                   "Ratio={5:P1} MinDist={6:N1} AvgDist={7:N1} Tol={8} Active={9}" -f `
                   $ClickY, $checkCenterX, $checkCenterY,
                   $totalPixels, $withinTol, $ratio, $minDist, $avgDist, $tol, $isActive) "DEBUG"
    }

    return $isActive
}

<#
    Fuehrt einen einzelnen Mausklick via externer AHK-Exe an Position (X,Y) aus.
    Nutzt das im Config gesetzte SingleClickExe und wartet auf Prozessende.
#>

function Invoke-SingleClick {
    param(
        [int]$X,
        [int]$Y,
        [string]$Label = ""
    )

    # Sehr spammy, bei Bedarf einkommentieren
    Write-Log ("Klick auf {0}: X={1}, Y={2}" -f $Label, $X, $Y) "DEBUG"

    $proc = Start-Process -FilePath $config.SingleClickExe `
                          -ArgumentList @($X, $Y) `
                          -PassThru
    Wait-Process -Id $proc.Id
}

<#
    Fuehrt einen Doppelklick via externer AHK-Exe an Position (X,Y) aus.
    Nutzt DoubleClickExe und wartet auf Prozessende.
#>
function Invoke-DoubleClick {
    param(
        [int]$X,
        [int]$Y,
        [string]$Label = ""
    )

    # Sehr spammy, bei Bedarf einkommentieren
    Write-Log ("Doppelklick auf {0}: X={1}, Y={2}" -f $Label, $X, $Y) "DEBUG"

    $proc = Start-Process -FilePath $config.DoubleClickExe `
                          -ArgumentList @($X, $Y) `
                          -PassThru
    Wait-Process -Id $proc.Id
}

# --- Auto-Kalibrierung StartOffset -------------------------------------------

<#
    Versucht bei gehaeuften Fehlstarts den vertikalen StartOffsetRel automatisch
    zu kalibrieren. Sucht um ClickY herum nach einem roten Fortschrittsbalken
    und mittelt den gefundenen Offset in die Config ein.
#>
function Auto-CalibrateStartOffset {
    param(
        [int]$FoundY,
        [int]$ClickY,
        [int]$ProgressCenterX,
        [int]$WinHeight
    )

    if (-not $config.AutoCalibEnabled) {
        return $false
    }

    $searchRangePixels  = $config.AutoCalibSearchRange
    $searchStepPixels   = $config.AutoCalibStep

    if ($stats.StartAttempts -lt $config.AutoCalibMinAttempts) {
        return $false
    }

    $currentFailRate = if ($stats.StartAttempts -gt 0) {
        ($stats.FailedStarts + 0.0) / [double]$stats.StartAttempts
    }
    else {
        0.0
    }

    if ($currentFailRate -lt $config.AutoCalibMinFailRate) {
        return $false
    }

    $stats.AutoCalibCalls++

    Write-Log ("AutoCalib: beginne vertikale Suche um ClickY={0} (FailRate={1:P0})" -f `
               $ClickY, $currentFailRate) "DEBUG"

    for ($deltaY = -$searchRangePixels; $deltaY -le $searchRangePixels; $deltaY += $searchStepPixels) {
        $testClickY = $ClickY + $deltaY
        if ($testClickY -lt 0) { continue }

        $slotHasProgressBar = Test-SlotRunning -ClickY $testClickY -ProgressCenterX $ProgressCenterX

        if ($slotHasProgressBar) {
            $newOffsetPixels = $testClickY - $FoundY
            $newOffsetRel    = $newOffsetPixels / [double]$WinHeight
            $stats.AutoCalibSuccess++

            if ($config.StartOffsetRel -ne $null) {
                $config.StartOffsetRel = ($config.StartOffsetRel + $newOffsetRel) / 2.0
            }
            else {
                $config.StartOffsetRel = $newOffsetRel
            }

            Write-Log ("AutoCalib: Balken bei Y={0} gefunden (FoundY={1}) -> neuer StartOffsetRel={2:N5}" -f `
                       $testClickY, $FoundY, $config.StartOffsetRel) "INFO"

            return $true
        }
    }

    Write-Log ("AutoCalib: in ±{0} px um Y={1} keinen Balken gefunden." -f $searchRangePixels, $ClickY) "DEBUG"
    return $false
}

# --- Slot-Status (roter Fortschrittsbalken) ----------------------------------

<#
    Prueft, ob an der ClickY-Position bereits ein Trade laeuft.
    Scannt ein schmales Rechteck um die Progress-Bar-Position und zaehlt
    „rote“ Pixel; ab MinRedPixelsForRunning gilt der Slot als laufend.
#>
function Test-SlotRunning {
    param(
        [int]$ClickY,
        [int]$ProgressCenterX
    )

    $halfProgressWidth = $config.ProgressHalfWidth
    $progressWidth     = 2 * $halfProgressWidth + 1
    $progressHeight    = $config.ProgressHeight

    $progressLeft = $ProgressCenterX - $halfProgressWidth
    $progressTop  = $ClickY - [int]($progressHeight / 2)

    $progressBitmap = New-Object System.Drawing.Bitmap $progressWidth, $progressHeight
    $graphics       = [System.Drawing.Graphics]::FromImage($progressBitmap)

    $graphics.CopyFromScreen($progressLeft, $progressTop, 0, 0,
        [System.Drawing.Size]::new($progressWidth, $progressHeight))

    $graphics.Dispose()

    $redPixelCount = 0

    for ($x = 0; $x -lt $progressBitmap.Width; $x++) {
        for ($y = 0; $y -lt $progressBitmap.Height; $y++) {

            $pixelColor = $progressBitmap.GetPixel($x, $y)

            if ($pixelColor.R -ge 150 -and
                $pixelColor.R - [math]::Max($pixelColor.G, $pixelColor.B) -ge 40) {

                $redPixelCount++
            }
        }
    }

    $progressBitmap.Dispose()

    return ($redPixelCount -ge $config.MinRedPixelsForRunning)
}

# --- Screenshots fuer Gem Value Debug -----------------------------------------

<#
    Speichert einen 16x16-Screenshot der Gem-Wert-Box zu Debugzwecken.
    Respektiert StatsGemScreenshotMode: OFF / ALL / UNKNOWN und baut den
    Dateinamen aus Reason, erkannter Ziffer und Position.
#>
function Save-GemDebugImage {
    param(
        [System.Drawing.Bitmap]$Bitmap,
        [int]$FoundX,
        [int]$FoundY,
        [int]$Digit,
        [string]$Reason
    )

    $screenshotMode = $config.StatsGemScreenshotMode  # "OFF" | "UNKNOWN" | "ALL"

    switch ($screenshotMode) {
        "OFF"     { return }

        "ALL"     { }  # immer speichern

        "UNKNOWN" {
            if ($Reason -eq "UNKNOWN" -or $Reason -eq "UNCERTAIN" -or $Reason -eq "OCR_FAIL") {
                  # immer speichern
            }
            else {
                return
            }
        }
    }

    $timestampLabel = (Get-Date).ToString("HHmmss_fff")

    $reasonLabel = if ([string]::IsNullOrEmpty($Reason)) { "UNKNOWN" } else { $Reason }
    $digitLabel  = if ($Digit -eq 0 -or $Digit -eq $null) { "0" } else { $Digit }

    $fileName = "GemValueDebug_{0}_D{1}_{2}_{3}_{4}.png" -f `
        $reasonLabel, $digitLabel, $FoundX, $FoundY, $timestampLabel

    $filePath = Join-Path $config.BasePath ("pictures\" + $fileName)

    try {
        $Bitmap.Save($filePath, [System.Drawing.Imaging.ImageFormat]::Png)
        Write-Log ("Save-GemDebugImage: Screenshot gespeichert '{0}'" -f $filePath) "DEBUG"
    }
    catch {
        Write-Log ("Save-GemDebugImage: Fehler beim Speichern von '{0}': {1}" -f $filePath, $_.Exception.Message) "DEBUG"
    }
}

# --- Gem Wert ermitteln mit Tesseract OCR (kein Fallback) --------------------

<#
    Liest den Gem-Wert (1-100) an FoundX/FoundY:
    - schneidet Box aus dem Screen
    - verwendet Tesseract OCR zur Ziffernerkennung (PSM 7 = Textzeile)
    Liefert:
    - erkannte Zahl (1-100) oder $null bei Fehler
    - BrightPixelCount
    - Score (0 bei Erfolg, 999 bei Fehler)
#>

function Get-GemValue {
    param(
        [int]$FoundX,
        [int]$FoundY
    )

    $boxWidth  = $config.GemValueBoxWidth
    $boxHeight = $config.GemValueBoxHeight
    $boxLeft = $FoundX + $config.GemValueOffsetX
    $boxTop  = $FoundY + $config.GemValueOffsetY

    $digitBitmap = New-Object System.Drawing.Bitmap $boxWidth, $boxHeight
    $graphics    = [System.Drawing.Graphics]::FromImage($digitBitmap)
    $graphics.CopyFromScreen($boxLeft, $boxTop, 0, 0,
        [System.Drawing.Size]::new($boxWidth, $boxHeight))
    $graphics.Dispose()

    if ($config.LogMode -eq "DEBUG") {
        $boxRight  = $boxLeft + $boxWidth  - 1
        $boxBottom = $boxTop  + $boxHeight - 1
        Write-Log (
            "Get-GemValue BoxCoords: FoundX={0}, FoundY={1}, Left={2}, Top={3}, Right={4}, Bottom={5}, W={6}, H={7}" -f `
            $FoundX, $FoundY, $boxLeft, $boxTop, $boxRight, $boxBottom, $boxWidth, $boxHeight
        ) "DEBUG"
    }

    # Bright-Pixel-Count fuer Kompatibilitaet
    # Bright-Pixel-Count
    $brightPixelCount = 0
    for ($x = 0; $x -lt $boxWidth; $x++) {
        for ($y = 0; $y -lt $boxHeight; $y++) {
            $pixelColor = $digitBitmap.GetPixel($x, $y)
            # ANGEPASST: Toleranter fuer dunkle Ziffern (braun auf dunkelbraun)
            $isBright = ($pixelColor.R -ge 150 -and $pixelColor.G -ge 150 -and $pixelColor.B -ge 130)
            #$isBright = ($pixelColor.R -ge 200 -and $pixelColor.G -ge 200 -and $pixelColor.B -ge 200)
            if ($isBright) { $brightPixelCount++ }
        }
    }
    

    if ($brightPixelCount -lt 2) {
        if ($config.LogMode -eq "DEBUG") {
            Write-Log ("Get-GemValue: too few bright pixels ({0}) -> UNKNOWN" -f $brightPixelCount) "DEBUG"
            Save-GemDebugImage -Bitmap $digitBitmap -FoundX $FoundX -FoundY $FoundY -Digit 0 -Reason "UNKNOWN"
        }
        
        $digitBitmap.Dispose()
        # WICHTIG: Return als Array mit 3 Elementen
        return @($null, $brightPixelCount, 999)
    }

    # === TESSERACT OCR (einzige Methode, PSM 7 = unterstuetzt 1-100) ===
   
    $ocrResult = Get-NumberFromBitmapTesseract -InputBitmap $digitBitmap -Prepare $true

    if ($ocrResult -ne $null -and $ocrResult -ge 1 -and $ocrResult -le 100) {
        if ($config.LogMode -eq "DEBUG") {
            Write-Log ("Get-GemValue OCR SUCCESS: Value={0} at Y={1}" -f $ocrResult, $FoundY) "DEBUG"
            Save-GemDebugImage -Bitmap $digitBitmap -FoundX $FoundX -FoundY $FoundY -Digit $ocrResult -Reason "OCR"
        }
        
        $digitBitmap.Dispose()
        # WICHTIG: Return als Array mit 3 Elementen
        return @($ocrResult, $brightPixelCount, 0)
    }

    # OCR fehlgeschlagen
    if ($config.LogMode -eq "DEBUG") {
        Write-Log ("Get-GemValue: OCR failed -> UNKNOWN; ocrResult: $ocrResult | brightPixelCount: $brightPixelCount") "DEBUG"
        Save-GemDebugImage -Bitmap $digitBitmap -FoundX $FoundX -FoundY $FoundY -Digit 0 -Reason "OCR_FAIL"
    }

    $digitBitmap.Dispose()
    # WICHTIG: Return als Array mit 3 Elementen
    return @($null, $brightPixelCount, 1)
}

# --- Beer Wert grob ermitteln, 1 ungueltig, Zahl "laenger" als 1 = starten -----

<#
    Prueft, ob der Beer-Wert optisch „groß“ ist (mehrere Ziffern).
    Zaehlt Spalten mit hellen Pixeln in der Value-Box und vergleicht sie
    mit BeerMinActiveColumns (z.B. kurze „1“ vs. langer Wert).
#>
function Test-BeerValueIsBig {
    param(
        [int]$FoundX,
        [int]$FoundY
    )

    $boxWidth  = $config.BeerValueBoxWidth
    $boxHeight = $config.BeerValueBoxHeight

    $boxLeft = $FoundX + $config.BeerValueOffsetX
    $boxTop  = $FoundY + $config.BeerValueOffsetY

    $valueBitmap = New-Object System.Drawing.Bitmap $boxWidth, $boxHeight
    $graphics    = [System.Drawing.Graphics]::FromImage($valueBitmap)

    $graphics.CopyFromScreen($boxLeft, $boxTop, 0, 0,
        [System.Drawing.Size]::new($boxWidth, $boxHeight))

    $graphics.Dispose()

    $activeColumns = 0

    for ($x = 0; $x -lt $boxWidth; $x++) {
        $columnHasBrightPixel = $false

        for ($y = 0; $y -lt $boxHeight; $y++) {
            $pixelColor = $valueBitmap.GetPixel($x, $y)

            $isBright = ($pixelColor.R -ge 200 -and
                         $pixelColor.G -ge 200 -and
                         $pixelColor.B -ge 160)

            if ($isBright) {
                $columnHasBrightPixel = $true
                break
            }
        }

        if ($columnHasBrightPixel) {
            $activeColumns++
        }
    }

    $valueBitmap.Dispose()

    if ($config.LogMode -eq "DEBUG") {
        Write-Log ("BeerValueCheck: activeColumns={0}/{1} (MinActiveColumns={2})" -f `
                   $activeColumns, $boxWidth, $config.BeerMinActiveColumns) "DEBUG"
    }

    return ($activeColumns -ge $config.BeerMinActiveColumns)
}

# --- Festlegen, ob ein Item ueberhaupt gehandelt werden soll ------------------
<#
    Wendet die Policy fuer einen Item-Typ an (Gem, Beer, ...):
    - prueft Start-Flag
    - bei NeedsGemValue optional MinValue-Grenze
    Liefert $true, wenn ein Trade fuer diesen Item-Typ gestartet werden darf.
#>function Should-StartItemTrade {
    param(
        [string]$ItemName,
        [int]$PreGemValue
    )

    $policy = $config.ItemPolicies[$ItemName]

    # unbekannte Items niemals traden
    if (-not $policy.Start) { return $false }

    if ($policy.NeedsGemValue) {
        if ($policy.ContainsKey("MinValue")) {
			# Nur Prüfen ob Gestartet werden soll, Wert ggf. noch unbekannt
            if ($PreGemValue -eq 0) {
				Write-Log ("Item = {0}: Value=0 , ShouldTrade = {1} -> noch kein OCR & check MinValue={2} überspringen" -f $ItemName, $policy.Start, $policy.MinValue) "DEBUG"
				return $true 
			}
			
			# hier auf "MinValue" pruefen, nicht auf den Zahlenwert aus der Config
            if ($PreGemValue -lt $policy.MinValue) {
				Write-Log ("Y={0}: MinValue = {1} GemValue = {2}" -f $ClickY, $policy.MinValue, $PreGemValue) "DEBUG"
				return $false 
			}
        }
    }

    return $true
}

# --- Start eines Trades ------------------------------------------------------

<#
    Fuehrt bis zu drei Start-Versuche fuer einen Slot durch (Doppelklicks),
    prueft jeweils per Test-SlotRunning, ob ein roter Balken auftaucht.
    Bei Misserfolg wird ggf. Auto-CalibrateStartOffset ausgeloest.
    Aktualisiert Start-/Fail-Statistiken.
#>
function Try-StartTrade {
    param(
        [int]$ClickY,
        [int]$StartClickX,
        [int]$ProgressCenterX,
        [int]$FoundY,
        [int]$WinHeight,
        [int]$FoundX,
        [int]$PreGemValue
    )

    $maxStartAttempts       = 3
    $slotRunningAfterClick  = $false

    $isDebugMode = ($config.LogMode -eq "DEBUG")

    if ($isDebugMode) {
        if ($PreGemValue -ne $null -and $PreGemValue -gt 0) {
            Write-Log ("Y={0}: GemValue vor Startversuchen = {1}" -f $ClickY, $PreGemValue) "DEBUG"
        }
        else {
            #Write-Log ("Y={0}: GemValueValue vor Startversuchen = none/null -> nicht relevant für Item" -f $ClickY) "DEBUG"
        }
    }

    for ($startAttempt = 1; $startAttempt -le $maxStartAttempts; $startAttempt++) {

        $stats.StartAttempts++
        Write-Log ("Y={0}: Start-Versuch {1}/{2}." -f $ClickY, $startAttempt, $maxStartAttempts) "DEBUG"

        Invoke-DoubleClick -X $StartClickX -Y $ClickY -Label "Start Craft"
        $stats.StartedTrades++

        if ($config.MultipleHitsWaitMilliseconds -gt 0) {
            Start-Sleep -Milliseconds $config.MultipleHitsWaitMilliseconds
        }
        if ($config.VerifyStartDelayMs -gt 0) {
            Start-Sleep -Milliseconds $config.VerifyStartDelayMs
        }

        $slotRunningAfterClick = Test-SlotRunning -ClickY $ClickY -ProgressCenterX $ProgressCenterX

        if ($slotRunningAfterClick) {
            $stats.SuccessfulStarts++
            Write-Log ("Y={0}: Start-Versuch {1} erfolgreich (roter Balken erkannt)." -f $ClickY, $startAttempt) "DEBUG"

            if ($PreGemValue -ne $null -and $PreGemValue -gt 0) {
                Write-Log ("Y={0}: Gem-Wert fuer diesen Trade = {1}" -f $ClickY, $PreGemValue) "DEBUG"
            }
            else {
                #Write-Log ("Y={0}: Kein Gem-Wert notwendig für dieses Item, Trade gestartet." -f $ClickY) "INFO"
            }

            break
        }
        else {
            Write-Log ("Y={0}: Start-Versuch {1} ohne Balken -> evtl. weiterer Versuch." -f $ClickY, $startAttempt) "DEBUG"
        }
    }

    if (-not $slotRunningAfterClick) {
        $stats.FailedStarts++
        Write-Log ("Y={0}: Alle {1} Start-Versuche ohne Erfolg, Slot gilt als FailedStart." -f $ClickY, $maxStartAttempts) "DEBUG"

        $autoCalibSucceeded = Auto-CalibrateStartOffset -FoundY $FoundY -ClickY $ClickY `
                                                          -ProgressCenterX $ProgressCenterX `
                                                          -WinHeight $WinHeight
        if ($autoCalibSucceeded) {
            Write-Log ("AutoCalib: StartOffsetRel angepasst auf {0:N5}." -f $config.StartOffsetRel) "INFO"
        }
    }

    return $slotRunningAfterClick
}

# --- Collect/Refresh Makros --------------------------------------------------

<#
    Fuehrt die Collect- und Refresh-AHK-Makros aus und aktualisiert
    Refresh-Statistiken. Danach kurze Pause (PostRefreshDelayMs).
#>
function Invoke-CollectRefresh {
    param(
        [int]$CollectX,
        [int]$CollectY,
        [int]$RefreshX,
        [int]$RefreshY
    )

    Write-Log "Collect+Refresh ausfuehren." "INFO"

    Invoke-DoubleClick -X $CollectX -Y $CollectY -Label "Collect"
    Invoke-SingleClick -X $RefreshX -Y $RefreshY -Label "Refresh"

    $stats.RefreshCount++
    $stats.LastCollectTime = Get-Date

    Start-Sleep -Milliseconds $config.PostRefreshDelayMs
}

<#
    Fuehrt nur das Refresh-Makro aus (kein Collect) und erhoeht RefreshCount.
    Wird genutzt, wenn Slots nicht voll sind oder Collect noch nicht faellig ist. <-- TODO stimmt das=?
#>
function Invoke-RefreshOnly {
    param(
        [int]$RefreshX,
        [int]$RefreshY
    )

    Write-Log "Nur Refresh ausfuehren." "INFO"

    Invoke-SingleClick -X $RefreshX -Y $RefreshY -Label "Refresh"
    $stats.RefreshCount++

    Start-Sleep -Milliseconds $config.PostRefreshDelayMs
}

# --- Snapshot des Suchbereichs ----------------------------------------------

$script:SearchSnapshotDone = $false

<#
    Speichert einmalig pro Scriptlauf einen Screenshot des Suchbereichs
    (SearchRect) als SearchArea.png unter pictures\\ zur visuellen Kontrolle.
#>
function Save-SearchAreaSnapshot {
    param(
        [int]$SearchLeft,
        [int]$SearchTop,
        [int]$SearchRight,
        [int]$SearchBottom
    )

    if ($script:SearchSnapshotDone) { return }

    $searchWidth  = $SearchRight  - $SearchLeft
    $searchHeight = $SearchBottom - $SearchTop

    $searchAreaBitmap = New-Object System.Drawing.Bitmap $searchWidth, $searchHeight
    $graphics         = [System.Drawing.Graphics]::FromImage($searchAreaBitmap)

    $graphics.CopyFromScreen($SearchLeft, $SearchTop, 0, 0,
        [System.Drawing.Size]::new($searchWidth, $searchHeight))

    $graphics.Dispose()

    $snapshotPath = Join-Path $config.BasePath "pictures\SearchArea.png"
    $searchAreaBitmap.Save($snapshotPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $searchAreaBitmap.Dispose()

    $script:SearchSnapshotDone = $true
    Write-Log ("SearchArea-Snapshot gespeichert unter {0}" -f $snapshotPath) "INFO"
}

# --- Symbol-Suche: ein Screen-Scan, mehrere Item-Typen -----------------------

<#
    Scannt den Suchbereich einmal als Bitmap und sucht nach Item-Symbolen.
    Fuer jeden Pixel:
    - naechstliegenden ItemType nach Farbdistanz bestimmen
    - im 3x3-Umfeld Cluster gleicher Farbe zaehlen
    - bei genuegend Clustern einen Hit mit FoundX/FoundY/ClickY anlegen
    Anschließend werden nahe Hits zu Zeilen zusammengefasst (Row-Gap).
#>
function Find-SymbolHits {
    param(
        [pscustomobject[]]$ItemTypes,
        [int]$SearchLeft,
        [int]$SearchTop,
        [int]$SearchRight,
        [int]$SearchBottom,
        [int]$StartOffsetPixels
    )

    # Mindestanzahl farbpassender Pixel im 3x3-Umfeld, damit ein Symbol als Treffer gilt
    $minClusterPixels = 4

    $searchWidth  = $SearchRight  - $SearchLeft
    $searchHeight = $SearchBottom - $SearchTop

    # Screenshot des Suchbereiches (einmal pro Loop)
    $searchBitmap = New-Object System.Drawing.Bitmap $searchWidth, $searchHeight
    $graphics     = [System.Drawing.Graphics]::FromImage($searchBitmap)

    $graphics.CopyFromScreen($SearchLeft, $SearchTop, 0, 0,
        [System.Drawing.Size]::new($searchWidth, $searchHeight))

    $graphics.Dispose()

    $hits = @()

    for ($pixelY = 0; $pixelY -lt $searchBitmap.Height; $pixelY++) {
        for ($pixelX = 0; $pixelX -lt $searchBitmap.Width; $pixelX++) {

            $pixelColor = $searchBitmap.GetPixel($pixelX, $pixelY)

            $bestItem = $null
            $bestDist = [double]::MaxValue

            foreach ($itemType in $ItemTypes) {
                $referenceColor      = $itemType.Color
                $referenceTolerance  = $itemType.Tolerance

                $deltaR = [int]$pixelColor.R - [int]$referenceColor.R
                $deltaG = [int]$pixelColor.G - [int]$referenceColor.G
                $deltaB = [int]$pixelColor.B - [int]$referenceColor.B

                $distance = [math]::Sqrt($deltaR*$deltaR + $deltaG*$deltaG + $deltaB*$deltaB)

                if ($distance -le $referenceTolerance -and $distance -lt $bestDist) {
                    $bestDist = $distance
                    $bestItem = $itemType
                }
            }

            if ($bestItem -eq $null) { continue }

            # Cluster-Check im 3x3-Umfeld um (pixelX,pixelY) fuer den gefundenen Item-Typ
            $clusterCount       = 0
            $clusterRefColor    = $bestItem.Color
            $clusterTolerance   = $bestItem.Tolerance

            for ($offsetY = -1; $offsetY -le 1; $offsetY++) {
                for ($offsetX = -1; $offsetX -le 1; $offsetX++) {

                    $neighborX = $pixelX + $offsetX
                    $neighborY = $pixelY + $offsetY

                    if ($neighborX -lt 0 -or $neighborY -lt 0 -or
                        $neighborX -ge $searchBitmap.Width -or $neighborY -ge $searchBitmap.Height) {
                        continue
                    }

                    $neighborColor = $searchBitmap.GetPixel($neighborX, $neighborY)

                    if (Test-ColorEqual -c1 $neighborColor -c2 $clusterRefColor -Tolerance $clusterTolerance) {
                        $clusterCount++
                    }
                }
            }

            if ($clusterCount -ge $minClusterPixels) {
                $foundX = $SearchLeft + $pixelX
                $foundY = $SearchTop  + $pixelY
                $clickY = $foundY + $StartOffsetPixels

                $hits += [pscustomobject]@{
                    Item   = $bestItem.Name
                    FoundX = $foundX
                    FoundY = $foundY
                    ClickY = $clickY
                }
            }
        }
    }

    $searchBitmap.Dispose()

    if ($hits.Count -gt 0) {

        # Nach ClickY sortieren
        $sortedHits   = $hits | Sort-Object ClickY
        $filteredHits = @()
        $lastClickY   = $null
        $minRowGap    = [int]($config.RowStep / 2)

        foreach ($hit in $sortedHits) {
            if ($lastClickY -eq $null -or
                [math]::Abs($hit.ClickY - $lastClickY) -ge $minRowGap) {

                $filteredHits += $hit
                $lastClickY = $hit.ClickY
            }
        }

        return $filteredHits
    }

    return @()
}

# --- Referenzfarbe fuer GemSymbol & ItemTypes ---------------------------------

# --- ItemTypes aus SymbolFolder aufbauen -------------------------------------

$script:ItemTypes = @()

$itemDefs = @(
    @{ Name = "Gem";   File = "GemSymbol.png";   Tolerance = $config.ItemPolicies.Gem.Tolerance   },
    @{ Name = "Beer";  File = "BeerSymbol.png";  Tolerance = $config.ItemPolicies.Beer.Tolerance  },
    @{ Name = "Mulch"; File = "MulchSymbol.png"; Tolerance = $config.ItemPolicies.Mulch.Tolerance },
    @{ Name = "Cheese"; File = "CheeseSymbol.png"; Tolerance = $config.ItemPolicies.Cheese.Tolerance },
    @{ Name = "GoldLeaf"; File = "GoldLeafSymbol.png"; Tolerance = $config.ItemPolicies.GoldLeaf.Tolerance },
    @{ Name = "Borb"; File = "BorbSymbol.png"; Tolerance = $config.ItemPolicies.Borb.Tolerance }
)

foreach ($def in $itemDefs) {
    Add-ItemTypeFromSymbol -Name      $def.Name `
                           -FileName  $def.File `
                           -Tolerance $def.Tolerance
}

# --- Globale Hotkeys registrieren -------------------------------------------

$okF8 = [HotKey]::RegisterHotKey([IntPtr]::Zero, 1,
                                 [HotKey]::MOD_NONE, [HotKey]::VK_F8)
$okF9 = [HotKey]::RegisterHotKey([IntPtr]::Zero, 2,
                                 [HotKey]::MOD_NONE, [HotKey]::VK_F9)

if (-not $okF8 -or -not $okF9) {
    throw "Konnte F8/F9 nicht als globale Hotkeys registrieren."
}

# --- Window Size Pruefung ----------------------------------------------------

$rect = Get-GameWindowRect
if (-not $rect) {
    Write-Log "game.exe window not found – aborting." "ERROR"
    return
}

$winWidth  = $rect.Right  - $rect.Left
$winHeight = $rect.Bottom - $rect.Top

$scaleX = $winWidth  / $config.BaseWindowWidth
$scaleY = $winHeight / $config.BaseWindowHeight
$tol    = $config.WindowSizeTolerance

if ( [math]::Abs($scaleX - 1.0) -gt $tol -or
     [math]::Abs($scaleY - 1.0) -gt $tol ) {

    Write-Log ("Fenstergroeße {0}x{1} passt nicht zur Referenz {2}x{3} – Gem-Stats werden deaktiviert." -f `
        $winWidth, $winHeight, $config.BaseWindowWidth, $config.BaseWindowHeight) "HINT"

    $config.EnableGemStats = $false
}
else {
    Write-Log ("Fenstergroeße {0}x{1} innerhalb Toleranz zur Referenz {2}x{3} – Gem-Stats aktiv." -f `
        $winWidth, $winHeight, $config.BaseWindowWidth, $config.BaseWindowHeight) "INFO"

    $config.EnableGemStats = $true
}

# --- Steuerung / Status ------------------------------------------------------

Write-Log "Globale Hotkeys: F8 = Start/Stop | F9 = Beenden." "HINT"
Write-Log ("GetGemNumberSampleMode={0}" -f $config.GetGemNumberSampleMode) "STATS"
$running = $false
$exit    = $false
$script:JustStarted = $false


# --- OCR-Status beim Start anzeigen ------------------------------------------

if (Get-Command -Name Get-OCRStats -ErrorAction SilentlyContinue) {
    $ocrStats = Get-OCRStats
    if ($ocrStats.TesseractAvailable) {
        Write-Host "✓ OCR-System initialisiert: Tesseract verfuegbar" -ForegroundColor Green
    } else {
        Write-Host "⚠ OCR-System: Tesseract NICHT gefunden unter $($ocrStats.TesseractPath)" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠ OCR-Modul nicht geladen" -ForegroundColor Yellow
}


# --- Hauptschleife -----------------------------------------------------------

while ($true) {

    # Hotkey-Events auslesen
    $hotKeyMessage = New-Object HotKey+MSG

    while ([HotKey]::PeekMessage([ref]$hotKeyMessage, [IntPtr]::Zero,
                                 [HotKey]::WM_HOTKEY, [HotKey]::WM_HOTKEY,
                                 [HotKey]::PM_REMOVE)) {

        if ($hotKeyMessage.message -eq [HotKey]::WM_HOTKEY) {
            $hotkeyId = $hotKeyMessage.wParam.ToInt32()

            switch ($hotkeyId) {

                1 { # F8: Start/Stop
                    $running = -not $running
                    if ($running) {
                        $stats.LastResumeTime = Get-Date
                        $script:JustStarted   = $true
                        Write-Log "Automation gestartet (F8)." "INFO"
                    }
                    else {
                        Write-Log "Automation pausiert (F8)." "INFO"
                    }
                }

                2 { # F9: Exit
                    $exit = $true
                }
            }
        }
    }

    # Exit-Handling
    if ($exit) {
        Write-Host ""
        foreach ($line in (Show-StatsBlock -Title "Final")) {
            Write-Host $line
        }

        Write-Log "Script per F9 beendet." "INFO"
        break
    }

    # Pausiert: CPU schonen
    if (-not $running) {
        Export-GUIStats -BotIsRunning $false
        Start-Sleep -Milliseconds 50
        continue
    }

    # Fenster finden
    $gameWindowRect = Get-GameWindowRect
    if (-not $gameWindowRect) {
        Write-Log "game.exe Fenster nicht gefunden – pausiert." "INFO"

        Start-Sleep -Seconds 1
        continue
    }
    $windowWidth  = $gameWindowRect.Right  - $gameWindowRect.Left
    $windowHeight = $gameWindowRect.Bottom - $gameWindowRect.Top

    # Y-Offset fuer Start-Button
    if ($config.StartOffsetRel -eq $null) {
        $startOffsetPixels = $config.StartYOffset
    }
    else {
        $startOffsetPixels = [int]($config.StartOffsetRel * $windowHeight)
    }

    # Suchbereich und UI-Elemente fensterrelativ berechnen
    $searchLeft   = [int]($gameWindowRect.Left + $config.SearchLeftRel   * $windowWidth)
    $searchTop    = [int]($gameWindowRect.Top  + $config.SearchTopRel    * $windowHeight)
    $searchRight  = [int]($gameWindowRect.Left + $config.SearchRightRel  * $windowWidth)
    $searchBottom = [int]($gameWindowRect.Top  + $config.SearchBottomRel * $windowHeight)

    $searchWidth  = $searchRight  - $searchLeft
    $searchHeight = $searchBottom - $searchTop

    # Sehr spammy, bei Be4darf einkommentieren
    #Write-Log ("SearchRect: L={0} T={1} R={2} B={3} (W={4}, H={5})" -f `
    #           $searchLeft, $searchTop, $searchRight, $searchBottom, `
    #           $searchWidth, $searchHeight) "DEBUG"

    $startButtonX = [int]($gameWindowRect.Left + $config.StartClickXRel * $windowWidth)

    $collectButtonX = [int]($gameWindowRect.Left + $config.CollectXRel * $windowWidth)
    $collectButtonY = [int]($gameWindowRect.Top  + $config.CollectYRel * $windowHeight)
    $refreshButtonX = [int]($gameWindowRect.Left + $config.RefreshXRel * $windowWidth)
    $refreshButtonY = [int]($gameWindowRect.Top  + $config.RefreshYRel * $windowHeight)

    $progressCenterX = [int]($gameWindowRect.Left + $config.ProgressCenterXRel * $windowWidth)

    # Zu Debugzwecken einmalig den Suchbereich als PNG speichern
    Save-SearchAreaSnapshot -SearchLeft $searchLeft -SearchTop $searchTop `
                            -SearchRight $searchRight -SearchBottom $searchBottom

    # Nach Start des Scripts einmalig Collect+Refresh, um alles zu resyncen
    if ($script:JustStarted) {
        Write-Log "Initialer Collect+Refresh nach Start." "INFO"
        Invoke-CollectRefresh -CollectX $collectButtonX -CollectY $collectButtonY `
                              -RefreshX $refreshButtonX -RefreshY $refreshButtonY
        $script:JustStarted = $false
        continue
    }

    # Symbole suchen (ein Durchlauf, mehrere Item-Typen)
    $symbolHits = Find-SymbolHits -ItemTypes $script:ItemTypes `
                                  -SearchLeft $searchLeft -SearchTop $searchTop `
                                  -SearchRight $searchRight -SearchBottom $searchBottom `
                                  -StartOffsetPixels $startOffsetPixels


    if ($symbolHits.Count -eq 0) {
        Write-Log "Kein Symbol gefunden -> nur Refresh." "INFO"
        Update-StatsDisplay -GemRows 0 -ActiveSlots 0
        Invoke-RefreshOnly -RefreshX $refreshButtonX -RefreshY $refreshButtonY
        continue
    }

    $startedThisRound = $false
    $activeSlotCount  = 0

    # Pro Treffer pruefen: laeuft Slot schon, ist Start-Button enabled
    # UND je nach Item-Typ unterschiedlich handeln
    foreach ($hit in $symbolHits) {

        # 1) Item-Typ ermitteln (Fallback = "Gem", falls kein Item-Feld vorhanden)
        $itemName = if ($hit.PSObject.Properties.Match("Item").Count -gt 0) {
            $hit.Item
        } else {
            "Gem"
        }
		
		# 2) Skip weitere Checks wenn Item nicht gehandelt werden soll
		if (-not (Should-StartItemTrade -ItemName $itemName)) {
			Write-Log ( "Y={0}: Policy -> Item={1} wird nicht gestartet." -f $hit.ClickY, $itemName) "INFO"
			continue
		}
			
        # 3)) Laeuft der Slot bereits?
        $slotIsRunning = Test-SlotRunning -ClickY $hit.ClickY -ProgressCenterX $progressCenterX
        if ($slotIsRunning) {
            $activeSlotCount++
            continue
        }
		
		# DEAKTIVIERT, nicht mehr notwendig mit OCR, bei Bedarf aktivierbar, sonst unnötig
        <# 2) Samplemodus: nur Gem-Wert ermitteln + Screenshot, KEIN Trade
        if ($config.GetGemNumberSampleMode -eq 1) {
            if ($itemName -eq "Gem") {
                $preGemValue, $brightCount, $bestScore, $secondBest = `
                    Get-GemValue -FoundX $hit.FoundX -FoundY $hit.FoundY

                if ($preGemValue -eq $null -or $preGemValue -le 0) {
                    Write-Log ("Y={0}: SampleMode -> keine valide Zahl erkannt (GemValue=null/<=0)." -f `
                               $hit.ClickY) "STATS"
                }
            }
            # Bei Beer/Mulch/etc. im SampleMode aktuell nichts tun
            continue
        }#>

        # Ab hier: normaler Betriebsmodus (SampleMode=0)

        # 4) Start-Button auf "disabled" pruefen (gemeinsam fuer alle Item-Typen)		
		Write-Log ("Test-SlotRunning für Item {0} mit -StartClickX {1} -ClickY {2}" -f $hit.Item, $startButtonX, $hit.ClickY) "DEBUG"
        if (-not (Test-StartButtonEnabled -StartClickX $startButtonX -ClickY $hit.ClickY)) {
            Write-Log ("Y={0}: Start-Button erscheint disabled -> Slot wird uebersprungen." -f $hit.ClickY) "INFO"
            continue
        }

        # 5) Item-spezifische Behandlung mit Policy
        if ($itemName -eq "Gem") {

            # Gem: Wert ermitteln und plausibilisieren
            $preGemValue, $brightCount, $bestScore, $secondBest = `
                Get-GemValue -FoundX $hit.FoundX -FoundY $hit.FoundY

            if ($preGemValue -eq $null -or $preGemValue -le 0) {
                Write-Log ("Y={0}: Kein plausibler Gem-Wert im Suchbereich -> Slot wird uebersprungen." -f $hit.ClickY) "INFO"
                continue
            }

            # zentrale Policy entscheidet, ob dieser Gem-Trade gestartet werden darf
            if (-not (Should-StartItemTrade -ItemName "Gem" -PreGemValue $preGemValue)) {
                Write-Log ("Y={0}: Policy -> Gem-Trade mit Value={1} wird nicht gestartet." -f `
                           $hit.ClickY, $preGemValue) "INFO"
                continue
            }

            Write-Log ("Y={0}: Slot nicht laufend, Gem ok, Button ok -> versuche Trade zu starten." -f $hit.ClickY) "DEBUG"

            $tradeStarted = Try-StartTrade -ClickY          $hit.ClickY `
                                           -StartClickX     $startButtonX `
                                           -ProgressCenterX $progressCenterX `
                                           -FoundY          $hit.FoundY `
                                           -WinHeight       $windowHeight `
                                           -FoundX          $hit.FoundX `
                                           -PreGemValue     $preGemValue

            if ($tradeStarted) {
                # ZEILE GELÖSCHT: $activeSlotCount++
                $startedThisRound = $true

                # Gem Statistik aktualisieren bei erfolgreichem Try-StartTrade
                if ($PreGemValue -ne $null -and $PreGemValue -gt 0) {
                    $stats.GemTrades++
                    $stats.GemsTotal += $PreGemValue

                    switch ($PreGemValue) {
                        1 { $stats.GemValue1Count++ }
                        2 { $stats.GemValue2Count++ }
                        3 { $stats.GemValue3Count++ }
                        4 { $stats.GemValue4Count++ }
                        5 { $stats.GemValue5Count++ }
                        6 { $stats.GemValue6Count++ }
                        7 { $stats.GemValue7Count++ }
                        8 { $stats.GemValue8Count++ }
                        9 { $stats.GemValue9Count++ }
                        10 { $stats.GemValue10Count++ }
                        11 { $stats.GemValue11Count++ }
                        12 { $stats.GemValue12Count++ }
                        13 { $stats.GemValue13Count++ }
                        14 { $stats.GemValue14Count++ }
                        15 { $stats.GemValue15Count++ }
                        16 { $stats.GemValue16Count++ }
                        17 { $stats.GemValue17Count++ }
                        18 { $stats.GemValue18Count++ }
                        19 { $stats.GemValue19Count++ }
                        20 { $stats.GemValue20Count++ }
                    }
                }
            }
        }
		else {
            # Nicht-Gem-Items (Beer, Mulch, Cheese, GoldLeaf, CosmicLeaf)

            if ($itemName -eq "Beer") {
                $isBigBeerValue = Test-BeerValueIsBig -FoundX $hit.FoundX -FoundY $hit.FoundY

                if (-not $isBigBeerValue) {
                    Write-Log ( "Y={0}: Beer-Wert sieht klein aus (z.B. '1') -> Slot wird uebersprungen." -f `
                               $hit.ClickY) "INFO"
                    continue
                }
            }

            Write-Log ( "Y={0}: Item={1}, Slot frei, Button ok -> versuche Trade zu starten." -f `
                       $hit.ClickY, $itemName) "INFO"

            $tradeStarted = Try-StartTrade -ClickY          $hit.ClickY `
                                           -StartClickX     $startButtonX `
                                           -ProgressCenterX $progressCenterX `
                                           -FoundY          $hit.FoundY `
                                           -WinHeight       $windowHeight `
                                           -FoundX          $hit.FoundX `
                                           -PreGemValue     $null

            if ($tradeStarted) {
                # ZEILE GELÖSCHT: $activeSlotCount++
                $startedThisRound = $true

                # Item-spezifischen Trade-Zaehler erhoehen, falls vorhanden
                $tradePropName = ($itemName + "Trades")
                $prop          = $stats.PSObject.Properties[$tradePropName]
                if ($prop) {
                    $stats.$tradePropName++
                }
            }
        }
    }

    # Live-Stats aktualisieren (Slots/GemRows)
    Update-StatsDisplay -GemRows $symbolHits.Count -ActiveSlots $activeSlotCount

    # Globale Entscheidung: Collect+Refresh oder nur Refresh?
    $now          = Get-Date
    $secondsSinceLastCollect = ($now - $stats.LastCollectTime).TotalSeconds

    if ($secondsSinceLastCollect -ge $config.CollectIntervalSeconds) {
        Write-Log ("Global: {0:N1}s seit letztem Collect -> Collect+Refresh." -f $secondsSinceLastCollect) "INFO"
        Invoke-CollectRefresh -CollectX $collectButtonX -CollectY $collectButtonY `
                              -RefreshX $refreshButtonX -RefreshY $refreshButtonY
    }
    else {
        if ($activeSlotCount -lt $config.MaxTrades) {
            Write-Log "Global: Slots nicht voll -> nur Refresh zum schnellen Nachladen." "INFO"
            Invoke-RefreshOnly -RefreshX $refreshButtonX -RefreshY $refreshButtonY
        }
    }
	
    # --- GUI Integration: Stats exportieren & Config laden ---
    $script:statsExportCounter++
    if ($script:statsExportCounter -ge 2) {
        Export-GUIStats -BotIsRunning $running
        $script:statsExportCounter = 0
    }
    
    if (((Get-Date) - $script:lastConfigCheck).TotalSeconds -gt 5) {
        Load-GUIConfig
        $script:lastConfigCheck = Get-Date
    }
}

# --- Aufraeumen ----------------------------------------------------------------

if ('HotKey' -as [type]) {

    $methods = [HotKey].GetMethods() | Where-Object { $_.Name -eq 'UnregisterHotKey' }

    foreach ($id in 1,2) {

        $called = $false

        foreach ($m in $methods) {
            $paramCount = $m.GetParameters().Count

            if ($paramCount -eq 2) {
                [HotKey]::UnregisterHotKey([IntPtr]::Zero, $id) | Out-Null
                $called = $true
                break
            }
            elseif ($paramCount -eq 4) {
                [HotKey]::UnregisterHotKey([IntPtr]::Zero, $id, 0, 0) | Out-Null
                $called = $true
                break
            }
        }

        if (-not $called) {
            Write-Log ("Konnte UnregisterHotKey fuer ID {0} nicht aufrufen (keine passende ueberladung)." -f $id) "INFO"
        }
    }
}

if ($script:GemValueTemplates) {
    foreach ($bmp in $script:GemValueTemplates.Values) {
        $bmp.Dispose()
    }
}


