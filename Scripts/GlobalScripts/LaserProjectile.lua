--[[
	Copyright (c) 2023 Cannons Pack Team
	Questionable Mark
]]

if LaserProjectile then return end

dofile("$CONTENT_DATA/Scripts/Libs/ScriptLoader.lua")

---@class LaserProjectile : ToolClass
LaserProjectile = class()
LaserProjectile.projectiles = {}
LaserProjectile.proj_queue = {}

local g_laserprojectile_host_tool = nil

function LaserProjectile:client_onCreate()
	if g_laserprojectile_host_tool == nil then
		g_laserprojectile_host_tool = self.tool
	end
end

function LaserProjectile.server_sendProjectile(self, shapeScript, data, id)
	_tableInsert(LaserProjectile.proj_queue, {id, shapeScript.shape, data[ProjSettingEnum.velocity]})
end

function LaserProjectile:client_loadProjectile(data)
	local proj_data_id, shape, velocity = unpack(data)

	if not _cpExists(shape) then
		_cpPrint("LaserProjectile: NO SHAPE")
		return
	end

	local proj_settings = _cpProj_GetProjectileSettings(proj_data_id)

	local position = proj_settings[ProjSettingEnum.position]
	position = shape.worldPosition + shape.worldRotation * position

	local shellEffect = _createEffect("LaserCannon - Shell")
	shellEffect:setPosition(position)
	shellEffect:start()

	LaserProjectile.projectiles[#LaserProjectile.projectiles + 1] = {
		effect = shellEffect,
		pos = position,
		dir = velocity,
		alive = proj_settings[ProjSettingEnum.lifetime]
	}
end

local _zAxis = _newVec(0, 0, 1)
local _vecOne = _newVec(1, 1, 1)
function LaserProjectile:server_onFixedUpdate(dt)
	if g_laserprojectile_host_tool ~= self.tool then
		return
	end

	for b, data in pairs(LaserProjectile.proj_queue) do
		self.network:sendToClients("client_loadProjectile", data)
		LaserProjectile.proj_queue[b] = nil
	end

	for k, proj in pairs(LaserProjectile.projectiles) do
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
function LaserProjectile:client_onFixedUpdate(dt)
	if g_laserprojectile_host_tool ~= self.tool then
		return
	end

	for k, proj in pairs(LaserProjectile.projectiles) do
		if proj then
			if proj.hit then
				LaserProjectile.projectiles[k] = nil
			else
				proj.alive = proj.alive - dt

				local p_Pos = proj.pos
				local p_Dir = proj.dir

				local r_hit, result = _physRaycast(p_Pos, p_Pos + p_Dir * dt * 1.2)
				if r_hit or proj.alive <= 0 then
					proj.hit = result
					_cpProj_cl_onProjHit(proj.effect)
				else
					proj.pos = p_Pos + p_Dir * dt

					local proj_effect = proj.effect
					proj_effect:setPosition(proj.pos)

					if p_Dir:length() > 0.0001 then
						proj_effect:setRotation(_getVec3Rotation(_xAxis, p_Dir))
					end
				end
			end
		end
	end
end

function LaserProjectile:client_onDestroy()
	if g_laserprojectile_host_tool ~= self.tool then
		return
	end

	local deleted_projectiles = _cpProj_cl_destroyProjectiles(LaserProjectile.projectiles)
	LaserProjectile.projectiles = {}
	LaserProjectile.proj_queue = {}

	_cpPrint(("LaserProjectile: Deleted %s projectiles"):format(deleted_projectiles))
end

_CP_gScript.LaserProjectile = LaserProjectile