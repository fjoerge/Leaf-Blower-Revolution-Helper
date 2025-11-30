# TradingGems v4.4 - Quick Fix Cheat Sheet

## ⚡ 4 Fixes in 10 Minuten

---

## ✂️ FIX 1: Active Slots - 2 Zeilen löschen

**Datei:** TradingGems.v4.3.ps1

### Stelle 1: Zeile ~1960
**Suchen:** `if ($tradeStarted) {` (erste Stelle)

**LÖSCHEN:** Zeile mit `$activeSlotCount++` direkt nach `if ($tradeStarted) {`

### Stelle 2: Zeile ~2003
**Suchen:** `if ($tradeStarted) {` (zweite Stelle)

**LÖSCHEN:** Zeile mit `$activeSlotCount++` direkt nach `if ($tradeStarted) {`

---

## ➕ FIX 2: LogMode Live-Update - 1 Block einfügen

**Datei:** TradingGems.v4.3.ps1
**Zeile:** ~520 (nach `RefreshIntervalRowsFull`)

**EINFÜGEN:**
```powershell
        # LogMode Live-Update (v4.4)
        if ($guiConfig.LogMode -and $guiConfig.LogMode -ne $config.LogMode) {
            $config.LogMode = $guiConfig.LogMode
            $configChanged = $true
        }
```

---

## ✂️ FIX 3: Debug-Zeile - 1 Zeile löschen

**Datei:** TradingGems.v4.3.ps1
**Zeile:** ~1158

**LÖSCHEN:** `write-host "Line 1158" -ForegroundColor Red`

---

## ➕ FIX 4: Activity Log Toggle - 2 Änderungen

**Datei:** TradingGems-GUI.ps1

### Teil A: Zeile ~48 (Control-Liste)
**HINZUFÜGEN:** `'chkShowActivityLog'` nach `'txtSlotUtilPerHour'`

```powershell
'txtSlotUtilPerHour',
'chkShowActivityLog'  # ← NEU
```

### Teil B: Zeile ~295 (Event Handler)
**EINFÜGEN nach ComboBox Block:**

```powershell
# Activity Log Toggle (v4.4)
$controls['chkShowActivityLog'].Add_Checked({
    $logRow = $window.FindName('LogRow')
    if ($logRow) {
        $logRow.Height = [Double]::NaN
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
```

---

## ✅ Test

1. Bot + GUI neu starten
2. Active Slots zeigt 9/9? ✓
3. LogMode wechseln funktioniert? ✓
4. Keine "Line 1158" Meldung? ✓

---

## 🆘 Bei Fehler

```powershell
# Backup wiederherstellen
Copy-Item "TradingGems.v4.3.BACKUP.ps1" "TradingGems.v4.3.ps1" -Force
Copy-Item "TradingGems-GUI.BACKUP.ps1" "TradingGems-GUI.ps1" -Force
```

---

## 📖 Mehr Details

- **Ausführlich:** MANUAL_FIX_GUIDE_v4.4.md
- **Changelog:** VERSION_4.4_CHANGELOG.md
- **Übersicht:** README_v4.4.md

---

**Geschätzte Zeit:** 10 Minuten | **Schwierigkeit:** Einfach
