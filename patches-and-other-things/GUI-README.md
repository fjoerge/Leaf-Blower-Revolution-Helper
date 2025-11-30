# 🎮 TradingGems Control Center - GUI für deinen Trading Bot

## 📋 Übersicht

Diese GUI-Lösung erweitert dein TradingGems v4.2 Script um eine moderne, benutzerfreundliche Oberfläche zur Steuerung und Überwachung.

## ✨ Features

### 🎛️ Steuerung
- **Start/Stop/Exit Controls** - Komfortable Buttons zusätzlich zu den Hotkeys
- **Hotkey-Integration** - F8 und F9 funktionieren weiterhin wie gewohnt
- **Live-Status-Anzeige** - Sofort sichtbar ob der Bot läuft oder pausiert

### 📊 Statistiken (Live-Updates)
- **Session-Info** - Startzeit, Laufzeit, Trades/Stunde
- **Gem-Statistiken** - Gesamt-Gems, Gems/Stunde, Durchschnitt pro Trade
- **Item-Verteilung** - Visuelle Balkendiagramme für alle Items
- **Erfolgsrate** - Start-Attempts und Erfolgsquote
- **High-Value-Trades** - Anteil der wertvollen Gem-Trades (3-6 Gems)

### ⚙️ Konfiguration
- **Item-Policies** - Aktiviere/Deaktiviere einzelne Items (Gem, Beer, Mulch, etc.)
- **Gem Min Value** - Setze Mindest-Gem-Wert zum Starten
- **Intervalle** - Collect-Intervall, Max Trades, Refresh-Intervall
- **Log-Modus** - STATS / INFO / DEBUG
- **Advanced** - Auto-Kalibrierung, Gem-Stats, Screenshot-Mode
- **Config speichern** - Alle Einstellungen werden in `gui-config.json` gespeichert

### 📝 Activity Log
- **Farbcodiertes Logging** - Grün (Erfolg), Gelb (Warnung), Rot (Fehler)
- **Zeitstempel** - Jeder Eintrag mit exakter Uhrzeit
- **Auto-Scroll** - Automatisches Scrollen zu neuesten Einträgen
- **Clear-Funktion** - Log auf Knopfdruck leeren

## 🚀 Installation & Start

### Variante 1: Einfacher Start (Empfohlen)
1. Doppelklick auf **`START_HERE.bat`**
2. Fertig! Bot und GUI starten automatisch

### Variante 2: Manueller Start
1. Öffne PowerShell im Script-Ordner
2. Führe aus: `.\Start-TradingGems.ps1`

### Variante 3: Separate Fenster
1. **Fenster 1 (Bot)**: `.\TradingGems.v4.2.ps1`
2. **Fenster 2 (GUI)**: `.\TradingGems-GUI.ps1`

## 📁 Dateien

```
TradingGems/
├── TradingGems.v4.2.ps1      # Haupt-Bot-Script (unverändert)
├── TradingGems-GUI.ps1        # Neue GUI-Anwendung
├── Start-TradingGems.ps1      # Launcher (startet beides)
├── START_HERE.bat             # Einfacher Doppelklick-Start
├── gui-config.json            # GUI-Konfiguration (wird automatisch erstellt)
├── stats.json                 # Statistik-Daten (vom Bot erstellt)
└── pictures/                  # Deine bestehenden Assets
    └── ItemSymbols/
```

## 🎯 Verwendung

### Erste Schritte

1. **Bot starten**
   - Klicke auf "▶ START (F8)" oder drücke F8
   - Status wechselt zu "RUNNING" (grün)

2. **Einstellungen anpassen**
   - Aktiviere/Deaktiviere Items über Checkboxen
   - Passe Intervalle und Werte an
   - Klicke "💾 Save Config" zum Speichern

3. **Statistiken beobachten**
   - Live-Updates alle 1 Sekunde
   - Balkendiagramme zeigen Item-Verteilung
   - Activity Log zeigt alle wichtigen Events

4. **Bot pausieren**
   - Klicke "⏸ PAUSE (F8)" oder drücke F8
   - Bot hält an, Statistiken bleiben erhalten

5. **Bot beenden**
   - Klicke "⏹ EXIT (F9)" oder drücke F9
   - Sicherheitsabfrage verhindert versehentliches Beenden

### Hotkeys (funktionieren weiterhin!)

- **F8** - Start/Pause Toggle
- **F9** - Beenden

### Item-Policies

Die GUI erlaubt dir, Items einzeln zu aktivieren/deaktivieren:

| Item | Symbol | Beschreibung |
|------|--------|--------------|
| Gem | ✦ | Mit MinValue-Einstellung (z.B. nur Trades mit ≥3 Gems) |
| Beer | 🍺 | Beer-Trades |
| Mulch | 🌿 | Mulch-Trades |
| Cheese | 🧀 | Cheese-Trades |
| GoldLeaf | 🍂 | GoldLeaf-Trades |
| CosmicLeaf | ✨ | CosmicLeaf-Trades |

## 🔧 Konfiguration

### Gespeicherte Einstellungen

Beim Klick auf "💾 Save Config" werden folgende Einstellungen in `gui-config.json` gespeichert:

- Item-Policies (welche Items aktiv sind)
- Gem MinValue
- Collect-Intervall
- Max Trades
- Refresh-Intervall
- Log-Modus
- Auto-Kalibrierung
- Gem-Stats aktiviert
- Screenshot-Mode

### Statistik-Synchronisierung

Die GUI liest automatisch die `stats.json` Datei, die vom Bot-Script erstellt wird. Updates erfolgen:
- Alle 1 Sekunde während der Bot läuft
- Beim Start der GUI (lädt vorherige Session)

## 🎨 Design

- **Dark Theme** - Augenfreundliche dunkle Oberfläche
- **Color Coding** - Farben für verschiedene Stati und Items
- **Responsive Layout** - Angepasste Größen für optimale Lesbarkeit
- **Progress Bars** - Visuelle Item-Verteilung
- **Monospace Log** - Übersichtliches Console-Log-Feeling

## ⚠️ Wichtige Hinweise

### Bot muss laufen!
Die GUI zeigt nur Statistiken und sendet Hotkey-Befehle. Der eigentliche Bot (`TradingGems.v4.2.ps1`) muss im Hintergrund laufen!

### Zwei Fenster erforderlich
- **Bot-Fenster** - Führt die Automatisierung aus
- **GUI-Fenster** - Zeigt Statistiken und ermöglicht Steuerung

### Konfiguration
Änderungen in der GUI werden NICHT automatisch an den laufenden Bot übertragen. Du musst:
1. Config speichern
2. Bot neu starten (F9 + F8)

Alternativ: Bearbeite `TradingGems.v4.2.ps1` direkt für permanente Änderungen.

## 🐛 Troubleshooting

### GUI startet nicht
```powershell
# Ausführungsrichtlinien prüfen
Get-ExecutionPolicy

# Falls "Restricted", ändern auf:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Statistiken werden nicht angezeigt
- Prüfe ob `stats.json` im Script-Ordner existiert
- Starte den Bot mindestens einmal, damit Statistiken generiert werden

### Hotkeys funktionieren nicht
- Stelle sicher, dass keine andere Anwendung F8/F9 verwendet
- Starte beide Scripts mit Admin-Rechten

### Bot reagiert nicht auf GUI-Befehle
- Die GUI sendet nur Hotkey-Simulationen
- Der Bot muss im Vordergrund oder als aktives Fenster laufen
- Verwende direkt F8/F9 als Alternative

## 🔄 Updates

### Was bleibt gleich?
- Dein Bot-Script (`TradingGems.v4.2.ps1`) ist **unverändert**
- Alle Hotkeys funktionieren wie gewohnt
- Keine Änderung an der Bot-Logik

### Was ist neu?
- Moderne GUI für bessere Übersicht
- Gespeicherte Konfigurationen
- Visuelle Statistiken
- Komfortable Steuerung

## 💡 Tipps

1. **Verwende den Launcher** - `START_HERE.bat` ist am einfachsten
2. **Speichere Configs** - Deine Lieblings-Settings immer griffbereit
3. **Beobachte Logs** - Wichtige Events werden farbcodiert angezeigt
4. **Nutze Statistiken** - Optimiere deine Item-Policies basierend auf Erfolgsraten

## 📞 Hilfe

Bei Problemen oder Fragen:
1. Prüfe ob beide Scripts im gleichen Ordner liegen
2. Stelle sicher, dass `pictures/ItemSymbols/` existiert
3. Prüfe ob `game.exe` läuft (der Bot braucht das Spiel)
4. Schaue ins Activity Log für Fehlermeldungen

## ✅ Checkliste vor dem ersten Start

- [ ] Alle Script-Dateien im gleichen Ordner
- [ ] `pictures/ItemSymbols/` mit Symbol-Bildern vorhanden
- [ ] AHK-Executables (`ahk/SingleClick.exe`, `ahk/DoubleClick.exe`) vorhanden
- [ ] Idle Leaf Blower (`game.exe`) läuft
- [ ] PowerShell ExecutionPolicy erlaubt Script-Ausführung

---

**Viel Erfolg beim Trading! 🎮💎**
