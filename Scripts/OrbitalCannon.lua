--[[
	Copyright (c) 2021 Cannons Pack Team
	Questionable Mark
]]

if OrbitalCannon then return end
dofile("Cannons_Pack_libs/ScriptLoader.lua")
OrbitalCannon = class(GLOBAL_SCRIPT)
OrbitalCannon.maxParentCount = 1
OrbitalCannon.maxChildCount = 0
OrbitalCannon.connectionInput = _connectionType.logic
OrbitalCannon.connectionOutput = _connectionType.none
OrbitalCannon.colorNormal = _colorNew(0x638583ff)
OrbitalCannon.colorHighlight = _colorNew(0x99cfcbff)

function OrbitalCannon:client_onCreate()
	self.effects = _cpEffect_cl_loadEffects(self)
	self.uv = {}
	self:client_injectScript("CPProjectile")
end

function OrbitalCannon:server_onCreate()
	self.projectileConfiguration = _cpCannons_loadCannonInfo(self)
end

function OrbitalCannon:server_createEffects(position, effectName, ExplLvl, ExplRad, ImpRad, ImpStr, explEffect, amonutOfBullets)
	self.projectileConfiguration.explosionLevel = ExplLvl
	self.projectileConfiguration.explosionRadius = ExplRad
	self.projectileConfiguration.explosionImpulseRadius = ImpRad
	self.projectileConfiguration.explosionImpulseStrength = ImpStr
	self.projectileConfiguration.explosionEffect = explEffect

	local effectPos = _newVec(position.x, position.y, 950)
	self.projectileConfiguration.position = effectPos

	_playEffect(effectName, effectPos)
	_playEffect("OrbitalCannon - PointSound", position)

	self.network:sendToClients("client_dispEffect", "pnt")
	for i = 1, amonutOfBullets do
		if effectName == "OrbitalCannon - PowerfulShot" then
			self.projectileConfiguration.velocity = _newVec(0, 0, -250)
		elseif effectName == "OrbitalCannon - OrdinaryShot" then
			self.projectileConfiguration.velocity = _gunSpread(_newVec(0, 0, _mathRandom(-250, -400)), 10)
		end

		CPProjectile:server_sendProjectile(self, self.projectileConfiguration)
	end
end

function OrbitalCannon:server_setValues(reload, sendData)
	self.reload = reload
	self.hold = nil

	if sendData then
		self.network:sendToClients("client_getUvData", {mode = "rld", rld = reload})
	end
end

function OrbitalCannon:server_onFixedUpdate()
	if not _smExists(self.interactable) then return end

	local parent = self.interactable:getSingleParent()
	local active = parent and parent.active

	if not self.reload then
		local hit, result = _physRaycast(self.shape.worldPosition, self.shape.worldPosition + self.shape.up * 2500)
		if hit and result.type ~= "invalid" and result.pointWorld.z < 900 then
			if active then
				if not self.hold then
					self.network:sendToClients("client_getUvData", {mode = "hld"})
				end
				self.hold = math.min((self.hold or 0) + 0.02, 1)
			end
			if self.hold and self.hold == 1 then
				self:server_createEffects(result.pointWorld, "OrbitalCannon - PowerfulShot", 99999, 7, 70, 40000, "OrbitalCannon - Explosion", 1)
				self:server_setValues(800, true)
			elseif self.hold and self.hold > 0 and not active then
				self:server_createEffects(result.pointWorld, "OrbitalCannon - OrdinaryShot", 10, 0.5, 10, 5000, "OrbitalCannon - ExplosionSmall", math.random(40, 80))
				self:server_setValues(450, true)
			end
		else
			if active then
				self.network:sendToClients("client_dispEffect", "err")
				self:server_setValues(0, false)
			end
		end
	else
		if self.reload == 30 then
			self.network:sendToClients("client_dispEffect", "rld")
		elseif self.reload <= 0 then
			self.network:sendToClients("client_getUvData", {mode = "clr"})
		end

		self.reload = (self.reload > 1 and self.reload - 1) or (active and 0 or nil)
	end
end

function OrbitalCannon:client_getUvData(data)
	if data.mode == "clr" then
		self.interactable:setUvFrameIndex(0)
	else
		self.uv.mode = data.mode
	end
	self.uv.rld = data.rld
	self.uv.index = nil
end

function OrbitalCannon:client_onFixedUpdate()
	if self.uv.mode == "rld" then
		self.uv.index = math.max((self.uv.index or 295) - (295 / self.uv.rld), 0)
		self.interactable:setUvFrameIndex(self.uv.index)
		if self.uv.index == 0 then
			self.uv = {}
		end
	elseif self.uv.mode == "hld" then
		self.uv.index = math.min((self.uv.index or 0) + 0.02, 1)
		self.interactable:setUvFrameIndex(self.uv.index * 295)
		if self.uv.index == 1 then
			self.uv = {}
		end
	end
end

function OrbitalCannon:client_onInteract(character, state)
	if not state then return end

	_cp_infoOutput("GUI Item drag", true, "A little advice:#ff0000 don't target the walls of the world", 2)
end

function OrbitalCannon:client_dispEffect(data)
	self.effects[data]:start()
end