--[[
    Copyright (c) 2021 Cannons Pack Team
    Questionable Mark
]]

if SmartCannon then return end
dofile("Cannons_Pack_libs/ScriptLoader.lua")
SmartCannon = class(GLOBAL_SCRIPT)
SmartCannon.maxParentCount = -1
SmartCannon.maxChildCount = 1
SmartCannon.connectionInput = _connectionType.logic + _connectionType.power
SmartCannon.connectionOutput = _connectionType.logic
SmartCannon.colorNormal = _colorNew(0x5d0096ff)
SmartCannon.colorHighlight = _colorNew(0x9000e8ff)

function SmartCannon:client_onCreate()
	self.effects = _cpEffect_cl_loadEffects(self)
	self.effects.sht_snd:setParameter("sound", 1)
	self.network:sendToServer("server_requestSound", {player = _getLocalPlayer()})
	self:client_injectScript("CPProjectile")
	self.cur_rld_effect = 1
	self.cur_muzzle_flash_effect = 1
end

local _ExplosionTrans = {
	[1] = "ExplSmall",
	[2] = "AircraftCannon - Explosion",
	[3] = "ExplBig2",
	[4] = "DoraCannon - Explosion",
	[5] = "EMPCannon - Explosion"
}

function SmartCannon:server_onCreate()
	self.sv_settings = {
		number = {
			fire_spread = 0.2,
			fire_force = 700,
			reload_time = 8,
			cannon_recoil = 0,
			projectile_per_shot = 0,
			expl_level = 5,
			expl_radius = 0.5,
			expl_impulse_radius = 15,
			expl_impulse_strength = 2000,
			projectile_friction = 0.003,
			projectile_gravity = 10,
			projectile_lifetime = 15,
			projectile_type = 0,
			proximity_fuze = 0,
			x_offset = 0,
			y_offset = 0,
			z_offset = 0
		},
		logic = {
			spudgun_mode = false,
			no_friction_mode = false,
			ignore_rotation_mode = false,
			no_recoil_mode = false,
			transfer_momentum = true
		},
		sound = 0,
		muzzle_flash = 0,
		reload_sound = 0,
		explosion_effect = 0
	}

	local _SavedData = self.storage:load()
	local _DataType = type(_SavedData)
	if _DataType == "number" then
		self.sv_settings.sound = _SavedData
	elseif _DataType == "table" then
		local _NumDat = _SavedData.number or {}
		local _LogicDat = _SavedData.logic or {}

		local sv_set = self.sv_settings
		local sv_num_set = sv_set.number
		local sv_log_set = sv_set.logic

		sv_num_set.fire_spread = _NumDat.fire_spread or 0.2
		sv_num_set.fire_force = _NumDat.fire_force or 700
		sv_num_set.reload_time = _NumDat.reload_time or 8
		sv_num_set.cannon_recoil = _NumDat.cannon_recoil or 0
		sv_num_set.projectile_per_shot = _NumDat.projectile_per_shot or 0
		sv_num_set.expl_level = _NumDat.expl_level or 5
		sv_num_set.expl_radius = _NumDat.expl_radius or 0.5
		sv_num_set.expl_impulse_radius = _NumDat.expl_impulse_radius or 15
		sv_num_set.expl_impulse_strength = _NumDat.expl_impulse_strength or 2000
		sv_num_set.projectile_gravity = _NumDat.projectile_gravity or 10
		sv_num_set.projectile_lifetime = _NumDat.projectile_lifetime or 15
		sv_num_set.projectile_type = _NumDat.projectile_type or 0
		sv_num_set.proximity_fuze = _NumDat.proximity_fuze or 0
		sv_num_set.x_offset = _NumDat.x_offset or 0
		sv_num_set.y_offset = _NumDat.y_offset or 0
		sv_num_set.z_offset = _NumDat.z_offset or 0
		sv_log_set.spudgun_mode = _LogicDat.spudgun_mode
		sv_log_set.no_friction_mode = _LogicDat.no_friction_mode
		sv_log_set.ignore_rotation_mode = _LogicDat.ignore_rotation_mode
		sv_log_set.no_recoil_mode = _LogicDat.no_recoil_mode
		sv_log_set.transfer_momentum = _LogicDat.transfer_momentum
		sv_set.sound = _SavedData.sound or 0
		sv_set.muzzle_flash = _SavedData.muzzle_flash or 0
		sv_set.explosion_effect = _SavedData.explosion_effect or 0
		sv_set.reload_sound = _SavedData.reload_sound or 0
	end

	self.data_request_queue = {}
	self.projectileConfiguration = _cpCannons_loadCannonInfo(self)
	if self.sv_settings.explosion_effect > 0 then
		self.projectileConfiguration.explosionEffect = _ExplosionTrans[self.sv_settings.explosion_effect + 1]
	end
end

local _ReloadSoundTimeOffsets = {
	[1] = {val = 30, min_rld = 80},
	[2] = {val = 190, min_rld = 210}
}

function SmartCannon:server_onFixedUpdate()
	if not _smExists(self.interactable) then return end

	local _NumSettings = self.sv_settings.number
	--cannon settings
	local fire_spread = _NumSettings.fire_spread
	local fire_force = _NumSettings.fire_force
	local reload_time = _NumSettings.reload_time
	local cannon_recoil = _NumSettings.cannon_recoil
	local projectile_per_shot = _NumSettings.projectile_per_shot

	--explosion settings
	local expl_level = _NumSettings.expl_level
	local expl_radius = _NumSettings.expl_radius
	local expl_impulse_radius = _NumSettings.expl_impulse_radius
	local expl_impulse_strength = _NumSettings.expl_impulse_strength

	--projectile settings
	local projectile_friction = 0.003
	local projectile_gravity = _NumSettings.projectile_gravity
	local projectile_lifetime = _NumSettings.projectile_lifetime
	local projectile_type = _NumSettings.projectile_type
	local proximity_fuze = _NumSettings.proximity_fuze
	local x_offset = _NumSettings.x_offset
	local y_offset = _NumSettings.y_offset
	local z_offset = _NumSettings.z_offset

	local _LogicSettings = self.sv_settings.logic
	--cannon modes
	local spudgun_mode = _LogicSettings.spudgun_mode
	local no_friction_mode = _LogicSettings.no_friction_mode
	local ignore_rotation_mode = _LogicSettings.ignore_rotation_mode
	local no_recoil_mode = _LogicSettings.no_recoil_mode
	local transfer_momentum = _LogicSettings.transfer_momentum
	local cannon_active = _LogicSettings.cannon_active

	local Parents = self.interactable:getParents()
	for l, gate in pairs(Parents) do
		if not gate:hasSteering() then
			local gate_color = tostring(gate:getShape():getColor())

			if _cp_isNumberLogic(gate) then
				local g_power = gate.power
				
				if gate_color == "eeaf5cff" then --1st orange
					if g_power > 0 then fire_force = g_power end
				elseif gate_color == "673b00ff" then --3rd orange
					fire_spread = g_power
				elseif gate_color == "472800ff" then --4th orange
					reload_time = g_power
				elseif gate_color == "f06767ff" then --1st red
					if g_power > 0 then expl_level = g_power end
				elseif gate_color == "d02525ff" then --2nd red
					if g_power > 0 then expl_radius = _mathMin(g_power, 100) end
				elseif gate_color == "7c0000ff" then --3rd red
					if g_power > 0 then expl_impulse_radius = g_power end
				elseif gate_color == "560202ff" then --4th red
					if g_power >= 0 then expl_impulse_strength = g_power end
				elseif gate_color == "ee7bf0ff" then --1st pink
					projectile_gravity = g_power
				elseif gate_color == "cf11d2ff" then --2nd pink
					if g_power > 0 then projectile_lifetime = _mathMin(g_power, 30) end
				elseif gate_color == "720a74ff" then --3rd pink
					if g_power > 0 then cannon_recoil = g_power end
				elseif gate_color == "520653ff" then --4th pink
					if g_power > 0 then proximity_fuze = _mathMin(g_power, 20) end
				elseif gate_color == "f5f071ff" then --1st yellow
					x_offset = g_power / 4
				elseif gate_color == "e2db13ff" then --2nd yellow
					y_offset = g_power / 4
				elseif gate_color == "817c00ff" then --3rd yellow
					z_offset = g_power / 4
				elseif gate_color == "35086cff" then --4th violet
					if g_power >= 0 then projectile_per_shot = _mathMin(g_power, 20) end
				elseif gate_color == "eeeeeeff" then --white
					if g_power >= 0 then projectile_type = _mathFloor(_mathMin(g_power, #self.projectileConfiguration.proj_types - 1)) end
				end
			else
				if _cp_isLogic(gate) then
					local g_active = gate.active

					if gate_color == "323000ff" then --4th yellow
						ignore_rotation_mode = g_active
					elseif gate_color == "eeeeeeff" then --white
						spudgun_mode = g_active
					elseif gate_color == "7f7f7fff" then --2nd gray
						no_friction_mode = g_active
					elseif gate_color == "4a4a4aff" then --3rd gray
						no_recoil_mode = g_active
					elseif gate_color == "222222ff" then --black
						transfer_momentum = g_active
					else
						if g_active then cannon_active = true end
					end
				end
			end
		else
			gate:disconnect(self.interactable)
		end
	end

	local child = self.interactable:getChildren()[1]
	if child and tostring(child.shape.uuid) ~= "5164495e-b681-4647-b622-031317e6f6b4" then self.interactable:disconnect(child) end
	if cannon_active and not self.reload then
		if child then child:setActive(true) end

		self.reload = reload_time
		self.network:sendToClients("client_displayEffect", "sht")

		if not spudgun_mode then
			self.projectileConfiguration.localPosition = not ignore_rotation_mode

			if not ignore_rotation_mode then
				self.projectileConfiguration.position = _newVec(x_offset, y_offset, z_offset + 0.1)
			else
				self.projectileConfiguration.position = self.shape.worldPosition + _newVec(x_offset, y_offset, z_offset)
			end

			self.projectileConfiguration.friction = no_friction_mode and 0 or 0.003
			self.projectileConfiguration.gravity = projectile_gravity
			self.projectileConfiguration.lifetime = projectile_lifetime
			self.projectileConfiguration.explosionLevel = expl_level
			self.projectileConfiguration.explosionRadius = expl_radius
			self.projectileConfiguration.explosionImpulseRadius = expl_impulse_radius
			self.projectileConfiguration.explosionImpulseStrength = expl_impulse_strength
			self.projectileConfiguration.proxFuze = proximity_fuze

			for i = 1, projectile_per_shot + 1, 1 do
				self.projectileConfiguration.velocity = _cp_calculateSpread(self, fire_spread, fire_force, not transfer_momentum)
				CPProjectile:server_sendProjectile(self, self.projectileConfiguration)
			end
		else
			local _Offset = _newVec(x_offset, y_offset, z_offset)
			local _VelVec = _newVec(0, 0, fire_force + _mathAbs(self.shape.up:dot(self.shape.velocity)))
			local _ProjType = self.projectileConfiguration.proj_types[projectile_type + 1]
			for i = 1, projectile_per_shot + 1, 1 do
				local _Spread = _gunSpread(_VelVec, fire_spread)
				_cp_shootProjectile(self.shape, _ProjType, _Offset, _Spread, ignore_rotation_mode)
			end
		end

		if not no_recoil_mode then 
			_applyImpulse(self.shape, _newVec(0, 0, -(fire_force + cannon_recoil))) 
		end
	end

	if self.reload then
		local _ReloadConfig = _ReloadSoundTimeOffsets[self.sv_settings.reload_sound + 1]
		if reload_time >= _ReloadConfig.min_rld and self.reload == _ReloadConfig.val then
			self.network:sendToClients("client_displayEffect", "rld")
		end
		self.reload = (self.reload > 1 and self.reload - 1) or nil
	end

	if #self.data_request_queue > 0 then
		for k, player in pairs(self.data_request_queue) do
			self.network:sendToClient(player, "client_receiveCannonData", {
				number = {
					fire_spread = fire_spread,
					fire_force = fire_force,
					reload_time = reload_time,
					cannon_recoil = cannon_recoil,
					projectile_per_shot = projectile_per_shot,
					expl_level = expl_level,
					expl_radius = expl_radius,
					expl_impulse_radius = expl_impulse_radius,
					expl_impulse_strength = expl_impulse_strength,
					projectile_gravity = projectile_gravity,
					projectile_lifetime = projectile_lifetime,
					projectile_type = projectile_type,
					proximity_fuze = proximity_fuze,
					x_offset = x_offset,
					y_offset = y_offset,
					z_offset = z_offset
				},
				logic = {
					spudgun_mode = spudgun_mode,
					no_friction_mode = no_friction_mode,
					ignore_rotation_mode = ignore_rotation_mode,
					no_recoil_mode = no_recoil_mode,
					transfer_momentum = transfer_momentum
				}
			})
			self.data_request_queue[k] = nil
		end
	end
end

function SmartCannon:client_receiveCannonData(data)
	self:client_GUI_LoadNewData(data)
end

function SmartCannon:server_requestNumberInputs(player)
	self.data_request_queue[#self.data_request_queue + 1] = player
end

function SmartCannon:server_requestCannonData(player)
	local _ServerData = self.sv_settings

	local _Data = {
		logic = _ServerData.logic,
		number = _ServerData.number,
		sound = _ServerData.sound,
		muzzle_flash = _ServerData.muzzle_flash,
		explosion_effect = self.projectileConfiguration.explosionEffect,
		reload_sound = _ServerData.reload_sound
	}

	self.network:sendToClient(player, "client_receiveCannonData", _Data)
end

function SmartCannon:server_requestSound(data)
	self.network:sendToClient(data.player, "client_setEffects", {
		sht_snd = self.sv_settings.sound + 1,
		rld_snd = self.sv_settings.reload_sound + 1,
		sht_eff = self.sv_settings.muzzle_flash + 1
	})
end

function SmartCannon:server_setNewSettings(data)
	for k, v in pairs(data.logic) do
		if self.sv_settings.logic[k] ~= nil then
			self.sv_settings.logic[k] = v
		end
	end

	for k, v in pairs(data.number) do
		if self.sv_settings.number[k] ~= nil then
			self.sv_settings.number[k] = v
		end
	end

	self.projectileConfiguration.explosionEffect = _ExplosionTrans[data.proj_explosion + 1]
	self.sv_settings.explosion_effect = data.proj_explosion
	self.sv_settings.sound = data.sound
	self.sv_settings.reload_sound = data.reload_sound
	self.sv_settings.muzzle_flash = data.muzzle_flash

	self.network:sendToClients("client_setEffects", {
		sht_snd = self.sv_settings.sound + 1,
		rld_snd = self.sv_settings.reload_sound + 1,
		sht_eff = self.sv_settings.muzzle_flash + 1
	})

	self.storage:save(self.sv_settings)
end

local _ReloadSoundNames = {
	[1] = "Reloading",
	[2] = "HeavyReloading"
}

function SmartCannon:client_setEffects(data)
	self.effects.sht_snd:setParameter("sound", data.sht_snd)

	if self.cur_rld_effect ~= data.rld_snd then
		self.cur_rld_effect = data.rld_snd
		self.effects.rld:stop()
		self.effects.rld:destroy()
		self.effects.rld = _createEffect(_ReloadSoundNames[data.rld_snd], self.interactable)
	end

	if self.cur_muzzle_flash_effect ~= data.sht_eff then
		self.cur_muzzle_flash_effect = data.sht_eff
		self.effects.sht:stop()
		self.effects.sht:destroy()
		self.effects.sht = _createEffect("SmartCannon - MuzzleFlash"..data.sht_eff, self.interactable)
	end
end

function SmartCannon:server_getChange(data)
	self.sv_settings.sound = (self.sv_settings.sound + data.mode) % 4
	self.storage:save(self.sv_settings.sound)
	self.network:sendToClients("client_setSound", {
		soundId = self.sv_settings.sound + 1,
		caller = data.player
	})
end

function SmartCannon:client_onInteract(character, state)
	if not state then return end

	if _cpGuiSupported then
		self:client_GUI_Open()
	else
		self.network:sendToServer("server_getChange", {
			mode = (character:isCrouching() and -1 or 1),
			player = _getLocalPlayer()
		})
	end
end

function SmartCannon:client_setSound(data)
	self.effects.sht_snd:setParameter("sound", data.soundId)

	local caller = data.caller
	local loc_pl = _getLocalPlayer()

	if caller and caller == loc_pl then
		_cp_infoOutput("GUI Item drag", true, "Changed the sound to #ffff00"..data.soundId.."#ffffff")
	end
end

function SmartCannon:client_onFixedUpdate(dt)
	self:client_GUI_UpdateDotAnim()
end

function SmartCannon:client_canInteract()
	local _InteractKey = _getKeyBinding("Use")
	if _cpGuiSupported then
		_setInteractionText("Press", _InteractKey, "to open Smart Cannon GUI")
	else
		local crawl_key = _getKeyBinding("Crawl")

		_setInteractionText("Press", _InteractKey, "or", ("%s + %s"):format(crawl_key, _InteractKey), "to change the shooting sound")
	end

	_setInteractionText("", "Check the workshop page of \"Cannons Pack\" for instructions")
	return true
end

function SmartCannon:client_onDestroy()
	self:client_GUI_onDestroyCallback()
end

function SmartCannon:client_displayEffect(data)
	local _EffList = (data == "sht" and {self.effects.sht_snd, self.effects.sht} or self.effects[data])

	_cp_spawnOptimizedEffect(self.shape, _EffList, 75)
end

-----------------------------------------------
---------------SMART CANNON GUI----------------
-----------------------------------------------

local _EffectCallbackTable = {
	MFlash = {val = 1, name = "muzzle_flash"},
	ExplEffect = {val = 2, name = "expl_effect"},
	Reload = {val = 3, name = "reload_effect"},
	ShtSound = {val = 4, name = "shoot_sound"}
}

function SmartCannon:client_GUI_Open()
	local gui = _cpCreateGui("SmartCannonGUI.layout")

	for k, tab in pairs({"NumLogic", "Logic", "Effects"}) do
		gui:setButtonCallback(tab.."_Tab", "client_GUI_TabCallback")
	end

	for btn, k in pairs(_EffectCallbackTable) do
		gui:setButtonCallback("LB_"..btn, "client_GUI_onEffectValueChange")
		gui:setButtonCallback("RB_"..btn, "client_GUI_onEffectValueChange")
	end

	for k, btn in pairs({"Left", "Right"}) do
		gui:setButtonCallback("Page"..btn, "client_GUI_onNumPageChange")
	end

	for i = 1, 8 do
		gui:setButtonCallback("LogicBTN"..i, "client_GUI_onLogicValueChange")
	end

	for k, btn in pairs({"L", "R"}) do
		gui:setButtonCallback(btn.."B_Mul", "client_GUI_onMultiplierChange")
	end

	for i = 1, 6 do
		gui:setButtonCallback("RB_Val"..i, "client_GUI_onNumValueChange")
		gui:setButtonCallback("LB_Val"..i, "client_GUI_onNumValueChange")
	end

	gui:setButtonCallback("SaveChanges", "client_GUI_onSaveButtonCallback")
	gui:setButtonCallback("GetValues", "client_GUI_onGetValueCallback")
	gui:setOnCloseCallback("client_GUI_onDestroyCallback")

	self.gui = {}
	self.gui.interface = gui
	self:client_GUI_CreateTempValTable()
	self.gui.cur_page = 0
	self.gui.max_page = _mathCeil(#self.gui.temp.num_logic / 6)
	self.gui.cur_mul_page = 3
	self.gui.cur_mul = 1

	self:client_GUI_SetWaitingState(false)

	self.network:sendToServer("server_requestCannonData", _getLocalPlayer())
	
	gui:open()
end

function SmartCannon:client_GUI_onDestroyCallback()
	local gui = self.gui
	if not gui then return end

	local gui_int = gui.interface
	if _cpExists(gui_int) then
		if gui_int:isActive() then
			gui_int:close()
		end

		gui_int:destroy()
	end

	self.gui = nil
end

function SmartCannon:client_GUI_onGetValueCallback()
	local gui = self.gui

	if gui.wait_for_number_data then return end

	gui.wait_for_number_data = true
	gui.dot_anim = 0
	gui.interface:setText("GetValues", "Getting Data")

	self.network:sendToServer("server_requestNumberInputs", _getLocalPlayer())
end

function SmartCannon:client_GUI_onSaveButtonCallback()
	local _Table = {logic = {}, number = {}}

	local gui = self.gui
	local gui_int = gui.interface
	local gui_temp = gui.temp

	for k, v in pairs(gui_temp.num_logic) do _Table.number[v.id] = v.value end
	for k, v in pairs(gui_temp.logic) do _Table.logic[v.id] = v.value end

	local tmp_eff = gui_temp.effects
	_Table.sound = tmp_eff[4].value
	_Table.muzzle_flash = tmp_eff[1].value
	_Table.proj_explosion = tmp_eff[2].value
	_Table.reload_sound = tmp_eff[3].value

	self.network:sendToServer("server_setNewSettings", _Table)
	_audioPlay("Retrowildblip")
	gui_int:setVisible("SaveChanges", false)
end

function SmartCannon:client_GUI_onEffectValueChange(btn_name)
	local btn_id = btn_name:sub(0, 2)
	local idx = (btn_id == "RB" and 1 or -1)
	local eff_name = btn_name:sub(4)

	local gui = self.gui
	local gui_int = gui.interface
	local temp_eff = gui.temp.effects

	local cur_btn_idx = _EffectCallbackTable[eff_name].val

	local cur_effect = temp_eff[cur_btn_idx]
	local cur_eff_list = cur_effect.list

	local new_eff_val = _utilClamp(cur_effect.value + idx, 0, #cur_eff_list - 1)
	if new_eff_val == cur_effect.value then return end

	cur_effect.value = new_eff_val
	local cur_eff_name = cur_eff_list[new_eff_val + 1]

	gui_int:setText(eff_name.."Value", cur_eff_name)
	gui_int:setVisible("SaveChanges", true)
	_audioPlay("GUI Item released")
end

local _BoolString = {
	[true] = {bool = "#009900true#ffffff", sound = "Lever on"},
	[false] = {bool = "#ff0000false#ffffff", sound = "Lever off"}
}

function SmartCannon:client_GUI_onLogicValueChange(btn_name)
	local idx = tonumber(btn_name:sub(9))

	local gui = self.gui
	local gui_int = gui.interface
	local temp_log = gui.temp.logic

	local cur_btn = temp_log[idx]
	cur_btn.value = not cur_btn.value

	local cur_bool = _BoolString[cur_btn.value]

	gui_int:setText(btn_name, ("%s: %s"):format(cur_btn.name, cur_bool.bool))
	gui_int:setVisible("SaveChanges", true)
	_audioPlay(cur_bool.sound)
end

local NumTable = {
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
function SmartCannon:client_GUI_onMultiplierChange(btn_name)
	local btn_id = btn_name:sub(0, 2)
	local idx = (btn_id == "RB" and 1 or -1)

	local gui = self.gui
	local new_mul = _utilClamp(gui.cur_mul_page + idx, 0, 8)
	if new_mul == gui.cur_mul_page then return end

	gui.cur_mul_page = new_mul
	gui.cur_mul = NumTable[new_mul + 1]

	gui.interface:setText("MultiplierVal", "Mul: "..gui.cur_mul)
	_audioPlay("GUI Item drag")
end

function SmartCannon:client_GUI_onNumValueChange(btn_name)
	local btn_idx = tonumber(btn_name:sub(7))

	local gui = self.gui
	local gui_int = gui.interface

	local offset = (gui.cur_page * 6)
	local cur_btn_idx = offset + btn_idx
	local cur_btn = gui.temp.num_logic[cur_btn_idx]

	local btn_id = btn_name:sub(0, 2)
	local cur_btn_list = cur_btn.list
	local cur_btn_int = cur_btn.int
	local mul_val = ((cur_btn_list or cur_btn_int) and 1 or gui.cur_mul)
	local idx = (btn_id == "RB" and 1 or -1) * mul_val

	local new_value = _mathMin(_mathMax(cur_btn.value + idx, cur_btn.min), cur_btn.max)
	if new_value == cur_btn.value then return end

	cur_btn.value = new_value
	gui_int:setVisible("SaveChanges", true)

	local cur_val_name = ("NumVal"..btn_idx)
	if cur_btn_list then
		local cur_item = cur_btn_list[cur_btn.value + 1]

		gui_int:setText(cur_val_name, cur_item)
		_audioPlay("GUI Item released")
	else
		local val_txt = cur_btn_int and "%d" or "%.3f"
		gui_int:setText(cur_val_name, (val_txt):format(cur_btn.value))
		_audioPlay("GUI Inventory highlight")
	end
end

local TabFunc = {
	NumLogic_Tab = function(self)
		local gui = self.gui
		local cur_page = gui.cur_page
		local gui_int = gui.interface
		local offset = (cur_page * 6)

		local temp_num = gui.temp.num_logic
		for i = 1, 6 do
			local cur_btn = temp_num[i + offset]
			local has_data = (cur_btn ~= nil)

			for k, btn in pairs({"NumName", "LB_Val", "RB_Val", "NumVal"}) do
				gui_int:setVisible(btn..i, has_data)
			end

			if has_data then
				local cur_list = cur_btn.list
				local num_val_id = ("NumVal"..i)

				if cur_list then
					gui_int:setText(num_val_id, cur_list[cur_btn.value + 1])
				else
					local val_txt = cur_btn.int and "%d" or "%.3f"
					gui_int:setText(num_val_id, (val_txt):format(cur_btn.value))
				end

				gui_int:setText("NumName"..i, cur_btn.name)
			end
		end

		gui_int:setText("PageValue", "Page: "..(cur_page + 1).." / "..gui.max_page)
	end,
	Logic_Tab = function(self)
		local gui = self.gui
		local gui_int = gui.interface

		local temp_log = gui.temp.logic
		for i = 1, 8 do
			local cur_btn = temp_log[i]
			local has_data = (cur_btn ~= nil)

			local btn_lbl = ("LogicBTN"..i)

			gui_int:setVisible(btn_lbl, has_data)

			if has_data then
				local cur_bool = _BoolString[cur_btn.value]

				gui_int:setText(btn_lbl, ("%s: %s"):format(cur_btn.name, cur_bool.bool))
			end
		end
	end,
	Effects_Tab = function(self)
		local gui = self.gui

		local temp_eff = gui.temp.effects
		local gui_int = gui.interface
		for k, v in pairs(_EffectCallbackTable) do
			local CurList = temp_eff[v.val]
			gui_int:setText(k.."Value", CurList.list[CurList.value + 1])
		end
	end
}

function SmartCannon:client_GUI_onNumPageChange(btn_name)
	local btn_id = btn_name:sub(5)
	local idx = (btn_id == "Left" and -1 or 1)

	local new_page = _utilClamp(self.gui.cur_page + idx, 0, self.gui.max_page - 1)
	if new_page == self.gui.cur_page then return end

	self.gui.cur_page = new_page
	_audioPlay("GUI Item drag")

	TabFunc.NumLogic_Tab(self)
end

function SmartCannon:client_GUI_CreateTempValTable()
	local temp = {}
	temp.num_logic = {
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
		[12] = {name = "Projectiles Per Shot", id = "projectile_per_shot", value = 0, min = 0, max = 20, int = true},
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
	temp.logic = {
		[1] = {name = "Ignore Cannon Rotation", id = "ignore_rotation_mode", value = false},
		[2] = {name = "No Projectile Friction", id = "no_friction_mode", value = false},
		[3] = {name = "Spudgun Mode", id = "spudgun_mode", value = false},
		[4] = {name = "No Recoil Mode", id = "no_recoil_mode", value = false},
		[5] = {name = "Transfer Momentum", id = "transfer_momentum", value = false}
	}
	temp.effects = {
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

	self.gui.temp = temp
end

local TabData = {
	NumLogic_Tab = "NumLogicPage",
	Logic_Tab = "LogicPage",
	Effects_Tab = "EffectsPage"
}
function SmartCannon:client_GUI_TabCallback(tab_name)
	if self.gui.cur_tab == tab_name then return end
	_audioPlay("Handbook - Turn page")

	self:client_GUI_SetCurrentTab(tab_name)
end

function SmartCannon:client_GUI_SetCurrentTab(tab_name)
	self.gui.cur_tab = tab_name
	local gui_int = self.gui.interface

	for tab, page in pairs(TabData) do
		local tab_eq = (tab == tab_name)

		gui_int:setButtonState(tab, tab_eq)
		gui_int:setVisible(page, tab_eq)
	end

	TabFunc[tab_name](self)
end

local _ExplTranslation = {
	["ExplSmall"] = 0,
	["AircraftCannon - Explosion"] = 1,
	["ExplBig2"] = 2,
	["DoraCannon - Explosion"] = 3,
	["EMPCannon - Explosion"] = 4
}

function SmartCannon:client_GUI_LoadNewData(data)
	local gui = self.gui
	if not gui then return end

	local gui_temp = gui.temp

	local s_logic = gui_temp.logic
	local d_logic = data.logic
	for k, v in pairs(s_logic) do
		local cur_d_log = d_logic[v.id]

		if cur_d_log ~= nil then
			s_logic[k].value = cur_d_log
		end
	end
	
	local s_numLog = gui_temp.num_logic
	local d_numLog = data.number
	for k, v in pairs(s_numLog) do
		local cur_dNumLog = d_numLog[v.id]

		if cur_dNumLog ~= nil then
			local cur_data = s_numLog[k]

			cur_data.value = _mathMin(_mathMax(cur_dNumLog, cur_data.min), cur_data.max)
		end
	end

	local m_flash = data.muzzle_flash
	local ex_eff = data.explosion_effect
	local rel_snd = data.reload_sound
	local d_snd = data.sound

	if m_flash and ex_eff and rel_snd and d_snd then
		local s_effects = gui_temp.effects

		s_effects[1].value = m_flash
		s_effects[2].value = _ExplTranslation[ex_eff]
		s_effects[3].value = rel_snd
		s_effects[4].value = d_snd
	end

	if gui.wait_for_data then
		self:client_GUI_SetCurrentTab("NumLogic_Tab")
		self:client_GUI_SetWaitingState(true)
	end

	if gui.wait_for_number_data then
		gui.wait_for_number_data = nil
		gui.dot_anim = nil

		local gui_int = gui.interface
		gui_int:setText("GetValues", "Get Input Values")
		gui_int:setVisible("SaveChanges", true)
		self:client_GUI_SetCurrentTab(gui.cur_tab)
		_audioPlay("ConnectTool - Selected")
	end
end

function SmartCannon:client_GUI_SetWaitingState(state)
	local gui = self.gui
	local gui_int = gui.interface

	local n_state = not state
	gui_int:setVisible("LoadingScreen", n_state)
	for k, btn in pairs({"NumLogic_Tab", "Logic_Tab", "Effects_Tab", "MultiplierVal", "RB_Mul", "LB_Mul", "GetValues", "NumLogicPage"}) do
		gui_int:setVisible(btn, state)
	end

	gui.wait_for_data = (n_state and true or nil)
	gui.dot_anim = (n_state and 0 or nil)
end

local _DotAnimation = {[1] = "", [2] = ".", [3] = "..", [4] = "..."}
function SmartCannon:client_GUI_UpdateDotAnim()
	local gui = self.gui
	if not gui then return end

	local _wait_for_data = gui.wait_for_data
	local _wait_for_n_data = gui.wait_for_number_data

	if gui and (_wait_for_data or _wait_for_n_data) then
		local cur_tick = _getCurrentTick() % 26

		if cur_tick == 25 then
			gui.dot_anim = (gui.dot_anim + 1) % 4
			local cur_step = _DotAnimation[gui.dot_anim + 1]

			local gui_int = gui.interface

			if _wait_for_data then
				gui_int:setText("LoadingScreen", "#ff6f00GETTING DATA FROM SERVER#ffffff"..cur_step)
			end

			if _wait_for_n_data then
				gui_int:setText("GetValues", "Getting Data"..cur_step)
			end
		end
	end
end