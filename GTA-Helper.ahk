#Requires AutoHotkey v2.0
#SingleInstance Force
#include Lib\AHK-ViGEm-BusV2.ahk

; Create a new Xbox 360 controller
controller := ViGEmXb360()

winTitle := "Grand Theft Auto V"
afkkey := "NumpadSub"
ClickDelay := 30000 ; Time delay per click (30 seconds)

Toggle := false ; Initialize toggle state as off
Mode := 1
ModeList := ["General", "LSCM", "Drone", "Survival"]
StartTime := 0 ; Total duration
NextClick := 0 ; Next click
Count := 0

; Create the overlay GUI, but don't show it initially
WS_EX_NOACTIVATE := 0x08000000
overlay := Gui("+AlwaysOnTop +ToolWindow -Caption +E0x20 +E0x8000000")  ; Create a new Gui object
overlay.BackColor := "111111"  ; Required for transparency

overlay.MarginX := 5
overlay.MarginY := 1

WinSetTransparent(150, overlay)

overlay.SetFont("s10 bold cWhite")
overlayText := overlay.AddText("vOverlayText w540 h20", "Initializing...")  ; Add text to the Gui

overlay.show("x0 y0 w540 h22 NA")

SetTimer UpdateOverlay, 250

Hotkey(afkkey, ToggleAFK)
Hotkey("^+F12", ToggleAFK)

ToggleAFK(*) {
    global Toggle, StartTime, Count
    Toggle := !Toggle

    if Toggle {
        StartTime := A_TickCount
        Count := 0
        SetTimer AFK, (Mode < 4 ? ClickDelay : 5000)
        AFK()
    } else {
        SetTimer AFK, 0
    }
}

F4::
{
    global Mode, ModeList
    Mode++
    if (Mode > ModeList.Length)
        Mode := 1
}

AFK(*) {
    global winTitle, StartTime, NextClick, ClickDelay, Count

    ; Update the next click time
    NextClick := A_TickCount + (Mode < 4 ? ClickDelay : 5000)

    ;if !WinActive(winTitle) {
    ;    SoundBeep(1000, 200)
    ;    overlayText.text := "Anit-AFK: GTA not focus"
    ;}
    ;else {
        if (Mode == 1) {
            ;SendKey("z")
            controller.Dpad.SetState("Down")
            Sleep(250)
            controller.Dpad.SetState("None")
        }
        else if (Mode == 2) {
            ;SendKey("a")
            controller.Axes.LX.SetState(0)
            Sleep(250)
            controller.Axes.LX.SetState(50)
            ;SendKey("z")
            controller.Dpad.SetState("Down")
            Sleep(250)
            controller.Dpad.SetState("None")
            ;SendKey("d")
            controller.Axes.LX.SetState(100)
            Sleep(250)
            controller.Axes.LX.SetState(50)
        }
        else if (Mode == 3) {
            ;SendKey("a")
            controller.Axes.LX.SetState(0)
            Sleep(250)
            controller.Axes.LX.SetState(50)
            ;SendKey("d")
            controller.Axes.LX.SetState(100)
            Sleep(250)
            controller.Axes.LX.SetState(50)
        }
        else if (Mode == 4) {
            ;SendKey("z")
            controller.Dpad.SetState("Down")
            Sleep(250)
            controller.Dpad.SetState("None")
            ;SendKey("w", 150)
            controller.Axes.LY.SetState(100)
            Sleep(150)
            controller.Axes.LY.SetState(50)
            ;SendKey("enter")
            controller.Buttons.A.SetState(true)
            Sleep(250)
            controller.Buttons.A.SetState(false)
        }
        Count += 1
    ;}
}

SendKey(key, delay := 500) {
    global winTitle
    if WinActive(winTitle) {
        Send("{" key " down}")
        Sleep(delay)
    }
    Send("{" key " up}")
    return
}

UpdateOverlay() {
    global Toggle, StartTime, NextClick, ClickDelay, Count

    if !WinExist("ahk_id " overlay.Hwnd)
        overlay.Show("NA")

    WinSetAlwaysOnTop(1, "ahk_id " overlay.Hwnd)

    ; If the script is disabled, show that status
    if !Toggle {
        overlayText.text := "Start Anti-AFK in " . ModeList[Mode] . " mode with [ " . afkkey . " ]"
        overlayText.SetFont("cGreen")
        return
    }
    overlayText.SetFont("cRed")

    ; Calculate the next click time (in seconds)
    NextClickTime := (NextClick - A_TickCount) // 1000 ; Calculate time remaining for the next click (in seconds)
    TotalDuration := Max(0, (A_TickCount - StartTime) // 1000) ; Total duration in seconds

    ; Update the overlay with total duration and next click time
    overlayText.text :=
        "Mode: " . ModeList[Mode] .
        "     Next click in: " . FormatDuration(NextClickTime) .
        "     Total duration: " . FormatDuration(TotalDuration) .
        "     Total clicks: " . Count

}

FormatDuration(sec) {
    h := sec // 3600
    m := Mod(sec // 60, 60)
    s := Mod(sec, 60)

    out := ""
    if h
        out .= h "h "
    if m || h
        out .= m "m "
    out .= s "s"

    return Trim(out)
}
