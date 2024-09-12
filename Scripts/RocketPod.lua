--[[
	Copyright (c) 2025 Cannons Pack Team
	Questionable Mark
]]

if RocketPod then return end

dofile("Cannons_Pack_libs/ScriptLoader.lua")

---@class RocketPod : GlobalScriptHandler
---@field reload integer|nil
RocketPod = class(GLOBAL_SCRIPT)
RocketPod.maxParentCount = 1
RocketPod.maxChildCount  = 0
RocketPod.connectionInput  = _connectionType.logic
RocketPod.connectionOutput = _connectionType.none
RocketPod.colorNormal    = _colorNew(0x4ebf61ff)
RocketPod.colorHighlight = _colorNew(0x65fc7eff)

function RocketPod:cl_initAmmoEffects(pod_data)
	local s_interactable = self.interactable

	local eff_scale = _newVec(0.25, 0.25, 0.25)
	local ammo_eff = pod_data.ammo_effect
	local shoot_pos_data = pod_data.effect_positions
	local shoot_order = pod_data.shoot_order

	self.ammo_effects = {}
	self.cl_effect_pos_data = {}
	self.cl_effect_count = #shoot_order

	for k, v in ipairs(shoot_order) do
		local shoot_offset = shoot_pos_data[v]

		local cur_effect = _createEffect(ammo_eff, s_interactable)
		cur_effect:setOffsetPosition(shoot_offset)
		cur_effect:setScale(eff_scale)
		cur_effect:start()

		_tableInsert(self.ammo_effects, cur_effect)
		_tableInsert(self.cl_effect_pos_data, shoot_offset)
	end
end

function RocketPod:client_onCreate()
	self:client_injectScript("CPProjectile")

	self.effects, self.eff_offsets = _cpEffect_cl_loadEffects2(self)
	local pod_data = _cpCannons_loadCannonInfo(self)

	local eff_config = pod_data.effect_config
	self:cl_initAmmoEffects(eff_config)
end

function RocketPod:client_onFixedUpdate(dt)
	if self.cl_reload_timer then
		self.cl_reload_timer = (self.cl_reload_timer - 1)

		local timer_frac = 1 - (self.cl_reload_timer / self.cl_reload_total)
		local effect_id = math.floor(timer_frac * self.cl_effect_count)

		if self.cl_eff_cache ~= effect_id then
			self.cl_eff_cache = effect_id

			if effect_id > 0 then
				self.ammo_effects[effect_id]:start()
			end
		end

		if self.cl_reload_timer == 30 then
			_playHostedEffect("Reloading", self.interactable)
		end

		if self.cl_reload_timer <= 0 then
			self.cl_reload_timer = nil
			self.cl_reload_total = nil
			self.cl_eff_cache = nil
		end
	end
end

function RocketPod:client_onShoot(id)
	local eff_id = self.cl_effect_count - id + 1

	for i = 1, eff_id do
		local inv_eff_id = self.cl_effect_count - i

		self.ammo_effects[inv_eff_id + 1]:stopImmediate()
	end

	local cur_shoot_offset = self.cl_effect_pos_data[id]
	local sht_eff_offset   = self.eff_offsets[EffectEnum.sht] or _vecZero()
	local cur_shoot_pos    = sht_eff_offset + cur_shoot_offset

	local sht_eff = self.effects[EffectEnum.sht]
	sht_eff:setOffsetPosition(cur_shoot_pos)
	sht_eff:start()

	local shape = self.shape
	local halfLength = (shape:getBoundingBox().z * 0.5) - 0.1
	local rayBegin = shape.worldPosition - shape.up * halfLength
	local rayEnd = rayBegin - self.shape.up * 0.15
	local hit, result = sm.physics.raycast(rayBegin, rayEnd, shape)
	if hit and result.type == "body" then
		return
	end

	self.effects[EffectEnum.fms]:start()
end

function RocketPod:client_onPodReload(reload_time)
	self.cl_reload_total = reload_time
	self.cl_reload_timer = reload_time

	for k, v in ipairs(self.ammo_effects) do
		if v:isPlaying() then
			v:stopImmediate()
		end
	end
end

function RocketPod:server_onCreate()
	local pod_data = _cpCannons_loadCannonInfo(self)
	local pod_eff_data    = pod_data.effect_config
	local pod_cannon_data = pod_data.cannon_config

	self.sv_ammo_capacity = #pod_eff_data.shoot_order
	self.sv_ammo_counter  = self.sv_ammo_capacity

	self.sv_shoot_delay      = pod_cannon_data.shoot_delay
	self.sv_full_reload_time = pod_cannon_data.full_reload_time
	self.sv_proj_id          = pod_cannon_data.proj_set_id
	self.sv_spread           = pod_cannon_data.spread
	self.sv_shoot_vel        = pod_cannon_data.velocity

	self.sv_proj_config = {}
end

function RocketPod:server_onFixedUpdate(dt)
	local s_inter = self.interactable
	if not _cpExists(s_inter) then return end

	local parent = s_inter:getSingleParent()
	local active = parent and parent.active

	if active and not self.reload then
		if self.sv_ammo_counter == 1 then
			self.reload = 30
		else
			self.reload = self.sv_shoot_delay
		end

		self.sv_proj_config[ProjSettingEnum.velocity] = _cp_calculateSpread(self, self.sv_spread, self.sv_shoot_vel)

		CPProjectile:server_sendProjectile(self, self.sv_proj_config, self.sv_proj_id)

		self.network:sendToClients("client_onShoot", self.sv_ammo_counter)
		self.sv_ammo_counter = self.sv_ammo_counter - 1
	end

	if self.reload then
		self.reload = (self.reload > 1 and self.reload - 1) or nil

		if self.sv_ammo_counter == 0 and self.reload == nil then
			self.reload = self.sv_full_reload_time
			self.sv_ammo_counter = self.sv_ammo_capacity
			self.network:sendToClients("client_onPodReload", self.reload)
		end
	end
end