#Requires AutoHotkey >=2.0

#SingleInstance Force ; if script is run again, replace the old instance
Critical("On") ; prevent the current thread from being interrupted
A_HotkeyInterval := 0 ; disable hotkey rate warning

{ ; REGION: IniReads

    ; This naming convention may seem overly verbose, but it allows me
    ; to support more complex controller mappings in the future.

    ; XL = XbarLeft
    XL_JoyPov_Up := IniRead("config.ini", "XbarLeft", "Dpad_Up", 0)
    XL_JoyPov_Down := IniRead("config.ini", "XbarLeft", "Dpad_Down", 18000)
    XL_JoyPov_Left := IniRead("config.ini", "XbarLeft", "Dpad_Left", 27000)
    XL_JoyPov_Right := IniRead("config.ini", "XbarLeft", "Dpad_Right", 9000)

    ; XR = XbarRight
    XR_JoyButton_Up := IniRead("config.ini", "XbarRight", "Button_Up", 0)
    XR_JoyButton_Down := IniRead("config.ini", "XbarRight", "Button_Down", 0)
    XR_JoyButton_Left := IniRead("config.ini", "XbarRight", "Button_Left", 0)
    XR_JoyButton_Right := IniRead("config.ini", "XbarRight", "Button_Right", 0)

    ; FM = FunctionMap
    FM_JoyButton_Confirm := IniRead("config.ini", "FunctionMap", "Button_Confirm", 0)
    FM_JoyButton_Cancel := IniRead("config.ini", "FunctionMap", "Button_Cancel", 0)
    FM_JoyButton_MainMenu := IniRead("config.ini", "FunctionMap", "Button_MainMenu", 0)
    FM_JoyButton_ActiveWindow := IniRead("config.ini", "FunctionMap", "Button_ActiveWindow", 0)
    FM_JoyButton_ToggleBind := IniRead("config.ini", "FunctionMap", "Button_ToggleBind", 0)
    FM_JoyButton_CycleSets := IniRead("config.ini", "FunctionMap", "Button_CycleSets", 0)
    FM_JoyButton_XbarLeft := IniRead("config.ini", "FunctionMap", "Button_XbarLeft", 0)
    FM_JoyButton_XbarRight := IniRead("config.ini", "FunctionMap", "Button_XbarRight", 0)
}

SetTimer(CheckJoyPov, 10) ; poll for D-pad changes every 10ms
OldJoyPov := -1 ; -1 = center position (no angle to report)

GetIsGameWindowActive() {
    WinActive("ahk_class FFXiClass")
}

GetIsXbarActive() {
    return GetKeyState("Joy" FM_JoyButton_XbarLeft)
        or GetKeyState("Joy" FM_JoyButton_XbarRight)
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

    ; if (!GetIsGameWindowActive()) {
    ;     return
    ; }

    if (GetIsXbarActive()) {

        if (joyPov == XL_JoyPov_Up) {
            SendInput("{F1}")
        } else if (joyPov == XL_JoyPov_Down) {
            SendInput("{F2}")
        } else if (joyPov == XL_JoyPov_Left) {
            SendInput("{F3}")
        } else if (joyPov == XL_JoyPov_Right) {
            SendInput("{F4}")
        }
    }
}

HandleJoyButton(joyButton) {

    ; for testing:
    ; SendInput("{Raw}" joyButton)

    ; if (!GetIsGameWindowActive()) {
    ;     return
    ; }

    if (joyButton == FM_JoyButton_ToggleBind) {
        SendInput("{F9}")
    } else if (joyButton == FM_JoyButton_CycleSets) {
        SendInput("{F10}")
    } else if (joyButton == FM_JoyButton_XbarLeft) {
        SendInput("{F11}")
    } else if (joyButton == FM_JoyButton_XbarRight) {
        SendInput("{F12}")
    }

    if (GetIsXbarActive()) {

        if (joyButton == XR_JoyButton_Up) {
            SendInput("{F5}")
        } else if (joyButton == XR_JoyButton_Down) {
            SendInput("{F6}")
        } else if (joyButton == XR_JoyButton_Left) {
            SendInput("{F7}")
        } else if (joyButton == XR_JoyButton_Right) {
            SendInput("{F8}")
        }

    } else { ; crossbar not active

        if (joyButton == FM_JoyButton_Confirm) {
            SendInput("{Enter}")
        } else if (joyButton == FM_JoyButton_Cancel) {
            SendInput("{Esc}")
        } else if (joyButton == FM_JoyButton_MainMenu) {
            SendInput("{NumpadSub}")
        } else if (joyButton == FM_JoyButton_ActiveWindow) {
            SendInput("{NumpadAdd}")
        }

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
