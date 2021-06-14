--[[
	Copyright (c) 2021 Cannons Pack Team
	Questionable Mark
]]

if SmartRocket then return end
SmartRocket = class(GLOBAL_SCRIPT)
SmartRocket.projectiles = {}
SmartRocket.proj_queue = {}

function SmartRocket.server_sendProjectile(self, shapeScript, data)
	local position = data.position
	local direction = data.direction
	local rocketSettings = data.rocketSettings
	local velocity = data.velocity
	local proxFuze = data.proxFuze or 0
	local ignored_players = _cpProj_proxFuzeIgnore(shapeScript.shape.worldPosition, proxFuze)

	_tableInsert(self.proj_queue,{shapeScript.shape,position,direction,rocketSettings,velocity,proxFuze,ignored_players})
end

function SmartRocket.client_loadProjectile(self, data)
	local shape, position, direction, rocketSettings, velocity, proxFuze, ignored_players = unpack(data)

	if not _cpExists(shape) then
		_cpPrint("SmartRocket: NO SHAPE")
		return
	end

	local effect = _createEffect("RocketLauncher - Shell")
	effect:setPosition(position)
	effect:start()

	local rocket = {
		effect = effect,
		pos = position,
		dir = direction,
		alive = 15,
		options = rocketSettings,
		vel = velocity,
		shape = shape,
		proxFuze = proxFuze,
		ignored_players = ignored_players,
		flar = nil
	}
	self.projectiles[#self.projectiles + 1] = rocket
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

local _RVis = _mathRad(60)
local function getClosestVisiblePlayer(v1, v1Pred)
	local ClosestPlayer = nil
	local ClosestDistance = math.huge

	for id, player in pairs(_getAllPlayers()) do
		if player.character then
			local isVisible = _cp_isObjectVisible(v1, v1Pred, player.character.worldPosition, _RVis, _RVis)
			local distance = (v1 - player.character.worldPosition):length()
			if isVisible and distance < ClosestDistance then
				ClosestPlayer = player
				ClosestDistance = distance
			end
		end
	end
	return ClosestPlayer
end

local function pickATarget(rocket_pos, player, flare, playerVisible)
	if (player and playerVisible) and flare then
		local char_pos = player.character.worldPosition

		local player_d = (rocket_pos - char_pos):length()
		local flare_d = (rocket_pos - flare):length()
		if player_d > flare_d then
			if (flare - char_pos):length() < 10 then return flare, "flare" end
		end

		local t = (player_d > flare_d) and flare or char_pos
		local t_type = (player_d > flare_d) and "flare" or "char"

		return t, t_type
	elseif player and playerVisible then
		return player.character.worldPosition, "char"
	elseif flare then
		return flare, "flare"
	end
end

local _xAxis = _newVec(1, 0, 0)
function SmartRocket.client_onScriptUpdate(self, dt)
	for k, rocket in pairs(self.projectiles) do
		if rocket and rocket.hit then self.projectiles[k] = nil end
		if rocket and not rocket.hit then
			rocket.alive = rocket.alive - dt
			local _Accuracy = 0.1
			local position = rocket.pos + rocket.dir
			local distance = math.huge
			local r_shape_exists = _cpExists(rocket.shape)
			local r_options = rocket.options
			local camera = r_options.mode == "cam" or r_options.mode == "dirCam"

			local player_table = _getAllPlayers()
			if #player_table > 0 then
				for amount, player in pairs(player_table) do
					if rocket.flar ~= "dead" and _cpProj_isFlareNear(FlareProjectile.projectiles, rocket.pos, 10) then
						rocket.flar = "dead"
					end

					local pl_char = player.character
					if pl_char then
						local pred_pos = rocket.pos + rocket.dir:normalize() * 2
						local char_pos = pl_char.worldPosition
						local opt_player = r_options.player

						if opt_player then
							if opt_player == player then
								if not camera then
									if rocket.alive < 14.5 and rocket.alive > 14 then
										_Accuracy = 0.25
										position = char_pos
										distance = (position - rocket.pos):length()
									end

									if rocket.alive < 14 and rocket.dir:length() > 0.001 then
										local closest_flare = _cpProj_getNearestVisibleFlare(FlareProjectile.projectiles, rocket.pos, pred_pos)
										local charVisible = _cp_isObjectVisible(rocket.pos, pred_pos, char_pos, _RVis, _RVis)
										local targetPos, targetType = pickATarget(rocket.pos, player, closest_flare, charVisible)

										if targetPos and targetType and ((targetType == "char" and rocket.flar ~= "dead") or targetType ~= "char") then
											position = targetPos
											distance = (position - rocket.pos):length()
											rocket.flar = targetType
										end
									end
								else
									local cam_offset = _newVec(0, 0, pl_char:isCrouching() and 0.277 or 0.569)
									local char_dir = pl_char.direction

									local bool, cam = _physRaycast(char_pos + cam_offset + char_dir, char_pos + char_dir * 2500)
									if r_options.mode ~= "dirCam" then
										if (r_shape_exists and cam:getBody() ~= rocket.shape.body) and cam:getCharacter() ~= player.id then
											position = cam.pointWorld
											distance = (position - rocket.pos):length()
										end
									else
										if r_shape_exists then
											position = cam.directionWorld * 20
										end
									end
								end
							end
						else
							if rocket.dir:length() > 0.001 then
								local cl_vis_char = getClosestVisiblePlayer(rocket.pos, pred_pos)
								local closest_flare = _cpProj_getNearestVisibleFlare(FlareProjectile.projectiles, rocket.pos, pred_pos)
								local t_pos, t_type = pickATarget(rocket.pos, cl_vis_char, closest_flare, true)
								if t_pos and t_type and ((t_type == "char" and rocket.flar ~= "dead") or t_type) then
									position = t_pos
									distance = (position - rocket.pos):length()
									rocket.flar = t_type
								end
							end
						end
					end
				end
			else
				if rocket.dir:length() > 0.001 then
					local closest_flare = _cpProj_getNearestVisibleFlare(FlareProjectile.projectiles, rocket.pos, rocket.pos + rocket.dir:normalize() * 2)
					if closest_flare then
						position = closest_flare
						distance = (position - rocket.pos):length()
					end
				end
			end

			if rocket.alive < 14.5 and position then
				local _NewDir = (position - rocket.pos):normalize()
				local _DirNorm = rocket.dir:normalize()
				if not camera then
					local hit1, result1 = _physRaycast(rocket.pos, rocket.pos + (rocket.dir / 1.5))
					if hit1 and result1.type == "terrainAsset" or result1.type == "terrainSurface" or (r_shape_exists and result1.type == "body" and result1:getBody() == rocket.shape.body) then
						local _normal = result1.normalWorld
						local _dotP = rocket.dir:dot(_normal)
						local reflected_vector = rocket.dir - (_normal * _dotP)

						rocket.dir = _vecLerp(_DirNorm, reflected_vector, 0.01):normalize() * rocket.vel
					else
						rocket.dir = _vecLerp(_DirNorm, _NewDir, _Accuracy):normalize() * rocket.vel
					end
				else
					rocket.dir = _vecLerp(_DirNorm, _NewDir, 0.08):normalize() * rocket.vel
				end
			end
			
			if rocket.dir:length() > rocket.vel and camera then
				rocket.vel = rocket.vel * 0.998
			end
			
			if rocket.dir:length() > 0.0001 then
				local _RocketDir = _getVec3Rotation(_xAxis, rocket.dir)
				local _RotSpeed = (_getCurrentTick() * 5) % 360
				local _RocketRot = _quatAngleAxis(_mathRad(_RotSpeed), _xAxis)

				rocket.effect:setRotation(_RocketDir * _RocketRot)
			end

			local hit, result = _physRaycast(rocket.pos, rocket.pos + rocket.dir * dt * 1.2)
			if hit or rocket.alive <= 0 or (rocket.flar == "char" and distance < 1) or (rocket.flar == "flare" and distance < 8) or (camera and distance < 1) or _cpProj_cl_proxFuze(rocket.proxFuze, rocket.pos, rocket.ignored_players) then
				rocket.hit = (result.pointWorld ~= _vecZero() and result.pointWorld) or rocket.pos
				
				_cpProj_cl_onProjHit(rocket.effect, true)
				_cpProj_killNearestFlares(FlareProjectile.projectiles, rocket.pos, 8)
			end

			rocket.pos = rocket.pos + rocket.dir * dt
			rocket.effect:setPosition(rocket.pos)
			rocket.effect:setParameter("intensity", _mathRandom(150, 230) / 100)
			rocket.effect:setParameter("velocity", rocket.dir:length())
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