#Requires AutoHotkey v2.0

GameTitle := "Leaf Blower Revolution"
GameExe   := "game.exe"
Running   := false

; Hier anpassen für andere Farben
; Farben
PumpkinColor := 0xFF9E13
ClawColor    := 0x303754

; Suchbereiche
PumpkinArea := { x1: 2400, y1: 1065, x2: 3230, y2: 1200 }
ClawArea    := { x1: 2400, y1: 913,  x2: 3230, y2: 919  }

IsGameOpen() {
    global GameTitle, GameExe
    return WinExist("ahk_exe " GameExe) || WinExist(GameTitle)
}

SendToGame(keys) {
    global GameTitle, GameExe
    if WinExist("ahk_exe " GameExe)
        ControlSend keys,, "ahk_exe " GameExe
    else if WinExist(GameTitle)
        ControlSend keys,, GameTitle
}

global TargetX := -1
global LastGrabTick := 0
global LastRerollTick := 0

GrabCooldown   := 1000    ; ms zwischen Grabs
RerollTimeout  := 3500    ; ms seit letztem Grab -> Notfall-Reroll
MinRerollDelay := 500     ; ms Mindestabstand zwischen TabTab

FindPumpkinX() {
    global PumpkinColor, PumpkinArea, TargetX
    a := PumpkinArea
    if PixelSearch(&fx, &fy, a.x1, a.y1, a.x2, a.y2, PumpkinColor, 0) {
        TargetX := fx
        return true
    }
    TargetX := -1
    return false
}

FindClawX() {
    global ClawColor, ClawArea
    a := ClawArea
    if PixelSearch(&cx, &cy, a.x1, a.y1, a.x2, a.y2, ClawColor, 20)
        return cx
    return -1
}

ClawTick() {
    global Running, TargetX, LastGrabTick, LastRerollTick
    global GrabCooldown, RerollTimeout, MinRerollDelay

    if !Running
        return
    if !IsGameOpen()
        return

    now := A_TickCount

    ; 1) Kürbis suchen
    hasPumpkin := FindPumpkinX()

    ; 2) Kein Kürbis da -> evtl. Reroll
    if !hasPumpkin {
        ; Notfall-Reroll: schon lange nichts gegrabbt UND seit letztem Reroll genug Zeit
        if (now - LastGrabTick > RerollTimeout) && (now - LastRerollTick > MinRerollDelay) {
            SendToGame("{Tab}")
            LastRerollTick := now
            LastGrabTick   := now    ; Timer resetten
			Sleep 25
			SendToGame("{Tab}")
			Sleep 25
        }
        return
    }

    ; 3) Kürbis ist da -> NIE TabTab, nur gezielt greifen
    if TargetX < 0
        return
	
    clawX := FindClawX()
    if clawX < 0
        return

    diff := Abs(clawX - TargetX)

    if (diff <= 10) && (now - LastGrabTick > GrabCooldown) {
        SendToGame("{Space}")
        LastGrabTick := now
    }
}

SetTimer ClawTick, 25

F8:: {
    global Running, LastGrabTick, LastRerollTick
    Running := !Running
    if Running {
        LastGrabTick   := A_TickCount
        LastRerollTick := A_TickCount
    }
}

F9::ExitApp
