--[[
    Copyright (c) 2021 Cannons Pack Team
    Questionable Mark
]]

if SmartRocket then return end
SmartRocket = class(GLOBAL_SCRIPT)

SmartRocket.projectiles = {}
SmartRocket.proj_queue = {}

if GLOBAL_SCRIPT.updateScript then GLOBAL_SCRIPT.updateScript("SmartRocket") end

function SmartRocket.server_sendProjectile(self, shapeScript, data)
    local position = data.position
    local direction = data.direction
    local rocketSettings = data.rocketSettings
    local velocity = data.velocity
    local proxFuze = data.proxFuze or 0
    local ignored_players = CP_Projectile.proximity_fuze_ignore(shapeScript.shape.worldPosition, proxFuze) or {}
    table.insert(self.proj_queue,{shapeScript.shape,position,direction,rocketSettings,velocity,proxFuze,ignored_players})
end

function SmartRocket.client_loadProjectile(self, shapeScript, data)
    local shape, position, direction, rocketSettings, velocity, proxFuze, ignored_players = unpack(data)
    if (shape == nil or not sm.exists(shape)) then print("[CannonsPack] SmartRocket: NO SHAPE") return end
    local effect = sm.effect.createEffect("RocketLauncher - Shell")
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

function SmartRocket.server_updateProjectile(self, dt)
    for k, data in pairs(self.proj_queue) do
        self:GS_sendToClients("client_loadProjectile", data)
        self.proj_queue[k] = nil
    end
    for b, proj in pairs(self.projectiles) do
        if proj and proj.hit then 
            CP_Projectile.better_explosion(proj.hit, 60, 0.7, 7000, 30, "ExplBig", true)
        end
    end
end

local _RVis = math.rad(60)
local function getClosestVisiblePlayer(v1, v1Pred)
    local ClosestPlayer = nil
    local ClosestDistance = math.huge

    for id, player in pairs(sm.player.getAllPlayers()) do
        if player.character then
            local isVisible = CP.isObjectVisible(v1, v1Pred, player.character.worldPosition, _RVis, _RVis)
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
        local player_d = (rocket_pos - player.character.worldPosition):length()
        local flare_d = (rocket_pos - flare):length()
        if player_d > flare_d then
            if (flare - player.character.worldPosition):length() < 10 then return flare, "flare" end
        end
        local t = (player_d > flare_d) and flare or player.character.worldPosition
        local t_type = (player_d > flare_d) and "flare" or "char"
        return t, t_type
    elseif player and playerVisible then
        return player.character.worldPosition, "char"
    elseif flare then
        return flare, "flare"
    end
end

function SmartRocket.client_updateProjectile(self, dt)
    for k, rocket in pairs(self.projectiles) do
        if rocket and rocket.hit then self.projectiles[k] = nil end
        if rocket and not rocket.hit then
            rocket.alive = rocket.alive - dt
            local _Accuracy = 0.1
            local position = rocket.pos + rocket.dir
            local distance = math.huge
            local valid, valid2 = pcall(sm.exists, rocket.shape)
            local camera = rocket.options.mode == "cam" or rocket.options.mode == "dirCam"
            local player_table = sm.player.getAllPlayers()
            if #player_table > 0 then
                for amount, player in pairs(player_table) do
                    if rocket.flar ~= "dead" and CP_Projectile.is_flare_near(FlareProjectile.projectiles, rocket.pos, 10) then rocket.flar = "dead" end
                    if player.character then
                        local pred_pos = rocket.pos + rocket.dir:normalize() * 2
                        if rocket.options.player then
                            if rocket.options.player == player then
                                if not camera then
                                    if rocket.alive < 14.5 and rocket.alive > 14 then
                                        _Accuracy = 0.25
                                        position = player.character.worldPosition
                                        distance = (position - rocket.pos):length()
                                    end
                                    if rocket.alive < 14 and rocket.dir:length() > 0.001 then
                                        local closest_flare = CP_Projectile.get_nearest_visible_flare(FlareProjectile.projectiles, rocket.pos, pred_pos)
                                        local charVisible = CP.isObjectVisible(rocket.pos, pred_pos, player.character.worldPosition, _RVis, _RVis)
                                        local targetPos, targetType = pickATarget(rocket.pos, player, closest_flare, charVisible)
                                        if targetPos and targetType and ((targetType == "char" and rocket.flar ~= "dead") or targetType ~= "char") then
                                            position = targetPos
                                            distance = (position - rocket.pos):length()
                                            rocket.flar = targetType
                                        end
                                    end
                                else
                                    local bool, cam = sm.physics.raycast(player.character.worldPosition + sm.vec3.new(0, 0, player.character:isCrouching() and 0.277 or 0.569) + player.character.direction, player.character.worldPosition + player.character.direction * 2500)
                                    if rocket.options.mode ~= "dirCam" then
                                        if ((valid and valid2) and cam:getBody() ~= rocket.shape.body) and cam:getCharacter() ~= player.id then
                                            position = cam.pointWorld
                                            distance = (position - rocket.pos):length()
                                        end
                                    else
                                        if valid and valid2 then
                                            position = cam.directionWorld * 20
                                        end
                                    end
                                end
                            end
                        else
                            if rocket.dir:length() > 0.001 then
                                local cl_vis_char = getClosestVisiblePlayer(rocket.pos, pred_pos)
                                local closest_flare = CP_Projectile.get_nearest_visible_flare(FlareProjectile.projectiles, rocket.pos, pred_pos)
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
                    local closest_flare = CP_Projectile.get_nearest_visible_flare(FlareProjectile.projectiles, rocket.pos, rocket.pos + rocket.dir:normalize() * 2)
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
                    local hit1, result1 = sm.physics.raycast(rocket.pos, rocket.pos + (rocket.dir / 1.5))
                    if hit1 and result1.type == "terrainAsset" or result1.type == "terrainSurface" or ((valid and valid2) and result1.type == "body" and result1:getBody() == rocket.shape.body) then
                        local _normal = result1.normalWorld
                        local _dotP = rocket.dir:dot(_normal)
                        local reflected_vector = rocket.dir - (_normal * _dotP)
                        rocket.dir = sm.vec3.lerp(_DirNorm, reflected_vector, 0.01):normalize() * rocket.vel
                    else
                        rocket.dir = sm.vec3.lerp(_DirNorm, _NewDir, _Accuracy):normalize() * rocket.vel
                    end
                else
                    rocket.dir = sm.vec3.lerp(_DirNorm, _NewDir, 0.08):normalize() * rocket.vel
                end
            end
            if rocket.dir:length() > rocket.vel and camera then
                rocket.vel = rocket.vel * 0.998
            end
            if rocket.dir:length() > 0.0001 then
                local _RocketDir = sm.vec3.getRotation(sm.vec3.new(1, 0, 0), rocket.dir)
                local _RotSpeed = (sm.game.getCurrentTick() * 5) % 360
                local _RocketRot = sm.quat.angleAxis(math.rad(_RotSpeed), sm.vec3.new(1, 0, 0))
                rocket.effect:setRotation(_RocketDir * _RocketRot)
            end
            local hit, result = sm.physics.raycast(rocket.pos, rocket.pos + rocket.dir * dt * 1.2)
            if hit or rocket.alive <= 0 or (rocket.flar == "char" and distance < 1) or (rocket.flar == "flare" and distance < 8) or (camera and distance < 1) or CP_Projectile.client_proximity_fuze(rocket.proxFuze, rocket.pos, rocket.ignored_players) then
                rocket.hit = (result.pointWorld ~= sm.vec3.zero() and result.pointWorld) or rocket.pos
                
                CP_Projectile.client_onProjHit(rocket.effect, true)
                CP_Projectile.kill_nearest_flares(FlareProjectile.projectiles, rocket.pos, 8)
            end
            rocket.pos = rocket.pos + rocket.dir * dt
            rocket.effect:setPosition(rocket.pos)
            rocket.effect:setParameter("intensity", math.random(150, 230) / 100)
            rocket.effect:setParameter("velocity", rocket.dir:length())
        end
    end
end

function SmartRocket.client_onDestroy(self)
    local deleted_projectiles = CP_Projectile.client_destroyProjectiles(self.projectiles)
    self.projectiles = {}
    self.proj_queue = {}
    CP.console_print(("SmartRocket: Deleted %s projectiles"):format(deleted_projectiles))
end