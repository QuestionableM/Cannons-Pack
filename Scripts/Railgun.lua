--[[
    Copyright (c) 2021 Cannons Pack Team
    Questionable Mark
]]

if Railgun then return end
dofile("Cannons_Pack_libs/ScriptLoader.lua")
Railgun = class(GLOBAL_SCRIPT)
Railgun.maxParentCount = 1
Railgun.maxChildCount = 0
Railgun.connectionInput = sm.interactable.connectionType.logic
Railgun.connectionOutput = sm.interactable.connectionType.none
Railgun.colorNormal = sm.color.new(0x00e8d1ff)
Railgun.colorHighlight = sm.color.new(0x00ffe6ff)
function Railgun:client_onCreate()
	self.effects = CP_Effects.client_loadEffect(self)
	self.effects.eff:setParameter("velocity", 0)
	self:client_injectScript("RailgunProjectile")
	self.constant = 0.4285714285714286
end
function Railgun:server_onCreate()
	self.projectileConfiguration = CP_Cannons.load_cannon_info(self)
end
function Railgun:client_uvAnim(data)
	self.fdp = self.constant * (240 - data)
end
function Railgun:client_onFixedUpdate(dt)
	if self.fdp then
		self.fdp = math.min(self.fdp + self.constant, 30)
		self.interactable:setUvFrameIndex(self.fdp)
		if not self.effects.eff:isPlaying() then
			self.effects.eff:start()
		else
			self.effects.eff:setParameter("velocity", self.fdp * 1.6)
		end
		if self.fdp >= 30 then
			self.fdp = nil
			if self.effects.eff:isPlaying() then
				self.effects.eff:stop()
				self.interactable:setUvFrameIndex(0)
			end
		end
	end
end
function Railgun:server_onFixedUpdate()
	if not sm.exists(self.interactable) then return end
	local parent = self.interactable:getSingleParent()
	local active = parent and parent.active
	if active and not self.reload then
		self.reload = 240
		self.network:sendToClients("client_uvAnim", self.reload)
	end
	if self.reload then
		if sm.game.getCurrentTick() % 21 == 20 and self.reload > 170 then
			self.network:sendToClients("client_uvAnim", self.reload)
		end
		if self.reload == 170 then
			CP.shoot(self, nil, "client_effects", "sht", sm.vec3.new(0, 0, -60000))
			self.projectileConfiguration.position = self.shape.worldPosition + self.shape.worldRotation * sm.vec3.new(0, 0, 1.4)
			self.projectileConfiguration.velocity = CP.calculate_spread(self, 0, 1000)
			RailgunProjectile:server_sendProjectile(self, self.projectileConfiguration)
		end
		if self.reload == 30 then self.network:sendToClients("client_effects", "rld") end
		self.reload = (self.reload > 1 and self.reload - 1) or (active and 0 or nil)
	end
end
function Railgun:client_effects(effect)
	if effect == "sht" then
		CP.spawn_optimized_effect(self.shape, {self.effects.sht, self.effects.sht2}, 100)
	else
		CP.spawn_optimized_effect(self.shape, self.effects[effect], 75)
	end
end