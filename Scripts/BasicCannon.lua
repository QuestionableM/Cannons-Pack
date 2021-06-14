--[[
	Copyright (c) 2021 Cannons Pack Team
	Questionable Mark
]]

if BasicCannon then return end
dofile("Cannons_Pack_libs/ScriptLoader.lua")
BasicCannon = class(GLOBAL_SCRIPT)
BasicCannon.maxParentCount = 1
BasicCannon.maxChildCount = 1
BasicCannon.connectionInput = _connectionType.logic
BasicCannon.connectionOutput = _connectionType.logic
BasicCannon.colorNormal = _colorNew(0xc75600ff)
BasicCannon.colorHighlight = _colorNew(0xff6e00ff)

function BasicCannon:client_onCreate()
	self.client_settings = _cpCannons_cl_loadCannonInfo(self)
	self.effects = _cpEffect_cl_loadEffects(self)
	self:client_injectScript(self.client_settings.t_script)
end

function BasicCannon:server_onCreate()
	local settings = _cpCannons_sv_loadCannonInfo(self)
	self.projectileConfig = settings.proj_config
	self.settings = settings.cannon_config
	self.proj_scr = _CP_gScript[settings.t_script]
end

function BasicCannon:server_onFixedUpdate()
	if not _smExists(self.interactable) then return end

	local parent = self.interactable:getSingleParent()
	local active = parent and parent.active
	local s_set = self.settings

	local child = self.interactable:getChildren()[1]
	if child and tostring(child.shape.uuid) ~= s_set.port_uuid then self.interactable:disconnect(child) end

	if active and not self.reload then
		self.reload = _cp_Shoot(self, s_set.reload, "client_shoot", "sht", s_set.impulse_dir * s_set.impulse_str)
		self.projectileConfig.velocity = _cp_calculateSpread(self, s_set.spread, s_set.velocity)
		self.proj_scr:server_sendProjectile(self, self.projectileConfig)
		if child then child:setActive(true) end
	end
	
	if self.reload then
		if ((s_set.no_snd_on_hold and not active) or not s_set.no_snd_on_hold) and s_set.rld_sound and self.reload == s_set.rld_sound then
			self.network:sendToClients("client_shoot", "rld")
		end

		self.reload = _cp_calculateReload(self.reload, s_set.auto_reload, active)
	end
end

function BasicCannon:client_shoot(effect)
	local cur_eff = self.effects[effect]
	if not cur_eff then return end

	_cp_spawnOptimizedEffect(self.shape, cur_eff, self.client_settings.effect_distance)
end