#Requires AutoHotkey v2.0
#Include CLRV2.ahk

; ==========================================================
; Static class, holds ViGEm Client instance
; ==========================================================

class ViGEmWrapper {
    static asm := 0
    static client := 0

    static Init() {
        if (this.client = 0) {
            SplitPath A_LineFile, , &Lib
            this.asm := CLR_LoadLibrary(Lib . "\ViGEmWrapper.dll")
            this.client := true
        }
    }

    static CreateInstance(cls) {
        return this.asm.CreateInstance(cls)
    }
}

; ==========================================================
; Base class for controller targets
; ==========================================================

class ViGEmTarget {
    target := 0
    helperClass := ""
    controllerClass := ""

    __New() {
        ViGEmWrapper.Init()
        this.Instance := ViGEmWrapper.CreateInstance(this.helperClass)

        if (this.Instance.OkCheck() != "OK") {
            MsgBox("ViGEmWrapper.dll failed to load!")
            ExitApp()
        }

        this.Buttons := {}
        this.Axes := {}

        clsName := this.__Class
        cls := %clsName%

        if cls.HasOwnProp("buttons")
            for (name, id in cls.buttons) {
                this.Buttons.%name% := cls._ButtonHelper(this, id)
            }

        if cls.HasOwnProp("axes")
            for name, id in cls.axes
                this.Axes.%name% := cls._AxisHelper(this, id)

        this.Dpad := cls._DpadHelper(this)
    }

    SendReport() {
        this.Instance.SendReport()
    }

    SubscribeFeedback(callback) {
        this.Instance.SubscribeFeedback(callback)
    }

    ; ==========================================================
    ; Shared Helpers
    ; ==========================================================

    class _ButtonHelper {
        __New(parent, id) {
            this._Parent := parent
            this._Id := id
        }

        SetState(state) {
            this._Parent.Instance.SetButtonState(this._Id, state)
            this._Parent.Instance.SendReport()
            return this._Parent
        }
    }

    class _SpecialButtonHelper {
        __New(parent, id) {
            this._Parent := parent
            this._Id := id
        }

        SetState(state) {
            this._Parent.Instance.SetSpecialButtonState(this._Id, state)
            this._Parent.Instance.SendReport()
            return this._Parent
        }
    }

    class _AxisHelper {
        __New(parent, id) {
            this._Parent := parent
            this._Id := id
        }

        SetState(state) {
            this._Parent.Instance.SetAxisState(this._Id, this.ConvertAxis(state))
            this._Parent.Instance.SendReport()
            return this._Parent
        }

        ConvertAxis(state) {
            return state
        }
    }

}
; ==========================================================
; DS4 Controller
; ==========================================================

class ViGEmDS4 extends ViGEmTarget {

    helperClass := "ViGEmWrapper.Ds4"

    static buttons := Map(
        "Square", 16, "Cross", 32, "Circle", 64, "Triangle", 128,
        "L1", 256, "R1", 512, "L2", 1024, "R2", 2048,
        "Share", 4096, "Options", 8192,
        "LS", 16384, "RS", 32768
    )

    static specialButtons := Map(
        "Ps", 1, "TouchPad", 2
    )

    static axes := Map(
        "LX", 2, "LY", 3,
        "RX", 4, "RY", 5,
        "LT", 0, "RT", 1
    )

    __New() {
        super.__New()

        for name, id in this.specialButtons
            this.Buttons[name] := this._SpecialButtonHelper(this, id)
    }

    class _AxisHelper extends ViGEmTarget._AxisHelper {
        ConvertAxis(state) {
            return round(state * 2.55)
        }
    }

    class _DpadHelper {
        __New(parent) {
            this._Parent := parent
        }

        SetState(state) {
            static dPadDirections := {
                Up: 0, UpRight: 1, Right: 2, DownRight: 3,
                Down: 4, DownLeft: 5, Left: 6, UpLeft: 7, None: 8
            }

            this._Parent.Instance.SetDpadState(dPadDirections[state])
            this._Parent.Instance.SendReport()
            return this._Parent
        }
    }
}

; ==========================================================
; Xbox 360 Controller
; ==========================================================
class ViGEmXb360 extends ViGEmTarget {
    helperClass := "ViGEmWrapper.Xb360"

    static buttons := Map(
        "A", 4096, "B", 8192, "X", 16384, "Y", 32768,
        "LB", 256, "RB", 512, "LS", 64, "RS", 128,
        "Back", 32, "Start", 16, "Xbox", 1024
    )

    static axes := Map(
        "LX", 2, "LY", 3,
        "RX", 4, "RY", 5,
        "LT", 0, "RT", 1
    )

    __New() {
        super.__New()
    }

    class _AxisHelper extends ViGEmTarget._AxisHelper {
        ConvertAxis(state) {
            value := Round((state * 655.36) - 32768)
            return (value = 32768) ? 32767 : value
        }
    }

    class _DpadHelper {
        _DpadStates := Map(1, 0, 8, 0, 2, 0, 4, 0)

        __New(parent) {
            this._Parent := parent
        }

        SetState(state) {

            static dpadDirections := Map(
                "None", Map(1, 0, 8, 0, 2, 0, 4, 0),
                "Up", Map(1, 1, 8, 0, 2, 0, 4, 0),
                "UpRight", Map(1, 1, 8, 1, 2, 0, 4, 0),
                "Right", Map(1, 0, 8, 1, 2, 0, 4, 0),
                "DownRight", Map(1, 0, 8, 1, 2, 1, 4, 0),
                "Down", Map(1, 0, 8, 0, 2, 1, 4, 0),
                "DownLeft", Map(1, 0, 8, 0, 2, 1, 4, 1),
                "Left", Map(1, 0, 8, 0, 2, 0, 4, 1),
                "UpLeft", Map(1, 1, 8, 0, 2, 0, 4, 1)
            )

            newStates := dpadDirections[state]

            for id, newState in newStates {
                oldState := this._DpadStates[id]
                if (oldState != newState) {
                    this._DpadStates[id] := newState
                    this._Parent.Instance.SetButtonState(id, newState)
                }
            }

            this._Parent.SendReport()
        }
    }
}
