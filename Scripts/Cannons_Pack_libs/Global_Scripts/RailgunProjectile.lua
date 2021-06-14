--[[
	Copyright (c) 2021 Cannons Pack Team
	Questionable Mark
]]

if RailgunProjectile then return end
RailgunProjectile = class(GLOBAL_SCRIPT)
RailgunProjectile.projectiles = {}
RailgunProjectile.proj_queue = {}

function RailgunProjectile.server_sendProjectile(self, shapeScript, data)
	local position = data.position
	local velocity = data.velocity
	local shellEffect = data.shellEffect
	local explosionEffect = data.explosionEffect or "PropaneTank - ExplosionBig"
	local explosionLevel = data.explosionLevel or 5
	local explosionRadius = data.explosionRadius or 0.5
	local explosionImpulseRadius = data.explosionImpulseRadius or 10
	local explosionImpulseStrength = data.explosionImpulseStrength or 50
	local count = data.count
	local effectToGive = data.shellEffect

	_tableInsert(self.proj_queue, {position, velocity, shellEffect, explosionEffect, explosionLevel, explosionRadius, explosionImpulseRadius, explosionImpulseStrength, count, effectToGive})
end

function RailgunProjectile.client_loadProjectile(self, data)
	local position,velocity,shellEffect,explosionEffect,explosionLevel,explosionRadius,explosionImpulseRadius,explosionImpulseStrength,count,effectToGive=unpack(data)

	local success, shellEffect = pcall(_createEffect, shellEffect)
	if not success then
		_logError(shellEffect)
		return
	end

	shellEffect:setPosition(position)
	shellEffect:start()

	local RlgProj = {
		effect = shellEffect,
		pos = position,
		dir = velocity,
		alive = 10,
		count = count,
		effTG = effectToGive,
		explosionLevel = explosionLevel,
		explosionRadius = explosionRadius,
		explosionImpulseRadius = explosionImpulseRadius,
		explosionImpulseStrength = explosionImpulseStrength,
		explosionEffect = explosionEffect
	}
	self.projectiles[#self.projectiles + 1] = RlgProj
end

function RailgunProjectile.server_onScriptUpdate(self, dt, network)
	for b, data in pairs(self.proj_queue) do
		self.network:sendToClients("client_loadProjectile", data)
		self.proj_queue[b] = nil
	end

	for k, RlgProj in pairs(self.projectiles) do
		if RlgProj and RlgProj.hit then
			_cpProj_betterExplosion(RlgProj.hit.result, RlgProj.explosionLevel, RlgProj.explosionRadius, RlgProj.explosionImpulseStrength, RlgProj.explosionImpulseRadius, RlgProj.explosionEffect, true)
			if RlgProj.count > 0 and RlgProj.hit.type ~= "invalid" and RlgProj.hit.type ~= "terrainAsset" and RlgProj.hit.type ~= "terrainSurface" then
				local proj = {
					RlgProj.hit.result,
					RlgProj.dir,
					RlgProj.effTG,
					RlgProj.explosionEffect,
					RlgProj.explosionLevel,
					RlgProj.explosionRadius - 0.2,
					RlgProj.explosionImpulseRadius - 10,
					RlgProj.explosionImpulseStrength - 1000,
					RlgProj.count - 1,
					RlgProj.effTG
				}

				self.network:sendToClients("client_loadProjectile", proj)
			end
		end
	end
end

local _xAxis = _newVec(1, 0, 0)
function RailgunProjectile.client_onScriptUpdate(self, dt)
	for k, RlgProj in pairs(self.projectiles) do
		if RlgProj and RlgProj.hit then self.projectiles[k] = nil end
		if RlgProj and not RlgProj.hit then
			RlgProj.alive = RlgProj.alive - dt

			local hit, result = _physRaycast(RlgProj.pos, RlgProj.pos + RlgProj.dir * dt * 1.2)
			if hit or RlgProj.alive <= 0 then 
				RlgProj.hit = {result = (result.pointWorld ~= _vecZero() and result.pointWorld) or RlgProj.pos, type = result.type}
				_cpProj_cl_onProjHit(RlgProj.effect)
			end

			RlgProj.pos = RlgProj.pos + RlgProj.dir * dt
			if RlgProj.dir:length() > 0.0001 then
				RlgProj.effect:setRotation(_getVec3Rotation(_xAxis, RlgProj.dir))
			end

			RlgProj.effect:setPosition(RlgProj.pos)
		end
	end
end

function RailgunProjectile.client_onScriptDestroy(self)
	local deleted_projectiles = _cpProj_cl_destroyProjectiles(self.projectiles)
	RailgunProjectile.projectiles = {}
	RailgunProjectile.proj_queue = {}
	_cpPrint(("RailgunProjectile: Deleted %s projectiles"):format(deleted_projectiles))
end

_CP_gScript.RailgunProjectile = RailgunProjectile