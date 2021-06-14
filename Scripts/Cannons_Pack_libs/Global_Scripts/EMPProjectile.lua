--[[
	Copyright (c) 2021 Cannons Pack Team
	Questionable Mark
]]

if EMPProjectile then return end
EMPProjectile = class(GLOBAL_SCRIPT)
EMPProjectile.projectiles = {}
EMPProjectile.proj_queue = {}

function EMPProjectile.client_loadProjectile(self, data)
	local shape,position,velocity,disconnectRadius = unpack(data)

	if not _cpExists(shape) then
		_cpPrint("EMPProjectile: NO SHAPE")
		return
	end

	local realPos = shape.worldPosition + shape.worldRotation * position
	local eff = _createEffect("EMPCannon - Shell")

	eff:setPosition(realPos)
	eff:start()
	
	local EMPProj = {effect = eff, pos = realPos, dir = velocity, alive = 10, disconnectRadius = disconnectRadius}
	self.projectiles[#self.projectiles + 1] = EMPProj
end

function EMPProjectile.server_sendProjectile(self, shapeScript, data)
	local position = data.position
	local velocity = data.velocity
	local disconnectRadius = data.disconnectRadius
	_tableInsert(self.proj_queue, {shapeScript.shape, position, velocity, disconnectRadius})
end

function EMPProjectile.server_onScriptUpdate(self, dt)
	for b, data in pairs(self.proj_queue) do
		self.network:sendToClients("client_loadProjectile", data)
		self.proj_queue[b] = nil
	end

	for k,EMPProjectile in pairs(self.projectiles) do
		if EMPProjectile and EMPProjectile.hit then
			local shape_list = _getShapesInSphere(EMPProjectile.hit, EMPProjectile.disconnectRadius)

			for k, shape in pairs(shape_list) do
				if _cpExists(shape) and shape:getInteractable() then
					local s_interactable = shape:getInteractable()

					for k, parent in pairs(s_interactable:getParents()) do
						parent:disconnect(s_interactable)
					end
				end
			end

			_playEffect("EMPCannon - Explosion", EMPProjectile.hit)
		end
	end
end

function EMPProjectile.client_onScriptUpdate(self, dt)
	for k,EMPProj in pairs(self.projectiles) do
		if EMPProj and EMPProj.hit then self.projectiles[k] = nil end
		if EMPProj and not EMPProj.hit then
			EMPProj.alive = EMPProj.alive - dt

			local hit,result = _physRaycast(EMPProj.pos, EMPProj.pos + EMPProj.dir * dt * 1.2)
			if hit or EMPProj.alive <= 0 then
				EMPProj.hit = (result.pointWorld ~= _vecZero() and result.pointWorld) or EMPProj.pos
				_cpProj_cl_onProjHit(EMPProj.effect)
			end

			EMPProj.pos = EMPProj.pos + EMPProj.dir * dt
			if EMPProj.dir:length() > 0.0001 then
				EMPProj.effect:setRotation(_getVec3Rotation(_newVec(1, 0, 0), EMPProj.dir))
			end

			EMPProj.effect:setPosition(EMPProj.pos)
		end
	end
end

function EMPProjectile.client_onScriptDestroy(self)
	local deleted_projectiles = _cpProj_cl_destroyProjectiles(self.projectiles)
	EMPProjectile.projectiles = {}
	EMPProjectile.proj_queue = {}
	_cpPrint(("EMPProjectile: Deleted %s projectiles"):format(deleted_projectiles))
end

_CP_gScript.EMPProjectile = EMPProjectile