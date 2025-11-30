# TradingGems Version 4.4 - Changelog

## Datum: 21.11.2024

---

## 🔧 PROBLEM 1: Active Slots Zählung korrigiert

### Symptom
- Bot zeigt 7/9 oder 8/9 Slots, obwohl ingame 9/9 laufen
- Dadurch ständiges unnötiges Refreshing

### Ursache
In der Hauptschleife (Zeile ~1935):
```powershell
# ALT - FALSCH:
foreach ($hit in $symbolHits) {
    $slotIsRunning = Test-SlotRunning -ClickY $hit.ClickY -ProgressCenterX $progressCenterX
    if ($slotIsRunning) {
        $activeSlotCount++    # ✅ OK: Bereits laufende Slots zählen
        continue
    }
    
    # ... Trade starten ...
    if ($tradeStarted) {
        $activeSlotCount++    # ❌ FEHLER: Hier NOCHMAL zählen!
        $startedThisRound = $true
    }
}
```

Das Problem: `$activeSlotCount` wurde für **bereits laufende** Slots UND **neu gestartete** Slots erhöht. Dadurch wurden neu gestartete Slots doppelt gezählt!

### Fix in v4.4
```powershell
# NEU - KORREKT:
foreach ($hit in $symbolHits) {
    $slotIsRunning = Test-SlotRunning -ClickY $hit.ClickY -ProgressCenterX $progressCenterX
    if ($slotIsRunning) {
        $activeSlotCount++    # ✅ Zählt bereits laufende
        continue
    }
    
    # ... Trade starten ...
    if ($tradeStarted) {
        # ✅ KEIN $activeSlotCount++ mehr hier!
        # Slot wurde bereits am Anfang der Schleife gezählt
        $startedThisRound = $true
    }
}
```

### Korrektur Details
**Geänderte Zeilen:**
- Zeile 1960: `$activeSlotCount++` entfernt (nach Gem-Trade-Start)
- Zeile 2003: `$activeSlotCount++` entfernt (nach Item-Trade-Start)

**Logik:**
1. Slot läuft bereits? → Zählen + Continue
2. Slot wird neu gestartet? → **NICHT** nochmal zählen (wird beim nächsten Loop-Durchlauf als "läuft bereits" erkannt)

### Ergebnis
✅ Active Slots Zählung jetzt korrekt (9/9 wenn alle Slots voll)
✅ Kein unnötiges Refreshing mehr

---

## 📝 PROBLEM 2: Neues Item-Hinzufügen vereinfacht

### Vorher
Manuelles Ändern an 6+ Stellen:
1. `$config.ItemPolicies` ergänzen
2. `$stats` Properties hinzufügen
3. `Add-ItemTypeFromSymbol` Aufruf
4. GUI XAML bearbeiten
5. GUI Controls registrieren
6. TradeConfig.json manuell anpassen

### Neu in v4.4
**Script: `Add-NewItem.ps1`**

Vollautomatische Integration eines neuen Items mit nur 2 Eingaben:
```powershell
.\Add-NewItem.ps1
# Eingabe 1: Item-Name (z.B. "Apple")
# Eingabe 2: Symbol-Datei (z.B. "AppleSymbol.png")
```

Das Script macht automatisch:
- ✅ Referenzfarbe aus Symbol auslesen (Pixel-Mitte)
- ✅ ItemPolicy in TradingGems.v4.4.ps1 einfügen
- ✅ Stats-Counter (`AppleTrades`) hinzufügen
- ✅ Add-ItemTypeFromSymbol Aufruf generieren
- ✅ GUI Checkbox + Progressbar + Labels hinzufügen
- ✅ TradeConfig.json aktualisieren
- ✅ Backups aller geänderten Dateien anlegen

### Nutzung
```powershell
# 1. Symbol-Datei nach pictures\ItemSymbols\ kopieren
Copy-Item "AppleSymbol.png" -Destination "pictures\ItemSymbols\"

# 2. Script ausführen
.\Add-NewItem.ps1

# 3. Fertig! Bot und GUI neu starten
```

---

## 🎛️ PROBLEM 3: LogMode in GUI jetzt wirksam

### Symptom
- LogMode in GUI ändern → keine Wirkung
- Bot nutzt immer den im Script hart codierten Wert

### Ursache
`Load-GUIConfig` (Zeile ~474) hat `LogMode` nicht geladen:
```powershell
# ALT:
function Load-GUIConfig {
    # ... lädt ItemPolicies ...
    # ... lädt CollectInterval, MaxTrades, RefreshInterval ...
    # ❌ LogMode wurde NICHT geladen!
}
```

### Fix in v4.4
```powershell
# NEU in Load-GUIConfig (Zeile ~520):
if ($guiConfig.LogMode -and $guiConfig.LogMode -ne $config.LogMode) {
    $config.LogMode = $guiConfig.LogMode
    $configChanged = $true
}
```

### Ergebnis
✅ LogMode-Wechsel in GUI funktioniert live (innerhalb 5 Sekunden übernommen)
✅ Keine Bot-Neustart mehr nötig für LogMode-Änderungen

---

## 👁️ PROBLEM 4: Activity Log ausblendbar

### Neu in v4.4
**Checkbox "Show Activity Log"** in der GUI

### Funktion
- ☑️ **Checked**: Activity Log Panel sichtbar (Standard)
- ☐ **Unchecked**: Activity Log komplett ausgeblendet
- 📏 Fensterhöhe passt sich automatisch an

### Implementation
**GUI Änderungen:**
1. XAML: Grid Row für Log mit `x:Name="LogRow"`
2. Checkbox `chkShowActivityLog` (Standard: Checked)
3. Event-Handler: Toggle `LogRow.Height` zwischen `Auto` und `0`

**Vorteile:**
- 🔲 Kompaktere GUI möglich (ca. 200px weniger Höhe)
- 🚀 Bessere Performance bei ausgeblendetem Log
- 📊 Mehr Platz für Statistiken

### Code
```powershell
$controls['chkShowActivityLog'].Add_Checked({
    $window.FindName('LogRow').Height = [Double]::NaN  # Auto
})

$controls['chkShowActivityLog'].Add_Unchecked({
    $window.FindName('LogRow').Height = 0
})
```

---

## 📦 Weitere Verbesserungen in v4.4

### Kleinere Fixes
- 🐛 Debug-Ausgabe "Line 1158" entfernt (war Testcode)
- 📊 SlotUtilPerHour wird jetzt korrekt aus Stats geladen
- 🎨 GUI: Bessere Fehlerbehandlung bei Stats-Import

### Code-Qualität
- 📝 Kommentare verbessert für bessere Wartbarkeit
- 🧹 Redundante Code-Teile entfernt
- ⚡ Keine Performance-Einbußen durch Fixes

---

## 🚀 Installation v4.4

### Schnellstart
1. **Backup anlegen** (wichtig!)
   ```powershell
   Copy-Item "TradingGems.v4.3.ps1" -Destination "TradingGems.v4.3.BACKUP.ps1"
   Copy-Item "TradingGems-GUI.ps1" -Destination "TradingGems-GUI.v1.4.BACKUP.ps1"
   ```

2. **Neue Dateien kopieren**
   - `TradingGems.v4.4.ps1` → Hauptverzeichnis
   - `TradingGems-GUI.ps1` (updated) → Hauptverzeichnis
   - `Add-NewItem.ps1` → Hauptverzeichnis

3. **Start-Scripts anpassen** (falls nötig)
   ```powershell
   # In Start-TradingGems.ps1:
   # Ändere: TradingGems.v4.3.ps1
   # Zu:     TradingGems.v4.4.ps1
   ```

4. **Bot + GUI neu starten**
   ```powershell
   .\START_HERE.bat
   ```

---

## ✅ Testen der Fixes

### Test 1: Active Slots Zählung
1. Bot starten und 9 Trades laufen lassen
2. **Erwarte:** GUI zeigt "9/9" bei Active Slots
3. **Erwarte:** Kein häufiges Refreshing mehr

### Test 2: LogMode Wechsel
1. GUI: LogMode auf "DEBUG" stellen
2. **Erwarte:** Bot Console zeigt Debug-Meldungen (innerhalb 5 Sek)
3. Zurück auf "STATS" stellen
4. **Erwarte:** Nur noch Stats-Anzeige

### Test 3: Activity Log ausblenden
1. GUI: "Show Activity Log" Checkbox deaktivieren
2. **Erwarte:** Log-Bereich verschwindet, Fenster wird kleiner
3. Checkbox wieder aktivieren
4. **Erwarte:** Log-Bereich erscheint wieder

### Test 4: Neues Item hinzufügen
1. Symbol-Datei vorbereiten (z.B. Test-Item)
2. `.\Add-NewItem.ps1` ausführen
3. **Erwarte:** Keine Fehler, alle Dateien aktualisiert
4. Bot + GUI neu starten
5. **Erwarte:** Neues Item in GUI sichtbar + funktionsfähig

---

## 🔄 Kompatibilität

### Aufwärts-Kompatibel
- ✅ TradeConfig.json von v4.3 wird unterstützt
- ✅ TradeStats.json bleibt kompatibel
- ✅ Alle Symbol-Dateien funktionieren weiter

### Keine Breaking Changes
- ✅ Alle Hotkeys gleich (F8/F9)
- ✅ AHK Scripts unverändert
- ✅ OCR-Modul unverändert
- ✅ Fenster-Koordinaten unverändert

---

## 📞 Support

Bei Problemen:
1. Alte Version wiederherstellen (Backup)
2. Logs prüfen (GUI Activity Log)
3. TradeConfig.json löschen (wird neu erstellt)
4. Issue beschreiben mit:
   - Fehlermeldung
   - Welcher Fix funktioniert nicht
   - LogMode: DEBUG Output

---

## 🎯 Roadmap v4.5 (geplant)

Mögliche zukünftige Features:
- 🔄 Auto-Update Funktion
- 📊 Erweiterte Statistiken (Export als CSV)
- 🎨 GUI Themes (Dark/Light Mode)
- 📱 Statistik-Übersicht als HTML-Dashboard
- 🔔 Benachrichtigungen bei Erreichen von Zielen

---

**Version:** 4.4
**Datum:** 21.11.2024
**Status:** ✅ Stable Release
