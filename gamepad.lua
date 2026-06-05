local gamepad = {}

local face_buttons = {
    [63] = true,
    [64] = true,
    [65] = true,
    [66] = true,
    [67] = true,
    [68] = true
}

local dpad_button = {
    [59] = true,
    [60] = true,
    [61] = true,
    [62] = true
}

-- TODO: maybe have callers compare to these variables instead of using functions?
local dpad_up = 59 -- F1
local dpad_right = 60 -- F2
local dpad_down = 61 -- F3
local dpad_left = 62 -- F4
local button_a = 63 -- F5
local button_b = 64 -- F6
local button_x = 65 -- F7
local button_y = 66 -- F8
local minus = 67 -- F9
local plus = 68 -- F10
local left_trigger = 87 -- F11
local right_trigger = 88 -- F12

-- https://community.bistudio.com/wiki/DIK_KeyCodes

-- XL = XbarLeft
gamepad.isXL_Up = function(dik) return dik == 59 end -- F1
gamepad.isXL_Down = function(dik) return dik == 60 end -- F2
gamepad.isXL_Left = function(dik) return dik == 61 end -- F3
gamepad.isXL_Right = function(dik) return dik == 62 end -- F4

-- XR = XbarRight
gamepad.isXR_Up = function(dik) return dik == 63 end -- F5
gamepad.isXR_Down = function(dik) return dik == 64 end -- F6
gamepad.isXR_Left = function(dik) return dik == 65 end -- F7
gamepad.isXR_Right = function(dik) return dik == 66 end -- F8

-- CS = CycleSets | TODO: dik should be based on setting
gamepad.isCS_Next = function(dik) return dik == 59 end -- F1
gamepad.isCS_Previous = function(dik) return dik == 60 end -- F2

-- FM = FunctionMap | TODO: Confirm/Cancel dik should be based on setting, maybe remove their FM_ prefix?
gamepad.isFM_Confirm = function(dik) return dik == 64 end -- F6
gamepad.isFM_Cancel = function(dik) return dik == 66 end -- F8
gamepad.isFM_ToggleBind = function(dik) return dik == 67 end -- F9
gamepad.isFM_CycleSets = function(dik) return dik == 68 end -- F10
gamepad.isFM_XbarLeft = function(dik) return dik == 87 end -- F11
gamepad.isFM_XbarRight = function(dik) return dik == 88 end -- F12

local functionKeys = {
    [59] = true, -- F1
    [60] = true, -- F2
    [61] = true, -- F3
    [62] = true, -- F4
    [63] = true, -- F5
    [64] = true, -- F6
    [65] = true, -- F7
    [66] = true, -- F8
    [67] = true, -- F9
    [68] = true, -- F10
    [87] = true, -- F11
    [88] = true, -- F12
}

function gamepad.isFunctionKey(dik)
    return functionKeys[dik] == true
end

function gamepad.is_face_button_or_dpad(dik)
    return face_buttons[dik] ~= nil or dpad_button[dik] ~= nil
end

return gamepad