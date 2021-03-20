--[[
    Copyright (c) 2021 Cannons Pack Team
    Questionable Mark
]]

if FlareProjectile then return end
FlareProjectile = class(GLOBAL_SCRIPT)

FlareProjectile.projectiles = {}
FlareProjectile.proj_queue = {}

if GLOBAL_SCRIPT.updateScript then GLOBAL_SCRIPT.updateScript("FlareProjectile") end

function FlareProjectile.server_sendProjectile(self, shapeScript, data)
    local lifetime = data.lifetime
    local dir = data.dir
    table.insert(self.proj_queue, {shapeScript.shape, lifetime, dir})
end

function FlareProjectile.client_loadProjectile(self, shapeScript, data)
    local shape, lifetime, dir = unpack(data)
    if shape == nil or not sm.exists(shape) then CP.console_print("FlareProjectile: NO SHAPE") return end
    local pos = shape.worldPosition + shape.worldRotation * sm.vec3.new(0, 0, 0.2)
    eff = sm.effect.createEffect("FlareLauncher - Shell")
    eff:setPosition(pos)
    eff:setVelocity(dir)
    eff:start()
    local FlareProj = {effect = eff, pos = pos, dir = dir, alive = lifetime, grav = 5}
    self.projectiles[#self.projectiles + 1] = FlareProj
end

function FlareProjectile.server_updateProjectile(self, dt)
    for k, data in pairs(self.proj_queue) do
        self:GS_sendToClients("client_loadProjectile", data)
        self.proj_queue[k] = nil
    end
end

function FlareProjectile.client_updateProjectile(self, dt)
    for k, flare in pairs(self.projectiles) do
        if flare and not flare.hit then
            flare.alive = flare.alive-dt
            flare.dir = flare.dir * 0.997 - sm.vec3.new(0, 0, flare.grav * dt)
            local hit, result = sm.physics.raycast(flare.pos, flare.pos + flare.dir * dt * 1.2)
            if hit then
                flare.effect:setVelocity(sm.vec3.zero())
                flare.dir = sm.vec3.zero()
            end
            flare.pos = flare.pos + flare.dir * dt
            flare.effect:setPosition(flare.pos)
            flare.effect:setParameter("intensity", flare.alive > 2 and math.random(100, 130) / 100 + 0.5 or math.random(100, 130) / 100 * ((flare.alive / 2) + 0.5))
        end
        if flare and (flare.hit or flare.alive <= 0) then
            CP_Projectile.client_onProjHit(flare.effect, true)
            self.projectiles[k] = nil
        end
    end
end

function FlareProjectile.client_onDestroy(self)
    local deleted_projectiles = CP_Projectile.client_destroyProjectiles(self.projectiles)
    self.projectiles = {}
    self.proj_queue = {}
    CP.console_print(("FlareProjectile: Deleted %s projectiles"):format(deleted_projectiles))
end