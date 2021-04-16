--[[
    Copyright (c) 2021 Cannons Pack Team
    Questionable Mark
]]

if CPProjectile then return end
CPProjectile = class(GLOBAL_SCRIPT)
CPProjectile.projectiles = {}
CPProjectile.proj_queue = {}

function CPProjectile.server_sendProjectile(self, shapeScript, data)
    local localPosition = data.localPosition or false
    local localVelocity = data.localVelocity or false
    local syncEffect = data.syncEffect or false
    local position = data.position or sm.vec3.new(0, 0, 0)
    local velocity = data.velocity or sm.noise.gunSpread(shapeScript.shape.up, 0) * 50
    local rotationAxis = data.rotationAxis or sm.vec3.new(1, 0, 0)
    local friction = data.friction or 0.003
    local gravity = data.gravity or 10
    local shellEffect = data.shellEffect
    local explosionEffect = data.explosionEffect or "PropaneTank - ExplosionBig"
    local lifetime = data.lifetime or 30
    local explosionLevel = data.explosionLevel or 5
    local explosionRadius = data.explosionRadius or 0.5
    local explosionImpulseRadius = data.explosionImpulseRadius or 10
    local explosionImpulseStrength = data.explosionImpulseStrength or 50
    local proxFuze = data.proxFuze or 0
    local ignored_players = CP_Projectile.proximity_fuze_ignore(shapeScript.shape.worldPosition, proxFuze) or {}
    local keep_effect = data.keep_effect
    table.insert(self.proj_queue,{shapeScript.shape,localPosition,localVelocity,syncEffect,position,velocity,rotationAxis,friction,gravity,shellEffect,explosionEffect,lifetime,explosionLevel,explosionRadius,explosionImpulseRadius,explosionImpulseStrength,proxFuze,ignored_players,keep_effect})
end

function CPProjectile.client_loadProjectile(self, data)
    local shape,localPosition,localVelocity,syncEffect,position,velocity,rotationAxis,friction,gravity,shellEffect,explosionEffect,lifetime,explosionLevel,explosionRadius,explosionImpulseRadius,explosionImpulseStrength,proxFuze,ignored_players,keep_effect=unpack(data)
    if (localPosition or localVelocity) and (shape == nil or not sm.exists(shape)) then CP.print("CPProjectile: NO SHAPE") return end
    if localVelocity then velocity = shape.worldRotation * velocity end
    if localPosition then position = shape.worldPosition + shape.worldRotation * position end
    local success, shellEffect = pcall(sm.effect.createEffect, shellEffect)
    if not success then sm.log.error(shellEffect) return end
    shellEffect:setPosition(position)
    shellEffect:start()
    local CPProj = {
        effect = shellEffect,
        pos = position,
        dir = velocity,
        alive = lifetime,
        grav = gravity,
        explosionLevel = explosionLevel,
        explosionRadius = explosionRadius,
        explosionImpulseRadius = explosionImpulseRadius,
        explosionImpulseStrength = explosionImpulseStrength,
        explosionEffect = explosionEffect,
        friction = friction,
        rotationAxis = rotationAxis,
        proxFuze = proxFuze,
        ignored_players = ignored_players,
        syncEffect = syncEffect,
        keep_effect = keep_effect
    }
    self.projectiles[#self.projectiles + 1] = CPProj
end

function CPProjectile.server_onScriptUpdate(self, dt)
    for b, data in pairs(self.proj_queue) do
        self.network:sendToClients("client_loadProjectile", data)
        self.proj_queue[b] = nil
    end
    for k,CPProj in pairs(self.projectiles) do
        if CPProj and CPProj.hit then 
            CP_Projectile.better_explosion(CPProj.hit, CPProj.explosionLevel, CPProj.explosionRadius, CPProj.explosionImpulseStrength, CPProj.explosionImpulseRadius, CPProj.explosionEffect, true)
        end
    end
end

local _PhysicsRaycast = sm.physics.raycast
local _Vec3Zero = sm.vec3.zero
local _ProxFuze = CP_Projectile.client_proximity_fuze
local _Vec3GetRotation = sm.vec3.getRotation

function CPProjectile.client_onScriptUpdate(self, dt)
    for k, CPProj in pairs(self.projectiles) do
        if CPProj and CPProj.hit then self.projectiles[k] = nil end
        if CPProj and not CPProj.hit then
            CPProj.alive = CPProj.alive - dt
            CPProj.dir = CPProj.dir * (1 - CPProj.friction) - sm.vec3.new(0, 0, CPProj.grav * dt)
            local hit, result = _PhysicsRaycast(CPProj.pos, CPProj.pos + CPProj.dir * dt * 1.2)
            if hit or CPProj.alive <= 0 or _ProxFuze(CPProj.proxFuze, CPProj.pos, CPProj.ignored_players) then
                CPProj.hit = (result.pointWorld ~= _Vec3Zero() and result.pointWorld) or CPProj.pos
                CP_Projectile.client_onProjHit(CPProj.effect, CPProj.keep_effect)
            end
            if CPProj.syncEffect then CPProj.effect:setPosition(CPProj.pos) end
            CPProj.pos = CPProj.pos + CPProj.dir * dt
            if CPProj.dir:length() > 0.0001 then
                CPProj.effect:setRotation(_Vec3GetRotation(CPProj.rotationAxis, CPProj.dir))
            end
        end
    end
end

function CPProjectile.client_onScriptDestroy(self)
    local deleted_projectiles = CP_Projectile.client_destroyProjectiles(self.projectiles)
    CPProjectile.projectiles = {}
    CPProjectile.proj_queue = {}
    CP.print(("CPProjectile: Deleted %s projectiles"):format(deleted_projectiles))
end

CP.g_script.CPProjectile = CPProjectile