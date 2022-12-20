--[[
	Copyright (c) 2022 Cannons Pack Team
	Questionable Mark
]]

--if SmartCannon then return end
dofile("Cannons_Pack_libs/ScriptLoader.lua")
SmartCannon = class(GLOBAL_SCRIPT)
SmartCannon.maxParentCount = -1
SmartCannon.maxChildCount  = 1
SmartCannon.connectionInput  = _connectionType.logic + _connectionType.power
SmartCannon.connectionOutput = _connectionType.logic
SmartCannon.colorNormal    = _colorNew(0x5d0096ff)
SmartCannon.colorHighlight = _colorNew(0x9000e8ff)

function SmartCannon:client_onCreate()
	self:client_injectScript("CPProjectile")

	self.effects = _cpEffect_cl_loadEffects(self)
	self.effects[EffectEnum.sht_snd]:setParameter("sound", 1)

	self.network:sendToServer("server_requestSound")

	self.cur_rld_effect = 1
	self.cur_muzzle_flash_effect = 1
end

local _ShellEffectTrans = {
	[1] = CP_ProjShellEffectEnum.SmallSmartCannonShell,
	[2] = CP_ProjShellEffectEnum.SmartCannonShell,
	[3] = CP_ProjShellEffectEnum.RocketLauncherShell,
	[4] = CP_ProjShellEffectEnum.RocketPodShell,
	[5] = CP_ProjShellEffectEnum.SmallRocketPodShell,
	[6] = CP_ProjShellEffectEnum.EmpCannonShell,
	[7] = CP_ProjShellEffectEnum.LaserCannonShell
}

local _ExplosionTrans = {
	[1] = ExplEffectEnum.ExplSmall,
	[2] = ExplEffectEnum.AircraftCannon,
	[3] = ExplEffectEnum.ExplBig2,
	[4] = ExplEffectEnum.DoraCannon,
	[5] = ExplEffectEnum.EMPCannon
}

local NumLogicTrTable =
{
	fire_spread           = 1,
	fire_force            = 2,
	reload_time           = 3,
	cannon_recoil         = 4,
	projectile_per_shot   = 5,
	expl_level            = 6,
	expl_radius           = 7,
	expl_impulse_radius   = 8,
	expl_impulse_strength = 9,
	projectile_gravity    = 10,
	projectile_lifetime   = 11,
	projectile_type       = 12,
	proximity_fuze        = 13,
	x_offset              = 14,
	y_offset              = 15,
	z_offset              = 16
}

local LogicTrTable = {spudgun_mode = 1, no_friction_mode = 2, ignore_rotation_mode = 3, no_recoil_mode = 4, transfer_momentum = 5}
local OtherTrTable = {sound = 1, muzzle_flash = 2, reload_sound = 3, explosion_effect = 4, ejected_shell_id = 5, shell_effect_id = 6}

local projectile_type_table =
{
	[1]  = { name = "Potato"         , uuid = _uuidNew("5e8eeaae-b5c1-4992-bb21-dec5254ce722") },
	[2]  = { name = "Small Potato"   , uuid = _uuidNew("132c44d3-7436-419d-ac6b-fc178336dcb7") },
	[3]  = { name = "Fries"          , uuid = _uuidNew("9b6b4c56-fba1-400f-94fa-23f9613c0423") },
	[4]  = { name = "Tomato"         , uuid = _uuidNew("b72b01a5-59ad-4882-bbd3-3cbc9f357823") },
	[5]  = { name = "Carrot"         , uuid = _uuidNew("69fc1a2b-77d2-40da-9a82-03fbe3c35a18") },
	[6]  = { name = "Redbeet"        , uuid = _uuidNew("358700c1-7555-41dc-90d1-92374051f985") },
	[7]  = { name = "Broccoli"       , uuid = _uuidNew("b6f296d0-bc03-4098-85b5-52546daad1d7") },
	[8]  = { name = "Pineapple"      , uuid = _uuidNew("65d509b9-09f8-4e32-8b1a-0a6aa11f8660") },
	[9]  = { name = "Orange"         , uuid = _uuidNew("9963fbc0-1314-4db4-8866-1237ace867c3") },
	[10] = { name = "Blueberry"      , uuid = _uuidNew("599b112d-2ff9-4f14-9051-0f58bebb2c94") },
	[11] = { name = "Banana"         , uuid = _uuidNew("4e259125-d1c0-4678-ae41-2652cf224692") },
	[12] = { name = "Tape"           , uuid = _uuidNew("1a981b70-dc08-4105-89b1-79819511a2fb") },
	[13] = { name = "Water"          , uuid = _uuidNew("2c3fc640-1a2e-4328-a872-f6d3f92d0fea") },
	[14] = { name = "Fertilizer"     , uuid = _uuidNew("5610b246-774e-4c1c-9adc-f87b4d993c43") },
	[15] = { name = "Chemical"       , uuid = _uuidNew("46292783-af41-49a5-91ef-092f22dfae91") },
	[16] = { name = "Pesticide"      , uuid = _uuidNew("68029b35-2028-42a5-8509-286d78656561") },
	[17] = { name = "Seed"           , uuid = _uuidNew("9512029a-3f1d-4aa2-92bf-cb876d5c8cb0") },
	[18] = { name = "Powerful Potato", uuid = _uuidNew("cb1c0aec-2f37-41b3-92b6-72a2bca5eb02") }
}

local projectile_type_count = #projectile_type_table - 1

function SmartCannon:getDefaultProjectileId()
	if tostring(self.shape.uuid) == "fd6130e4-261d-4875-a418-96fe33bb2714" then --small smart cannon
		return 0
	else
		return 1
	end
end

function SmartCannon:server_onCreate()
	self.sv_settings = {
		number = {
			[NumLogicTrTable.fire_spread          ] = 0.2,
			[NumLogicTrTable.fire_force           ] = 700,
			[NumLogicTrTable.reload_time          ] = 8,
			[NumLogicTrTable.cannon_recoil        ] = 0,
			[NumLogicTrTable.projectile_per_shot  ] = 0,
			[NumLogicTrTable.expl_level           ] = 5,
			[NumLogicTrTable.expl_radius          ] = 0.5,
			[NumLogicTrTable.expl_impulse_radius  ] = 15,
			[NumLogicTrTable.expl_impulse_strength] = 2000,
			[NumLogicTrTable.projectile_gravity   ] = 10,
			[NumLogicTrTable.projectile_lifetime  ] = 15,
			[NumLogicTrTable.projectile_type      ] = 0,
			[NumLogicTrTable.proximity_fuze       ] = 0,
			[NumLogicTrTable.x_offset             ] = 0,
			[NumLogicTrTable.y_offset             ] = 0,
			[NumLogicTrTable.z_offset             ] = 0
		},
		logic = {
			[LogicTrTable.spudgun_mode        ] = false,
			[LogicTrTable.no_friction_mode    ] = false,
			[LogicTrTable.ignore_rotation_mode] = false,
			[LogicTrTable.no_recoil_mode      ] = false,
			[LogicTrTable.transfer_momentum   ] = true
		},
		[OtherTrTable.sound           ] = 0,
		[OtherTrTable.muzzle_flash    ] = 0,
		[OtherTrTable.reload_sound    ] = 0,
		[OtherTrTable.explosion_effect] = 0,
		[OtherTrTable.ejected_shell_id] = -1,
		[OtherTrTable.shell_effect_id ] = -1,
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
	self.ejector_uuids = cannon_info.port_uuids

	--Load the current ejected shell id
	local saved_ejected_shell_id = self.sv_settings[OtherTrTable.ejected_shell_id]
	local current_shell_id = nil
	if saved_ejected_shell_id == -1 then
		current_shell_id = cannon_info.ejected_shell_id
	else
		current_shell_id = saved_ejected_shell_id + 1
	end

	if self.sv_settings[OtherTrTable.shell_effect_id] == -1 then
		self.sv_settings[OtherTrTable.shell_effect_id] = self:getDefaultProjectileId()
	end

	self.interactable.publicData = { ejectedShellId = current_shell_id, allowedPorts = cannon_info.port_uuids }

	--Read projectile config
	self.projConfig = _cpProj_GetProjectileSettings(self.proj_data_id)

	local sv_expl_eff = self.sv_settings[OtherTrTable.explosion_effect]
	if sv_expl_eff > 0 then
		self.projConfig[ProjSettingEnum.explosionEffect] = _ExplosionTrans[sv_expl_eff + 1]
	end

	local saved_shell_effect_id = self.sv_settings[OtherTrTable.shell_effect_id]
	self.projConfig[ProjSettingEnum.shellEffect] = _ShellEffectTrans[saved_shell_effect_id + 1]
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
	local fire_spread         = _NumSettings[NumLogicTrTable.fire_spread]
	local fire_force          = _NumSettings[NumLogicTrTable.fire_force]
	local reload_time         = _NumSettings[NumLogicTrTable.reload_time]
	local cannon_recoil       = _NumSettings[NumLogicTrTable.cannon_recoil]
	local projectile_per_shot = _NumSettings[NumLogicTrTable.projectile_per_shot]

	--explosion settings
	local expl_level            = _NumSettings[NumLogicTrTable.expl_level]
	local expl_radius           = _NumSettings[NumLogicTrTable.expl_radius]
	local expl_impulse_radius   = _NumSettings[NumLogicTrTable.expl_impulse_radius]
	local expl_impulse_strength = _NumSettings[NumLogicTrTable.expl_impulse_strength]

	--projectile settings
	local projectile_friction = 0.003
	local projectile_gravity  = _NumSettings[NumLogicTrTable.projectile_gravity]
	local projectile_lifetime = _NumSettings[NumLogicTrTable.projectile_lifetime]
	local projectile_type     = _NumSettings[NumLogicTrTable.projectile_type]
	local proximity_fuze      = _NumSettings[NumLogicTrTable.proximity_fuze]
	local x_offset            = _NumSettings[NumLogicTrTable.x_offset]
	local y_offset            = _NumSettings[NumLogicTrTable.y_offset]
	local z_offset            = _NumSettings[NumLogicTrTable.z_offset]

	local _LogicSettings = self.sv_settings.logic
	--cannon modes
	local spudgun_mode         = _LogicSettings[LogicTrTable.spudgun_mode]
	local no_friction_mode     = _LogicSettings[LogicTrTable.no_friction_mode]
	local ignore_rotation_mode = _LogicSettings[LogicTrTable.ignore_rotation_mode]
	local no_recoil_mode       = _LogicSettings[LogicTrTable.no_recoil_mode]
	local transfer_momentum    = _LogicSettings[LogicTrTable.transfer_momentum]
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
					projectile_type = _mathFloor(_mathMin(g_power, projectile_type_count))
				end
			end
		else
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

	local child = self.interactable:getChildren()[1]
	if child ~= self.sv_saved_child then
		self.sv_saved_child = child

		if self.sv_saved_child and self.ejector_uuids[tostring(child.shape.uuid)] ~= true then
			self.interactable:disconnect(child)
			self.sv_saved_child = nil
		end
	end

	if cannon_active and not self.reload then
		if self.sv_saved_child then
			local s_pub_data = self.sv_saved_child.publicData
			if s_pub_data then
				s_pub_data.canShoot   = true
				s_pub_data.reloadTime = reload_time
			end
		end

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

			local l_proj_type = projectile_type_table[projectile_type + 1].uuid
			for i = 1, projectile_per_shot + 1, 1 do
				local _Spread = _gunSpread(_VelVec, fire_spread)
				_cp_shootProjectile(s_Shape, l_proj_type, 28, _Offset, _Spread, ignore_rotation_mode)
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
				[1] = {
					[NumLogicTrTable.fire_spread          ] = fire_spread,
					[NumLogicTrTable.fire_force           ] = fire_force,
					[NumLogicTrTable.reload_time          ] = reload_time,
					[NumLogicTrTable.cannon_recoil        ] = cannon_recoil,
					[NumLogicTrTable.projectile_per_shot  ] = projectile_per_shot,
					[NumLogicTrTable.expl_level           ] = expl_level,
					[NumLogicTrTable.expl_radius          ] = expl_radius,
					[NumLogicTrTable.expl_impulse_radius  ] = expl_impulse_radius,
					[NumLogicTrTable.expl_impulse_strength] = expl_impulse_strength,
					[NumLogicTrTable.projectile_gravity   ] = projectile_gravity,
					[NumLogicTrTable.projectile_lifetime  ] = projectile_lifetime,
					[NumLogicTrTable.projectile_type      ] = projectile_type,
					[NumLogicTrTable.proximity_fuze       ] = proximity_fuze,
					[NumLogicTrTable.x_offset             ] = x_offset,
					[NumLogicTrTable.y_offset             ] = y_offset,
					[NumLogicTrTable.z_offset             ] = z_offset
				},
				[2] = {
					[LogicTrTable.spudgun_mode        ] = spudgun_mode,
					[LogicTrTable.no_friction_mode    ] = no_friction_mode,
					[LogicTrTable.ignore_rotation_mode] = ignore_rotation_mode,
					[LogicTrTable.no_recoil_mode      ] = no_recoil_mode,
					[LogicTrTable.transfer_momentum   ] = transfer_momentum
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
	local sv_data = self.sv_settings

	local output_data =
	{
		[1] = sv_data.number,
		[2] = sv_data.logic,
		[3] = --effect data
		{
			[OtherTrTable.sound           ] = sv_data[OtherTrTable.sound],
			[OtherTrTable.muzzle_flash    ] = sv_data[OtherTrTable.muzzle_flash],
			[OtherTrTable.reload_sound    ] = sv_data[OtherTrTable.reload_sound],
			[OtherTrTable.explosion_effect] = sv_data[OtherTrTable.explosion_effect],
			[OtherTrTable.ejected_shell_id] = self.interactable.publicData.ejectedShellId - 1,
			[OtherTrTable.shell_effect_id]  = sv_data[OtherTrTable.shell_effect_id]
		}
	}

	self.network:sendToClient(player, "client_receiveCannonData", output_data)
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

local function assign_new_data_to_settings(setting_table, new_data)
	for k, v in ipairs(new_data) do
		if setting_table[k] ~= nil then
			setting_table[k] = v
		end
	end
end

function SmartCannon:server_setNewSettings(data)
	local sv_set = self.sv_settings

	assign_new_data_to_settings(sv_set.number, data[1]) --number logic
	assign_new_data_to_settings(sv_set.logic, data[2]) --logic

	local eff_data = data[3]

	local expl_eff_id = eff_data[OtherTrTable.explosion_effect]
	self.projConfig[ProjSettingEnum.explosionEffect] = _ExplosionTrans[expl_eff_id + 1]

	local shell_effect_id = eff_data[OtherTrTable.shell_effect_id]
	self.projConfig[ProjSettingEnum.shellEffect] = _ShellEffectTrans[shell_effect_id + 1]

	sv_set[OtherTrTable.explosion_effect] = expl_eff_id
	sv_set[OtherTrTable.sound           ] = eff_data[OtherTrTable.sound]
	sv_set[OtherTrTable.reload_sound    ] = eff_data[OtherTrTable.reload_sound]
	sv_set[OtherTrTable.muzzle_flash    ] = eff_data[OtherTrTable.muzzle_flash]
	sv_set[OtherTrTable.ejected_shell_id] = eff_data[OtherTrTable.ejected_shell_id]
	sv_set[OtherTrTable.shell_effect_id ] = shell_effect_id

	self.interactable.publicData.ejectedShellId = eff_data[OtherTrTable.ejected_shell_id] + 1

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

local default_hypertext = "<p textShadow='false' bg='gui_keybinds_bg_orange' color='#66440C' spacing='9'>%s</p>"
function SmartCannon:client_canInteract()
	local k_Inter = _getKeyBinding("Use", true)
	_setInteractionText("Press", k_Inter, "to open Smart Cannon GUI")

	local instruction_hyper = default_hypertext:format("Check the workshop page of \"Cannons Pack\" for instructions")
	_setInteractionText("", instruction_hyper)

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

--Gui input value types
local sc_gui_num_val = 1
local sc_gui_bool_val = 2
local sc_gui_list_val = 3

local sc_gui_col_value_issame = "#ffffff"
local sc_gui_col_value_changed = "#999999"
local sc_gui_col_value_invalid = "#ff0000"

local function client_GUI_getValueColor(cur_set)
	return (cur_set.value == cur_set.cur_val) and sc_gui_col_value_issame or sc_gui_col_value_changed
end

function SmartCannon:client_GUI_Open()
	local gui = _cpCreateGui("SmartCannonGui.layout")

	gui:setButtonCallback("Tab1", "client_GUI_TabCallback")
	gui:setButtonCallback("Tab2", "client_GUI_TabCallback")
	gui:setButtonCallback("Tab3", "client_GUI_TabCallback")

	for i = 1, 6 do
		gui:setButtonCallback("R_ListBoxBtn"..i, "client_GUI_onListBoxChangeCallback")
		gui:setButtonCallback("L_ListBoxBtn"..i, "client_GUI_onListBoxChangeCallback")

		gui:setButtonCallback("Bool"..i, "client_GUI_onBooleanChangedCallback")

		gui:setTextChangedCallback("NumVal"..i, "client_GUI_onTextChangedCallback")
	end

	gui:setButtonCallback("PageLeft" , "client_GUI_onNumPageChange")
	gui:setButtonCallback("PageRight", "client_GUI_onNumPageChange")
	gui:setButtonCallback("SaveChanges", "client_GUI_onSaveButtonCallback")
	gui:setButtonCallback("ResetDefaults", "client_GUI_onResetDefaultsCallback")
	gui:setButtonCallback("GetValues", "client_GUI_onGetValueCallback")

	gui:setOnCloseCallback("client_GUI_onDestroyCallback")

	self.gui = {}
	self.gui.interface = gui
	self:client_GUI_CreateTempValTable()
	self.gui.cur_tab = 1
	self.gui.cur_page = 1
	self.gui.max_page = 0

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
	local s_gui = self.gui

	if s_gui.wait_for_number_data then return end

	s_gui.wait_for_number_data = true
	s_gui.dot_anim = 0
	s_gui.interface:setText("GetValues", "Getting Data")

	self.network:sendToServer("server_requestNumberInputs")
end

local function temp_table_to_network_data(gui_temp, data_output)
	for k, v in ipairs(gui_temp) do
		v.value = v.cur_val

		data_output[v.id] = v.value
	end
end

function SmartCannon:client_GUI_onSaveButtonCallback()
	local data_output = {[1] = {}, [2] = {}, [3] = {}}

	local gui = self.gui
	local gui_int = gui.interface
	local gui_temp = gui.temp

	temp_table_to_network_data(gui_temp[1], data_output[1]) --number data
	temp_table_to_network_data(gui_temp[2], data_output[2]) --logic data
	temp_table_to_network_data(gui_temp[3], data_output[3]) --effect data

	self.network:sendToServer("server_setNewSettings", data_output)

	gui_int:setVisible("SaveChanges", false)
	self:client_GUI_updateCurrentTab()

	_audioPlay("Retrowildblip")
end

local function reset_table_to_defaults(gui_table)
	for k, cur_set in ipairs(gui_table) do
		cur_set.cur_val = cur_set.default
	end
end

function SmartCannon:client_GUI_onResetDefaultsCallback()
	local s_gui = self.gui
	local gui_temp = s_gui.temp
	local gui_int = s_gui.interface

	reset_table_to_defaults(gui_temp[1]) --reset number logic values
	reset_table_to_defaults(gui_temp[2]) --reset logic values
	reset_table_to_defaults(gui_temp[3]) --reset effect values

	gui_int:setVisible("SaveChanges", true)
	self:client_GUI_updateCurrentTab()

	_audioPlay("PaintTool - Erase")
end

function SmartCannon:client_GUI_onNumPageChange(btn_name)
	local btn_id = btn_name:sub(5)
	local value_step = (btn_id == "Left" and -1 or 1)
	local s_gui = self.gui

	local new_page = _utilClamp(s_gui.cur_page + value_step, 1, s_gui.max_page)
	if s_gui.cur_page ~= new_page then
		s_gui.cur_page = new_page

		self:client_GUI_updateCurrentTab()

		_audioPlay("GUI Item drag")
	end
end

function SmartCannon:client_GUI_CreateTempValTable()
	local temp = {}
	temp[1] = --number logic
	{
		[1]  = {name = "Fire Force (m/s)"              , type = sc_gui_num_val , id = NumLogicTrTable.fire_force           , value = 0, default = 700 , min = 1, max = 99999999},
		[2]  = {name = "Spread (deg)"                  , type = sc_gui_num_val , id = NumLogicTrTable.fire_spread          , value = 0, default = 0.2 , min = 0, max = 360},
		[3]  = {name = "Reload Time (ticks)"           , type = sc_gui_num_val , id = NumLogicTrTable.reload_time          , value = 0, default = 8   , min = 0, max = 1000000},
		[4]  = {name = "Explosion Level"               , type = sc_gui_num_val , id = NumLogicTrTable.expl_level           , value = 0, default = 5   , min = 0.001, max = 99999999},
		[5]  = {name = "Explosion Radius (m)"          , type = sc_gui_num_val , id = NumLogicTrTable.expl_radius          , value = 0, default = 0.5 , min = 0.1, max = 100},
		[6]  = {name = "Explosion Impulse Radius (m)"  , type = sc_gui_num_val , id = NumLogicTrTable.expl_impulse_radius  , value = 0, default = 15.0, min = 0.001, max = 99999999},
		[7]  = {name = "Explosion Impulse Strength"    , type = sc_gui_num_val , id = NumLogicTrTable.expl_impulse_strength, value = 0, default = 2000, min = 0, max = 99999999},
		[8]  = {name = "Projectile Gravity"            , type = sc_gui_num_val , id = NumLogicTrTable.projectile_gravity   , value = 0, default = 10  , min = -99999999, max = 99999999},
		[9]  = {name = "Projectile Lifetime (s)"       , type = sc_gui_num_val , id = NumLogicTrTable.projectile_lifetime  , value = 0, default = 15  , min = 0.001, max = 30},
		[10] = {name = "Recoil"                        , type = sc_gui_num_val , id = NumLogicTrTable.cannon_recoil        , value = 0, default = 0   , min = 0, max = 99999999},
		[11] = {name = "Proximity Fuze (m)"            , type = sc_gui_num_val , id = NumLogicTrTable.proximity_fuze       , value = 0, default = 0   , min = 0, max = 20},
		[12] = {name = "Projectiles Per Shot"          , type = sc_gui_num_val , id = NumLogicTrTable.projectile_per_shot  , value = 0, default = 0   , min = 0, max = 20, int = true},
		[13] = {name = "X Projectile Offset (m)"       , type = sc_gui_num_val , id = NumLogicTrTable.x_offset             , value = 0, default = 0   , min = -99999999, max = 99999999},
		[14] = {name = "Y Projectile Offset (m)"       , type = sc_gui_num_val , id = NumLogicTrTable.y_offset             , value = 0, default = 0   , min = -99999999, max = 99999999},
		[15] = {name = "Z Projectile Offset (m)"       , type = sc_gui_num_val , id = NumLogicTrTable.z_offset             , value = 0, default = 0   , min = -99999999, max = 99999999},
		[16] = {name = "Projectile Type (Spudgun Mode)", type = sc_gui_list_val, id = NumLogicTrTable.projectile_type      , value = 0, default = 0   , min = 0, max = projectile_type_count, list = projectile_type_table}
	}

	temp[2] = --logic
	{
		[1] = {name = "Ignore Cannon Rotation", type = sc_gui_bool_val, id = LogicTrTable.ignore_rotation_mode, value = false, default = false},
		[2] = {name = "No Projectile Friction", type = sc_gui_bool_val, id = LogicTrTable.no_friction_mode    , value = false, default = false},
		[3] = {name = "Spudgun Mode"          , type = sc_gui_bool_val, id = LogicTrTable.spudgun_mode        , value = false, default = false},
		[4] = {name = "No Recoil Mode"        , type = sc_gui_bool_val, id = LogicTrTable.no_recoil_mode      , value = false, default = false},
		[5] = {name = "Transfer Momentum"     , type = sc_gui_bool_val, id = LogicTrTable.transfer_momentum   , value = false, default = true }
	}

	temp[3] = --effects
	{
		[1] = {name = "Muzzle Flash", value = 0, default = 0, max = 4, type = sc_gui_list_val, id = OtherTrTable.muzzle_flash, list = { --1 muzzle flash
			[1] = { name = "Default"              }, [2] = { name = "Small Explosion"    },
			[3] = { name = "Big Explosion"        }, [4] = { name = "Frier Muzzle Flash" },
			[5] = { name = "Spinner Muzzle Flash" }
		}},
		[2] = {name = "Explosion Effect", value = 0, default = 0, max = 4, type = sc_gui_list_val, id = OtherTrTable.explosion_effect, list = { --2 explosion effect
			[1] = { name = "Default"       }, [2] = { name = "Little Explosion" },
			[3] = { name = "Big Explosion" }, [4] = { name = "Giant Explosion"  },
			[5] = { name = "Sparks"        }
		}},
		[3] = {name = "Reload Sound", value = 0, default = 0, max = 1, type = sc_gui_list_val, id = OtherTrTable.reload_sound, list = { --3 reloading effect
			[1] = { name = "Default" }, [2] = { name = "Heavy Realoading" }
		}},
		[4] = {name = "Shooting Sound", value = 0, default = 0, max = 4, type = sc_gui_list_val, id = OtherTrTable.sound, list = { --4 shooting sound
			[1] = { name = "Default"        }, [2] = { name = "Sound 1"      },
			[3] = { name = "Potato Shotgun" }, [4] = { name = "Spudling Gun" },
			[5] = { name = "Explosion"      }
		}},
		[5] = {name = "Ejector Shell Model", value = 0, default = self:getDefaultProjectileId(), max = 3, type = sc_gui_list_val, id = OtherTrTable.ejected_shell_id, list = { --5 ejected shell model
			[1] = { name = "Small Shell" }, [2] = { name = "Medium Shell" },
			[3] = { name = "Large Shell" }, [4] = { name = "Giant Shell"  }
		}},
		[6] = {name = "Shell Model", value = 0, default = self:getDefaultProjectileId(), max = 6, type = sc_gui_list_val, id = OtherTrTable.shell_effect_id, list = {
			[1] = { name = "Small Smart Cannon"      }, [2] = { name = "Smart Cannon"      },
			[3] = { name = "Rocket"                  }, [4] = { name = "Rocket Pod Rocket" },
			[5] = { name = "Small Rocket Pod Rocket" }, [6] = { name = "EMP"               },
			[7] = { name = "Laser"                   }
		}}
	}

	self.gui.temp = temp
end

function SmartCannon:client_GUI_TabCallback(tab_name)
	local tab_idx = tonumber(tab_name:sub(-1))

	if self.gui.cur_tab ~= tab_idx then
		self.gui.cur_tab = tab_idx
		self.gui.cur_page = 1

		self:client_GUI_updateTabButtons()
		self:client_GUI_updateCurrentTab()

		_audioPlay("Handbook - Turn page")
	end
end

function SmartCannon:client_GUI_updateTabButtons()
	local s_gui = self.gui
	local cur_tab = s_gui.cur_tab
	local gui_int = s_gui.interface

	for i = 1, 3 do
		gui_int:setButtonState("Tab"..i, i == cur_tab)
	end
end

local function client_GUI_updateListBoxWidget(gui, slot, cur_func)
	local c_value = cur_func.cur_val
	local max_val = cur_func.max

	local tex_col = client_GUI_getValueColor(cur_func)

	gui:setText("ListBoxName"..slot, tex_col..cur_func.name)
	gui:setText("ListBoxVal" ..slot, cur_func.list[c_value + 1].name)

	gui:setVisible("R_ListBoxBtn"..slot, c_value < max_val)
	gui:setVisible("L_ListBoxBtn"..slot, c_value > 0)
end

local g_bool_string =
{
	[true ] = {bool = "#009900true#ffffff" , sound = "Lever on" },
	[false] = {bool = "#ff0000false#ffffff", sound = "Lever off"}
}

local function client_GUI_updateBooleanWidget(gui, slot, cur_func)
	local val_changed = (cur_func.value == cur_func.cur_val) and "" or "*"
	local cur_bool = g_bool_string[cur_func.cur_val]

	gui:setText("Bool"..slot, ("%s%s: %s"):format(val_changed, cur_func.name, cur_bool.bool))
end

local function client_GUI_updateNumberValueWidget(gui, slot, cur_func)
	local text_col = client_GUI_getValueColor(cur_func)
	gui:setText("NumName"..slot, ("%s%s"):format(text_col, cur_func.name))

	local val_txt = cur_func.int and "%d" or "%.3f"
	gui:setText("NumVal"..slot, (val_txt):format(cur_func.cur_val))
end

function SmartCannon:client_GUI_getCurrentOption(btn_id)
	local s_gui = self.gui
	local cur_temp = s_gui.temp[s_gui.cur_tab]

	local page_offset = (s_gui.cur_page - 1) * 6

	return cur_temp[page_offset + btn_id]
end

function SmartCannon:client_GUI_onListBoxChangeCallback(btn_name)
	local value_step = (btn_name:sub(0, 1) == "R" and 1 or -1)
	local btn_id = tonumber(btn_name:sub(-1))

	local s_gui = self.gui
	local cur_set = self:client_GUI_getCurrentOption(btn_id)

	local new_value = _utilClamp(cur_set.cur_val + value_step, 0, cur_set.max)
	if cur_set.cur_val == new_value then return end
	cur_set.cur_val = new_value

	local gui_int = s_gui.interface
	gui_int:setVisible("SaveChanges", true)

	client_GUI_updateListBoxWidget(gui_int, btn_id, cur_set)
	_audioPlay("GUI Item released")
end

function SmartCannon:client_GUI_onBooleanChangedCallback(btn_name)
	local btn_id = tonumber(btn_name:sub(-1))

	local s_gui = self.gui
	local cur_set = self:client_GUI_getCurrentOption(btn_id)

	cur_set.cur_val = not cur_set.cur_val
	
	local gui_int = s_gui.interface
	gui_int:setVisible("SaveChanges", true)

	client_GUI_updateBooleanWidget(gui_int, btn_id, cur_set)

	local cur_bool = g_bool_string[cur_set.cur_val]
	_audioPlay(cur_bool.sound)
end

function SmartCannon:client_GUI_onTextChangedCallback(widget, text)
	local widget_id = tonumber(widget:sub(-1))

	local s_gui = self.gui
	local gui_int = s_gui.interface
	local cur_set = self:client_GUI_getCurrentOption(widget_id)

	local hex_color_str
	local num_value = tonumber(text)
	if num_value ~= nil then
		local clamped_new = _utilClamp(num_value, cur_set.min, cur_set.max)
		if cur_set.int then
			clamped_new = _mathFloor(clamped_new)
		end

		cur_set.cur_val = clamped_new
		hex_color_str = client_GUI_getValueColor(cur_set)

		gui_int:setVisible("SaveChanges", true)
	else
		hex_color_str = sc_gui_col_value_invalid
		cur_set.cur_val = cur_set.value
	end

	gui_int:setText("NumName"..widget_id, hex_color_str..cur_set.name)
end

local value_update_functions =
{
	[1] = client_GUI_updateNumberValueWidget,
	[2] = client_GUI_updateBooleanWidget,
	[3] = client_GUI_updateListBoxWidget
}

function SmartCannon:client_GUI_updateCurrentTab()
	local s_gui = self.gui
	local cur_temp = s_gui.temp[s_gui.cur_tab]
	local cur_page = s_gui.cur_page
	local gui_int = s_gui.interface

	s_gui.max_page = _mathCeil(#cur_temp / 6)

	local page_offset_idx = (s_gui.cur_page - 1) * 6
	for i = 1, 6 do
		local cur_idx = page_offset_idx + i
		local cur_opt = cur_temp[cur_idx]

		local opt_id = (cur_opt and cur_opt.type or 0)
		gui_int:setVisible("NumInputBG"..i, opt_id == 1)
		gui_int:setVisible("Bool"      ..i, opt_id == 2)
		gui_int:setVisible("ListBoxBG" ..i, opt_id == 3)

		if cur_opt ~= nil then
			value_update_functions[cur_opt.type](gui_int, i, cur_opt)
		end
	end

	self:client_GUI_updateCurrentPageText()
end

function SmartCannon:client_GUI_updateCurrentPageText()
	local s_gui = self.gui
	local gui_int = s_gui.interface
	local cur_page = s_gui.cur_page
	local max_page = s_gui.max_page

	gui_int:setText("PageValue", ("%d / %d"):format(cur_page, max_page))
	gui_int:setVisible("PageLeft" , cur_page > 1)
	gui_int:setVisible("PageRight", cur_page < max_page)
end

local function load_new_data_table(gui_table, new_data)
	for k, cur_set in ipairs(gui_table) do
		local cur_data_val = new_data[cur_set.id]

		if cur_data_val ~= nil then
			cur_set.value = cur_data_val
			cur_set.cur_val = cur_data_val
		end
	end
end

function SmartCannon:client_GUI_LoadNewData(data)
	local gui = self.gui
	if not gui then return end

	local gui_temp = gui.temp

	load_new_data_table(gui_temp[1], data[1]) --load number logic data
	load_new_data_table(gui_temp[2], data[2]) --load logic data

	local effect_data = data[3]
	if effect_data ~= nil then
		load_new_data_table(gui_temp[3], effect_data) --load effect data
	end

	if gui.wait_for_data then
		self.gui.cur_tab = 1 --number logic tab
		self:client_GUI_updateCurrentTab()
		self:client_GUI_updateTabButtons()
		self:client_GUI_SetWaitingState(true)
	end

	if gui.wait_for_number_data then
		gui.wait_for_number_data = nil
		gui.dot_anim = nil

		local gui_int = gui.interface
		gui_int:setText("GetValues", "Get Input Values")
		gui_int:setVisible("SaveChanges", true)

		self:client_GUI_updateCurrentTab()
		_audioPlay("ConnectTool - Selected")
	end
end

function SmartCannon:client_GUI_SetWaitingState(state)
	local gui = self.gui
	local gui_int = gui.interface

	local n_state = not state
	gui_int:setVisible("LoadingScreen", n_state)
	for k, btn in pairs({"Tab1", "Tab2", "Tab3", "GetValues", "MainPage", "GuiTitle"}) do
		gui_int:setVisible(btn, state)
	end

	gui.wait_for_data = (n_state and true or nil)
	gui.dot_anim      = (n_state and 0    or nil)
end

local g_dot_animation = {[1] = "", [2] = ".", [3] = "..", [4] = "..."}
function SmartCannon:client_GUI_UpdateDotAnim()
	local gui = self.gui
	if not gui then return end

	local _wait_for_data = gui.wait_for_data
	local _wait_for_n_data = gui.wait_for_number_data

	if gui and (_wait_for_data or _wait_for_n_data) then
		local cur_tick = _getCurrentTick() % 26

		if cur_tick == 25 then
			gui.dot_anim = (gui.dot_anim + 1) % 4
			local cur_step = g_dot_animation[gui.dot_anim + 1]

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