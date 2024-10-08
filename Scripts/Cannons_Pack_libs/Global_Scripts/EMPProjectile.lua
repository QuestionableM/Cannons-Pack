--[[
	Copyright (c) 2025 Cannons Pack Team
	Questionable Mark
]]

if EMPProjectile then return end

---@class EMPProjectileInstance : ProjectileInstance
---@field hit? Vec3
---@field disconnectRadius number

---@class EMPProjectile : GlobalScript
---@field projectiles EMPProjectileInstance[]
EMPProjectile = class(GLOBAL_SCRIPT)
EMPProjectile.projectiles = {}
EMPProjectile.proj_queue = {}

EMPProjectile.sv_last_update = 0
EMPProjectile.cl_last_update = 0
EMPProjectile.m_ref_count = 0

function EMPProjectile.server_sendProjectile(self, shapeScript, data, id)
	local data_to_send = _cpProj_ClearNetworkData(data, id)

	_tableInsert(EMPProjectile.proj_queue, {id, shapeScript.shape, data_to_send})
end

function EMPProjectile.client_loadProjectile(self, data)
	local proj_data_id, shape, data = unpack(data)

	if not _cpExists(shape) then
		_cpPrint("EMPProjectile: NO SHAPE")
		return
	end

	local proj_settings = _cpProj_CombineProjectileData(data, proj_data_id)

	local position = proj_settings[ProjSettingEnum.position]
	position = shape.worldPosition + shape.worldRotation * position

	local eff = _createEffect("EMPCannon - Shell")
	eff:setPosition(position)
	eff:start()

	EMPProjectile.projectiles[#EMPProjectile.projectiles + 1] = {
		effect = eff,
		pos = position,
		dir = proj_settings[ProjSettingEnum.velocity],
		alive = 10,
		disconnectRadius = proj_settings[ProjSettingEnum.disconnectRadius]
	}
end

function EMPProjectile.server_onScriptUpdate(self, dt)
	for b, data in pairs(EMPProjectile.proj_queue) do
		self.network:sendToClients("client_loadProjectile", data)
		EMPProjectile.proj_queue[b] = nil
	end

	for k,EMPProjectile in pairs(EMPProjectile.projectiles) do
		if EMPProjectile and EMPProjectile.hit then
			local shape_list = _getShapesInSphere(EMPProjectile.hit, EMPProjectile.disconnectRadius)

			for k, shape in pairs(shape_list) do
				if _cpExists(shape) then
					local s_Inter = shape:getInteractable()

					if s_Inter then
						for k, parent in pairs(s_Inter:getParents()) do
							parent:disconnect(s_Inter)
						end
					end
				end
			end

			_playEffect("EMPCannon - Explosion", EMPProjectile.hit)
		end
	end
end

---@param EMPProj EMPProjectileInstance
local function EMPProj_UpdateEffect(EMPProj)
	local emp_effect = EMPProj.effect

	emp_effect:setPosition(EMPProj.pos)

	local emp_dir = EMPProj.dir
	if emp_dir:length() > 0.0001 then
		emp_effect:setRotation(_getVec3Rotation(_newVec(1, 0, 0), emp_dir))
	end
end

function EMPProjectile.client_onScriptUpdate(self, dt)
	for k,EMPProj in pairs(EMPProjectile.projectiles) do
		if EMPProj and EMPProj.hit then EMPProjectile.projectiles[k] = nil end
		if EMPProj and not EMPProj.hit then
			EMPProj.alive = EMPProj.alive - dt

			local emp_pos = EMPProj.pos
			local emp_dir = EMPProj.dir

			local hit,result = _physRaycast(emp_pos, emp_pos + emp_dir * dt * 1.2)
			if hit or EMPProj.alive <= 0 then
				EMPProj.hit = (result.pointWorld ~= _vecZero() and result.pointWorld) or emp_pos
				_cpProj_cl_onProjHit(EMPProj.effect)
			else
				EMPProj.pos = emp_pos + emp_dir * dt
				EMPProj_UpdateEffect(EMPProj)
			end
		end
	end
end

function EMPProjectile.client_onScriptDestroy(self)
	local deleted_projectiles = _cpProj_cl_destroyProjectiles(EMPProjectile.projectiles)
	EMPProjectile.projectiles = {}
	EMPProjectile.proj_queue = {}
	_cpPrint(("EMPProjectile: Deleted %s projectiles"):format(deleted_projectiles))
end

_CP_gScript.EMPProjectile = EMPProjectile