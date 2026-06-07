--[[    BSD License Disclaimer
        Copyright © 2017, SirEdeonX
        All rights reserved.

        Redistribution and use in source and binary forms, with or without
        modification, are permitted provided that the following conditions are met:

            * Redistributions of source code must retain the above copyright
              notice, this list of conditions and the following disclaimer.
            * Redistributions in binary form must reproduce the above copyright
              notice, this list of conditions and the following disclaimer in the
              documentation and/or other materials provided with the distribution.
            * Neither the name of xivcrossbar nor the
              names of its contributors may be used to endorse or promote products
              derived from this software without specific prior written permission.

        THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
        ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
        WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
        DISCLAIMED. IN NO EVENT SHALL SirEdeonX BE LIABLE FOR ANY
        DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
        (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
        LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
        ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
        (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
        SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]

-- https://github.com/Windower/Lua/wiki/
-- https://docs.windower.net/commands/

-- TODO: add keybind for rewriting (what did I mean by this?)
-- TODO: FEATURE IDEA: "flat mode" where icons are horizontal (left up down right)
-- TODO: FEATURE IDEA: "left only" or "right only" modes where you only have keybinds for half the controller

-- Addon description
_addon.name = 'XIV Crossbar' -- based on Edeon's XIV Hotbar
_addon.author = 'Aliekber'
_addon.version = '0.1'
_addon.language = 'english'
_addon.commands = {'xivcrossbar', 'xb'}

-- Libs
res = require 'resources'
config = require('config')
file = require('files')
texts = require('texts')
images = require('images')
tables = require('tables')
resources = require('resources')
xml = require('libs/xml2')   -- TODO: REMOVE

-- User settings
local defaults = require('defaults')
local settings = config.load(defaults)
config.save(settings)

-- Load theme options according to settings
local theme = require('theme')
local theme_options = theme.apply(settings)
local resource_generator = require('resource_generator')
resource_generator.generate_outdated_resources()

-- Addon Dependencies
local action_manager = require('action_manager')
local keyboard = require('keyboard_mapper')
local gamepad = require('gamepad')
local player = require('player')
local ui = require('ui')
local env_chooser = require('environment_chooser')
local action_binder = require('action_binder')
local enchanted_items = require('enchanted_items')
local xivcrossbar = require('variables')
local skillchains = require('libs/skillchain/skillchains')
local consumables = require('consumables')
local gamepad_converter = require('gamepad_converter')

-----------------------------
-- Main
-----------------------------

local gamepad_state = {
    ahkCtrl_IsPressed = false,
    ahkAlt_IsPressed = false,
    xbarChain = "", -- L, R, LR, RL, LL, RR
    isLeftDoublePressWindowOpen = false,
    isRightDoublePressWindowOpen = false,
}
gamepad_state.active_bar = 0
local ui_dirty = false

local function closeLeftDoublePressWindow()
    gamepad_state.isLeftDoublePressWindowOpen = false
end

local function closeRightDoublePressWindow()
    gamepad_state.isRightDoublePressWindowOpen = false
end

-- command to set a crossbar action in action_binder
function set_hotkey(hotbar, slot, action_type, action, target, command, icon)
    local environment = player.hotbar_settings.active_environment

    local alias = nil
    if (action == 'Ranged Attack') then
        action = 'ra'
        alias = 'Ranged Attack'
        icon = 'ranged'
    elseif (action == 'Attack') then
        action = 'a'
        alias = 'Attack'
        icon = 'attack'
    elseif (action_type == 'assist') then
        action_type = 'ct'
        alias = action
        action = action:lower()
        icon = 'assist'
    elseif (action == 'Last Synth') then
        action = 'lastsynth'
        alias = 'Last Synth'
        icon = 'synth'
    end

    if (command ~= nil) then
        alias = action
        action = command
    end

    local new_action = action_manager:build(action_type, action, target, alias, icon)
    player:add_action(new_action, environment, hotbar, slot)
    player:save_hotbar()
    reload_hotbar()
    set_active_environment(environment)
end

-- command to set a crossbar action in action_binder
function delete_hotkey(hotbar, slot)
    local environment = player.hotbar_settings.active_environment

    player:remove_action(environment, hotbar, slot)
    player:save_hotbar()
    reload_hotbar()
    set_active_environment(environment)
end

function get_crossbar_sets()
    return player:get_crossbar_names()
end

function start_controller_wrappers()
    -- only one of these is ever needed at a time, but there's no harm in running both
    windower.send_command('run addons/xivcrossbar/ffxi_directinput.ahk')
    windower.send_command('run addons/xivcrossbar/ffxi_xinput.ahk')
end

-- initialize addon
function initialize()
    local windower_player = windower.ffxi.get_player()
    local server = resources.servers[windower.ffxi.get_info().server].en
    if (server == nil) then
        server = 'UnknownServer'
    end

    if windower_player == nil then return end

    -- TODO: untangle this mess
    theme_options.button_layout = 'nintendo'
    action_binder:setup(set_hotkey, delete_hotkey, theme_options, get_crossbar_sets, 150, 150, windower.get_windower_settings().ui_x_res - 300, windower.get_windower_settings().ui_y_res - 450)

    player:initialize(windower_player, server, theme_options, enchanted_items)
    player:load_hotbar()
    ui:setup(theme_options, enchanted_items)
    action_binder:set_ui_offset_callback(function(x, y)
        ui:update_offsets(x, y)
        if (settings.Style.OffsetX ~= x) then
            settings.Style.OffsetX = x
        end
        if (settings.Style.OffsetY ~= y) then
            settings.Style.OffsetY = y
        end
        config.save(settings)
    end)

    local default_active_environment = env_chooser:get_default_active_environment(player.hotbar)
    set_active_environment(default_active_environment)
    ui:load_player_hotbar(player.hotbar, player.vitals, player.hotbar_settings.active_environment, gamepad_state)

    consumables:setup()
    env_chooser:setup(theme_options)
    gamepad_converter:setup(theme_options.button_layout)

    xivcrossbar.ready = true
    xivcrossbar.initialized = true
end

-- trigger hotbar action
function trigger_action(slot)
    player:execute_action(slot)
    ui:trigger_feedback(player.hotbar_settings.active_hotbar, slot)
end

-- set battle environment
function set_battle_environment(in_battle)
    player:set_battle_environment(in_battle)
    ui:load_player_hotbar(player.hotbar, player.vitals, player.hotbar_settings.active_environment, gamepad_state)
end

-- set battle environment
function set_active_environment(environment_name)
    player:set_active_environment(environment_name)
    ui:load_player_hotbar(player.hotbar, player.vitals, player.hotbar_settings.active_environment, gamepad_state)
end

-- check validity of an environment
function is_valid_environment(environment_name)
    return player:is_valid_environment(environment_name)
end

-- reload hotbar
function reload_hotbar()
    player:load_hotbar()
    ui:load_player_hotbar(player.hotbar, player.vitals, player.hotbar_settings.active_environment, gamepad_state)
end

-- change active hotbar
function change_active_hotbar(new_hotbar)
    gamepad_state.active_bar = new_hotbar
    player:change_active_hotbar(new_hotbar)
end

-----------------------------
-- Addon Commands
-----------------------------

-- command to switch to a specific crossbar
function switch_crossbars_command(args)
    if not args[1] then
        print('XIVCROSSBAR: Invalid arguments: crossbar <crossbar_set>')
        return
    end

    local environment = args[1]:lower()

    if (is_valid_environment(environment)) then
        set_active_environment(environment)
    else
        print('XIVCROSSBAR: "' .. environment .. '" is not a valid crossbar set.')
    end
end

-- command to set an action in a hotbar
function set_action_command(args)
    if not args[5] then
        print('XIVCROSSBAR: Invalid arguments: set <mode> <hotbar> <slot> <action_type> <action> <target (optional)> <alias (optional)> <icon (optional)>')
        return
    end

    local environment = args[1]:lower()

    if (args[2] == nil) then
        if (is_valid_environment(args[2])) then
            set_active_environment(args[2])
        else
            print('XIVCROSSBAR: "' .. args[2] .. '" is not a valid crossbar set.')
        end
    end

    local hotbar = gamepad_converter:convert_to_crossbar(args[2]) or 0
    local slot = gamepad_converter:convert_to_slot(args[3]) or 0
    local action_type = args[4]:lower()
    local action = args[5]
    local target = args[6] or nil
    local alias = args[7] or nil
    local icon = args[8] or nil

    if hotbar < 1 or hotbar > theme_options.hotbar_number then
        print('XIVCROSSBAR: Invalid hotbar. Please use a number between 1 and ' .. theme_options.hotbar_number .. '.')
        return
    end

    if slot < 1 or slot > 8 then
        print('XIVCROSSBAR: Invalid slot. Please use a number between 1 and 8.')
        return
    end

    if target ~= nil then target = target:lower() end

    local new_action = action_manager:build(action_type, action, target, alias, icon)
    player:add_action(new_action, environment, hotbar, slot)
    player:save_hotbar()
    reload_hotbar()
end

-- command to delete an action from an hotbar
function delete_action_command(args)
    if not args[3] then
        print('XIVCROSSBAR: Invalid arguments: del <mode> <hotbar> <slot>')
        return
    end

    local environment = args[1]:lower()
    local hotbar = gamepad_converter:convert_to_crossbar(args[2]) or 0
    local slot = gamepad_converter:convert_to_slot(args[3]) or 0

    if hotbar < 1 or hotbar > theme_options.hotbar_number then
        print('XIVCROSSBAR: Invalid hotbar. Please use a number between 1 and ' .. theme_options.hotbar_number .. '.')
        return
    end

    if slot < 1 or slot > 8 then
        print('XIVCROSSBAR: Invalid slot. Please use a number between 1 and 8.')
        return
    end

    player:remove_action(environment, hotbar, slot)
    player:save_hotbar()
    reload_hotbar()
end

-- command to copy an action to another slot
function copy_action_command(args, is_moving)
    local command = 'copy'
    if is_moving then command = 'move' end

    if not args[6] then
        print('XIVCROSSBAR: Invalid arguments: ' .. command .. ' <mode> <hotbar> <slot> <to_mode> <to_hotbar> <to_slot>')
        return
    end

    local environment = args[1]:lower()
    local hotbar = gamepad_converter:convert_to_crossbar(args[2]) or 0
    local slot = gamepad_converter:convert_to_slot(args[3]) or 0
    local to_environment = args[4]:lower()
    local to_hotbar = gamepad_converter:convert_to_crossbar(args[5]) or 0
    local to_slot = gamepad_converter:convert_to_slot(args[6]) or 0

    if hotbar < 1 or hotbar > 3 or to_hotbar < 1 or to_hotbar > 3 then
        print('XIVCROSSBAR: Invalid hotbar. Please use a number between 1 and ' .. theme_options.hotbar_number .. '.')
        return
    end

    if slot < 1 or slot > 8 or to_slot < 1 or to_slot > 8 then
        print('XIVCROSSBAR: Invalid slot. Please use a number between 1 and 8.')
        return
    end

    player:copy_action(environment, hotbar, slot, to_environment, to_hotbar, to_slot, is_moving)
    player:save_hotbar()
    reload_hotbar()
end

-- command to update action alias
function update_alias_command(args)
    if not args[4] then
        print('XIVCROSSBAR: Invalid arguments: alias <mode> <hotbar> <slot> <alias>')
        return
    end

    local environment = args[1]:lower()
    local hotbar = gamepad_converter:convert_to_crossbar(args[2]) or 0
    local slot = gamepad_converter:convert_to_slot(args[3]) or 0
    local alias = args[4]

    if hotbar < 1 or hotbar > 3 then
        print('XIVCROSSBAR: Invalid hotbar. Please use a number between 1 and ' .. theme_options.hotbar_number .. '.')
        return
    end

    if slot < 1 or slot > 8 then
        print('XIVCROSSBAR: Invalid slot. Please use a number between 1 and 8.')
        return
    end

    player:set_action_alias(environment, hotbar, slot, alias)
    player:save_hotbar()
    reload_hotbar()
end

-- command to update action icon
function update_icon_command(args)
    if not args[4] then
        print('XIVCROSSBAR: Invalid arguments: icon <mode> <hotbar> <slot> <icon>')
        return
    end

    local environment = args[1]:lower()
    local hotbar = gamepad_converter:convert_to_crossbar(args[2]) or 0
    local slot = gamepad_converter:convert_to_slot(args[3]) or 0
    local icon = args[4]

    if hotbar < 1 or hotbar > 3 then
        print('XIVCROSSBAR: Invalid hotbar. Please use a number between 1 and ' .. theme_options.hotbar_number .. '.')
        return
    end

    if slot < 1 or slot > 8 then
        print('XIVCROSSBAR: Invalid slot. Please use a number between 1 and 8.')
        return
    end

    player:set_action_icon(environment, hotbar, slot, icon)
    player:save_hotbar()
    reload_hotbar()
end

-- command to update action icon
function new_environment_command(args)
    if not args[1] then
        print('XIVCROSSBAR: Invalid arguments: new <name>')
        return
    end

    local environment = args[1]
    local env_lower = environment:lower()

    if (env_lower == 'default' or env_lower == 'job-default' or env_lower == 'all-jobs-default') then
        print('XIVCROSSBAR: Crossbar set name "' .. environment .. '" is reserved. Unable to create.')
        return
    end

    player:create_new_environment(environment)
    player:save_hotbar()
    reload_hotbar()
    set_active_environment(environment)
end

function regenerate_resources()
    resource_generator.generate_all_resources()
end

-- command to display help for the user
function display_help_menu()

    -- TODO: add other commands here
    windower.send_command('echo ================XIVCrossbar Help===============')
    windower.send_command('echo To create a new crossbar set, use the command:')
    windower.send_command('echo xb new <crossbar set name>')
    windower.send_command('echo ===============================================')
    windower.send_command('echo Typical Gamepad Controls:')
    windower.send_command('echo Center-Left Button: Toggle button bind utility.')
    windower.send_command('echo Center-Right Button + D-Pad (↑/↓): Switch between crossbar sets.')
    windower.send_command('echo L/R Bumper + D-Pad/Face Button: Navigate button bind utility.')
    windower.send_command('echo L/R Bumper + D-Pad/Face Button: Execute bound action.')
    windower.send_command('echo ===============================================')

end

-----------------------------
-- Bind Events
-----------------------------

-- ON LOAD
windower.register_event('load', function()
    start_controller_wrappers()

    if windower.ffxi.get_info().logged_in then
        initialize()
    end
    skillchains.load()

    -- Unbind <F1 through F12> up because they're going proxy the gamepad's triggers and buttons.
    -- These inputs are preceeded by Ctrl and Alt, but Windower does not interpret the function
    -- keys as having modifiers (because the keyboard event "flags" parameter is always zero).
    windower.send_command('unbind F1 up') -- XbarLeft Up, CycleSets Next
    windower.send_command('unbind F2 up') -- XbarLeft Down, CycleSets Previous
    windower.send_command('unbind F3 up') -- XbarLeft Left
    windower.send_command('unbind F4 up') -- XbarLeft Right
    windower.send_command('unbind F5 up') -- XbarRight Up
    windower.send_command('unbind F6 up') -- XbarRight Down
    windower.send_command('unbind F7 up') -- XbarRight Left
    windower.send_command('unbind F8 up') -- XbarRight Right
    windower.send_command('unbind F9 up') -- FunctionMap ToggleBind
    windower.send_command('unbind F10 up') -- FunctionMap CycleSets
    windower.send_command('unbind F11 up') -- FunctionMap XbarLeft
    windower.send_command('unbind F12 up') -- FunctionMap XbarRight

end)

-- ON LOGIN
windower.register_event('login', function()
    initialize()
    skillchains.login()
end)

-- ON LOGOUT
windower.register_event('logout', function()
    -- TODO: UI did not properly hide on logout
    -- it also doesn't work properly when you log back in (no reaction to controller inputs)
    ui:hide()
    skillchains.logout()
end)

-- ON COMMAND
windower.register_event('addon command', function(command, ...)
    command = command and command:lower() or 'help'
    local args = {...}

    if command == 'reload' then
        return reload_hotbar()

    elseif command == 'bar' or command == 'crossbar' or command == 'hotbar' then
        switch_crossbars_command(args)
    elseif command == 'set' then
        set_action_command(args)
    elseif command == 'del' or command == 'delete' then
        delete_action_command(args)
    elseif command == 'cp' or command == 'copy' then
        copy_action_command(args, false)
    elseif command == 'mv' or command == 'move' then
        copy_action_command(args, true)
    elseif command == 'ic' or command == 'icon' then
        update_icon_command(args)
    elseif command == 'al' or command == 'alias' or command == 'ca' or command == 'caption' then
        update_alias_command(args)
    elseif command == 'n' or command == 'new' then
        new_environment_command(args)
    elseif command == 'regenerate' then
        regenerate_resources()
    elseif command == '?' or command == 'help' then
        display_help_menu()
    end
end)

local function updateXbarChain(dik, pressed)

    if gamepad.isFM_XbarLeft(dik) then

        if pressed then

            if gamepad_state.FM_XbarRight_IsPressed then
                gamepad_state.xbarChain = "RL"

            elseif gamepad_state.isLeftDoublePressWindowOpen then
                gamepad_state.isLeftDoublePressWindowOpen = false
                gamepad_state.xbarChain = "LL"

            else -- only this FM_Xbar is pressed
                ---@diagnostic disable-next-line: undefined-field
                coroutine.schedule(closeLeftDoublePressWindow, 0.5)
                gamepad_state.isLeftDoublePressWindowOpen = true
                gamepad_state.xbarChain = "L"
            end

        else -- released

            if gamepad_state.FM_XbarRight_IsPressed then
                gamepad_state.xbarChain = "R"
            else -- neither FM_Xbar pressed
                gamepad_state.xbarChain = ""
            end

        end

    elseif gamepad.isFM_XbarRight(dik) then

        if pressed then

            if gamepad_state.FM_XbarLeft_IsPressed then
                gamepad_state.xbarChain = "LR"

            elseif gamepad_state.isRightDoublePressWindowOpen then
                gamepad_state.isRightDoublePressWindowOpen = false
                gamepad_state.xbarChain = "RR"

            else -- only this FM_Xbar is pressed
                ---@diagnostic disable-next-line: undefined-field
                coroutine.schedule(closeRightDoublePressWindow, 0.5)
                gamepad_state.isRightDoublePressWindowOpen = true
                gamepad_state.xbarChain = "R"
            end

        else -- released

            if gamepad_state.FM_XbarLeft_IsPressed then
                gamepad_state.xbarChain = "L"
            else -- neither FM_Xbar pressed
                gamepad_state.xbarChain = ""
            end

        end

    else return false end -- no change

    local max = theme_options.hotbar_number

    if gamepad_state.xbarChain == "" then
        change_active_hotbar(0)
    elseif gamepad_state.xbarChain == "L" then
        change_active_hotbar(1)
    elseif gamepad_state.xbarChain == "R" then
        change_active_hotbar(2)
    elseif gamepad_state.xbarChain == "LR" then
        change_active_hotbar(max >= 3 and 3 or 0)
    elseif gamepad_state.xbarChain == "RL" then
        change_active_hotbar(max >= 4 and 4 or 3)
    elseif gamepad_state.xbarChain == "LL" then
        change_active_hotbar(max >= 5 and 5 or 1)
    elseif gamepad_state.xbarChain == "RR" then
        change_active_hotbar(max >= 6 and 6 or 2)
    end

    return true

end

windower.register_event('keyboard', function(dik, pressed, flags, blocked)

    -- AutoHotkey SendInput("^{F1 up}") is sent as "{Ctrl down}{F1 up}{Ctrl up}".
    -- The input sent by AutoHotkey does NOT have flags like keyboard input does.
    -- FFXI interprets this as Ctrl+F1, but Windower interprets it as just F1.
    -- It looks like Windower relies on the event flags but FFXI does not.

    -- Windower documentation states that returning true will prevent the keyboard
    -- action from reaching the game. In reality, returning true changes nothing.
    -- https://github.com/Windower/Lua/wiki/Events

    -- This lua version does not seem to support bitwise operators.
    -- flags: 1 = shift, 2 = alt, 4 = ctrl
    -- 1/3/5/7 = shift
    -- 2/3/6/7 = alt
    -- 4/5/6/7 = ctrl

    -- for testing:
    -- windower.send_command(string.format(
    --     "echo dik: %s | pressed: %s | flags: %s | blocked %s",
    --     dik, tostring(pressed), flags, tostring(blocked)))

    if flags ~= 0 then return end -- all AutoHotkey input is sent without flags

    if dik == keyboard.ctrl then gamepad_state.ahkCtrl_IsPressed = pressed
    elseif dik == keyboard.alt then gamepad_state.ahkAlt_IsPressed = pressed end

    if not gamepad.isFunctionKey(dik) then return end -- remaining logic only cares about F1-F12
    if not gamepad_state.ahkCtrl_IsPressed then return end -- AutoHotkey always sends Alt before F1-F12
    if pressed then return end -- AutoHotkey always sends F1-F12 as keyup events

    -- AutoHotkey sends F1-F12 as keyup events to avoid interfering with normal functionality.
    -- Most keys are are "clicked", and only one event is needed to trigger the desired result.
    -- For keys that can be held and later released, Alt is sent when the key is being released.
    pressed = not gamepad_state.ahkAlt_IsPressed

    local xbarChainChanged = updateXbarChain(dik, pressed)
    if xbarChainChanged then ui_dirty = true end

    if gamepad.isFM_XbarLeft(dik) then
        gamepad_state.FM_XbarLeft_IsPressed = pressed
    elseif gamepad.isFM_XbarRight(dik) then
        gamepad_state.FM_XbarRight_IsPressed = pressed
    elseif gamepad.isFM_CycleSets(dik) then
        gamepad_state.FM_CycleSets_IsPressed = pressed
    end

    -- TODO: for action binding, first Xbar event indicates the key being used to bind.

    if (gamepad.isFM_ToggleBind(dik)) then
        if (action_binder.is_hidden) then
            action_binder:show()
            ui:hide_button_hints()
            env_chooser:temp_hide_default_sets_tooltip()
        else
            action_binder:hide()
            action_binder:reset_state()
            ui:maybe_show_button_hints()
            env_chooser:maybe_unhide_default_sets_tooltip()
        end
        return true
    end

    if (not action_binder.is_hidden) then
        if (gamepad.is_face_button_or_dpad(dik)) then
            local action_binder_was_showing = not action_binder.is_hidden

            if (gamepad.isFM_Confirm(dik)) then
                action_binder:FM_Confirm()
            elseif (gamepad.isFM_Cancel(dik)) then
                action_binder:FM_Cancel()
            end

            if (gamepad.isXL_Left(dik)) then
                action_binder:XL_Left()
            elseif (gamepad.isXL_Down(dik)) then
                action_binder:XL_Down()
            elseif (gamepad.isXL_Right(dik)) then
                action_binder:XL_Right()
            elseif (gamepad.isXL_Up(dik)) then
                action_binder:XL_Up()
            elseif (gamepad.isXR_Left(dik)) then
                action_binder:XR_Left()
            elseif (gamepad.isXR_Down(dik)) then
                action_binder:XR_Down()
            elseif (gamepad.isXR_Right(dik)) then
                action_binder:XR_Right()
            elseif (gamepad.isXR_Up(dik)) then
                action_binder:XR_Up()
            end

            if (action_binder_was_showing and action_binder.is_hidden) then
                ui:maybe_show_button_hints()
            end
            return true
        end

        if (gamepad.isFM_XbarLeft(dik)) then
            action_binder:FM_XbarLeft(pressed)
        elseif (gamepad.isFM_XbarRight(dik)) then
            action_binder:FM_XbarRight(pressed)
        end
    end

    if (env_chooser:is_showing()) then
        -- handle up and down arrows if the environment chooser is showing
        if gamepad.isCS_Previous(dik) then
            local prev_environment = env_chooser:get_prev_environment(player.hotbar, player.hotbar_settings.active_environment)
            set_active_environment(prev_environment)
            env_chooser:show_player_environments(player.hotbar, player.hotbar_settings.active_environment)
            return true
        elseif gamepad.isCS_Next(dik) then -- up dpad
            local next_environment = env_chooser:get_next_environment(player.hotbar, player.hotbar_settings.active_environment)
            set_active_environment(next_environment)
            env_chooser:show_player_environments(player.hotbar, player.hotbar_settings.active_environment)
            return true
        end
    end

    local any_trigger_down = gamepad_state.FM_XbarLeft_IsPressed or gamepad_state.FM_XbarRight_IsPressed
    if (any_trigger_down and gamepad.is_face_button_or_dpad(dik)) then
        if (gamepad.isXL_Left(dik)) then
            trigger_action(1)
        elseif (gamepad.isXL_Down(dik)) then
            trigger_action(2)
        elseif (gamepad.isXL_Right(dik)) then
            trigger_action(3)
        elseif (gamepad.isXL_Up(dik)) then
            trigger_action(4)
        elseif (gamepad.isXR_Left(dik)) then
            trigger_action(5)
        elseif (gamepad.isXR_Down(dik)) then
            trigger_action(6)
        elseif (gamepad.isXR_Right(dik)) then
            trigger_action(7)
        elseif (gamepad.isXR_Up(dik)) then
            trigger_action(8)
        end
    end

    if gamepad.isFM_CycleSets(dik) then
        if (pressed) then
            env_chooser:show_player_environments(player.hotbar, player.hotbar_settings.active_environment)
        else
            env_chooser:hide_player_environments()
        end
    end

end)

local frame = 0

-- ON PRERENDER
windower.register_event('prerender',function()
    -- allow settings to skip rendering frames
    frame = (frame + 1)  % (theme_options.frame_skip + 1)
    if (frame > 0 and not ui_dirty) then
        return
    end

    skillchains.prerender()
    if xivcrossbar.ready == false then
        return
    end

    if ui.feedback.is_active then
        ui:show_feedback()
    end

    if ui.is_setup and xivcrossbar.hide_hotbars == false then
        local dim_default_slots = not action_binder.is_hidden        
        ui:check_recasts(player.hotbar, player.vitals, player.hotbar_settings.active_environment, player.current_spells, gamepad_state, skillchains, consumables, dim_default_slots, xivcrossbar.in_battle)
    end

    ui_dirty = false
end)

-- ON ACTIONS (filtered to Job Abilities)
windower.register_event('action', function(actor_id, category)
    if (actor_id == player:get_id() and category == 6) then -- category 6 = Job Ability
        player:update_current_spells()
    end
end)

-- EVERY VANA'DIEL MINUTE
windower.register_event('time change', function(actor_id, category)
    player:update_current_spells()
end)

-- ON MP CHANGE
windower.register_event('mp change', function(new, old)
    player.vitals.mp = new
    ui:check_vitals(player.hotbar, player.vitals, player.hotbar_settings.active_environment)
end)

-- ON TP CHANGE
windower.register_event('tp change', function(new, old)
    player.vitals.tp = new
    ui:check_vitals(player.hotbar, player.vitals, player.hotbar_settings.active_environment)
end)

-- ON STATUS CHANGE
windower.register_event('status change', function(new_status_id)
    -- hide/show bar in cutscenes
    if xivcrossbar.hide_hotbars == false and new_status_id == 4 then
        xivcrossbar.hide_hotbars = true
        ui:hide()
    elseif xivcrossbar.hide_hotbars and new_status_id ~= 4 then
        xivcrossbar.hide_hotbars = false
        ui:show(player.hotbar, player.hotbar_settings.active_environment)
    end

    -- Disabling this for now, but we might want it later
    -- -- alternate environment on battle
    if xivcrossbar.in_battle == false and (new_status_id == 1 or new_status_id == 3) then
        xivcrossbar.in_battle = true
        player:set_is_in_battle(true)
    --     set_battle_environment(true)
    elseif xivcrossbar.in_battle and new_status_id ~= 1 and new_status_id ~= 3 then
        xivcrossbar.in_battle = false
        player:set_is_in_battle(false)
    --     set_battle_environment(false)
    end
end)

-- ON JOB CHANGE
windower.register_event('job change',function(main_job, main_job_level, sub_job, sub_job_level)
    skillchains.job_change(main_job, main_job_level)
    player:update_jobs(resources.jobs[main_job].ens, resources.jobs[sub_job].ens)
    reload_hotbar()
end)

local CATEGORY_COMPLETED_SPELL = 4
local CATEGORY_JOB_ABILITY = 6
local SUMMONING_MAGIC = 38
local RELEASE = 90
local LIGHT_ARTS = 211
local DARK_ARTS = 212
local ADDENDUM_WHITE = 234
local ADDENDUM_BLACK = 235

local no_pet_environment = nil

windower.register_event('action', function(act)
    -- Don't swap crossbars when someone *else* summons or uses Light/Dark Arts
    local windower_player = windower.ffxi.get_player()
    if (act.actor_id ~= windower_player.id) then
        return
    end

    if (act.category == CATEGORY_COMPLETED_SPELL) then
        local spell = resources.spells[act.param]
        if (spell ~= nil and spell.skill == SUMMONING_MAGIC and is_valid_environment(spell.en:gsub(' ', ''):lower())) then
            no_pet_environment = player.hotbar_settings.active_environment
            set_active_environment(spell.en:gsub(' ', ''):lower())
        end
    elseif (act.category == CATEGORY_JOB_ABILITY and act.param == RELEASE) then
        if (no_pet_environment ~= nil and is_valid_environment(no_pet_environment)) then
            set_active_environment(no_pet_environment)
            no_pet_environment = nil
        end
    elseif (act.category == CATEGORY_JOB_ABILITY and act.param == LIGHT_ARTS) then
        if (is_valid_environment('lightarts')) then
            set_active_environment('lightarts')
        end
    elseif (act.category == CATEGORY_JOB_ABILITY and act.param == DARK_ARTS) then
        if (is_valid_environment('darkarts')) then
            set_active_environment('darkarts')
        end
    elseif (act.category == CATEGORY_JOB_ABILITY and act.param == ADDENDUM_WHITE) then
        if (is_valid_environment('addendumwhite')) then
            set_active_environment('addendumwhite')
        end
    elseif (act.category == CATEGORY_JOB_ABILITY and act.param == ADDENDUM_BLACK) then
        if (is_valid_environment('addendumblack')) then
            set_active_environment('addendumblack')
        end
    end
end)

windower.register_event('incoming chunk', function(id, data)
    skillchains.incoming_chunk(id, data)
end)

windower.register_event('zone change', function()
    skillchains.zone_change()
end)
