--[[
    Copyright (c) 2021 Cannons Pack Team
    Questionable Mark
]]

if EMPProjectile then return end
EMPProjectile = class(GLOBAL_SCRIPT)
EMPProjectile.projectiles = {}
EMPProjectile.proj_queue = {}

function EMPProjectile.client_loadProjectile(self, shapeScript, data)
    local shape,position,velocity,disconnectRadius = unpack(data)
    if shape == nil or not sm.exists(shape) then CP.print("EMPProjectile: NO SHAPE") return end
    local realPos = shape.worldPosition + shape.worldRotation * position
    local eff = sm.effect.createEffect("EMPCannon - Shell")
    eff:setPosition(realPos)
    eff:start()
    local EMPProj = {effect = eff, pos = realPos, dir = velocity, alive = 10, disconnectRadius = disconnectRadius}
    self.projectiles[#self.projectiles + 1] = EMPProj
end

function EMPProjectile.server_sendProjectile(self, shapeScript, data)
    local position = data.position
    local velocity = data.velocity
    local disconnectRadius = data.disconnectRadius
    table.insert(self.proj_queue, {shapeScript.shape, position, velocity, disconnectRadius})
end

function EMPProjectile.server_updateProjectile(self, dt)
    for b, data in pairs(self.proj_queue) do
        self:GS_sendToClients("client_loadProjectile", data)
        self.proj_queue[b] = nil
    end
    for k,EMPProjectile in pairs(self.projectiles) do
        if EMPProjectile and EMPProjectile.hit then
            for k, shape in pairs(sm.shape.shapesInSphere(EMPProjectile.hit, EMPProjectile.disconnectRadius)) do
                if CP.exists(shape) and shape:getInteractable() then
                    local s_interactable = shape:getInteractable()
                    for k, parent in pairs(s_interactable:getParents()) do
                        parent:disconnect(s_interactable)
                    end
                end
            end
            sm.effect.playEffect("EMPCannon - Explosion", EMPProjectile.hit)
        end
    end
end

function EMPProjectile.client_updateProjectile(self, dt)
    for k,EMPProj in pairs(self.projectiles) do
        if EMPProj and EMPProj.hit then self.projectiles[k] = nil end
        if EMPProj and not EMPProj.hit then
            EMPProj.alive = EMPProj.alive - dt
            local hit,result = sm.physics.raycast(EMPProj.pos, EMPProj.pos + EMPProj.dir * dt * 1.2)
            if hit or EMPProj.alive <= 0 then
                EMPProj.hit = (result.pointWorld ~= sm.vec3.zero() and result.pointWorld) or EMPProj.pos
                CP_Projectile.client_onProjHit(EMPProj.effect)
            end
            EMPProj.pos = EMPProj.pos + EMPProj.dir * dt
            if EMPProj.dir:length() > 0.0001 then
                EMPProj.effect:setRotation(sm.vec3.getRotation(sm.vec3.new(1, 0, 0), EMPProj.dir))
            end
            EMPProj.effect:setPosition(EMPProj.pos)
        end
    end
end

function EMPProjectile.client_onDestroy(self)
    local deleted_projectiles = CP_Projectile.client_destroyProjectiles(self.projectiles)
    self.projectiles = {}
    self.proj_queue = {}
    CP.print(("EMPProjectile: Deleted %s projectiles"):format(deleted_projectiles))
end

CP.g_script.EMPProjectile = EMPProjectile
if GLOBAL_SCRIPT.updateScript then GLOBAL_SCRIPT.updateScript("EMPProjectile") end