--[[
	Copyright (c) 2021 Cannons Pack Team
	Questionable Mark
]]

if CPProjectile then return end
CPProjectile = class(GLOBAL_SCRIPT)
CPProjectile.projectiles = {}
CPProjectile.proj_queue = {}

function CPProjectile.server_sendProjectile(self, shapeScript, data)
	local localPosition = data.localPosition or false
	local localVelocity = data.localVelocity or false
	local syncEffect = data.syncEffect or false
	local position = data.position or _newVec(0, 0, 0)
	local velocity = data.velocity or _gunSpread(shapeScript.shape.up, 0) * 50
	local friction = data.friction or 0.003
	local gravity = data.gravity or 10
	local shellEffect = data.shellEffect
	local explosionEffect = data.explosionEffect or "PropaneTank - ExplosionBig"
	local lifetime = data.lifetime or 30
	local explosionLevel = data.explosionLevel or 5
	local explosionRadius = data.explosionRadius or 0.5
	local explosionImpulseRadius = data.explosionImpulseRadius or 10
	local explosionImpulseStrength = data.explosionImpulseStrength or 50
	local proxFuze = data.proxFuze or 0
	local ignored_players = _cpProj_proxFuzeIgnore(shapeScript.shape.worldPosition, proxFuze)
	local keep_effect = data.keep_effect

	_tableInsert(self.proj_queue,{shapeScript.shape,localPosition,localVelocity,syncEffect,position,velocity,friction,gravity,shellEffect,explosionEffect,lifetime,explosionLevel,explosionRadius,explosionImpulseRadius,explosionImpulseStrength,proxFuze,ignored_players,keep_effect})
end

function CPProjectile.client_loadProjectile(self, data)
	local shape,localPosition,localVelocity,syncEffect,position,velocity,friction,gravity,shellEffect,explosionEffect,lifetime,explosionLevel,explosionRadius,explosionImpulseRadius,explosionImpulseStrength,proxFuze,ignored_players,keep_effect=unpack(data)
	
	if (localPosition or localVelocity) and not _cpExists(shape) then
		_cpPrint("CPProjectile: NO SHAPE")
		return
	end

	if localVelocity then velocity = shape.worldRotation * velocity end
	if localPosition then position = shape.worldPosition + shape.worldRotation * position end

	local success, shellEffect = pcall(_createEffect, shellEffect)
	if not success then
		_logError(shellEffect)
		return
	end

	shellEffect:setPosition(position)
	shellEffect:start()

	local CPProj = {
		effect = shellEffect,
		pos = position,
		dir = velocity,
		alive = lifetime,
		grav = gravity,
		explosionLevel = explosionLevel,
		explosionRadius = explosionRadius,
		explosionImpulseRadius = explosionImpulseRadius,
		explosionImpulseStrength = explosionImpulseStrength,
		explosionEffect = explosionEffect,
		friction = friction,
		proxFuze = proxFuze,
		ignored_players = ignored_players,
		syncEffect = syncEffect,
		keep_effect = keep_effect
	}

	self.projectiles[#self.projectiles + 1] = CPProj
end

function CPProjectile.server_onScriptUpdate(self, dt)
	for b, data in pairs(self.proj_queue) do
		self.network:sendToClients("client_loadProjectile", data)
		self.proj_queue[b] = nil
	end
	for k,CPProj in pairs(self.projectiles) do
		if CPProj and CPProj.hit then 
			_cpProj_betterExplosion(CPProj.hit, CPProj.explosionLevel, CPProj.explosionRadius, CPProj.explosionImpulseStrength, CPProj.explosionImpulseRadius, CPProj.explosionEffect, true)
		end
	end
end

local _xAxis = _newVec(1, 0, 0)
function CPProjectile.client_onScriptUpdate(self, dt)
	for k, CPProj in pairs(self.projectiles) do
		if CPProj then
			if CPProj.hit then
				self.projectiles[k] = nil
			else
				CPProj.alive = CPProj.alive - dt
				CPProj.dir = CPProj.dir * (1 - CPProj.friction) - _newVec(0, 0, CPProj.grav * dt)

				local hit, result = _physRaycast(CPProj.pos, CPProj.pos + CPProj.dir * dt * 1.2)
				if hit or CPProj.alive <= 0 or _cpProj_cl_proxFuze(CPProj.proxFuze, CPProj.pos, CPProj.ignored_players) then
					CPProj.hit = (result.valid and result.pointWorld) or CPProj.pos
					_cpProj_cl_onProjHit(CPProj.effect, CPProj.keep_effect)
				end

				if CPProj.syncEffect then CPProj.effect:setPosition(CPProj.pos) end
				CPProj.pos = CPProj.pos + CPProj.dir * dt
				if CPProj.dir:length() > 0.0001 then
					CPProj.effect:setRotation(_getVec3Rotation(_xAxis, CPProj.dir))
				end
			end
		end
	end
end

function CPProjectile.client_onScriptDestroy(self)
	local deleted_projectiles = _cpProj_cl_destroyProjectiles(self.projectiles)
	CPProjectile.projectiles = {}
	CPProjectile.proj_queue = {}
	_cpPrint(("CPProjectile: Deleted %s projectiles"):format(deleted_projectiles))
end

_CP_gScript.CPProjectile = CPProjectile