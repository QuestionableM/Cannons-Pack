--[[
    Copyright (c) 2021 Cannons Pack Team
    Questionable Mark
]]

if LaserProjectile then return end
LaserProjectile = class(GLOBAL_SCRIPT)
LaserProjectile.projectiles = {}
LaserProjectile.proj_queue = {}

function LaserProjectile.server_sendProjectile(self, shapeScript, data)
    local position = data.position or sm.vec3.zero()
    local velocity = data.velocity or sm.vec3.new(0, 0, 1)
    local shellEffect = data.shellEffect
    local lifetime = data.lifetime or 30

    table.insert(self.proj_queue, {shapeScript.shape,position,velocity,shellEffect,lifetime})
end

function LaserProjectile.client_loadProjectile(self, shapeScript, data)
    local shape, position, velocity, shellEffect, lifetime = unpack(data)
    if (shape == nil or not sm.exists(shape)) then CP.print("LaserProjectile: NO SHAPE") return end
    position = shape.worldPosition + shape.worldRotation * position
    local success, shellEffect = pcall(sm.effect.createEffect, shellEffect)
    if not success then sm.log.error(shellEffect) return end
    shellEffect:setPosition(position)
    shellEffect:start()
    local laser_proj = {
        effect = shellEffect,
        pos = position,
        dir = velocity,
        alive = lifetime
    }
    self.projectiles[#self.projectiles + 1] = laser_proj
end

function LaserProjectile.server_updateProjectile(self, dt)
    for b, data in pairs(self.proj_queue) do
        self:GS_sendToClients("client_loadProjectile", data)
        self.proj_queue[b] = nil
    end
    for k, proj in pairs(self.projectiles) do
        if proj and proj.hit then
            local _RayRes = proj.hit
            if _RayRes.valid then
                local _Shape = nil
                local _HitPos = _RayRes.pointWorld

                if _RayRes.type == "body" then
                    _Shape = _RayRes:getShape()
                elseif _RayRes.type == "joint" then
                    local _Joint = _RayRes:getJoint()
                    if CP.exists(_Joint) then _Shape = _Joint:getShapeA() end
                end

                if CP.exists(_Shape) then
                    if sm.item.isBlock(_Shape:getShapeUuid()) then
                        local _BlockPos = _Shape:getClosestBlockLocalPosition(_HitPos)
                        _Shape:destroyBlock(_BlockPos, sm.vec3.new(1, 1, 1), 0)
                    else
                        _Shape:destroyShape(0)
                    end
                end

                local _EffectRotation = sm.quat.identity()
                if _RayRes.normalWorld:length() > 0.0001 then
                    _EffectRotation = sm.vec3.getRotation(sm.vec3.new(0, 0, 1), _RayRes.normalWorld)
                end
                sm.effect.playEffect("LaserCannon - Explosion", _HitPos, sm.vec3.zero(), _EffectRotation)
            else
                sm.effect.playEffect("LaserCannon - Explosion2", _RayRes.originWorld)
            end
        end
    end
end

function LaserProjectile.client_updateProjectile(self, dt)
    for k, proj in pairs(self.projectiles) do
        if proj and proj.hit then self.projectiles[k] = nil end
        if proj and not proj.hit then
            proj.alive = proj.alive - dt
            local r_hit, result = sm.physics.raycast(proj.pos, proj.pos + proj.dir * dt * 1.2)
            if r_hit or proj.alive <= 0 then
                proj.hit = result
                CP_Projectile.client_onProjHit(proj.effect)
            end
            proj.effect:setPosition(proj.pos)
            proj.pos = proj.pos + proj.dir * dt
            if proj.dir:length() > 0.0001 then
                proj.effect:setRotation(sm.vec3.getRotation(sm.vec3.new(1, 0, 0), proj.dir))
            end
        end
    end
end

function LaserProjectile.client_onDestroy(self)
    local deleted_projectiles = CP_Projectile.client_destroyProjectiles(self.projectiles)
    self.projectiles = {}
    self.proj_queue = {}
    CP.print(("LaserProjectile: Deleted %s projectiles"):format(deleted_projectiles))
end

CP.g_script.LaserProjectile = LaserProjectile
if GLOBAL_SCRIPT.updateScript then GLOBAL_SCRIPT.updateScript("LaserProjectile") end