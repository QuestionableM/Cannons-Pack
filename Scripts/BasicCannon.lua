--[[
	Copyright (c) 2022 Cannons Pack Team
	Questionable Mark
]]

if BasicCannon then return end
dofile("Cannons_Pack_libs/ScriptLoader.lua")
BasicCannon = class(GLOBAL_SCRIPT)
BasicCannon.maxParentCount = 1
BasicCannon.maxChildCount  = 1
BasicCannon.connectionInput  = _connectionType.logic
BasicCannon.connectionOutput = _connectionType.logic
BasicCannon.colorNormal    = _colorNew(0xc75600ff)
BasicCannon.colorHighlight = _colorNew(0xff6e00ff)

function BasicCannon:client_onCreate()
	self.client_settings = _cpCannons_cl_loadCannonInfo(self)
	self.effects = _cpEffect_cl_loadEffects(self)
	self:client_injectScript(self.client_settings.t_script)
end

function BasicCannon:server_onCreate()
	local settings = _cpCannons_sv_loadCannonInfo(self)
	self.projectileConfig = settings.proj_config or {}
	self.settings = settings.cannon_config
	self.proj_scr = _CP_gScript[settings.t_script]
	self.interactable.publicData = { allowedPorts = self.settings.port_uuids, ejectedShellId = self.settings.ejected_shell_id }
end

function BasicCannon:client_getAvailableChildConnectionCount(connectionType)
	if connectionType == _connectionType.logic then
		return 1 - #self.interactable:getChildren(_connectionType.logic)
	end

	return 0
end

function BasicCannon:client_getAvailableParentConnectionCount(connectionType)
	if connectionType == _connectionType.logic then
		return 1 - #self.interactable:getParents(_connectionType.logic)
	end

	return 0
end

function BasicCannon:server_updateAndCheckChild(port_uuids)
	local sInteractable = self.interactable

	local child = sInteractable:getChildren()[1]
	if self.sv_saved_child ~= child then
		self.sv_saved_child = child

		if child and port_uuids[tostring(child.shape.uuid)] ~= true then
			self.sv_saved_child = nil
			sInteractable:disconnect(child)
		end
	end
end

function BasicCannon:server_onFixedUpdate()
	if not _smExists(self.interactable) then return end

	local parent = self.interactable:getSingleParent()
	local active = parent and parent.active

	local s_set = self.settings
	self:server_updateAndCheckChild(s_set.port_uuids)

	if active and not self.reload then
		self.reload = _cp_Shoot(self, s_set.reload, "client_shoot", EffectEnum.sht, s_set.impulse_dir * s_set.impulse_str)

		self.projectileConfig[ProjSettingEnum.velocity] = _cp_calculateSpread(self, s_set.spread, s_set.velocity)
		self.proj_scr:server_sendProjectile(self, self.projectileConfig, s_set.proj_data_id)

		if self.sv_saved_child then
			local s_pub_data = self.sv_saved_child.publicData
			if s_pub_data then
				s_pub_data.canShoot = true
				s_pub_data.reloadTime = self.reload
			end
		end
	end

	if self.reload then
		local snd_on_hold = s_set.no_snd_on_hold
		local r_Sound = s_set.rld_sound

		if ((snd_on_hold and not active) or not snd_on_hold) and (r_Sound and self.reload == r_Sound) then
			self.network:sendToClients("client_shoot", EffectEnum.rld)
		end

		self.reload = _cp_calculateReload(self.reload, s_set.auto_reload, active)
	end
end

function BasicCannon:client_shoot(effect)
	local cur_eff = self.effects[effect]
	if not cur_eff then return end

	_cp_spawnOptimizedEffect(self.shape, cur_eff, self.client_settings.effect_distance)
end