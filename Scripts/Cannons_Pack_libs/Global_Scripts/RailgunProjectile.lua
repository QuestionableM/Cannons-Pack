--[[
    Copyright (c) 2021 Cannons Pack Team
    Questionable Mark
]]

if RailgunProjectile then return end
RailgunProjectile = class(GLOBAL_SCRIPT)
RailgunProjectile.projectiles = {}
RailgunProjectile.proj_queue = {}

function RailgunProjectile.server_sendProjectile(self, shapeScript, data)
    local position = data.position
    local velocity = data.velocity
    local shellEffect = data.shellEffect
    local explosionEffect = data.explosionEffect or "PropaneTank - ExplosionBig"
    local explosionLevel = data.explosionLevel or 5
    local explosionRadius = data.explosionRadius or 0.5
    local explosionImpulseRadius = data.explosionImpulseRadius or 10
    local explosionImpulseStrength = data.explosionImpulseStrength or 50
    local count = data.count
    local effectToGive = data.shellEffect
    table.insert(self.proj_queue, {position, velocity, shellEffect, explosionEffect, explosionLevel, explosionRadius, explosionImpulseRadius, explosionImpulseStrength, count, effectToGive})
end

function RailgunProjectile.client_loadProjectile(self, shapeScript, data)
    local position,velocity,shellEffect,explosionEffect,explosionLevel,explosionRadius,explosionImpulseRadius,explosionImpulseStrength,count,effectToGive=unpack(data)
    local success,shellEffect = pcall(sm.effect.createEffect,shellEffect)
    if not success then sm.log.error(shellEffect) return end
    shellEffect:setPosition(position)
    shellEffect:start()
    local RlgProj = {
        effect = shellEffect,
        pos = position,
        dir = velocity,
        alive = 10,
        count = count,
        effTG = effectToGive,
        explosionLevel = explosionLevel,
        explosionRadius = explosionRadius,
        explosionImpulseRadius = explosionImpulseRadius,
        explosionImpulseStrength = explosionImpulseStrength,
        explosionEffect = explosionEffect
    }
    self.projectiles[#self.projectiles + 1] = RlgProj
end

function RailgunProjectile.server_updateProjectile(self, dt, network)
    for b, data in pairs(self.proj_queue) do
        self:GS_sendToClients("client_loadProjectile", data)
        self.proj_queue[b] = nil
    end
    for k, RlgProj in pairs(self.projectiles) do
        if RlgProj and RlgProj.hit then
            CP_Projectile.better_explosion(RlgProj.hit.result, RlgProj.explosionLevel, RlgProj.explosionRadius, RlgProj.explosionImpulseStrength, RlgProj.explosionImpulseRadius, RlgProj.explosionEffect, true)
            if RlgProj.count > 0 and RlgProj.hit.type ~= "invalid" and RlgProj.hit.type ~= "terrainAsset" and RlgProj.hit.type ~= "terrainSurface" then
                local proj = {
                    position = RlgProj.hit.result,
                    velocity = RlgProj.dir,
                    shellEffect = RlgProj.effTG,
                    explosionEffect = RlgProj.explosionEffect,
                    explosionLevel = RlgProj.explosionLevel,
                    explosionRadius = RlgProj.explosionRadius-0.2,
                    explosionImpulseRadius = RlgProj.explosionImpulseRadius-10,
                    explosionImpulseStrength = RlgProj.explosionImpulseStrength-1000,
                    count = RlgProj.count - 1,
                    effectToGive = RlgProj.effTG
                }
                self:GS_sendToClients("client_loadProjectile",{proj.position,proj.velocity,proj.shellEffect,proj.explosionEffect,proj.explosionLevel,proj.explosionRadius,proj.explosionImpulseRadius,proj.explosionImpulseStrength,proj.count,proj.effectToGive})
            end
        end
    end
end

function RailgunProjectile.client_updateProjectile(self, dt)
    for k, RlgProj in pairs(self.projectiles) do
        if RlgProj and RlgProj.hit then self.projectiles[k] = nil end
        if RlgProj and not RlgProj.hit then
            RlgProj.alive = RlgProj.alive - dt
            local hit, result = sm.physics.raycast(RlgProj.pos, RlgProj.pos + RlgProj.dir * dt * 1.2)
            if hit or RlgProj.alive <= 0 then 
                RlgProj.hit = {result = (result.pointWorld ~= sm.vec3.zero() and result.pointWorld) or RlgProj.pos, type = result.type}
                CP_Projectile.client_onProjHit(RlgProj.effect)
            end
            RlgProj.pos = RlgProj.pos + RlgProj.dir * dt
            if RlgProj.dir:length() > 0.0001 then
                RlgProj.effect:setRotation(sm.vec3.getRotation(sm.vec3.new(1, 0, 0), RlgProj.dir))
            end
            RlgProj.effect:setPosition(RlgProj.pos)
        end
    end
end

function RailgunProjectile.client_onDestroy(self)
    local deleted_projectiles = CP_Projectile.client_destroyProjectiles(self.projectiles)
    self.projectiles = {}
    self.proj_queue = {}
    CP.print(("RailgunProjectile: Deleted %s projectiles"):format(deleted_projectiles))
end

CP.g_script.RailgunProjectile = RailgunProjectile
if GLOBAL_SCRIPT.updateScript then GLOBAL_SCRIPT.updateScript("RailgunProjectile") end