--[[
	Copyright (c) 2023 Cannons Pack Team
	Questionable Mark
]]

if CPProjectile then return end

dofile("$CONTENT_DATA/Scripts/Libs/ScriptLoader.lua")

---@class CPProjectile : ToolClass
CPProjectile = class()
CPProjectile.projectiles = {}
CPProjectile.proj_queue  = {}

local g_cpprojectile_host_tool = nil

function CPProjectile:client_onCreate()
	if g_cpprojectile_host_tool == nil then
		g_cpprojectile_host_tool = self.tool
	end
end

function CPProjectile.server_sendProjectile(self, shapeScript, data, id)
	local data_to_send = _cpProj_ClearNetworkData(data, id)
	_tableInsert(CPProjectile.proj_queue, {id, shapeScript.shape, data_to_send})
end

function CPProjectile:client_loadProjectile(data)
	local proj_data_id, shape, rc_proj_data = unpack(data)
	local proj_settings = _cpProj_CombineProjectileData(rc_proj_data, proj_data_id)

	local localPosition = proj_settings[ProjSettingEnum.localPosition]
	local localVelocity = proj_settings[ProjSettingEnum.localVelocity]

	if (localPosition or localVelocity) and not _cpExists(shape) then
		_cpPrint("CPProjectile: NO SHAPE")
		return
	end

	local velocity = proj_settings[ProjSettingEnum.velocity]
	local position = proj_settings[ProjSettingEnum.position]

	if localVelocity then velocity = shape.worldPosition * velocity end
	if localPosition then position = shape.worldPosition + shape.worldRotation * position end

	local v_effectId = proj_settings[ProjSettingEnum.shellEffect]
	local v_effectName = CP_ProjShellEffectEnumStrings[v_effectId]

	local success, shellEffect = pcall(_createEffect, v_effectName)
	if not success then
		_logError(shellEffect)
		return
	end

	shellEffect:setPosition(position)
	shellEffect:start()

	local proxFuze = proj_settings[ProjSettingEnum.proxFuze] or 0
	local ignored_players = _cpProj_proxFuzeIgnore(shape.worldPosition, proxFuze)

	CPProjectile.projectiles[#CPProjectile.projectiles + 1] = {
		effect = shellEffect,
		pos = position,
		dir = velocity,
		alive = proj_settings[ProjSettingEnum.lifetime],
		grav = proj_settings[ProjSettingEnum.gravity],
		explLvl = proj_settings[ProjSettingEnum.explosionLevel],
		explRad = proj_settings[ProjSettingEnum.explosionRadius],
		explImpRad = proj_settings[ProjSettingEnum.explosionImpulseRadius],
		explImpStr = proj_settings[ProjSettingEnum.explosionImpulseStrength],
		explEff = proj_settings[ProjSettingEnum.explosionEffect],
		friction = proj_settings[ProjSettingEnum.friction],
		proxFuze = proxFuze,
		ignored_players = ignored_players,
		syncEffect = proj_settings[ProjSettingEnum.syncEffect],
		keep_effect = CP_ProjShouldKeepEffect[v_effectId]
	}
end

local CPProj_ProjectilesWithNormals =
{
	[ExplEffectEnum.PotatoHit] = true,
	[ExplEffectEnum.EMPCannon] = true
}

local function CPProj_PlayEffect(proj)
	local v_proj_expl_id = proj.explEff
	local v_expl_eff = ExplEffectEnumTrans[v_proj_expl_id]

	if CPProj_ProjectilesWithNormals[v_proj_expl_id] then
		local v_ray_result = proj.ray_result --[[@as RaycastResult]]

		if v_ray_result ~= nil then
			local v_eff_rotation = _getVec3Rotation(_newVec(0, 0, 1), v_ray_result.normalWorld)
			_playEffect(v_expl_eff, v_ray_result.pointWorld, nil, v_eff_rotation)

			return nil
		end
	end

	return v_expl_eff
end

local function CPProj_spawnExplosion(proj)
	local v_proj_hit = proj.hit

	if proj.explRad < 0.3 then
		local v_hit_shape = proj.hit_shape --[[@as Shape]]
		if _cpExists(v_hit_shape) then
			local v_shape_uuid = v_hit_shape.uuid

			if _getItemQualityLevel(v_shape_uuid) <= proj.explLvl then
				if _isItemBlock(v_shape_uuid) then
					local v_block_hit = v_hit_shape:getClosestBlockLocalPosition(v_proj_hit)
					v_hit_shape:destroyBlock(v_block_hit, _vecOne())
				else
					v_hit_shape:destroyShape()
				end

				local v_eff_rotation = nil
				local v_ray_result = proj.ray_result
				if v_ray_result ~= nil then
					v_eff_rotation = _getVec3Rotation(_newVec(0, 0, 1), v_ray_result.normalWorld)
				end

				_playEffect(ExplEffectEnumTrans[proj.explEff], v_proj_hit, nil, v_eff_rotation)

				return
			end
		end
	end

	local v_effect_string = CPProj_PlayEffect(proj)
	_cpProj_betterExplosion(v_proj_hit, proj.explLvl, math.max(proj.explRad, 0.3), proj.explImpStr, proj.explImpRad, v_effect_string, true)
end

function CPProjectile:server_onFixedUpdate(dt)
	if g_cpprojectile_host_tool ~= self.tool then
		return
	end

	for b, data in pairs(CPProjectile.proj_queue) do
		self.network:sendToClients("client_loadProjectile", data)
		CPProjectile.proj_queue[b] = nil
	end

	for k, CPProj in pairs(CPProjectile.projectiles) do
		if CPProj and CPProj.hit then
			CPProj_spawnExplosion(CPProj)
		end
	end
end

local _xAxis = _newVec(1, 0, 0)
local function CPProj_UpdateEffect(CPProj)
	local cp_effect = CPProj.effect

	if CPProj.syncEffect then
		cp_effect:setPosition(CPProj.pos)
	end

	local cp_dir = CPProj.dir
	if cp_dir:length() > 0.0001 then
		cp_effect:setRotation(_getVec3Rotation(_xAxis, cp_dir))
	end
end

---@param result RaycastResult
local function CPProj_TryCreateDebris(result, proj)
	if result.type ~= "body" then
		return
	end

	local v_hit_shape = result:getShape()
	if not _cpExists(v_hit_shape) then
		return
	end

	local v_shape_uuid = v_hit_shape.uuid
	proj.hit_shape = v_hit_shape

	if _getItemQualityLevel(v_shape_uuid) <= proj.explLvl and proj.explRad < 0.3 then
		local v_ang_vel = _newVec(
			_mathRandom(1, 500) / 10,
			_mathRandom(1, 500) / 10,
			_mathRandom(1, 500) / 10
		)

		local v_debri_pos = _isItemBlock(v_shape_uuid) and result.pointWorld or v_hit_shape.worldPosition
		local v_debri_lifetime = _mathRandom(3, 7)

		_createDebris(v_shape_uuid, v_debri_pos, v_hit_shape.worldRotation, v_hit_shape.velocity, v_ang_vel, v_hit_shape.color, v_debri_lifetime)
	end
end

function CPProjectile:client_onFixedUpdate(dt)
	if g_cpprojectile_host_tool ~= self.tool then
		return
	end

	for k, CPProj in pairs(CPProjectile.projectiles) do
		if CPProj then
			if CPProj.hit then
				CPProjectile.projectiles[k] = nil
			else
				CPProj.alive = CPProj.alive - dt
				CPProj.dir = CPProj.dir * (1 - CPProj.friction) - _newVec(0, 0, CPProj.grav * dt)

				local cp_dir = CPProj.dir
				local cp_pos = CPProj.pos

				local hit, result = _physRaycast(cp_pos, cp_pos + cp_dir * dt * 1.2)
				if hit or CPProj.alive <= 0 or _cpProj_cl_proxFuze(CPProj.proxFuze, cp_pos, CPProj.ignored_players) then
					if hit then
						CPProj.ray_result = result
						CPProj.hit = result.pointWorld

						CPProj_TryCreateDebris(result, CPProj)
					else
						CPProj.hit = cp_pos
					end

					_cpProj_cl_onProjHit(CPProj.effect, CPProj.keep_effect)
				else
					CPProj.pos = cp_pos + cp_dir * dt
					CPProj_UpdateEffect(CPProj)
				end
			end
		end
	end
end

function CPProjectile:client_onDestroy()
	if g_cpprojectile_host_tool ~= self.tool then
		return
	end

	local deleted_projectiles = _cpProj_cl_destroyProjectiles(CPProjectile.projectiles)
	CPProjectile.projectiles = {}
	CPProjectile.proj_queue = {}

	_cpPrint(("CPProjectile: Deleted %s projectiles"):format(deleted_projectiles))
end

_CP_gScript.CPProjectile = CPProjectile