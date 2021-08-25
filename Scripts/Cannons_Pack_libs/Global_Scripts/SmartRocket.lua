--[[
	Copyright (c) 2021 Cannons Pack Team
	Questionable Mark
]]

if SmartRocket then return end
SmartRocket = class(GLOBAL_SCRIPT)
SmartRocket.projectiles = {}
SmartRocket.proj_queue = {}

--The FOV of Smart Rocket is 60 degrees (-0.66)
--The FOV of Smart Rocket Detector is 80 degress (-0.88)

function SmartRocket.server_sendProjectile(self, shapeScript, data, id)
	local data_to_send = _cpProj_ClearNetworkData(data, id)

	_tableInsert(self.proj_queue, {id, shapeScript.shape, data_to_send})
end

SR_ModeEnum = {
	cam = 1,
	dirCam = 2
}

function SmartRocket.client_loadProjectile(self, data)
	local proj_data_id, shape, rc_proj_data = unpack(data)

	if not _cpExists(shape) then
		_cpPrint("SmartRocket: NO SHAPE")
		return
	end

	local proj_settings = _cpProj_CombineProjectileData(rc_proj_data, proj_data_id)

	local position = proj_settings[ProjSettingEnum.position]
	position = shape.worldPosition + shape.worldRotation * position

	local velocity = proj_settings[ProjSettingEnum.velocity]

	local effect = _createEffect("RocketLauncher - Shell")
	effect:setPosition(position)
	effect:start()

	local proximity_fuze = proj_settings[ProjSettingEnum.proxFuze]
	local ignored_players = _cpProj_proxFuzeIgnore(shape.worldPosition, proximity_fuze)

	self.projectiles[#self.projectiles + 1] = {
		effect = effect,
		pos = position,
		dir = velocity,
		alive = 15,
		mode = proj_settings[ProjSettingEnum.mode],
		vel = proj_settings[ProjSettingEnum.speed],
		player = proj_settings[ProjSettingEnum.player],
		shape = shape,
		proxFuze = proximity_fuze,
		ignored_players = ignored_players
	}
end

function SmartRocket.server_onScriptUpdate(self, dt)
	for k, data in pairs(self.proj_queue) do
		self.network:sendToClients("client_loadProjectile", data)
		self.proj_queue[k] = nil
	end

	for b, proj in pairs(self.projectiles) do
		if proj and proj.hit then
			_cpProj_betterExplosion(proj.hit, 60, 0.7, 7000, 30, "ExplBig", true)
		end
	end
end

local function getClosestVisiblePlayer(pos, dir)
	local ClosestPlayer = nil
	local ClosestDistance = math.huge

	for id, player in pairs(_getAllPlayers()) do
		local p_Char = player.character

		if _cpExists(p_Char) then
			local c_Position = p_Char.worldPosition
			local isVisible = _cp_isObjectVisible(pos, dir, c_Position, -0.66)

			if isVisible then
				local target_dist = (pos - c_Position):length()

				if target_dist < ClosestDistance then
					ClosestPlayer = c_Position
					ClosestDistance = target_dist
				end
			end
		end
	end

	return ClosestPlayer
end

local _xAxis = _newVec(1, 0, 0)
local function UpdateRocketEffect(rocket)
	local dir_len = rocket.dir:length()
	local r_Effect = rocket.effect

	r_Effect:setPosition(rocket.pos)
	r_Effect:setParameter("intensity", _mathRandom(150, 230) / 100)
	r_Effect:setParameter("velocity", dir_len)

	if dir_len > 0.001 then
		local r_QuatDir = _getVec3Rotation(_xAxis, rocket.dir)
		local r_RotSpeed = (_getCurrentTick() * 5) % 360
		local r_QuatRot = _quatAngleAxis(_mathRad(r_RotSpeed), _xAxis)

		r_Effect:setRotation(r_QuatDir * r_QuatRot)
	end
end

local function GetPlayerCharacter(player)
	if not _cpExists(player) then return end

	local pl_char = player:getCharacter()
	if _cpExists(pl_char) then
		return pl_char
	end
end

local r_FlarEnum = {
	dead = 1,
	char = 2,
	flare = 3
}

local r_ModeDist = {
	[r_FlarEnum.flare] = 8
}

local function PickATargetInternal(rocket_pos, char_pos, playerVisible, flare)
	local has_char = (char_pos ~= nil and playerVisible)

	if has_char and flare then
		local pl_dist = (rocket_pos - char_pos):length()
		local fl_dist = (rocket_pos - flare):length()

		local is_pl_further = (pl_dist > fl_dist)

		if is_pl_further and (flare - char_pos):length() < 10 then
			return flare, r_FlarEnum.flare
		end

		local o_Pos = is_pl_further and flare or char_pos
		local o_Type = is_pl_further and "flare" or "char"

		return o_Pos, o_Type
	elseif has_char then
		return char_pos, r_FlarEnum.char
	elseif flare then
		return flare, r_FlarEnum.flare
	end
end

local function PickATarget(rocket, char_pos, char_visible)
	local r_Pos = rocket.pos

	local closest_flare = _cpProj_getNearestVisibleFlare(FlareProjectile.projectiles, r_Pos, rocket.dir)
	local targetPos, targetType = PickATargetInternal(r_Pos, char_pos, char_visible, closest_flare)

	local is_char = (targetType == r_FlarEnum.char)
	if targetPos and ((is_char and rocket.flar ~= r_FlarEnum.dead) or not is_char) then
		local target_dist = (targetPos - r_Pos):length()

		return targetPos, target_dist, targetType
	end
end

function SmartRocket.client_onScriptUpdate(self, dt)
	for k, rocket in pairs(self.projectiles) do
		if rocket and rocket.hit then
			self.projectiles[k] = nil
		end

		if rocket and not rocket.hit then
			rocket.alive = rocket.alive - dt
			local r_Alive = rocket.alive
			local r_Pos = rocket.pos

			local r_Accuracy = 0.1
			local t_Position = r_Pos + rocket.dir
			local t_Distance = math.huge
			local r_shape = rocket.shape
			local r_shape_exists = _cpExists(r_shape)
			local r_Mode = rocket.mode
			local camera = (r_Mode ~= nil)

			if rocket.flar ~= r_FlarEnum.dead and _cpProj_isFlareNear(FlareProjectile.projectiles, r_Pos, 10) then
				rocket.flar = r_FlarEnum.dead
			end

			local r_DirGood = (rocket.dir:length() > 0.001)
			local o_Char = GetPlayerCharacter(rocket.player)
			if o_Char ~= nil then
				local char_pos = o_Char.worldPosition

				if camera then
					local cam_offset = _newVec(0, 0, o_Char:isCrouching() and 0.275 or 0.575)
					local offset_pos = char_pos + cam_offset
					local char_dir = o_Char.direction

					local hit, result = _physRaycast(offset_pos + char_dir, offset_pos + char_dir * 2500)
					if hit then
						if r_Mode == SR_ModeEnum.dirCam then
							if r_shape_exists then
								t_Position = result.directionWorld * 20
							end
						else
							if (r_shape_exists and result:getBody() ~= r_shape.body) and result:getCharacter() ~= o_Char then
								t_Position = result.pointWorld
								t_Distance = (t_Position - r_Pos):length()
							end
						end
					end
				else
					if r_Alive < 14.5 and r_Alive > 14 then
						r_Accuracy = 0.25
						t_Position = char_pos
						t_Distance = (t_Position - r_Pos):length()
					elseif r_Alive < 14 and r_DirGood then
						local charVisible = _cp_isObjectVisible(r_Pos, rocket.dir, char_pos, -0.66)
						local tar_pos, tar_dst, tar_type = PickATarget(rocket, char_pos, charVisible)

						if tar_pos ~= nil then
							t_Position = tar_pos
							t_Distance = tar_dst
							rocket.flar = tar_type
						end
					end
				end
			else
				if r_DirGood then
					local vis_char = getClosestVisiblePlayer(r_Pos, rocket.dir)
					local tar_pos, tar_dst, tar_type = PickATarget(rocket, vis_char, true)

					if tar_pos ~= nil then
						t_Position = tar_pos
						t_Distance = tar_dst
						rocket.flar = tar_type
					end
				end
			end

			if r_Alive < 14.5 and t_Position then
				local new_dir = (t_Position - r_Pos):normalize()
				local dir_norm = rocket.dir:normalize()

				if camera then
					rocket.dir = _vecLerp(dir_norm, new_dir, 0.08):normalize() * rocket.vel
				else
					local hit, result = _physRaycast(r_Pos, r_Pos + (rocket.dir / 1.5))
					local r_Type = result.type

					if hit and r_Type == "terrainAsset" or r_Type == "terrainSurface" or (r_shape_exists and result:getBody() == r_shape.body) then
						local r_Normal = result.normalWorld
						local r_Dot = rocket.dir:dot(r_Normal)
						local r_Vector = rocket.dir - (r_Normal * r_Dot)

						rocket.dir = _vecLerp(dir_norm, r_Vector, 0.01):normalize() * rocket.vel
					else
						rocket.dir = _vecLerp(dir_norm, new_dir, r_Accuracy):normalize() * rocket.vel
					end
				end
			end
			
			if camera and rocket.dir:length() > rocket.vel then
				rocket.vel = rocket.vel * 0.998
			end

			local hit, result = _physRaycast(r_Pos, r_Pos + rocket.dir * dt * 1.2)
			if hit or r_Alive <= 0 or t_Distance < (r_ModeDist[camera or rocket.flar] or 1) or _cpProj_cl_proxFuze(rocket.proxFuze, r_Pos, rocket.ignored_players) then
				rocket.hit = (result.pointWorld ~= _vecZero() and result.pointWorld) or r_Pos
				
				_cpProj_cl_onProjHit(rocket.effect, true)
				_cpProj_killNearestFlares(FlareProjectile.projectiles, rocket.hit, 8)
			else
				rocket.pos = r_Pos + rocket.dir * dt
				UpdateRocketEffect(rocket)
			end
		end
	end
end

function SmartRocket.client_onScriptDestroy(self)
	local deleted_projectiles = _cpProj_cl_destroyProjectiles(self.projectiles)
	SmartRocket.projectiles = {}
	SmartRocket.proj_queue = {}
	_cpPrint(("SmartRocket: Deleted %s projectiles"):format(deleted_projectiles))
end

_CP_gScript.SmartRocket = SmartRocket