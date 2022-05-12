--[[
	Copyright (c) 2021 Cannons Pack Team
	Questionable Mark
]]

if BulletShell then return end
BulletShell = class(GLOBAL_SCRIPT)
BulletShell.projectiles = {}
BulletShell.proj_queue = {}

function BulletShell.server_sendProjectile(self, shapeScript, proj_data_id)
	_tableInsert(self.proj_queue, {proj_data_id, shapeScript.shape})
end

function BulletShell.client_loadProjectile(self, data)
	local proj_data_id, shape = unpack(data)

	if not _cpExists(shape) then
		_cpPrint("BulletShell: NO SHAPE")
		return
	end

	local proj_settings = _cpProj_GetProjectileSettings(proj_data_id)

	local effect_name = proj_settings[ProjSettingEnum.shellEffect]
	local success, effect = pcall(_createEffect, effect_name)
	if not success then
		_logError("[CannonsPack] ERROR:\n"..effect)
		return
	end

	local position = proj_settings[ProjSettingEnum.position]
	local velocity = proj_settings[ProjSettingEnum.velocity]
	local lifetime = proj_settings[ProjSettingEnum.lifetime]

	local offset_position = shape.worldPosition + shape.worldRotation * position
	local vel_length = velocity * 100
	local random_velocity = _mathRandom(vel_length - 500, vel_length + 500) / 100
	local angle = _gunSpread(shape.at, 60) * random_velocity

	effect:setPosition(offset_position)
	effect:setRotation(shape.worldRotation)
	effect:start()

	self.projectiles[#self.projectiles + 1] = {
		effect = effect,
		pos = offset_position,
		dir = angle + shape.velocity,
		alive = _mathRandom(lifetime - 2, lifetime),
		gravity = proj_settings[ProjSettingEnum.gravity],
		friction = proj_settings[ProjSettingEnum.friction],
		no_col = 0.5,
		counter = 0,
		col_size = proj_settings[ProjSettingEnum.collision_size]
	}
end

function BulletShell.server_onScriptUpdate(self, dt)
	for b, data in pairs(self.proj_queue) do
		self.network:sendToClients("client_loadProjectile", data)
		self.proj_queue[b] = nil
	end
end

local _xAxis = _newVec(1, 0, 0)
local _zAxis = _newVec(0, 0, 1)
function BulletShell.client_onScriptUpdate(self, dt)
	for id, shell in pairs(self.projectiles) do
		if shell and shell.alive > 0 then
			shell.alive = shell.alive - dt
			shell.dir = shell.dir * (1 - shell.friction) - _newVec(0, 0, shell.gravity * dt)
			local dir_length = _mathMin(_mathMax(shell.dir:length() / 3, 0.7) - 0.7, 0.7)
			shell.counter = (shell.counter + (dir_length / (shell.col_size - 1))) % math.pi

			local hit, result = _physRaycast(shell.pos, shell.pos + (shell.dir * shell.col_size) * dt * 1.2)
			if hit then
				local velocity = _vecZero()
				local reflected_vector = _vecZero()
				if shell.alive > shell.no_col then
					if dir_length > 0 then
						if dir_length > 0.5 and (_getCamPosition() - result.pointWorld):length() < 50 then
							local _EffectRotation = _getVec3Rotation(_zAxis, result.normalWorld)
							local _EffMaterial = (result.type == "body" and result:getShape():getMaterialId()) or 1
							local _Mass = (result.type == "body" and result:getShape():getMass()) or 0.01

							_playEffect("Collision - Impact", result.pointWorld, _vecZero(), _EffectRotation, _vecZero(), {
								Size = _Mass / 1024,
								Velocity_max_50 = dir_length * 3.5 * shell.col_size,
								Material = _EffMaterial,
								Phys_energy = 1.0 * shell.col_size
							})
						end

						local normal = result.normalWorld
						local dot_product = shell.dir:dot(normal)
						local bounciness = 1.3
						reflected_vector = (shell.dir * 0.7) - (normal * dot_product * bounciness)
					end
					
					if result.type == "body" then velocity = result:getShape().velocity end
					shell.dir = reflected_vector + velocity
				end
			else
				if dir_length > 0 then
					local _RotDir = _getVec3Rotation(_xAxis, shell.dir)
					local _ZRot = _quatAngleAxis(shell.counter, _zAxis)

					local _FinalRot = _RotDir * _ZRot
					shell.effect:setRotation(_FinalRot)
				end
			end

			shell.pos = shell.pos + shell.dir * dt
			shell.effect:setPosition(shell.pos)
		else
			shell.effect:setPosition(_newVec(0, 0, 10000))
			shell.effect:stopImmediate()
			shell.effect:destroy()
			_createParticle("hammer_metal", shell.pos)
			self.projectiles[id] = nil
		end
	end
end

function BulletShell.client_onScriptDestroy(self)
	local deleted_projectiles = _cpProj_cl_destroyProjectiles(self.projectiles)
	BulletShell.projectiles = {}
	BulletShell.proj_queue = {}
	_cpPrint(("BulletShell: Deleted %s shells"):format(deleted_projectiles))
end

_CP_gScript.BulletShell = BulletShell