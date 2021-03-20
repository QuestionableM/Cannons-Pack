--[[
    Copyright (c) 2021 Cannons Pack Team
    Questionable Mark
]]

if flare then return end
dofile("Cannons_Pack_libs/ScriptLoader.lua")
flare = class(GLOBAL_SCRIPT)
flare.maxParentCount = 1
flare.maxChildCount = 0
flare.connectionInput = sm.interactable.connectionType.logic
flare.connectionOutput = sm.interactable.connectionType.none
flare.colorNormal = sm.color.new(0x000396ff)
flare.colorHighlight = sm.color.new(0x0004c7ff)
function flare:server_onCreate()
    self:GS_init()
    self.o = {bulPerShot = 6}
    self.projectileConfiguration = CP_Cannons.load_cannon_info(self)
end
function flare:server_onFixedUpdate()
    if not sm.exists(self.interactable) then return end
    local parent = self.interactable:getSingleParent()
    local active = parent and parent.active
    if active and not self.o.reload and self.o.bulPerShot > 0 then
        self.o.reload = CP.shoot(self, (self.o.bulPerShot > 1 and 8) or (self.o.bulPerShot == 1 and 300), "client_net", "sht", sm.vec3.new(0, 0, -250))
        self.o.bulPerShot = self.o.bulPerShot - 1
        self.projectileConfiguration.dir = CP.calculate_spread(self, 10, 25)
        FlareProjectile:server_sendProjectile(self, self.projectileConfiguration)
    end
    if self.o.reload then
        if self.o.reload == 30 and not active then self.network:sendToClients("client_net", "rld") end
        self.o.reload = (self.o.reload > 1 and self.o.reload - 1) or nil
        self.o.bulPerShot = ((self.o.reload == 1 and self.o.bulPerShot == 0) and 6) or self.o.bulPerShot
    end
end
function flare:client_onCreate()
    self.effects = CP_Effects.client_loadEffect(self)
    self:client_injectScript("FlareProjectile")
end
function flare:client_net(data)
    CP.spawn_optimized_effect(self.shape, self.effects[data], 75)
end