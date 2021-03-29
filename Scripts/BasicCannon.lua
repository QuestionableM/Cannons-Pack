--[[
    Copyright (c) 2021 Cannons Pack Team
    Questionable Mark
]]

if BasicCannon then return end
dofile("Cannons_Pack_libs/ScriptLoader.lua")
BasicCannon = class(GLOBAL_SCRIPT)
BasicCannon.maxParentCount = 1
BasicCannon.maxChildCount = 1
BasicCannon.connectionInput = sm.interactable.connectionType.logic
BasicCannon.connectionOutput = sm.interactable.connectionType.logic
BasicCannon.colorNormal = sm.color.new(0xc75600ff)
BasicCannon.colorHighlight = sm.color.new(0xff6e00ff)
function BasicCannon:client_onCreate()
    self.client_settings = CP_Cannons.client_load_CannonInfo(self)
    self.effects = CP_Effects.client_loadEffect(self)
    self:client_injectScript(self.client_settings.t_script)
end
function BasicCannon:server_onCreate()
    self:GS_init()
    local settings = CP_Cannons.server_load_CannonInfo(self)
    self.projectileConfig = settings.proj_config
    self.settings = settings.cannon_config
    self.settings.t_script = settings.t_script
end
function BasicCannon:server_onFixedUpdate()
    if not sm.exists(self.interactable) then return end
    local parent = self.interactable:getSingleParent()
    local active = parent and parent.active

    local child = self.interactable:getChildren()[1]
    if child and tostring(child.shape.uuid) ~= self.settings.port_uuid then self.interactable:disconnect(child) end

    if active and not self.reload then
        self.reload = CP.Shoot(self, self.settings.reload, "client_shoot", "sht", self.settings.impulse_dir, self.settings.impulse_str)
        self.projectileConfig.velocity = CP.calculate_spread(self, self.settings.spread, self.settings.velocity)
        CP.g_script[self.settings.t_script]:server_sendProjectile(self, self.projectileConfig)
        if child then child:setActive(true) end
    end
    if self.reload then
        if ((self.settings.no_snd_on_hold and not active) or not self.settings.no_snd_on_hold) and self.settings.rld_sound and self.reload == self.settings.rld_sound then
            self.network:sendToClients("client_shoot", "rld")
        end
        self.reload = CP.calculate_reload(self.reload, self.settings.auto_reload, active)
    end
end
function BasicCannon:client_shoot(effect)
    if self.effects[effect] then
        CP.spawn_optimized_effect(self.shape, self.effects[effect], self.client_settings.effect_distance)
    end
end