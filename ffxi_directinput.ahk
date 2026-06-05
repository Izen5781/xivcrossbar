#Requires AutoHotkey >=2.0

#SingleInstance Force ; if script is run again, replace the old instance
Critical("On") ; prevent the current thread from being interrupted
A_HotkeyInterval := 0 ; disable hotkey rate warning

{ ; REGION: IniReads

    ; This naming convention may seem overly verbose, but it allows me
    ; to support more complex controller mappings in the future.

    ; XL = XbarLeft
    XL_JoyPov_Up := IniRead("config.ini", "XbarLeft", "POV_Up", "NOTSET")
    XL_JoyPov_Down := IniRead("config.ini", "XbarLeft", "POV_Down", "NOTSET")
    XL_JoyPov_Left := IniRead("config.ini", "XbarLeft", "POV_Left", "NOTSET")
    XL_JoyPov_Right := IniRead("config.ini", "XbarLeft", "POV_Right", "NOTSET")

    ; XR = XbarRight
    XR_JoyButton_Up := IniRead("config.ini", "XbarRight", "Button_Up", "NOTSET")
    XR_JoyButton_Down := IniRead("config.ini", "XbarRight", "Button_Down", "NOTSET")
    XR_JoyButton_Left := IniRead("config.ini", "XbarRight", "Button_Left", "NOTSET")
    XR_JoyButton_Right := IniRead("config.ini", "XbarRight", "Button_Right", "NOTSET")

    ; CS = CycleSets
    CS_JoyPov_Next := IniRead("config.ini", "CycleSets", "POV_Next", "NOTSET")
    CS_JoyPov_Previous := IniRead("config.ini", "CycleSets", "POV_Previous", "NOTSET")

    ; FM = FunctionMap
    FM_JoyButton_Confirm := IniRead("config.ini", "FunctionMap", "Button_Confirm", "NOTSET")
    FM_JoyButton_Cancel := IniRead("config.ini", "FunctionMap", "Button_Cancel", "NOTSET")
    FM_JoyButton_MainMenu := IniRead("config.ini", "FunctionMap", "Button_MainMenu", "NOTSET")
    FM_JoyButton_ActiveWindow := IniRead("config.ini", "FunctionMap", "Button_ActiveWindow", "NOTSET")
    FM_JoyButton_ToggleBind := IniRead("config.ini", "FunctionMap", "Button_ToggleBind", "NOTSET")
    FM_JoyButton_CycleSets := IniRead("config.ini", "FunctionMap", "Button_CycleSets", "NOTSET")
    FM_JoyButton_XbarLeft := IniRead("config.ini", "FunctionMap", "Button_XbarLeft", "NOTSET")
    FM_JoyButton_XbarRight := IniRead("config.ini", "FunctionMap", "Button_XbarRight", "NOTSET")
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

    if (FM_XbarLeft_IsPressed or FM_XbarRight_IsPressed) {

        if (joyPov == XL_JoyPov_Up) {
            Send_XL_Up()
        } else if (joyPov == XL_JoyPov_Down) {
            Send_XL_Down()
        } else if (joyPov == XL_JoyPov_Left) {
            Send_XL_Left()
        } else if (joyPov == XL_JoyPov_Right) {
            Send_XL_Right()
        }

    } else if (FM_CycleSets_IsPressed) {

        if (joyPov == CS_JoyPov_Next) {
            Send_CS_Next()
        } else if (joyPov == CS_JoyPov_Previous) {
            Send_CS_Previous()
        }
    }
}

HandleJoyButton(joyButton) {

    ; for testing:
    ; SendInput("{Raw}" joyButton)

    if (!GetIsGameWindowActive()) {
        return
    }

    if (joyButton == FM_JoyButton_ToggleBind) {
        Send_FM_ToggleBind()
    } else if (joyButton == FM_JoyButton_CycleSets) {
        Send_FM_CycleSets_Press("Joy" joyButton, true)
    } else if (joyButton == FM_JoyButton_XbarLeft) {
        Send_FM_XbarLeft_Press("Joy" joyButton, true)
    } else if (joyButton == FM_JoyButton_XbarRight) {
        Send_FM_XbarRight_Press("Joy" joyButton, true)
    }

    if (FM_XbarLeft_IsPressed or FM_XbarRight_IsPressed) {

        if (joyButton == XR_JoyButton_Up) {
            Send_XR_Up()
        } else if (joyButton == XR_JoyButton_Down) {
            Send_XR_Down()
        } else if (joyButton == XR_JoyButton_Left) {
            Send_XR_Left()
        } else if (joyButton == XR_JoyButton_Right) {
            Send_XR_Right()
        }

    } else { ; crossbar not active

        if (joyButton == FM_JoyButton_Confirm) {
            Send_FM_Confirm()
        } else if (joyButton == FM_JoyButton_Cancel) {
            Send_FM_Cancel()
        } else if (joyButton == FM_JoyButton_MainMenu) {
            Send_FM_MainMenu()
        } else if (joyButton == FM_JoyButton_ActiveWindow) {
            Send_FM_ActiveWindow()
        }
    }
}

{ ; REGION: SendInputs

    Send_XL_Up()
    {
        SendInput("^{F1}")
    }

    Send_XL_Down()
    {
        SendInput("^{F2}")
    }

    Send_XL_Left()
    {
        SendInput("^{F3}")
    }

    Send_XL_Right()
    {
        SendInput("^{F4}")
    }

    Send_XR_Up()
    {
        SendInput("^{F5}")
    }

    Send_XR_Down()
    {
        SendInput("^{F6}")
    }

    Send_XR_Left()
    {
        SendInput("^{F7}")
    }

    Send_XR_Right()
    {
        SendInput("^{F8}")
    }

    Send_CS_Next()
    {
        SendInput("^{F1}")
    }

    Send_CS_Previous()
    {
        SendInput("^{F2}")
    }

    Send_FM_Confirm()
    {
        SendInput("{Enter}")
    }

    Send_FM_Cancel()
    {
        SendInput("{Esc}")
    }

    Send_FM_MainMenu()
    {
        SendInput("{NumpadSub}")
    }

    Send_FM_ActiveWindow()
    {
        SendInput("{NumpadAdd}")
    }

    Send_FM_ToggleBind()
    {
        SendInput("^{F9}")
    }

    Send_FM_CycleSets_Press(keyName, releaseState)
    {
        global FM_CycleSets_KeyName := keyName
        global FM_CycleSets_PressedState := releaseState
        global FM_CycleSets_IsPressed := true

        SendInput("^{F10 down}")
        SetTimer(Send_FM_CycleSets_Release, 10)
    }

    Send_FM_CycleSets_Release()
    {
        if (GetKeyState(FM_CycleSets_KeyName) == FM_CycleSets_PressedState) {
            return
        }

        global FM_CycleSets_IsPressed := false
        SendInput("^{F10 up}")
        SetTimer(, 0) ; stop polling
    }

    Send_FM_XbarLeft_Press(keyName, releaseState)
    {
        global FM_XbarLeft_KeyName := keyName
        global FM_XbarLeft_PressedState := releaseState
        global FM_XbarLeft_IsPressed := true

        SendInput("^{F11 down}")
        SetTimer(Send_FM_XbarLeft_Release, 10)
    }

    Send_FM_XbarLeft_Release()
    {
        if (GetKeyState(FM_XbarLeft_KeyName) == FM_XbarLeft_PressedState) {
            return
        }

        global FM_XbarLeft_IsPressed := false
        SendInput("^{F11 up}")
        SetTimer(, 0) ; stop polling
    }

    Send_FM_XbarRight_Press(keyName, releaseState)
    {
        global FM_XbarRight_KeyName := keyName
        global FM_XbarRight_PressedState := releaseState
        global FM_XbarRight_IsPressed := true

        SendInput("^{F12 down}")
        SetTimer(Send_FM_XbarRight_Release, 10)
    }

    Send_FM_XbarRight_Release()
    {
        if (GetKeyState(FM_XbarRight_KeyName) == FM_XbarRight_PressedState) {
            return
        }

        global FM_XbarRight_IsPressed := false
        SendInput("^{F12 up}")
        SetTimer(, 0) ; stop polling
    }
}

{ ; REGION: JoyButton Remaps

    Joy1::HandleJoyButton(1)
    Joy2::HandleJoyButton(2)
    Joy3::HandleJoyButton(3)
    Joy4::HandleJoyButton(4)
    Joy5::HandleJoyButton(5)
    Joy6::HandleJoyButton(6)
    Joy7::HandleJoyButton(7)
    Joy8::HandleJoyButton(8)
    Joy9::HandleJoyButton(9)
    Joy10::HandleJoyButton(10)
    Joy11::HandleJoyButton(11)
    Joy12::HandleJoyButton(12)
    Joy13::HandleJoyButton(13)
    Joy14::HandleJoyButton(14)
    Joy15::HandleJoyButton(15)
    Joy16::HandleJoyButton(16)
    Joy17::HandleJoyButton(17)
    Joy18::HandleJoyButton(18)
    Joy19::HandleJoyButton(19)
    Joy20::HandleJoyButton(20)
    Joy21::HandleJoyButton(21)
    Joy22::HandleJoyButton(22)
    Joy23::HandleJoyButton(23)
    Joy24::HandleJoyButton(24)
    Joy25::HandleJoyButton(25)
    Joy26::HandleJoyButton(26)
    Joy27::HandleJoyButton(27)
    Joy28::HandleJoyButton(28)
    Joy29::HandleJoyButton(29)
    Joy30::HandleJoyButton(30)
    Joy31::HandleJoyButton(31)
    Joy32::HandleJoyButton(32)
}
