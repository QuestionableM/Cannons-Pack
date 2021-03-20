--[[
    Copyright (c) 2021 Cannons Pack Team
    Questionable Mark
]]

if Railgun2 then return end
dofile("Cannons_Pack_libs/ScriptLoader.lua")
Railgun2 = class(GLOBAL_SCRIPT)
Railgun2.maxParentCount = 1
Railgun2.maxChildCount = 0
Railgun2.connectionInput = sm.interactable.connectionType.logic
Railgun2.connectionOutput = sm.interactable.connectionType.none
Railgun2.colorNormal = sm.color.new(0x700000ff)
Railgun2.colorHighlight = sm.color.new(0xd10000ff)
function Railgun2:client_onCreate()
	self.effects = CP_Effects.client_loadEffect(self)
	self:client_injectScript("RailgunProjectile")
	self.uv = {pitch = 0, speed = 0, anim = 0}
end
function Railgun2:server_onCreate()
	self:GS_init()
	self.projectileConfiguration = CP_Cannons.load_cannon_info(self)
end
function Railgun2:client_uvAnim(data) self.uv.fdp = data end
function Railgun2:client_onFixedUpdate(dt)
	if self.uv.fdp then
		if self.uv.fdp < 360 and not self.effects.eff:isPlaying() then self.effects.eff:start() end
		if self.uv.fdp < 359 and self.uv.fdp > 260 then 
			self.effects.eff:setParameter("velocity", self.uv.pitch) 
			self.interactable:setUvFrameIndex(self.uv.anim) 
		end
		if self.uv.fdp < 265 then
			self.effects.eff:setParameter("velocity", 0)
			self.interactable:setUvFrameIndex(0)
			self.effects.eff:stop()
		end
		self.uv.fdp = (self.uv.fdp > 240 and self.uv.fdp - 1) or nil
		self.uv.pitch = math.min((self.uv.fdp and self.uv.pitch + 0.59) or 0.50)
		self.uv.speed = math.min((self.uv.fdp and self.uv.speed + 0.07) or 0.6)
		self.uv.anim = (self.uv.fdp and self.uv.anim % 53 + self.uv.speed) or 0
	end
end
function Railgun2:server_onFixedUpdate()
	if not sm.exists(self.interactable) then return end
	local parent = self.interactable:getSingleParent()
	local active = parent and parent.active
	if active and not self.reload then
		self.reload = 360
		self.network:sendToClients("client_uvAnim", self.reload)
	end
	if self.reload then
		if sm.game.getCurrentTick() % 21 == 20 then
			self.network:sendToClients("client_uvAnim", self.reload)
		end
		if self.reload == 265 then
			CP.shoot(self, nil, "client_effects", "sht", sm.vec3.new(0, 0, -80000))
			self.projectileConfiguration.position = self.shape.worldPosition + self.shape.worldRotation * sm.vec3.new(0, 0, 1.1)
			self.projectileConfiguration.velocity = CP.calculate_spread(self, 0, 1000)
			RailgunProjectile:server_sendProjectile(self, self.projectileConfiguration)
		end
		if self.reload == 30 then self.network:sendToClients("client_effects", "rld") end
		self.reload = (self.reload > 1 and self.reload - 1) or (active and 0 or nil)
	end
end
function Railgun2:client_effects(effect)
	CP.spawn_optimized_effect(self.shape, self.effects[effect], 125)
end