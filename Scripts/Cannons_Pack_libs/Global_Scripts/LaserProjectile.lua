--[[
	Copyright (c) 2021 Cannons Pack Team
	Questionable Mark
]]

if LaserProjectile then return end
LaserProjectile = class(GLOBAL_SCRIPT)
LaserProjectile.projectiles = {}
LaserProjectile.proj_queue = {}

function LaserProjectile.server_sendProjectile(self, shapeScript, data)
	local position = data.position or _vecZero()
	local velocity = data.velocity or _newVec(0, 0, 1)
	local shellEffect = data.shellEffect
	local lifetime = data.lifetime or 30

	_tableInsert(self.proj_queue, {shapeScript.shape,position,velocity,shellEffect,lifetime})
end

function LaserProjectile.client_loadProjectile(self, data)
	local shape, position, velocity, shellEffect, lifetime = unpack(data)

	if not _cpExists(shape) then
		_cpPrint("LaserProjectile: NO SHAPE")
		return
	end

	position = shape.worldPosition + shape.worldRotation * position

	local success, shellEffect = pcall(_createEffect, shellEffect)
	if not success then
		_logError(shellEffect)
		return
	end

	shellEffect:setPosition(position)
	shellEffect:start()

	local laser_proj = {effect = shellEffect, pos = position, dir = velocity, alive = lifetime}
	self.projectiles[#self.projectiles + 1] = laser_proj
end

local _zAxis = _newVec(0, 0, 1)
local _vecOne = _newVec(1, 1, 1)
function LaserProjectile.server_onScriptUpdate(self, dt)
	for b, data in pairs(self.proj_queue) do
		self.network:sendToClients("client_loadProjectile", data)
		self.proj_queue[b] = nil
	end
	for k, proj in pairs(self.projectiles) do
		if proj and proj.hit then
			local _RayRes = proj.hit
			if _RayRes.valid then
				local _Shape = nil
				local _HitPos = _RayRes.pointWorld

				if _RayRes.type == "body" then
					_Shape = _RayRes:getShape()
				elseif _RayRes.type == "joint" then
					local _Joint = _RayRes:getJoint()

					if _cpExists(_Joint) then
						_Shape = _Joint:getShapeA()
					end
				end

				if _cpExists(_Shape) then
					if _isItemBlock(_Shape:getShapeUuid()) then
						local _BlockPos = _Shape:getClosestBlockLocalPosition(_HitPos)
						_Shape:destroyBlock(_BlockPos, _vecOne, 0)
					else
						_Shape:destroyShape(0)
					end
				end

				local _EffectRotation = _quatIdentity()
				if _RayRes.normalWorld:length() > 0.0001 then
					_EffectRotation = _getVec3Rotation(_zAxis, _RayRes.normalWorld)
				end

				_playEffect("LaserCannon - Explosion", _HitPos, _vecZero(), _EffectRotation)
			else
				_playEffect("LaserCannon - Explosion2", _RayRes.originWorld)
			end
		end
	end
end

local _xAxis = _newVec(1, 0, 0)
function LaserProjectile.client_onScriptUpdate(self, dt)
	for k, proj in pairs(self.projectiles) do
		if proj and proj.hit then
			self.projectiles[k] = nil
		end

		if proj and not proj.hit then
			proj.alive = proj.alive - dt

			local r_hit, result = _physRaycast(proj.pos, proj.pos + proj.dir * dt * 1.2)
			if r_hit or proj.alive <= 0 then
				proj.hit = result
				_cpProj_cl_onProjHit(proj.effect)
			end
			
			proj.effect:setPosition(proj.pos)
			proj.pos = proj.pos + proj.dir * dt

			if proj.dir:length() > 0.0001 then
				proj.effect:setRotation(_getVec3Rotation(_xAxis, proj.dir))
			end
		end
	end
end

function LaserProjectile.client_onScriptDestroy(self)
	local deleted_projectiles = _cpProj_cl_destroyProjectiles(self.projectiles)
	LaserProjectile.projectiles = {}
	LaserProjectile.proj_queue = {}
	_cpPrint(("LaserProjectile: Deleted %s projectiles"):format(deleted_projectiles))
end

_CP_gScript.LaserProjectile = LaserProjectile