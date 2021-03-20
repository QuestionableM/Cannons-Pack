--[[
    Copyright (c) 2021 Cannons Pack Team
    Questionable Mark
]]

if SmartCannon then return end
dofile("../Cannons_Pack_libs/ScriptLoader.lua")
dofile("SmartCannonGUI.lua")
SmartCannon = class(GLOBAL_SCRIPT)
SmartCannon.maxParentCount = -1
SmartCannon.maxChildCount = 1
SmartCannon.connectionInput = sm.interactable.connectionType.logic + sm.interactable.connectionType.power
SmartCannon.connectionOutput = sm.interactable.connectionType.logic
SmartCannon.colorNormal = sm.color.new(0x5d0096ff)
SmartCannon.colorHighlight = sm.color.new(0x9000e8ff)
function SmartCannon:client_onCreate()
	self.effects = CP_Effects.client_loadEffect(self)
	self.effects.sht_snd:setParameter("sound", 1)
	self.network:sendToServer("server_requestSound", {player = sm.localPlayer.getPlayer()})
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
	self:GS_init()
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

		self.sv_settings.number.fire_spread = _NumDat.fire_spread or 0.2
		self.sv_settings.number.fire_force = _NumDat.fire_force or 700
		self.sv_settings.number.reload_time = _NumDat.reload_time or 8
		self.sv_settings.number.cannon_recoil = _NumDat.cannon_recoil or 0
		self.sv_settings.number.projectile_per_shot = _NumDat.projectile_per_shot or 0
		self.sv_settings.number.expl_level = _NumDat.expl_level or 5
		self.sv_settings.number.expl_radius = _NumDat.expl_radius or 0.5
		self.sv_settings.number.expl_impulse_radius = _NumDat.expl_impulse_radius or 15
		self.sv_settings.number.expl_impulse_strength = _NumDat.expl_impulse_strength or 2000
		self.sv_settings.number.projectile_gravity = _NumDat.projectile_gravity or 10
		self.sv_settings.number.projectile_lifetime = _NumDat.projectile_lifetime or 15
		self.sv_settings.number.projectile_type = _NumDat.projectile_type or 0
		self.sv_settings.number.proximity_fuze = _NumDat.proximity_fuze or 0
		self.sv_settings.number.x_offset = _NumDat.x_offset or 0
		self.sv_settings.number.y_offset = _NumDat.y_offset or 0
		self.sv_settings.number.z_offset = _NumDat.z_offset or 0
		self.sv_settings.logic.spudgun_mode = _LogicDat.spudgun_mode
		self.sv_settings.logic.no_friction_mode = _LogicDat.no_friction_mode
		self.sv_settings.logic.ignore_rotation_mode = _LogicDat.ignore_rotation_mode
		self.sv_settings.logic.no_recoil_mode = _LogicDat.no_recoil_mode
		self.sv_settings.logic.transfer_momentum = _LogicDat.transfer_momentum
		self.sv_settings.sound = _SavedData.sound or 0
		self.sv_settings.muzzle_flash = _SavedData.muzzle_flash or 0
		self.sv_settings.explosion_effect = _SavedData.explosion_effect or 0
		self.sv_settings.reload_sound = _SavedData.reload_sound or 0
	end
	self.data_request_queue = {}
	self.projectileConfiguration = CP_Cannons.load_cannon_info(self)
	if self.sv_settings.explosion_effect > 0 then
		self.projectileConfiguration.explosionEffect = _ExplosionTrans[self.sv_settings.explosion_effect + 1]
	end
end
local _ReloadSoundTimeOffsets = {
	[1] = {val = 30, min_rld = 80},
	[2] = {val = 190, min_rld = 210}
}
function SmartCannon:server_onFixedUpdate()
	if not sm.exists(self.interactable) then return end

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

	for l, gate in pairs(self.interactable:getParents()) do
		local gate_type = gate:getType()
		if not gate:hasSteering() then
			local gate_color = tostring(gate:getShape():getColor())
			if gate_type == "scripted" and tostring(gate.shape.shapeUuid) ~= "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07" then --The Modpack Number logic check
				if gate_color == "eeaf5cff" then --1st orange
					if gate.power > 0 then fire_force = gate.power end
				elseif gate_color == "673b00ff" then --3rd orange
					fire_spread = gate.power
				elseif gate_color == "472800ff" then --4th orange
					reload_time = gate.power
				elseif gate_color == "f06767ff" then --1st red
					if gate.power > 0 then expl_level = gate.power end
				elseif gate_color == "d02525ff" then --2nd red
					if gate.power > 0 then expl_radius = math.min(gate.power, 100) end
				elseif gate_color == "7c0000ff" then --3rd red
					if gate.power > 0 then expl_impulse_radius = gate.power end
				elseif gate_color == "560202ff" then --4th red
					if gate.power >= 0 then expl_impulse_strength = gate.power end
				elseif gate_color == "ee7bf0ff" then --1st pink
					projectile_gravity = gate.power
				elseif gate_color == "cf11d2ff" then --2nd pink
					if gate.power > 0 then projectile_lifetime = math.min(gate.power, 30) end
				elseif gate_color == "720a74ff" then --3rd pink
					if gate.power > 0 then cannon_recoil = gate.power end
				elseif gate_color == "520653ff" then --4th pink
					if gate.power > 0 then proximity_fuze = math.min(gate.power, 20) end
				elseif gate_color == "f5f071ff" then --1st yellow
					x_offset = gate.power / 4
				elseif gate_color == "e2db13ff" then --2nd yellow
					y_offset = gate.power / 4
				elseif gate_color == "817c00ff" then --3rd yellow
					z_offset = gate.power / 4
				elseif gate_color == "35086cff" then --4th violet
					if gate.power >= 0 then projectile_per_shot = math.min(gate.power, 20) end
				elseif gate_color == "eeeeeeff" then --white
					if gate.power >= 0 then projectile_type = math.floor(math.min(gate.power, #self.projectileConfiguration.proj_types - 1)) end
				end
			else --Vanilla logic
				if gate_color == "323000ff" then --4th yellow
					ignore_rotation_mode = gate.active
				elseif gate_color == "eeeeeeff" then --white
					spudgun_mode = gate.active
				elseif gate_color == "7f7f7fff" then --2nd gray
					no_friction_mode = gate.active
				elseif gate_color == "4a4a4aff" then --3rd gray
					no_recoil_mode = gate.active
				elseif gate_color == "222222ff" then --black
					transfer_momentum = gate.active
				else
					if gate.active then cannon_active = true end
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
				self.projectileConfiguration.position = sm.vec3.new(x_offset, y_offset, z_offset + 0.1)
			else
				self.projectileConfiguration.position = self.shape.worldPosition + sm.vec3.new(x_offset, y_offset, z_offset)
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
				self.projectileConfiguration.velocity = CP.calculate_spread(self, fire_spread, fire_force, not transfer_momentum)
				CPProjectile:server_sendProjectile(self, self.projectileConfiguration)
			end
		else
			local _Offset = sm.vec3.new(x_offset, y_offset, z_offset)
			local _VelVec = sm.vec3.new(0, 0, fire_force + math.abs(self.shape.up:dot(self.shape.velocity)))
			local _ProjType = self.projectileConfiguration.proj_types[projectile_type + 1]
			for i = 1, projectile_per_shot + 1, 1 do
				local _Spread = sm.noise.gunSpread(_VelVec, fire_spread)
				CP.shoot_projectile(self.shape, _ProjType, _Offset, _Spread, ignore_rotation_mode)
			end
		end
		if not no_recoil_mode then 
			sm.physics.applyImpulse(self.shape, sm.vec3.new(0, 0, -(fire_force + cannon_recoil))) 
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
	SmartCannonGUI.LoadNewData(self, data)
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
		self.effects.rld = sm.effect.createEffect(_ReloadSoundNames[data.rld_snd], self.interactable)
	end
	if self.cur_muzzle_flash_effect ~= data.sht_eff then
		self.cur_muzzle_flash_effect = data.sht_eff
		self.effects.sht:stop()
		self.effects.sht:destroy()
		self.effects.sht = sm.effect.createEffect("SmartCannon - MuzzleFlash"..data.sht_eff, self.interactable)
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
	if state then
		if CP_GUI.GuiSupported() then
			SmartCannonGUI.CreateGUI(self)
		else
			local mode = character:isCrouching() and -1 or 1
			self.network:sendToServer("server_getChange", {
				mode = mode,
				player = sm.localPlayer.getPlayer()
			})
		end
	end
end
function SmartCannon:client_setSound(data)
	self.effects.sht_snd:setParameter("sound", data.soundId)
	if data.caller and data.caller == sm.localPlayer.getPlayer() then
		CP.info_output("GUI Item drag", true, "Changed the sound to #ffff00"..data.soundId.."#ffffff")
	end
end
function SmartCannon:client_onFixedUpdate(dt)
	SmartCannonGUI.UpdateGuiText(self)
end
function SmartCannon:client_canInteract()
	local _InteractKey = sm.gui.getKeyBinding("Use")
	if CP_GUI.GuiSupported() then
		sm.gui.setInteractionText("Press", _InteractKey, "to open Smart Cannon GUI")
	else
		sm.gui.setInteractionText("Press", _InteractKey, "or", ("%s + %s"):format(sm.gui.getKeyBinding("Crawl"), _InteractKey), "to change the shooting sound")
	end
	sm.gui.setInteractionText("", "check the workshop page of \"Cannons Pack\" for instructions")
	return true
end
function SmartCannon:client_onDestroy()
	if self.c_gui then
		if self.c_gui:isActive() then self.c_gui:close() end
		SmartCannonGUI.OnDestroyGUICallback(self)
	end
end
function SmartCannon:client_displayEffect(data)
	local _EffList = {}
	if data == "sht" then
		_EffList = {self.effects.sht_snd, self.effects.sht}
	else
		_EffList = self.effects[data]
	end
	CP.spawn_optimized_effect(self.shape, _EffList, 75)
end