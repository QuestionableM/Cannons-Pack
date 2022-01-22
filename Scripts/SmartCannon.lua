--[[
	Copyright (c) 2021 Cannons Pack Team
	Questionable Mark
]]

--if SmartCannon then return end
dofile("Cannons_Pack_libs/ScriptLoader.lua")
SmartCannon = class(GLOBAL_SCRIPT)
SmartCannon.maxParentCount = -1
SmartCannon.maxChildCount = 1
SmartCannon.connectionInput = _connectionType.logic + _connectionType.power
SmartCannon.connectionOutput = _connectionType.logic
SmartCannon.colorNormal = _colorNew(0x5d0096ff)
SmartCannon.colorHighlight = _colorNew(0x9000e8ff)

function SmartCannon:client_onCreate()
	self:client_injectScript("CPProjectile")

	self.effects = _cpEffect_cl_loadEffects(self)
	self.effects[EffectEnum.sht_snd]:setParameter("sound", 1)

	self.network:sendToServer("server_requestSound")

	self.cur_rld_effect = 1
	self.cur_muzzle_flash_effect = 1
end

local _ExplosionTrans = {
	[1] = ExplEffectEnum.ExplSmall,
	[2] = ExplEffectEnum.AircraftCannon,
	[3] = ExplEffectEnum.ExplBig2,
	[4] = ExplEffectEnum.DoraCannon,
	[5] = ExplEffectEnum.EMPCannon
}

local NumLogicTrTable = {
	fire_spread = 1,
	fire_force = 2,
	reload_time = 3,
	cannon_recoil = 4,
	projectile_per_shot = 5,
	expl_level = 6,
	expl_radius = 7,
	expl_impulse_radius = 8,
	expl_impulse_strength = 9,
	projectile_gravity = 10,
	projectile_lifetime = 11,
	projectile_type = 12,
	proximity_fuze = 13,
	x_offset = 14,
	y_offset = 15,
	z_offset = 16
}

local LogicTrTable = {spudgun_mode = 1, no_friction_mode = 2, ignore_rotation_mode = 3, no_recoil_mode = 4, transfer_momentum = 5}
local OtherTrTable = {sound = 1, muzzle_flash = 2, reload_sound = 3, explosion_effect = 4}

function SmartCannon:server_onCreate()
	self.sv_settings = {
		number = {
			[NumLogicTrTable.fire_spread] = 0.2,
			[NumLogicTrTable.fire_force] = 700,
			[NumLogicTrTable.reload_time] = 8,
			[NumLogicTrTable.cannon_recoil] = 0,
			[NumLogicTrTable.projectile_per_shot] = 0,
			[NumLogicTrTable.expl_level] = 5,
			[NumLogicTrTable.expl_radius] = 0.5,
			[NumLogicTrTable.expl_impulse_radius] = 15,
			[NumLogicTrTable.expl_impulse_strength] = 2000,
			[NumLogicTrTable.projectile_gravity] = 10,
			[NumLogicTrTable.projectile_lifetime] = 15,
			[NumLogicTrTable.projectile_type] = 0,
			[NumLogicTrTable.proximity_fuze] = 0,
			[NumLogicTrTable.x_offset] = 0,
			[NumLogicTrTable.y_offset] = 0,
			[NumLogicTrTable.z_offset] = 0
		},
		logic = {
			[LogicTrTable.spudgun_mode] = false,
			[LogicTrTable.no_friction_mode] = false,
			[LogicTrTable.ignore_rotation_mode] = false,
			[LogicTrTable.no_recoil_mode] = false,
			[LogicTrTable.transfer_momentum] = true
		},
		[OtherTrTable.sound] = 0,
		[OtherTrTable.muzzle_flash] = 0,
		[OtherTrTable.reload_sound] = 0,
		[OtherTrTable.explosion_effect] = 0,
		version = 1
	}

	local _SavedData = self.storage:load()
	local _DataType = type(_SavedData)
	if _DataType == "number" then
		self.sv_settings.sound = _SavedData
	elseif _DataType == "table" then
		local sv_set = self.sv_settings
		local sv_num_set = sv_set.number
		local sv_log_set = sv_set.logic
		local sv_ver_exists = (_SavedData.version ~= nil)

		for k, v in pairs(_SavedData.number or {}) do
			local tr_key = (sv_ver_exists and k or NumLogicTrTable[k])
			if sv_num_set[tr_key] ~= nil then
				sv_num_set[tr_key] = v
			end
		end

		for k, v in pairs(_SavedData.logic or {}) do
			local tr_key = (sv_ver_exists and k or LogicTrTable[k])
			if sv_log_set[tr_key] ~= nil then
				sv_log_set[tr_key] = v
			end
		end

		for k, v in pairs(_SavedData or {}) do
			if k ~= "logic" and k ~= "number" and k ~= "version" then
				local tr_key = (sv_ver_exists and k or OtherTrTable[k])
				if sv_set[tr_key] ~= nil then
					sv_set[tr_key] = v
				end
			end
		end
	end

	self.data_request_queue = {}

	local cannon_info = _cpCannons_loadCannonInfo(self)
	self.proj_data_id = cannon_info.proj_data_id
	self.proj_types = cannon_info.proj_types
	self.proj_type_amount = #self.proj_types

	self.projConfig = _cpProj_GetProjectileSettings(self.proj_data_id)

	local sv_expl_eff = self.sv_settings[OtherTrTable.explosion_effect]
	if sv_expl_eff > 0 then
		self.projConfig[ProjSettingEnum.explosionEffect] = _ExplosionTrans[sv_expl_eff + 1]
	end
end

local _ReloadSoundTimeOffsets = {
	[1] = {val = 30, min_rld = 80},
	[2] = {val = 190, min_rld = 210}
}

local number_or_logic = bit.bnot(bit.bor(_connectionType.logic, _connectionType.power))
function SmartCannon:client_getAvailableParentConnectionCount(connectionType)
	if bit.band(connectionType, number_or_logic) == 0 then
		return 1
	end

	return 0
end

function SmartCannon:client_getAvailableChildConnectionCount(connectionType)
	if connectionType == _connectionType.logic then
		return 1 - #self.interactable:getChildren(_connectionType.logic)
	end

	return 0
end

function SmartCannon:server_onFixedUpdate()
	if not _smExists(self.interactable) then return end

	local _NumSettings = self.sv_settings.number
	--cannon settings
	local fire_spread = _NumSettings[NumLogicTrTable.fire_spread]
	local fire_force = _NumSettings[NumLogicTrTable.fire_force]
	local reload_time = _NumSettings[NumLogicTrTable.reload_time]
	local cannon_recoil = _NumSettings[NumLogicTrTable.cannon_recoil]
	local projectile_per_shot = _NumSettings[NumLogicTrTable.projectile_per_shot]

	--explosion settings
	local expl_level = _NumSettings[NumLogicTrTable.expl_level]
	local expl_radius = _NumSettings[NumLogicTrTable.expl_radius]
	local expl_impulse_radius = _NumSettings[NumLogicTrTable.expl_impulse_radius]
	local expl_impulse_strength = _NumSettings[NumLogicTrTable.expl_impulse_strength]

	--projectile settings
	local projectile_friction = 0.003
	local projectile_gravity = _NumSettings[NumLogicTrTable.projectile_gravity]
	local projectile_lifetime = _NumSettings[NumLogicTrTable.projectile_lifetime]
	local projectile_type = _NumSettings[NumLogicTrTable.projectile_type]
	local proximity_fuze = _NumSettings[NumLogicTrTable.proximity_fuze]
	local x_offset = _NumSettings[NumLogicTrTable.x_offset]
	local y_offset = _NumSettings[NumLogicTrTable.y_offset]
	local z_offset = _NumSettings[NumLogicTrTable.z_offset]

	local _LogicSettings = self.sv_settings.logic
	--cannon modes
	local spudgun_mode = _LogicSettings[LogicTrTable.spudgun_mode]
	local no_friction_mode = _LogicSettings[LogicTrTable.no_friction_mode]
	local ignore_rotation_mode = _LogicSettings[LogicTrTable.ignore_rotation_mode]
	local no_recoil_mode = _LogicSettings[LogicTrTable.no_recoil_mode]
	local transfer_momentum = _LogicSettings[LogicTrTable.transfer_momentum]
	local cannon_active = false

	local Parents = self.interactable:getParents()
	for l, gate in pairs(Parents) do
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
				if g_power >= 0 then
					projectile_type = _mathFloor(_mathMin(g_power, self.proj_type_amount - 1))
				end
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
	end

	local child = self.interactable:getChildren()[1]
	if child and tostring(child.shape.uuid) ~= "5164495e-b681-4647-b622-031317e6f6b4" then self.interactable:disconnect(child) end
	if cannon_active and not self.reload then
		if child then child:setActive(true) end

		self.reload = reload_time
		self.network:sendToClients("client_displayEffect", EffectEnum.sht)
		local s_Shape = self.shape

		if not spudgun_mode then
			self.projConfig[ProjSettingEnum.localPosition] = not ignore_rotation_mode

			if not ignore_rotation_mode then
				self.projConfig[ProjSettingEnum.position] = _newVec(x_offset, y_offset, z_offset + 0.1)
			else
				self.projConfig[ProjSettingEnum.position] = s_Shape.worldPosition + _newVec(x_offset, y_offset, z_offset)
			end

			self.projConfig[ProjSettingEnum.friction] = no_friction_mode and 0 or 0.003
			self.projConfig[ProjSettingEnum.gravity] = projectile_gravity
			self.projConfig[ProjSettingEnum.lifetime] = projectile_lifetime
			self.projConfig[ProjSettingEnum.explosionLevel] = expl_level
			self.projConfig[ProjSettingEnum.explosionRadius] = expl_radius
			self.projConfig[ProjSettingEnum.explosionImpulseRadius] = expl_impulse_radius
			self.projConfig[ProjSettingEnum.explosionImpulseStrength] = expl_impulse_strength
			self.projConfig[ProjSettingEnum.proxFuze] = proximity_fuze

			for i = 1, projectile_per_shot + 1, 1 do
				self.projConfig[ProjSettingEnum.velocity] = _cp_calculateSpread(self, fire_spread, fire_force, not transfer_momentum)
				CPProjectile:server_sendProjectile(self, self.projConfig, self.proj_data_id)
			end
		else
			local _Offset = _newVec(x_offset, y_offset, z_offset)

			local _VelVec = _newVec(0, 0, fire_force)
			if transfer_momentum then
				_VelVec.z = _VelVec.z + _mathAbs(s_Shape.up:dot(s_Shape.velocity))
			end

			local _ProjType = self.proj_types[projectile_type + 1]
			for i = 1, projectile_per_shot + 1, 1 do
				local _Spread = _gunSpread(_VelVec, fire_spread)
				_cp_shootProjectile(s_Shape, _ProjType, 28, _Offset, _Spread, ignore_rotation_mode)
			end
		end

		if not no_recoil_mode then 
			_applyImpulse(self.shape, _newVec(0, 0, -(fire_force + cannon_recoil))) 
		end
	end

	if self.reload then
		local _ReloadConfig = _ReloadSoundTimeOffsets[self.sv_settings[OtherTrTable.reload_sound] + 1]
		if reload_time >= _ReloadConfig.min_rld and self.reload == _ReloadConfig.val then
			self.network:sendToClients("client_displayEffect", EffectEnum.rld)
		end
		self.reload = (self.reload > 1 and self.reload - 1) or nil
	end

	if #self.data_request_queue > 0 then
		for k, player in pairs(self.data_request_queue) do
			self.network:sendToClient(player, "client_receiveCannonData", {
				number = {
					[NumLogicTrTable.fire_spread] = fire_spread,
					[NumLogicTrTable.fire_force] = fire_force,
					[NumLogicTrTable.reload_time] = reload_time,
					[NumLogicTrTable.cannon_recoil] = cannon_recoil,
					[NumLogicTrTable.projectile_per_shot] = projectile_per_shot,
					[NumLogicTrTable.expl_level] = expl_level,
					[NumLogicTrTable.expl_radius] = expl_radius,
					[NumLogicTrTable.expl_impulse_radius] = expl_impulse_radius,
					[NumLogicTrTable.expl_impulse_strength] = expl_impulse_strength,
					[NumLogicTrTable.projectile_gravity] = projectile_gravity,
					[NumLogicTrTable.projectile_lifetime] = projectile_lifetime,
					[NumLogicTrTable.projectile_type] = projectile_type,
					[NumLogicTrTable.proximity_fuze] = proximity_fuze,
					[NumLogicTrTable.x_offset] = x_offset,
					[NumLogicTrTable.y_offset] = y_offset,
					[NumLogicTrTable.z_offset] = z_offset
				},
				logic = {
					[LogicTrTable.spudgun_mode] = spudgun_mode,
					[LogicTrTable.no_friction_mode] = no_friction_mode,
					[LogicTrTable.ignore_rotation_mode] = ignore_rotation_mode,
					[LogicTrTable.no_recoil_mode] = no_recoil_mode,
					[LogicTrTable.transfer_momentum] = transfer_momentum
				}
			})
			self.data_request_queue[k] = nil
		end
	end
end

function SmartCannon:client_receiveCannonData(data)
	self:client_GUI_LoadNewData(data)
end

function SmartCannon:server_requestNumberInputs(data, player)
	self.data_request_queue[#self.data_request_queue + 1] = player
end

function SmartCannon:server_requestCannonData(data, player)
	local _ServerData = self.sv_settings

	local _Data = {
		logic = _ServerData.logic,
		number = _ServerData.number,
		snd = _ServerData[OtherTrTable.sound],
		mzl_fls = _ServerData[OtherTrTable.muzzle_flash],
		exp_eff = self.projConfig[ProjSettingEnum.explosionEffect],
		rld_snd = _ServerData[OtherTrTable.reload_sound]
	}

	self.network:sendToClient(player, "client_receiveCannonData", _Data)
end

function SmartCannon:server_prepareEffectTable()
	local sv_set = self.sv_settings
	return {
		sv_set[OtherTrTable.sound] + 1,
		sv_set[OtherTrTable.reload_sound] + 1,
		sv_set[OtherTrTable.muzzle_flash] + 1
	}
end

function SmartCannon:server_requestSound(data, caller)
	self.network:sendToClient(caller, "client_setEffects", self:server_prepareEffectTable())
end

function SmartCannon:server_setNewSettings(data)
	local sv_logic = self.sv_settings.logic
	for k, v in pairs(data.logic) do
		if sv_logic[k] ~= nil then sv_logic[k] = v end
	end

	local sv_number = self.sv_settings.number
	for k, v in pairs(data.number) do
		if sv_number[k] ~= nil then sv_number[k] = v end
	end

	self.projConfig[ProjSettingEnum.explosionEffect] = _ExplosionTrans[data.exp_eff + 1]
	self.sv_settings[OtherTrTable.explosion_effect] = data.exp_eff
	self.sv_settings[OtherTrTable.sound] = data.snd
	self.sv_settings[OtherTrTable.reload_sound] = data.rld_snd
	self.sv_settings[OtherTrTable.muzzle_flash] = data.mzl_fls

	self.network:sendToClients("client_setEffects", self:server_prepareEffectTable())

	self.storage:save(self.sv_settings)
end

local _ReloadSoundNames = {[1] = "Reloading", [2] = "HeavyReloading"}
function SmartCannon:client_setEffects(data)
	self.effects[EffectEnum.sht_snd]:setParameter("sound", data[1])

	local rld_snd = data[2]
	if self.cur_rld_effect ~= rld_snd then
		self.cur_rld_effect = rld_snd

		local rld_effect = self.effects[EffectEnum.rld]
		rld_effect:stopImmediate()
		rld_effect:destroy()
		self.effects[EffectEnum.rld] = _createEffect(_ReloadSoundNames[rld_snd], self.interactable)
	end

	local sht_eff = data[3]
	if self.cur_muzzle_flash_effect ~= sht_eff then
		self.cur_muzzle_flash_effect = sht_eff

		local sht_effect = self.effects[EffectEnum.sht]
		sht_effect:stopImmediate()
		sht_effect:destroy()
		self.effects[EffectEnum.sht] = _createEffect("SmartCannon - MuzzleFlash"..sht_eff, self.interactable)
	end
end

function SmartCannon:client_onInteract(character, state)
	if not state then return end

	self:client_GUI_Open()
end

function SmartCannon:client_onFixedUpdate(dt)
	self:client_GUI_UpdateDotAnim()
end

function SmartCannon:client_canInteract()
	local k_Inter = _getKeyBinding("Use")

	_setInteractionText("Press", k_Inter, "to open Smart Cannon GUI")
	_setInteractionText("", "Check the workshop page of \"Cannons Pack\" for instructions")

	return true
end

function SmartCannon:client_onDestroy()
	self:client_GUI_onDestroyCallback()
end

function SmartCannon:client_displayEffect(data)
	local e_List = self.effects
	local cur_effects = (data == EffectEnum.sht and {e_List[EffectEnum.sht_snd], e_List[EffectEnum.sht]} or e_List[data])

	_cp_spawnOptimizedEffect(self.shape, cur_effects, 75)
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

	self.network:sendToServer("server_requestCannonData")
	
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

	self.network:sendToServer("server_requestNumberInputs")
end

function SmartCannon:client_GUI_onSaveButtonCallback()
	local _Table = {logic = {}, number = {}}

	local gui = self.gui
	local gui_int = gui.interface
	local gui_temp = gui.temp

	for k, v in pairs(gui_temp.num_logic) do _Table.number[v.id] = v.value end
	for k, v in pairs(gui_temp.logic) do _Table.logic[v.id] = v.value end


	local tmp_eff = gui_temp.effects
	_Table.snd = tmp_eff[4].value
	_Table.mzl_fls = tmp_eff[1].value
	_Table.exp_eff = tmp_eff[2].value
	_Table.rld_snd = tmp_eff[3].value

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
		[1] = {name = "Fire Force", id = NumLogicTrTable.fire_force, value = 0, min = 1, max = math.huge},
		[2] = {name = "Spread", id = NumLogicTrTable.fire_spread, value = 0, min = 0, max = 360},
		[3] = {name = "Reload Time", id = NumLogicTrTable.reload_time, value = 0, min = 0, max = 1000000},
		[4] = {name = "Explosion Level", id = NumLogicTrTable.expl_level, value = 0, min = 0.001, max = math.huge},
		[5] = {name = "Explosion Radius", id  = NumLogicTrTable.expl_radius, value = 0, min = 0.001, max = 100},
		[6] = {name = "Explosion Impulse Radius", id = NumLogicTrTable.expl_impulse_radius, value = 0, min = 0.001, max = math.huge},
		[7] = {name = "Explosion Impulse Strength", id = NumLogicTrTable.expl_impulse_strength, value = 0, min = 0, max = math.huge},
		[8] = {name = "Projectile Gravity", id = NumLogicTrTable.projectile_gravity, value = 0, min = -math.huge, max = math.huge},
		[9] = {name = "Projectile Lifetime", id = NumLogicTrTable.projectile_lifetime, value = 0, min = 0.001, max = 30},
		[10] = {name = "Recoil", id = NumLogicTrTable.cannon_recoil, value = 0, min = 0, max = math.huge},
		[11] = {name = "Proximity Fuze", id = NumLogicTrTable.proximity_fuze, value = 0, min = 0, max = 20},
		[12] = {name = "Projectiles Per Shot", id = NumLogicTrTable.projectile_per_shot, value = 0, min = 0, max = 20, int = true},
		[13] = {name = "X Projectile Offset", id = NumLogicTrTable.x_offset, value = 0, min = -math.huge, max = math.huge},
		[14] = {name = "Y Projectile Offset", id = NumLogicTrTable.y_offset, value = 0, min = -math.huge, max = math.huge},
		[15] = {name = "Z Projectile Offset", id = NumLogicTrTable.z_offset, value = 0, min = -math.huge, max = math.huge},
		[16] = {name = "Projectile Type (Spudgun Mode)", id = NumLogicTrTable.projectile_type, value = 0, min = 0, max = 16, list = {
			[1] = "Potato",     [2] = "Small Potato", [3] = "Fries",
			[4] = "Tomato",     [5] = "Carrot",      [6] = "Redbeet",
			[7] = "Broccoli",   [8] = "Pineapple",   [9] = "Orange",
			[10] = "Blueberry", [11] = "Banana",     [12] = "Tape",
			[13] = "Water",     [14] = "Fertilizer", [15] = "Chemical",
			[16] = "Pesticide", [17] = "Seed"
		}}
	}
	temp.logic = {
		[1] = {name = "Ignore Cannon Rotation", id = LogicTrTable.ignore_rotation_mode, value = false},
		[2] = {name = "No Projectile Friction", id = LogicTrTable.no_friction_mode, value = false},
		[3] = {name = "Spudgun Mode", id = LogicTrTable.spudgun_mode, value = false},
		[4] = {name = "No Recoil Mode", id = LogicTrTable.no_recoil_mode, value = false},
		[5] = {name = "Transfer Momentum", id = LogicTrTable.transfer_momentum, value = false}
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
	[ExplEffectEnum.ExplSmall] = 0,
	[ExplEffectEnum.AircraftCannon] = 1,
	[ExplEffectEnum.ExplBig2] = 2,
	[ExplEffectEnum.DoraCannon] = 3,
	[ExplEffectEnum.EMPCannon] = 4
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

	local m_flash = data.mzl_fls
	local ex_eff = data.exp_eff
	local rel_snd = data.rld_snd
	local d_snd = data.snd

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