--[[
	Copyright (c) 2025 Cannons Pack Team
	Questionable Mark
]]

if Railgun then return end

dofile("Cannons_Pack_libs/ScriptLoader.lua")

---@class Railgun : GlobalScriptHandler
Railgun = class(GLOBAL_SCRIPT)
Railgun.maxParentCount = 1
Railgun.maxChildCount  = 0
Railgun.connectionInput  = _connectionType.logic
Railgun.connectionOutput = _connectionType.none
Railgun.colorNormal    = _colorNew(0x00e8d1ff)
Railgun.colorHighlight = _colorNew(0x00ffe6ff)

function Railgun:client_onCreate()
	self.effects = _cpEffect_cl_loadEffects(self)
	self.effects[EffectEnum.eff]:setParameter("velocity", 0)
	self:client_injectScript("RailgunProjectile")
end

function Railgun:server_onCreate()
	self.projectileConfiguration = _cpCannons_loadCannonInfo(self)
end

local const_anim_val = 0.4285714285714286
function Railgun:client_uvAnim(data)
	self.fdp = const_anim_val * (240 - data)
end

function Railgun:client_onFixedUpdate(dt)
	if not self.fdp then return end

	self.fdp = _mathMin(self.fdp + const_anim_val, 30)
	self.interactable:setUvFrameIndex(self.fdp)

	local eff_effect = self.effects[EffectEnum.eff]

	if not eff_effect:isPlaying() then
		eff_effect:start()
	else
		eff_effect:setParameter("velocity", self.fdp * 1.6)
	end

	if self.fdp >= 30 then
		self.fdp = nil

		if eff_effect:isPlaying() then
			eff_effect:stop()
			self.interactable:setUvFrameIndex(0)
		end
	end
end

local railgun_recoil = _newVec(0, 0, -60000)
function Railgun:server_onFixedUpdate()
	if not _smExists(self.interactable) then return end

	local parent = self.interactable:getSingleParent()
	local active = parent and parent.active

	if active and not self.reload then
		self.reload = 240
		self.network:sendToClients("client_uvAnim", self.reload)
	end

	if self.reload then
		if _getCurrentTick() % 21 == 20 and self.reload > 170 then
			self.network:sendToClients("client_uvAnim", self.reload)
		end

		if self.reload == 170 then
			_cp_Shoot(self, nil, "client_effects", EffectEnum.sht, railgun_recoil)
			self.projectileConfiguration[ProjSettingEnum.velocity] = _cp_calculateSpread(self, 0, 1000)

			RailgunProjectile:server_sendProjectile(self, self.projectileConfiguration, ProjEnum.Railgun)
		end

		if self.reload == 30 then
			self.network:sendToClients("client_effects", EffectEnum.rld)
		end

		self.reload = (self.reload > 1 and self.reload - 1) or (active and 0 or nil)
	end
end

function Railgun:client_effects(effect)
	local eff_list = self.effects
	local is_sht_eff = (effect == EffectEnum.sht)

	local cur_eff = (is_sht_eff and {eff_list[EffectEnum.sht], eff_list[EffectEnum.sht2]} or eff_list[effect])
	local eff_dist = (is_sht_eff and 100 or 75)

	_cp_spawnOptimizedEffect(self.shape, cur_eff, eff_dist)
end