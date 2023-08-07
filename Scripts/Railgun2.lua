--[[
	Copyright (c) 2023 Cannons Pack Team
	Questionable Mark
]]

if Railgun2 then return end

dofile("Libs/ScriptLoader.lua")

Railgun2 = class()
Railgun2.maxParentCount = 1
Railgun2.maxChildCount  = 0
Railgun2.connectionInput  = _connectionType.logic
Railgun2.connectionOutput = _connectionType.none
Railgun2.colorNormal    = _colorNew(0x700000ff)
Railgun2.colorHighlight = _colorNew(0xd10000ff)

function Railgun2:client_onCreate()
	self.effects = _cpEffect_cl_loadEffects(self)
	self.uv = {pitch = 0, speed = 0, anim = 0}
end

function Railgun2:server_onCreate()
	self.projectileConfiguration = _cpCannons_loadCannonInfo(self)
end

function Railgun2:client_uvAnim(data)
	self.uv.fdp = data
end

function Railgun2:client_onFixedUpdate(dt)
	local uv_fdp = self.uv.fdp
	if not uv_fdp then return end

	local eff_effect = self.effects[EffectEnum.eff]

	if uv_fdp < 360 and not eff_effect:isPlaying() then
		eff_effect:start()
	end

	if uv_fdp < 359 and uv_fdp > 260 then 
		eff_effect:setParameter("velocity", self.uv.pitch) 
		self.interactable:setUvFrameIndex(self.uv.anim) 
	end

	if uv_fdp < 265 then
		eff_effect:setParameter("velocity", 0)
		self.interactable:setUvFrameIndex(0)
		eff_effect:stop()
	end

	uv_fdp = (uv_fdp > 240 and uv_fdp - 1) or nil
	self.uv.pitch = _mathMin((uv_fdp and self.uv.pitch + 0.59) or 0.50)
	self.uv.speed = _mathMin((uv_fdp and self.uv.speed + 0.07) or 0.6)
	self.uv.anim = (uv_fdp and self.uv.anim % 53 + self.uv.speed) or 0
	self.uv.fdp = uv_fdp
end

local railgun2_recoil = _newVec(0, 0, -80000)
function Railgun2:server_onFixedUpdate()
	if not _smExists(self.interactable) then return end

	local parent = self.interactable:getSingleParent()
	local active = parent and parent.active

	if active and not self.reload then
		self.reload = 360
		self.network:sendToClients("client_uvAnim", self.reload)
	end

	if self.reload then
		if _getCurrentTick() % 21 == 20 then
			self.network:sendToClients("client_uvAnim", self.reload)
		end

		if self.reload == 265 then
			_cp_Shoot(self, nil, "client_effects", EffectEnum.sht, railgun2_recoil)
			self.projectileConfiguration[ProjSettingEnum.velocity] = _cp_calculateSpread(self, 0, 1000)

			RailgunProjectile:server_sendProjectile(self, self.projectileConfiguration, ProjEnum.Railgun2)
		end

		if self.reload == 30 then
			self.network:sendToClients("client_effects", EffectEnum.rld)
		end

		self.reload = (self.reload > 1 and self.reload - 1) or (active and 0 or nil)
	end
end

function Railgun2:client_effects(effect)
	_cp_spawnOptimizedEffect(self.shape, self.effects[effect], 125)
end