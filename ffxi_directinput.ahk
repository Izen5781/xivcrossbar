#Requires AutoHotkey >=2.0

#SingleInstance Force ; if script is run again, replace the old instance
Critical("On") ; prevent the current thread from being interrupted
A_HotkeyInterval := 0 ; disable hotkey rate warning

{ ; REGION: IniReads

    ; This naming convention may seem overly verbose, but it allows us
    ; to support more complex controller mappings in the future.

    ; XL = XbarLeft
    JoyPov_XL_Up := IniRead("config.ini", "XbarLeft", "POV_Up", "NOTSET")
    JoyPov_XL_Down := IniRead("config.ini", "XbarLeft", "POV_Down", "NOTSET")
    JoyPov_XL_Left := IniRead("config.ini", "XbarLeft", "POV_Left", "NOTSET")
    JoyPov_XL_Right := IniRead("config.ini", "XbarLeft", "POV_Right", "NOTSET")

    ; XR = XbarRight
    JoyButton_XR_Up := IniRead("config.ini", "XbarRight", "Button_Up", "NOTSET")
    JoyButton_XR_Down := IniRead("config.ini", "XbarRight", "Button_Down", "NOTSET")
    JoyButton_XR_Left := IniRead("config.ini", "XbarRight", "Button_Left", "NOTSET")
    JoyButton_XR_Right := IniRead("config.ini", "XbarRight", "Button_Right", "NOTSET")

    ; FM = FunctionMap
    JoyButton_FM_Confirm := IniRead("config.ini", "FunctionMap", "Button_Confirm", "NOTSET")
    JoyButton_FM_Cancel := IniRead("config.ini", "FunctionMap", "Button_Cancel", "NOTSET")
    JoyButton_FM_MainMenu := IniRead("config.ini", "FunctionMap", "Button_MainMenu", "NOTSET")
    JoyButton_FM_ActiveWindow := IniRead("config.ini", "FunctionMap", "Button_ActiveWindow", "NOTSET")
    JoyButton_FM_ToggleBind := IniRead("config.ini", "FunctionMap", "Button_ToggleBind", "NOTSET")
    JoyButton_FM_CycleSets := IniRead("config.ini", "FunctionMap", "Button_CycleSets", "NOTSET")
    JoyButton_FM_XbarLeft := IniRead("config.ini", "FunctionMap", "Button_XbarLeft", "NOTSET")
    JoyButton_FM_XbarRight := IniRead("config.ini", "FunctionMap", "Button_XbarRight", "NOTSET")
}

SetTimer(CheckJoyPov, 10) ; poll for D-pad changes every 10ms
OldJoyPov := -1 ; -1 = center position (no angle to report)

FM_CycleSets_IsPressed := false
FM_XbarLeft_IsPressed := false
FM_XbarRight_IsPressed := false

GetIsGameWindowActive() {
    return WinActive("ahk_class FFXiClass")
}

CheckJoyPov() {

    ; modifies these global variables
    global OldJoyPov

    newJoyPov := GetKeyState("JoyPOV") ; D-pad

    if (newJoyPov == OldJoyPov) {
        return
    }

    HandleJoyPov(newJoyPov)
    OldJoyPov := newJoyPov
}

HandleJoyPov(joyPov) {

    ; for testing:
    ; SendInput("{Raw}" joyPov)

    if (!GetIsGameWindowActive()) {
        return
    }

    if (FM_XbarLeft_IsPressed
        or FM_XbarRight_IsPressed
        or FM_CycleSets_IsPressed) {

        if (joyPov == JoyPov_XL_Up) {
            Send_XL_Up()
        } else if (joyPov == JoyPov_XL_Down) {
            Send_XL_Down()
        } else if (joyPov == JoyPov_XL_Left) {
            Send_XL_Left()
        } else if (joyPov == JoyPov_XL_Right) {
            Send_XL_Right()
        }
    }
}

HandleJoyButton(joyButton) {

    ; for testing:
    ; SendInput("{Raw}" joyButton)

    if (!GetIsGameWindowActive()) {
        return
    }

    if (joyButton == JoyButton_FM_ToggleBind) {
        Send_FM_ToggleBind()
    } else if (joyButton == JoyButton_FM_CycleSets) {
        Send_FM_CycleSets_Press("Joy" joyButton, true)
    } else if (joyButton == JoyButton_FM_XbarLeft) {
        Send_FM_XbarLeft_Press("Joy" joyButton, true)
    } else if (joyButton == JoyButton_FM_XbarRight) {
        Send_FM_XbarRight_Press("Joy" joyButton, true)
    }

    if (FM_XbarLeft_IsPressed
        or FM_XbarRight_IsPressed
        or FM_CycleSets_IsPressed) {

        if (joyButton == JoyButton_XR_Up) {
            Send_XR_Up()
        } else if (joyButton == JoyButton_XR_Down) {
            Send_XR_Down()
        } else if (joyButton == JoyButton_XR_Left) {
            Send_XR_Left()
        } else if (joyButton == JoyButton_XR_Right) {
            Send_XR_Right()
        }

    } else { ; crossbar not active

        if (joyButton == JoyButton_FM_Confirm) {
            Send_FM_Confirm()
        } else if (joyButton == JoyButton_FM_Cancel) {
            Send_FM_Cancel()
        } else if (joyButton == JoyButton_FM_MainMenu) {
            Send_FM_MainMenu()
        } else if (joyButton == JoyButton_FM_ActiveWindow) {
            Send_FM_ActiveWindow()
        }
    }
}

{ ; REGION: SendInputs

    Send_XL_Up() {
        SendInput("^{F1 up}")
    }

    Send_XL_Down() {
        SendInput("^{F2 up}")
    }

    Send_XL_Left() {
        SendInput("^{F3 up}")
    }

    Send_XL_Right() {
        SendInput("^{F4 up}")
    }

    Send_XR_Up() {
        SendInput("^{F5 up}")
    }

    Send_XR_Down() {
        SendInput("^{F6 up}")
    }

    Send_XR_Left() {
        SendInput("^{F7 up}")
    }

    Send_XR_Right() {
        SendInput("^{F8 up}")
    }

    Send_FM_Confirm() {
        SendInput("{Enter}")
    }

    Send_FM_Cancel() {
        SendInput("{Esc}")
    }

    Send_FM_MainMenu() {
        SendInput("{NumpadSub}")
    }

    Send_FM_ActiveWindow() {
        SendInput("{NumpadAdd}")
    }

    Send_FM_ToggleBind() {
        SendInput("^{F9 up}")
    }

    Send_FM_CycleSets_Press(keyName, releaseState) {

        global FM_CycleSets_KeyName := keyName
        global FM_CycleSets_PressedState := releaseState
        global FM_CycleSets_IsPressed := true

        SendInput("^{F10 up}")
        SetTimer(Send_FM_CycleSets_Release, 10)
    }

    Send_FM_CycleSets_Release() {

        if (GetKeyState(FM_CycleSets_KeyName) == FM_CycleSets_PressedState) {
            return
        }

        global FM_CycleSets_IsPressed := false
        SendInput("^!{F10 up}")
        SetTimer(, 0) ; stop polling
    }

    Send_FM_XbarLeft_Press(keyName, releaseState) {

        global FM_XbarLeft_KeyName := keyName
        global FM_XbarLeft_PressedState := releaseState
        global FM_XbarLeft_IsPressed := true

        SendInput("^{F11 up}")
        SetTimer(Send_FM_XbarLeft_Release, 10)
    }

    Send_FM_XbarLeft_Release() {

        if (GetKeyState(FM_XbarLeft_KeyName) == FM_XbarLeft_PressedState) {
            return
        }

        global FM_XbarLeft_IsPressed := false
        SendInput("^!{F11 up}")
        SetTimer(, 0) ; stop polling
    }

    Send_FM_XbarRight_Press(keyName, releaseState) {

        global FM_XbarRight_KeyName := keyName
        global FM_XbarRight_PressedState := releaseState
        global FM_XbarRight_IsPressed := true

        SendInput("^{F12 up}")
        SetTimer(Send_FM_XbarRight_Release, 10)
    }

    Send_FM_XbarRight_Release() {

        if (GetKeyState(FM_XbarRight_KeyName) == FM_XbarRight_PressedState) {
            return
        }

        global FM_XbarRight_IsPressed := false
        SendInput("^!{F12 up}")
        SetTimer(, 0) ; stop polling
    }
}

{ ; REGION: JoyButton Remaps

    Joy1:: HandleJoyButton(1)
    Joy2:: HandleJoyButton(2)
    Joy3:: HandleJoyButton(3)
    Joy4:: HandleJoyButton(4)
    Joy5:: HandleJoyButton(5)
    Joy6:: HandleJoyButton(6)
    Joy7:: HandleJoyButton(7)
    Joy8:: HandleJoyButton(8)
    Joy9:: HandleJoyButton(9)
    Joy10:: HandleJoyButton(10)
    Joy11:: HandleJoyButton(11)
    Joy12:: HandleJoyButton(12)
    Joy13:: HandleJoyButton(13)
    Joy14:: HandleJoyButton(14)
    Joy15:: HandleJoyButton(15)
    Joy16:: HandleJoyButton(16)
    Joy17:: HandleJoyButton(17)
    Joy18:: HandleJoyButton(18)
    Joy19:: HandleJoyButton(19)
    Joy20:: HandleJoyButton(20)
    Joy21:: HandleJoyButton(21)
    Joy22:: HandleJoyButton(22)
    Joy23:: HandleJoyButton(23)
    Joy24:: HandleJoyButton(24)
    Joy25:: HandleJoyButton(25)
    Joy26:: HandleJoyButton(26)
    Joy27:: HandleJoyButton(27)
    Joy28:: HandleJoyButton(28)
    Joy29:: HandleJoyButton(29)
    Joy30:: HandleJoyButton(30)
    Joy31:: HandleJoyButton(31)
    Joy32:: HandleJoyButton(32)
}
