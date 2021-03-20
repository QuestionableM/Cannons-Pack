--[[
    Copyright (c) 2021 Cannons Pack Team
    Questionable Mark
]]

if BulletShell then return end
BulletShell = class(GLOBAL_SCRIPT)
BulletShell.projectiles = {}
BulletShell.proj_queue = {}

if GLOBAL_SCRIPT.updateScript then GLOBAL_SCRIPT.updateScript("BulletShell") end

function BulletShell.server_sendProjectile(self, shapeScript, data)
    local position = data.position or sm.vec3.new(0, 0, 0)
    local velocity = data.velocity or sm.vec3.new(0, 0, 1)
    local friction = data.friction or 0.003
    local gravity = data.gravity or 10
    local lifetime = data.lifetime or 8
    local shellEffect = data.shellEffect or "AircraftCannon - Case"
    local collision_size = data.collision_size or 2
    table.insert(self.proj_queue, {shapeScript.shape, position, velocity, friction, gravity, lifetime, shellEffect, collision_size})
end

function BulletShell.client_loadProjectile(self, shapeScript, data)
    local shape, position, velocity, friction, gravity, lifetime, shellEffect, collision_size = unpack(data)
    if (shape == nil or not sm.exists(shape)) then CP.console_print("BulletShell: NO SHAPE") return end
    local success, effect = pcall(sm.effect.createEffect, shellEffect)
    if not success then sm.log.error("[CannonsPack] ERROR:\n"..effect) return end
    local offset_position = shape.worldPosition + shape.worldRotation * position
    local vel_length = velocity:length() * 100
    local random_velocity = math.random(vel_length - 500, vel_length + 500) / 100
    local angle = sm.noise.gunSpread(shape.at, 60) * random_velocity

    effect:setPosition(offset_position)
    effect:setRotation(shape.worldRotation)
    effect:start()
    
    local shell = {
        effect = effect,
        pos = offset_position,
        dir = angle + shape.velocity,
        alive = math.random(lifetime - 2, lifetime),
        gravity = gravity,
        friction = friction,
        no_col = 0.5,
        counter = 0,
        col_size = collision_size
    }
    self.projectiles[#self.projectiles + 1] = shell
end

function BulletShell.server_updateProjectile(self, dt)
    for b, data in pairs(self.proj_queue) do
        self:GS_sendToClients("client_loadProjectile", data)
        self.proj_queue[b] = nil
    end
end

function BulletShell.client_updateProjectile(self, dt)
    for id, shell in pairs(self.projectiles) do
        if shell and shell.alive > 0 then
            shell.alive = shell.alive - dt
            shell.dir = shell.dir * (1 - shell.friction) - sm.vec3.new(0, 0, shell.gravity * dt)
            local dir_length = math.min(math.max(shell.dir:length() / 3, 0.7) - 0.7, 0.7)
            shell.counter = (shell.counter + (dir_length / (shell.col_size - 1))) % math.pi
            local hit, result = sm.physics.raycast(shell.pos, shell.pos + (shell.dir * shell.col_size) * dt * 1.2)
            if hit then
                local velocity = sm.vec3.zero()
                local reflected_vector = sm.vec3.zero()
                if shell.alive > shell.no_col then
                    if dir_length > 0 then
                        if dir_length > 0.5 and (sm.camera.getPosition() - result.pointWorld):length() < 50 then
                            local _EffectRotation = sm.vec3.getRotation(sm.vec3.new(0, 0, 1), result.normalWorld)
                            local _EffMaterial = (result.type == "body" and result:getShape():getMaterialId()) or 1
                            local _Mass = (result.type == "body" and result:getShape():getMass()) or 0.01
                            sm.effect.playEffect("Collision - Impact", result.pointWorld, sm.vec3.zero(), _EffectRotation, sm.vec3.zero(), {
                                Size = _Mass / 1024,
                                Velocity_max_50 = dir_length * 3.5 * shell.col_size,
                                Material = _EffMaterial,
                                Phys_energy = 1.0 * shell.col_size
                            })
                        end
                        local normal = result.normalWorld
                        local dot_product = shell.dir:dot(normal)
                        local bounciness = 1.3
                        reflected_vector = (shell.dir * 0.7) - (normal * dot_product * bounciness)
                    end
                    if result.type == "body" then velocity = result:getShape().velocity end
                    shell.dir = reflected_vector + velocity
                end
            else
                if dir_length > 0 then
                    local _RotDir = sm.vec3.getRotation(sm.vec3.new(1, 0, 0), shell.dir)
                    local _ZRot = sm.quat.angleAxis(shell.counter, sm.vec3.new(0, 0, 1))

                    local _FinalRot = _RotDir * _ZRot
                    shell.effect:setRotation(_FinalRot)
                end
            end
            shell.pos = shell.pos + shell.dir * dt
            shell.effect:setPosition(shell.pos)
        else
            shell.effect:setPosition(sm.vec3.new(0, 0, 10000))
            shell.effect:stop()
            shell.effect:destroy()
            sm.particle.createParticle("hammer_metal", shell.pos)
            self.projectiles[id] = nil
        end
    end
end

function BulletShell.client_onDestroy(self)
    local deleted_projectiles = CP_Projectile.client_destroyProjectiles(self.projectiles)
    self.projectiles = {}
    self.proj_queue = {}
    CP.console_print(("BulletShell: Deleted %s shells"):format(deleted_projectiles))
end