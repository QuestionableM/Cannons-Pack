--[[
	Copyright (c) 2022 Cannons Pack Team
	Questionable Mark
]]

if CPProjectile then return end
CPProjectile = class(GLOBAL_SCRIPT)

function CPProjectile.server_sendProjectile(proj_script, self, data, id)
	local data_to_send = _cpProj_ClearNetworkData(data, id)

	_tableInsert(self.proj_queue, {id, data_to_send})
end

function CPProjectile.client_loadProjectile(self, data)
	local shape = self.shape
	local proj_data_id, rc_proj_data = unpack(data)
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

	local effName = proj_settings[ProjSettingEnum.shellEffect]
	local success, shellEffect = pcall(_createEffect, effName)
	if not success then
		_logError(shellEffect)
		return
	end

	shellEffect:setPosition(position)
	shellEffect:start()

	local proxFuze = proj_settings[ProjSettingEnum.proxFuze] or 0
	local ignored_players = _cpProj_proxFuzeIgnore(shape.worldPosition, proxFuze)

	self.projectiles[#self.projectiles + 1] = {
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
		keep_effect = proj_settings[ProjSettingEnum.keep_effect]
	}
end

function CPProjectile.server_onScriptUpdate(self, dt)
	for b, data in pairs(self.proj_queue) do
		self.network:sendToClients("client_loadProjectile", data)
		self.proj_queue[b] = nil
	end

	for k, CPProj in pairs(self.projectiles) do
		if CPProj and CPProj.hit then 
			local expl_eff_name = ExplEffectEnumTrans[CPProj.explEff]

			_cpProj_betterExplosion(CPProj.hit, CPProj.explLvl, CPProj.explRad, CPProj.explImpStr, CPProj.explImpRad, expl_eff_name, true)
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

function CPProjectile.client_onScriptUpdate(self, dt)
	for k, CPProj in pairs(self.projectiles) do
		if CPProj then
			if CPProj.hit then
				self.projectiles[k] = nil
			else
				CPProj.alive = CPProj.alive - dt
				CPProj.dir = CPProj.dir * (1 - CPProj.friction) - _newVec(0, 0, CPProj.grav * dt)

				local cp_dir = CPProj.dir
				local cp_pos = CPProj.pos

				local hit, result = _physRaycast(cp_pos, cp_pos + cp_dir * dt * 1.2)
				if hit or CPProj.alive <= 0 or _cpProj_cl_proxFuze(CPProj.proxFuze, cp_pos, CPProj.ignored_players) then
					CPProj.hit = (result.valid and result.pointWorld) or cp_pos
					_cpProj_cl_onProjHit(CPProj.effect, CPProj.keep_effect)
				else
					CPProj.pos = cp_pos + cp_dir * dt
					CPProj_UpdateEffect(CPProj)
				end
			end
		end
	end
end

function CPProjectile.client_onScriptDestroy(self)
	_cpProj_cl_destroyProjectiles(self.projectiles)
end

_CP_gScript.CPProjectile = CPProjectile