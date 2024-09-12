--[[
	Copyright (c) 2025 Cannons Pack Team
	Questionable Mark
]]

if RailgunProjectile then return end

---@class RailgunProjHitResult
---@field result Vec3
---@field type string

---@class RailgunProjectileInstance : ProjectileInstance
---@field hit? RailgunProjHitResult
---@field explLvl number
---@field explRad number
---@field explImpStr number
---@field explImpRad number
---@field explEff string
---@field count integer
---@field proj_id integer

---@class RailgunProjectile : GlobalScript
---@field projectiles RailgunProjectileInstance[]
RailgunProjectile = class(GLOBAL_SCRIPT)
RailgunProjectile.projectiles = {}
RailgunProjectile.proj_queue = {}

RailgunProjectile.sv_last_update = 0
RailgunProjectile.cl_last_update = 0
RailgunProjectile.m_ref_count = 0

function RailgunProjectile.server_sendProjectile(self, shapeScript, data, id)
	local data_to_send = _cpProj_ClearNetworkData(data, id)

	_tableInsert(RailgunProjectile.proj_queue, {id, shapeScript.shape, data_to_send})
end

function RailgunProjectile.client_loadProjectile(self, data)
	local proj_data_id = data[1]
	local shape = data[2]
	local rc_proj_data = data[3]

	local has_shape = (shape ~= nil)
	if has_shape and not _cpExists(shape) then
		_cpPrint("RailgunProjectile: NO SHAPE")
		return
	end

	local proj_settings = _cpProj_CombineProjectileData(rc_proj_data, proj_data_id)
	local effect_id = proj_settings[ProjSettingEnum.shellEffect]
	local effect_name = CP_ProjShellEffectEnumStrings[effect_id]

	local success, shellEffect = pcall(_createEffect, effect_name)
	if not success then
		_logError(shellEffect)
		return
	end

	local position = proj_settings[ProjSettingEnum.position]
	if has_shape then
		position = shape.worldPosition + shape.worldRotation * position
	end

	shellEffect:setPosition(position)
	shellEffect:start()

	RailgunProjectile.projectiles[#RailgunProjectile.projectiles + 1] = {
		effect = shellEffect,
		pos = position,
		dir = proj_settings[ProjSettingEnum.velocity],
		alive = 10,
		count = proj_settings[ProjSettingEnum.count],
		explLvl = proj_settings[ProjSettingEnum.explosionLevel],
		explRad = proj_settings[ProjSettingEnum.explosionRadius],
		explImpRad = proj_settings[ProjSettingEnum.explosionImpulseRadius],
		explImpStr = proj_settings[ProjSettingEnum.explosionImpulseStrength],
		explEff = proj_settings[ProjSettingEnum.explosionEffect],
		proj_id = proj_data_id
	}
end

function RailgunProjectile.server_onScriptUpdate(self, dt, network)
	for b, data in pairs(RailgunProjectile.proj_queue) do
		self.network:sendToClients("client_loadProjectile", data)
		RailgunProjectile.proj_queue[b] = nil
	end

	for k, RlgProj in pairs(RailgunProjectile.projectiles) do
		if RlgProj and RlgProj.hit then
			_cpProj_betterExplosion(RlgProj.hit.result, RlgProj.explLvl, RlgProj.explRad, RlgProj.explImpStr, RlgProj.explImpRad, RlgProj.explEff, true)
			if RlgProj.count > 0 and RlgProj.hit.type ~= "invalid" and RlgProj.hit.type ~= "terrainAsset" and RlgProj.hit.type ~= "terrainSurface" then
				local data_to_send = {}
				data_to_send[ProjSettingEnum.position] = RlgProj.hit.result
				data_to_send[ProjSettingEnum.velocity] = RlgProj.dir
				data_to_send[ProjSettingEnum.explosionRadius] = RlgProj.explRad - 0.2
				data_to_send[ProjSettingEnum.explosionImpulseRadius] = RlgProj.explImpRad * 0.8
				data_to_send[ProjSettingEnum.explosionImpulseStrength] = RlgProj.explImpStr * 0.75
				data_to_send[ProjSettingEnum.count] = RlgProj.count - 1
				
				self.network:sendToClients("client_loadProjectile", {RlgProj.proj_id, nil, data_to_send})
			end
		end
	end
end

local _xAxis = _newVec(1, 0, 0)
function RailgunProjectile.client_onScriptUpdate(self, dt)
	for k, RlgProj in pairs(RailgunProjectile.projectiles) do
		if RlgProj and RlgProj.hit then RailgunProjectile.projectiles[k] = nil end
		if RlgProj and not RlgProj.hit then
			RlgProj.alive = RlgProj.alive - dt

			local rlg_pos = RlgProj.pos
			local rlg_dir = RlgProj.dir

			local hit, result = _physRaycast(rlg_pos, rlg_pos + rlg_dir * dt * 1.2)
			if hit or RlgProj.alive <= 0 then 
				RlgProj.hit = {result = (result.pointWorld ~= _vecZero() and result.pointWorld) or rlg_pos, type = result.type}
				_cpProj_cl_onProjHit(RlgProj.effect)
			else
				RlgProj.pos = rlg_pos + rlg_dir * dt

				local proj_eff = RlgProj.effect
				if rlg_dir:length() > 0.0001 then
					proj_eff:setRotation(_getVec3Rotation(_xAxis, rlg_dir))
				end

				proj_eff:setPosition(RlgProj.pos)
			end
		end
	end
end

function RailgunProjectile.client_onScriptDestroy(self)
	local deleted_projectiles = _cpProj_cl_destroyProjectiles(RailgunProjectile.projectiles)
	RailgunProjectile.projectiles = {}
	RailgunProjectile.proj_queue = {}
	_cpPrint(("RailgunProjectile: Deleted %s projectiles"):format(deleted_projectiles))
end

_CP_gScript.RailgunProjectile = RailgunProjectile