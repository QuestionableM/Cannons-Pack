--[[
	Copyright (c) 2021 Cannons Pack Team
	Questionable Mark
]]

if FlareProjectile then return end
FlareProjectile = class(GLOBAL_SCRIPT)
FlareProjectile.projectiles = {}
FlareProjectile.proj_queue = {}

function FlareProjectile.server_sendProjectile(self, shapeScript, direction)
	_tableInsert(self.proj_queue, {shapeScript.shape, direction})
end

function FlareProjectile.client_loadProjectile(self, data)
	local shape, dir = unpack(data)

	if not _cpExists(shape) then
		_cpPrint("FlareProjectile: NO SHAPE")
		return
	end

	local pos = shape.worldPosition + shape.worldRotation * _newVec(0, 0, 0.2)

	eff = _createEffect("FlareLauncher - Shell")
	eff:setPosition(pos)
	eff:start()

	self.projectiles[#self.projectiles + 1] = {
		effect = eff,
		pos = pos,
		dir = dir,
		alive = 5,
		grav = 5
	}
end

function FlareProjectile.server_onScriptUpdate(self, dt)
	for k, data in pairs(self.proj_queue) do
		self.network:sendToClients("client_loadProjectile", data)
		self.proj_queue[k] = nil
	end
end

function FlareProjectile.client_onScriptUpdate(self, dt)
	for k, flare in pairs(self.projectiles) do
		if flare and not flare.hit then
			flare.alive = flare.alive - dt
			flare.dir = flare.dir * 0.997 - _newVec(0, 0, flare.grav * dt)

			local hit, result = _physRaycast(flare.pos, flare.pos + flare.dir * dt * 1.2)
			if hit then
				flare.effect:setVelocity(_vecZero())
				flare.dir = _vecZero()
			else
				flare.pos = flare.pos + flare.dir * dt

				flare.effect:setPosition(flare.pos)
			end

			local _randVal = _mathRandom(100, 130)
			flare.effect:setParameter("intensity", flare.alive > 2 and (_randVal / 100 + 0.5) or (_randVal / 100 * ((flare.alive / 2) + 0.5)))
		end

		if flare and (flare.hit or flare.alive <= 0) then
			_cpProj_cl_onProjHit(flare.effect, true)
			self.projectiles[k] = nil
		end
	end
end

function FlareProjectile.client_onScriptDestroy(self)
	local deleted_projectiles = _cpProj_cl_destroyProjectiles(self.projectiles)
	FlareProjectile.projectiles = {}
	FlareProjectile.proj_queue = {}
	_cpPrint(("FlareProjectile: Deleted %s projectiles"):format(deleted_projectiles))
end

_CP_gScript.FlareProjectile = FlareProjectile