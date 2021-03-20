--[[
    Copyright (c) 2021 Cannons Pack Team
    Questionable Mark
]]

if SmartCannonGUI then return end
SmartCannonGUI = class()

SmartCannonGUI.NumTable = {
    [1] = 0.001,
    [2] = 0.01,
    [3] = 0.1,
    [4] = 1,
    [5] = 10,
    [6] = 100,
    [7] = 1000,
    [8] = 10000,
    [9] = 100000
}
local _TabCallbacks = {
    {button = "NumLogic_Tab", state = 0},
    {button = "Logic_Tab", state = 1},
    {button = "Effects_Tab", state = 2}
}

function SmartCannonGUI.SetupTabCallbacks(self)
    for k, v in pairs(_TabCallbacks) do
        local _CallbackName = (v.button.."_clickCallback")
        self[_CallbackName] = function(self)
            SmartCannonGUI.SwitchTab(self, v.state)
        end
        self.c_gui:setButtonCallback(v.button, _CallbackName)
    end
end

function SmartCannonGUI.CreateTempVariableTable(self)
    self.gui_temp_value_table = {
        [1] = {name = "Fire Force", id = "fire_force", value = 0, min = 1, max = math.huge},
        [2] = {name = "Spread", id = "fire_spread", value = 0, min = 0, max = 360},
        [3] = {name = "Reload Time", id = "reload_time", value = 0, min = 0, max = 1000000},
        [4] = {name = "Explosion Level", id = "expl_level", value = 0, min = 0.001, max = math.huge},
        [5] = {name = "Explosion Radius", id  = "expl_radius", value = 0, min = 0.001, max = 100},
        [6] = {name = "Explosion Impulse Radius", id = "expl_impulse_radius", value = 0, min = 0.001, max = math.huge},
        [7] = {name = "Explosion Impulse Strength", id = "expl_impulse_strength", value = 0, min = 0, max = math.huge},
        [8] = {name = "Projectile Gravity", id = "projectile_gravity", value = 0, min = -math.huge, max = math.huge},
        [9] = {name = "Projectile Lifetime", id = "projectile_lifetime", value = 0, min = 0.001, max = 30},
        [10] = {name = "Recoil", id = "cannon_recoil", value = 0, min = 0, max = math.huge},
        [11] = {name = "Proximity Fuze", id = "proximity_fuze", value = 0, min = 0, max = 20},
        [12] = {name = "Projectiles Per Shot", id = "projectile_per_shot", value = 0, min = 0, max = 20},
        [13] = {name = "X Projectile Offset", id = "x_offset", value = 0, min = -math.huge, max = math.huge},
        [14] = {name = "Y Projectile Offset", id = "y_offset", value = 0, min = -math.huge, max = math.huge},
        [15] = {name = "Z Projectile Offset", id = "z_offset", value = 0, min = -math.huge, max = math.huge},
        [16] = {name = "Projectile Type (Spudgun Mode)", id = "projectile_type", value = 0, min = 0, max = 16, list = {
            [1] = "Potato",     [2] = "Small Potato", [3] = "Fries",
            [4] = "Tomato",     [5] = "Carrot",      [6] = "Redbeet",
            [7] = "Broccoli",   [8] = "Pineapple",   [9] = "Orange",
            [10] = "Blueberry", [11] = "Banana",     [12] = "Tape",
            [13] = "Water",     [14] = "Fertilizer", [15] = "Chemical",
            [16] = "Pesticide", [17] = "Seed"
        }}
    }
    self.gui_temp_logic_table = {
        [1] = {name = "Ignore Cannon Rotation", id = "ignore_rotation_mode", value = false},
        [2] = {name = "No Projectile Friction", id = "no_friction_mode", value = false},
        [3] = {name = "Spudgun Mode", id = "spudgun_mode", value = false},
        [4] = {name = "No Recoil Mode", id = "no_recoil_mode", value = false},
        [5] = {name = "Transfer Momentum", id = "transfer_momentum", value = false}
    }
    self.gui_temp_effect_values = {
        [1] = {value = 0, list = { --1 muzzle flash
            [1] = "Default", [2] = "Small Explosion",
            [3] = "Big Explosion", [4] = "Frier Muzzle Flash",
            [5] = "Spinner Muzzle Flash"
        }},
        [2] = {value = 0, list = { --2 explosion effect
            [1] = "Default",         [2] = "Little Explosion",
            [3] = "Big Explosion",   [4] = "Giant Explosion",
            [5] = "Sparks"
        }},
        [3] = {value = 0, list = { --3 reloading effect
            [1] = "Default", [2] = "Heavy Realoading"
        }},
        [4] = {value = 0, list = { --4 shooting sound
            [1] = "Default", [2] = "Sound 1",
            [3] = "Potato Shotgun", [4] = "Spudling Gun",
            [5] = "Explosion"
        }}
    }
end

local _NumVarComponents = {"NumName", "LB_Val", "RB_Val", "NumVal"}
function SmartCannonGUI.LoadNumLogicPage(self, page)
    local _PageOffset = (6 * page) - 6
    for i = 1, 6 do
        local _CurVariable = self.gui_temp_value_table[i + _PageOffset]

        if _CurVariable then
            for k, v in pairs(_NumVarComponents) do
                self.c_gui:setVisible(v..i, true)
            end

            self.c_gui:setText("NumName"..i, _CurVariable.name)
            local _NumValId = ("NumVal"..i)
            if _CurVariable.list then
                self.c_gui:setText(_NumValId, _CurVariable.list[_CurVariable.value + 1])
            else
                self.c_gui:setText(_NumValId, ("%.3f"):format(_CurVariable.value))
            end
        else
            for k, v in pairs(_NumVarComponents) do
                self.c_gui:setVisible(v..i, false)
            end
        end
    end
    self.c_gui:setText("PageValue", "Page: "..page.." / "..self.gui_maximum_page)
end

local _BoolString = {
    [true] = {bool = "#009900true#ffffff", sound = "Lever on"},
    [false] = {bool = "#ff0000false#ffffff", sound = "Lever off"}
}

function SmartCannonGUI.LoadLogicPage(self, page)
    local _PageOffset = (8 * page) - 8
    for i = 1, 8 do
        local _CurVariable = self.gui_temp_logic_table[i + _PageOffset]

        local _ButtonId = ("LogicBTN"..i)
        if _CurVariable then
            self.c_gui:setVisible(_ButtonId, true)
            self.c_gui:setText(_ButtonId, _CurVariable.name..": ".._BoolString[_CurVariable.value].bool)
        else
            self.c_gui:setVisible(_ButtonId, false)
        end
    end
end

function SmartCannonGUI.SetupPageCallbacks(self)
    self.PageRight_Callback = function(self) SmartCannonGUI.SwitchPages(self, 1) end
    self.c_gui:setButtonCallback("PageRight", "PageRight_Callback")

    self.PageLeft_Callback = function(self) SmartCannonGUI.SwitchPages(self, -1) end
    self.c_gui:setButtonCallback("PageLeft", "PageLeft_Callback")
end

function SmartCannonGUI.SwitchPages(self, page)
    local _NewValue = math.min(math.max(self.gui_page + page, 1), self.gui_maximum_page)
    if _NewValue ~= self.gui_page then
        self.gui_page = _NewValue
        SmartCannonGUI.LoadNumLogicPage(self, self.gui_page)
        sm.audio.play("GUI Item drag")
    end
end

function SmartCannonGUI.CreateButtonCallbacks(self)
    for i = 1, 6 do
        local _LeftCallback = "LeftButton_callback"..i
        local _RightCallback = "RightButton_callback"..i
        self[_LeftCallback] = function(self)
            SmartCannonGUI.ChangeNumberValue(self, i, -1)
        end
        self.c_gui:setButtonCallback("LB_Val"..i, _LeftCallback)

        self[_RightCallback] = function(self)
            SmartCannonGUI.ChangeNumberValue(self, i, 1)
        end
        self.c_gui:setButtonCallback("RB_Val"..i, _RightCallback)
    end

    for i = 1, 8 do
        local _ButtonCallback = "LogicButton_callback"..i
        self[_ButtonCallback] = function(self)
            SmartCannonGUI.ChangeBooleanValue(self, i)
        end
        self.c_gui:setButtonCallback("LogicBTN"..i, _ButtonCallback)
    end
end

local _ExplTranslation = {
    ["ExplSmall"] = 0,
    ["AircraftCannon - Explosion"] = 1,
    ["ExplBig2"] = 2,
    ["DoraCannon - Explosion"] = 3,
    ["EMPCannon - Explosion"] = 4
}

function SmartCannonGUI.LoadNewData(self, data)
    if not self.c_gui then return end

    for k, v in pairs(self.gui_temp_logic_table) do
        if data.logic[v.id] ~= nil then
            self.gui_temp_logic_table[k].value = data.logic[v.id]
        end
    end

    for k, v in pairs(self.gui_temp_value_table) do
        if data.number[v.id] ~= nil then
            local _CurList = self.gui_temp_value_table[k]
            self.gui_temp_value_table[k].value = math.min(math.max(data.number[v.id], _CurList.min), _CurList.max)
        end
    end

    if data.muzzle_flash and data.explosion_effect and data.reload_sound and data.sound then
        self.gui_temp_effect_values[1].value = data.muzzle_flash
        self.gui_temp_effect_values[2].value = _ExplTranslation[data.explosion_effect]
        self.gui_temp_effect_values[3].value = data.reload_sound
        self.gui_temp_effect_values[4].value = data.sound

        SmartCannonGUI.UpdateEffectsPage(self)
    end

    SmartCannonGUI.LoadNumLogicPage(self, self.gui_page)
    SmartCannonGUI.LoadLogicPage(self, 1)

    if self.gui_waiting_for_data then
        self.gui_waiting_for_data = nil
        self.gui_animation_step = nil
        self.gui_animation_time = nil

        self.c_gui:setVisible("LoadingScreen", false)
        for k, v in pairs({"NumLogic_Tab", "Logic_Tab", "Effects_Tab", "MultiplierVal", "RB_Mul", "LB_Mul", "GetValues", "NumLogicPage"}) do
            self.c_gui:setVisible(v, true)
        end
    end

    if self.gui_waiting_for_number_data then
        self.gui_waiting_for_number_data = nil
        self.gui_animation_time = nil
        self.gui_animation_step = nil

        self.c_gui:setText("GetValues", "Get Input Values")
        sm.audio.play("ConnectTool - Selected")
        self.c_gui:setVisible("SaveChanges", true)
    end
end

local _AnimationStrings = {[1] = "", [2] = ".", [3] = "..", [4] = "..."}
function SmartCannonGUI.UpdateGuiText(self)
    local _GuiActive = (self.c_gui and self.c_gui:isActive())
    if not _GuiActive then return end

    if (sm.game.getCurrentTick() % 26) == 25 then
        if self.gui_waiting_for_data or self.gui_waiting_for_number_data then
            self.gui_animation_step = (self.gui_animation_step + 1) % #_AnimationStrings
            self.gui_animation_time = self.gui_animation_time + 1
            local _DotAnim = _AnimationStrings[self.gui_animation_step + 1]

            if self.gui_waiting_for_data then
                local _OutOfTime = ""
                if self.gui_animation_time > 15 then
                    self.gui_animation_time = 15
                    _OutOfTime = "\nDamn your ping is pretty bad ngl"
                end

                self.c_gui:setText("LoadingScreen", "#ff6f00GETTING DATA FROM SERVER#ffffff".._DotAnim.._OutOfTime)
            end

            if self.gui_waiting_for_number_data then
                self.c_gui:setText("GetValues", "Getting Data".._DotAnim)
            end
        end
    end
end

function SmartCannonGUI.SetupMultiplierCallbacks(self)
    self.multiplier_callback_left = function(self) SmartCannonGUI.OnMultiplierChange(self, -1) end
    self.multiplier_callback_right = function(self) SmartCannonGUI.OnMultiplierChange(self, 1) end
    self.c_gui:setButtonCallback("RB_Mul", "multiplier_callback_right")
    self.c_gui:setButtonCallback("LB_Mul", "multiplier_callback_left")
end

local _EffectCallbackTable = {
    [1] = {val = 1, name = "muzzle_flash", id = "MFlash"},
    [2] = {val = 2, name = "expl_effect", id = "ExplEffect"},
    [3] = {val = 3, name = "reload_effect", id = "Reload"},
    [4] = {val = 4, name = "shoot_sound", id = "ShtSound"}
}

function SmartCannonGUI.ChangeEffectValue(self, label, index, changer)
    local _CurVal = self.gui_temp_effect_values[index]
    self.gui_temp_effect_values[index].value = (_CurVal.value + changer) % #_CurVal.list

    self.c_gui:setText(label, _CurVal.list[self.gui_temp_effect_values[index].value + 1])
    sm.audio.play("GUI Item released")
    self.c_gui:setVisible("SaveChanges", true)
end

function SmartCannonGUI.SetupEffectTabCallbacks(self)
    for k, v in pairs(_EffectCallbackTable) do
        local _RCallbackName = "R"..v.name.."_callback_func"
        local _LCallbackName = "L"..v.name.."_callback_func"
        
        local _LabelVal = (v.id.."Value")
        self[_RCallbackName] = function(self) SmartCannonGUI.ChangeEffectValue(self, _LabelVal, k, 1) end
        self[_LCallbackName] = function(self) SmartCannonGUI.ChangeEffectValue(self, _LabelVal, k, -1) end

        self.c_gui:setButtonCallback("RB_"..v.id, _RCallbackName)
        self.c_gui:setButtonCallback("LB_"..v.id, _LCallbackName)

        local _CurList = self.gui_temp_effect_values[k]
        self.c_gui:setText(_LabelVal, _CurList.list[_CurList.value + 1])
    end
end

function SmartCannonGUI.UpdateEffectsPage(self)
    for k, v in pairs(_EffectCallbackTable) do
        local _CurList = self.gui_temp_effect_values[k]
        self.c_gui:setText(v.id.."Value", _CurList.list[_CurList.value + 1])
    end
end

function SmartCannonGUI.CreateGUI(self)
    self.c_gui = CP_GUI.CreateGUI("SmartCannonGUI.layout")
    self.c_gui:setButtonState("NumLogic_Tab", true)
    self.current_tab = 0

    SmartCannonGUI.SetupTabCallbacks(self)
    SmartCannonGUI.SetupPageCallbacks(self)
    SmartCannonGUI.CreateTempVariableTable(self)
    SmartCannonGUI.CreateButtonCallbacks(self)
    SmartCannonGUI.SetupMultiplierCallbacks(self)
    SmartCannonGUI.SetupEffectTabCallbacks(self)

    self.gui_multiplier_page = 3
    self.gui_maximum_page = math.ceil(#self.gui_temp_value_table / 6)
    self.gui_page = 1
    self.gui_animation_step = 0
    self.gui_animation_time = 0
    self.gui_waiting_for_data = true
    SmartCannonGUI.LoadNumLogicPage(self, self.gui_page)
    SmartCannonGUI.LoadLogicPage(self, 1)
    self.c_gui:setText("MultiplierVal", "Mul: "..SmartCannonGUI.NumTable[self.gui_multiplier_page + 1])

    self.save_button_callback = SmartCannonGUI.OnSaveButtonPress
    self.c_gui:setButtonCallback("SaveChanges", "save_button_callback")

    self.destroy_gui_callback = SmartCannonGUI.OnDestroyGUICallback
    self.c_gui:setOnCloseCallback("destroy_gui_callback")

    self.request_input_values_callback = function(self)
        if self.gui_waiting_for_number_data then return end
        self.c_gui:setText("GetValues", "Getting Data")
        self.gui_animation_step = 0
        self.gui_animation_time = 0
        self.gui_waiting_for_number_data = true
        self.network:sendToServer("server_requestNumberInputs", sm.localPlayer.getPlayer())
    end
    self.c_gui:setButtonCallback("GetValues", "request_input_values_callback")
    self.c_gui:open()
    self.network:sendToServer("server_requestCannonData", sm.localPlayer.getPlayer())
end

local _SwitchFunctions = {
    [1] = {btn = "NumLogic_Tab", page = "NumLogicPage"},
    [2] = {btn = "Logic_Tab", page = "LogicPage"},
    [3] = {btn = "Effects_Tab", page = "EffectsPage"}
}

function SmartCannonGUI.SwitchTab(self, state)
    if self.current_tab ~= state then
        self.current_tab = state

        local _ActiveIndex = state + 1
        local _ActivePage = _SwitchFunctions[_ActiveIndex]

        for k, v in pairs(_SwitchFunctions) do
            if _ActiveIndex ~= k then
                self.c_gui:setVisible(v.page, false)
                self.c_gui:setButtonState(v.btn, false)
            end
        end
        self.c_gui:setVisible(_ActivePage.page, true)
        self.c_gui:setButtonState(_ActivePage.btn, true)

        sm.audio.play("Handbook - Turn page")
    end
end

function SmartCannonGUI.ChangeNumberValue(self, index, changer)
    local _IndexOffset = index + ((6 * self.gui_page) - 6)
    local _CurTab = self.gui_temp_value_table[_IndexOffset]
    
    if _CurTab.list then
        self.gui_temp_value_table[_IndexOffset].value = (_CurTab.value + changer) % #_CurTab.list

        self.c_gui:setText("NumVal"..index, _CurTab.list[self.gui_temp_value_table[_IndexOffset].value + 1])
        sm.audio.play("GUI Item released")
        self.c_gui:setVisible("SaveChanges", true)
    else
        local _FinalChanger = SmartCannonGUI.NumTable[self.gui_multiplier_page + 1] * changer
        local _ChangedValue = math.min(math.max(_CurTab.value + _FinalChanger, _CurTab.min), _CurTab.max)
        if _ChangedValue ~= _CurTab.value then
            self.gui_temp_value_table[_IndexOffset].value = _ChangedValue
            self.c_gui:setText("NumVal"..index, ("%.3f"):format(self.gui_temp_value_table[_IndexOffset].value))
            sm.audio.play("GUI Inventory highlight")
            self.c_gui:setVisible("SaveChanges", true)
        end
    end
end

function SmartCannonGUI.ChangeBooleanValue(self, index)
    local _CurTab = self.gui_temp_logic_table[index]
    self.gui_temp_logic_table[index].value = not _CurTab.value

    self.c_gui:setText("LogicBTN"..index, _CurTab.name..": ".._BoolString[_CurTab.value].bool)
    sm.audio.play(_BoolString[self.gui_temp_logic_table[index].value].sound)
    self.c_gui:setVisible("SaveChanges", true)
end

function SmartCannonGUI.OnSaveButtonPress(self, data)
    local _Table = {logic = {}, number = {}}
    for k, v in pairs(self.gui_temp_value_table) do _Table.number[v.id] = v.value end
    for k, v in pairs(self.gui_temp_logic_table) do _Table.logic[v.id] = v.value end
    _Table.sound = self.gui_temp_effect_values[4].value
    _Table.muzzle_flash = self.gui_temp_effect_values[1].value
    _Table.proj_explosion = self.gui_temp_effect_values[2].value
    _Table.reload_sound = self.gui_temp_effect_values[3].value
    self.network:sendToServer("server_setNewSettings", _Table)
    sm.audio.play("Retrowildblip")
    self.c_gui:setVisible("SaveChanges", false)
end

function SmartCannonGUI.OnMultiplierChange(self, changer)
    self.gui_multiplier_page = (self.gui_multiplier_page + changer) % #SmartCannonGUI.NumTable

    self.c_gui:setText("MultiplierVal", "Mul: "..SmartCannonGUI.NumTable[self.gui_multiplier_page + 1])
    sm.audio.play("GUI Item drag")
end

function SmartCannonGUI.OnDestroyGUICallback(self)
    if not self.c_gui then return end
    self.c_gui:destroy()
    self.c_gui = nil
    for i = 1, 6 do
        self["LeftButton_callback"..i] = nil
        self["RightButton_callback"..i] = nil
    end
    for i = 1, 8 do self["LogicButton_callback"..i] = nil end
    for k, v in pairs(_TabCallbacks) do self[v.button.."_clickCallback"] = nil end
    for k, v in pairs(_EffectCallbackTable) do
        self["R"..v.name.."_callback_func"] = nil
        self["L"..v.name.."_callback_func"] = nil
    end
    self.PageRight_Callback = nil
    self.PageLeft_Callback = nil
    self.gui_temp_effect_values = nil
    self.gui_temp_logic_table = nil
    self.gui_temp_value_table = nil
    self.destroy_gui_callback = nil
    self.multiplier_callback_left = nil
    self.multiplier_callback_right = nil
    self.gui_multiplier_page = nil
    self.gui_maximum_page = nil
    self.gui_page = nil
    self.save_button_callback = nil
    self.current_tab = nil
    self.gui_waiting_for_data = nil
    self.gui_animation_step = nil
    self.gui_animation_time = nil
    self.request_input_values_callback = nil
end