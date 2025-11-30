# TradingGems v4.4 - Manuelle Fix-Anleitung

## ⚡ SCHNELLSTART - Die 4 wichtigsten Fixes

Diese Anleitung zeigt dir **genau**, wo du was ändern musst. Jeder Fix ist in 2-5 Minuten erledigt.

---

## 🔧 FIX 1: Active Slots Zählung korrigieren

### Problem
Bot zeigt 7/9 oder 8/9 Slots, obwohl ingame 9/9 laufen

### Lösung
**Datei:** `TradingGems.v4.3.ps1`

#### Änderung 1 von 2 - Gem Trade Block

**Zeile suchen (~1944-1970):**
```powershell
            if ($tradeStarted) {
                $activeSlotCount++        # ❌ DIESE ZEILE LÖSCHEN!
                $startedThisRound = $true

                # Gem Statistik aktualisieren bei erfolgreichem Try-StartTrade
                if ($PreGemValue -ne $null -and $PreGemValue -gt 0) {
                    $stats.GemTrades++
```

**Ändern zu:**
```powershell
            if ($tradeStarted) {
                # ZEILE GELÖSCHT: $activeSlotCount++
                $startedThisRound = $true

                # Gem Statistik aktualisieren bei erfolgreichem Try-StartTrade
                if ($PreGemValue -ne $null -and $PreGemValue -gt 0) {
                    $stats.GemTrades++
```

**Wie finden:** 
- Strg+F → Suche nach: `if ($tradeStarted) {`
- Erste Stelle im Code (ca. Zeile 1960)
- Prüfe dass darüber steht: `Try-StartTrade -ClickY`

---

#### Änderung 2 von 2 - Item Trade Block

**Zeile suchen (~1990-2010):**
```powershell
            if ($tradeStarted) {
                $activeSlotCount++        # ❌ DIESE ZEILE LÖSCHEN!
                $startedThisRound = $true

                # Item-spezifischen Trade-Zähler erhöhen, falls vorhanden
                $tradePropName = ($itemName + "Trades")
```

**Ändern zu:**
```powershell
            if ($tradeStarted) {
                # ZEILE GELÖSCHT: $activeSlotCount++
                $startedThisRound = $true

                # Item-spezifischen Trade-Zähler erhöhen, falls vorhanden
                $tradePropName = ($itemName + "Trades")
```

**Wie finden:**
- Strg+F → Suche nach: `if ($tradeStarted) {`
- **Zweite** Stelle im Code (ca. Zeile 2003)
- Prüfe dass darüber steht: `Try-StartTrade -ClickY` (nochmal)

---

### ✅ Test für Fix 1

1. Bot starten
2. 9 Trades laufen lassen  
3. GUI prüfen: Zeigt "9/9" bei Active Slots? → ✅ Fix funktioniert
4. Kein häufiges Refreshing mehr? → ✅ Fix funktioniert

---

## 📝 FIX 2: LogMode in GUI wirksam machen

### Problem
LogMode in GUI ändern hat keine Wirkung

### Lösung
**Datei:** `TradingGems.v4.3.ps1`

**Zeile suchen (~515-520):**
```powershell
        if ($guiConfig.RefreshIntervalRowsFull -and $guiConfig.RefreshIntervalRowsFull -ne $config.RefreshIntervalRowsFull) {
            $config.RefreshIntervalRowsFull = $guiConfig.RefreshIntervalRowsFull
            $configChanged = $true
        }
        
        if ($configChanged) {
```

**Einfügen VOR `if ($configChanged)` :**
```powershell
        if ($guiConfig.RefreshIntervalRowsFull -and $guiConfig.RefreshIntervalRowsFull -ne $config.RefreshIntervalRowsFull) {
            $config.RefreshIntervalRowsFull = $guiConfig.RefreshIntervalRowsFull
            $configChanged = $true
        }
        
        # === NEU: LogMode Live-Update (v4.4) ===
        if ($guiConfig.LogMode -and $guiConfig.LogMode -ne $config.LogMode) {
            $config.LogMode = $guiConfig.LogMode
            $configChanged = $true
        }
        # === ENDE NEU ===
        
        if ($configChanged) {
```

**Wie finden:**
- Strg+F → Suche nach: `function Load-GUIConfig {`
- Scroll nach unten bis: `RefreshIntervalRowsFull`
- Neuen Block darunter einfügen

---

### ✅ Test für Fix 2

1. Bot laufen lassen (mit LogMode = "STATS")
2. GUI öffnen → LogMode auf "DEBUG" stellen
3. Nach 5-10 Sekunden: Bot Console zeigt Debug-Meldungen? → ✅ Fix funktioniert
4. Zurück auf "STATS" stellen
5. Nach 5-10 Sekunden: Nur noch Stats? → ✅ Fix funktioniert

---

## 🧹 FIX 3: Debug-Zeile entfernen

### Problem
Im Code steht eine Test-Zeile "Line 1158" die nicht da sein sollte

### Lösung
**Datei:** `TradingGems.v4.3.ps1`

**Zeile suchen (~1158):**
```powershell
        write-host "Line 1158" -ForegroundColor Red    # ❌ DIESE ZEILE LÖSCHEN!
        return @($null, $brightPixelCount, 999)
```

**Ändern zu:**
```powershell
        # Debug-Zeile entfernt
        return @($null, $brightPixelCount, 999)
```

**Wie finden:**
- Strg+F → Suche nach: `Line 1158`
- Zeile löschen oder auskommentieren

---

## 👁️ FIX 4: Activity Log ausblendbar machen

### Problem
Activity Log immer sichtbar, keine Option zum Ausblenden

### Lösung
Dieser Fix erfordert Änderungen an **2 Dateien**

---

### Teil 4A: GUI Script - Controls hinzufügen

**Datei:** `TradingGems-GUI.ps1`

**Zeile suchen (~42-48):**
```powershell
'txtGemPercent','txtBeerPercent','txtMulchPercent','txtCheesePercent',
'txtGemTotal','txtBeerTotal','txtMulchTotal','txtCheeseTotal',
'logScrollViewer',
'btnGemMinUp','btnGemMinDown',
'txtSlotUtilPerHour'
) | ForEach-Object {
$controls[$_] = $window.FindName($_)
}
```

**Ändern zu:**
```powershell
'txtGemPercent','txtBeerPercent','txtMulchPercent','txtCheesePercent',
'txtGemTotal','txtBeerTotal','txtMulchTotal','txtCheeseTotal',
'logScrollViewer',
'btnGemMinUp','btnGemMinDown',
'txtSlotUtilPerHour',
'chkShowActivityLog'    # ← NEU HINZUGEFÜGT
) | ForEach-Object {
$controls[$_] = $window.FindName($_)
}
```

---

### Teil 4B: GUI Script - Event Handler hinzufügen

**Datei:** `TradingGems-GUI.ps1`

**Zeile suchen (~290-295):**
```powershell
# Auto-Save: ComboBoxen
@('cmbLogMode','cmbScreenshotMode') | ForEach-Object {
$controls[$_].Add_SelectionChanged({ Save-Configuration -ShowLog $false })
}

# Timer tick
$script:timer.Add_Tick({ Update-Statistics })
```

**Einfügen NACH dem ComboBox Block, VOR "# Timer tick":**
```powershell
# Auto-Save: ComboBoxen
@('cmbLogMode','cmbScreenshotMode') | ForEach-Object {
$controls[$_].Add_SelectionChanged({ Save-Configuration -ShowLog $false })
}

# === NEU: Activity Log Toggle (v4.4) ===
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
# === ENDE NEU ===

# Timer tick
$script:timer.Add_Tick({ Update-Statistics })
```

---

### Teil 4C: GUI Script - XAML Markup (OPTIONAL - wenn du XAML-Editor hast)

**Falls du die GUI XAML bearbeiten kannst**, füge eine CheckBox hinzu:

**Im XAML, bei den anderen CheckBoxen/Controls:**
```xml
<CheckBox x:Name="chkShowActivityLog" Content="Show Activity Log" IsChecked="True" Margin="5"/>
```

**Und das Log Row:**
```xml
<Grid.RowDefinitions>
    <!-- ... andere Rows ... -->
    <RowDefinition Height="Auto" x:Name="LogRow"/>  <!-- ← Name="LogRow" hinzufügen -->
</Grid.RowDefinitions>
```

**HINWEIS:** Wenn du das XAML nicht hast oder nicht bearbeiten kannst, funktioniert der Fix trotzdem, aber die CheckBox erscheint nicht in der GUI. Der Code ist aber vorbereitet für später.

---

### ✅ Test für Fix 4

1. GUI neu starten
2. Suche nach Checkbox "Show Activity Log" (falls XAML geändert)
3. Checkbox deaktivieren → Log verschwindet? → ✅ Fix funktioniert
4. Checkbox aktivieren → Log erscheint wieder? → ✅ Fix funktioniert

---

## 📦 Zusammenfassung - Änderungen pro Datei

### TradingGems.v4.3.ps1 (4 Änderungen)
1. ✂️ Zeile ~1960: `$activeSlotCount++` entfernen (Gem Block)
2. ✂️ Zeile ~2003: `$activeSlotCount++` entfernen (Item Block)
3. ➕ Zeile ~520: LogMode Live-Update einfügen
4. ✂️ Zeile ~1158: Debug-Zeile "Line 1158" entfernen

### TradingGems-GUI.ps1 (2 Änderungen)
1. ➕ Zeile ~48: `'chkShowActivityLog'` zur Control-Liste hinzufügen
2. ➕ Zeile ~295: Event Handler für Activity Log Toggle einfügen

---

## ⚡ Quick-Copy Code-Blöcke

### Code-Block 1: LogMode Live-Update
```powershell
        # === NEU: LogMode Live-Update (v4.4) ===
        if ($guiConfig.LogMode -and $guiConfig.LogMode -ne $config.LogMode) {
            $config.LogMode = $guiConfig.LogMode
            $configChanged = $true
        }
        # === ENDE NEU ===
```

### Code-Block 2: Activity Log Toggle Event
```powershell
# === NEU: Activity Log Toggle (v4.4) ===
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
# === ENDE NEU ===
```

---

## 🔍 Fehlerbehebung

### "Kann Zeile nicht finden"
- Nutze Strg+F und kopiere den Suchtext exakt
- Achte auf Leerzeichen und Einrückungen
- Prüfe ob du die richtige Datei offen hast

### "Code funktioniert nicht nach Änderung"
1. Speichere alle Dateien (Strg+S)
2. Schließe Bot komplett
3. Schließe GUI komplett
4. Starte `START_HERE.bat` neu

### "Fehler beim Start"
- Prüfe ob alle `}` und `{` korrekt sind
- Prüfe ob du versehentlich andere Zeilen gelöscht hast
- Restore aus Backup (falls vorhanden)

---

## ✅ Vollständige Test-Checkliste

Nach allen Fixes:

- [ ] Fix 1: Active Slots zeigt 9/9 korrekt
- [ ] Fix 1: Kein unnötiges Refreshing mehr
- [ ] Fix 2: LogMode Wechsel funktioniert in GUI
- [ ] Fix 3: Keine "Line 1158" Meldung mehr
- [ ] Fix 4: Activity Log ausblendbar (falls XAML geändert)
- [ ] Bot startet ohne Fehler
- [ ] GUI startet ohne Fehler
- [ ] Alle Items werden weiterhin erkannt
- [ ] Trading funktioniert wie vorher

---

## 📞 Bei Problemen

Falls etwas nicht klappt:

1. **Backup wiederherstellen**
   - Kopiere alte Dateien zurück
   
2. **Screenshots machen**
   - Von Fehlermeldungen
   - Von der geänderten Code-Stelle
   
3. **LogMode auf DEBUG stellen**
   - Mehr Details in der Console
   
4. **Beschreibe Problem genau**
   - Welcher Fix?
   - Welche Fehlermeldung?
   - Was hast du geändert?

---

## 🎯 Nächste Schritte nach Fixes

1. **Version benennen**
   ```powershell
   # Ändere in beiden Dateien den Version-Kommentar:
   # Von: "Version 4.2" oder "v1.4"
   # Zu:  "Version 4.4" oder "v1.5"
   ```

2. **Start-Script anpassen**
   ```powershell
   # In Start-TradingGems.ps1:
   # Ändere: "TradingGems.v4.3.ps1"
   # Zu:     "TradingGems.v4.4.ps1"
   ```

3. **Teste neues Item hinzufügen**
   ```powershell
   # Nutze das neue Add-NewItem.ps1 Script
   .\Add-NewItem.ps1
   ```

---

**Version:** 4.4 Manual Fix Guide
**Erstellt:** 21.11.2024
**Geschätzte Zeit:** 10-15 Minuten für alle 4 Fixes
