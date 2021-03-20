--[[
    Copyright (c) 2021 Cannons Pack Team
    Questionable Mark
]]

if RocketDetector then return end
dofile("Cannons_Pack_libs/ScriptLoader.lua")
RocketDetector = class()
RocketDetector.connectionInput = sm.interactable.connectionType.logic
RocketDetector.connectionOutput = sm.interactable.connectionType.logic
RocketDetector.maxChildCount = -1
RocketDetector.maxParentCount = 2
RocketDetector.colorNormal = sm.color.new(0x009130ff)
RocketDetector.colorHighlight = sm.color.new(0x00cf44ff)
function RocketDetector:client_onCreate()
    self.nearest_distance = math.huge
    self.client_detectDistance = 300
    self.network:sendToServer("server_getDetectDistance", sm.localPlayer.getPlayer())
end
function RocketDetector:client_receiveDetectDistance(distance) self.client_detectDistance = distance end
function RocketDetector:server_getDetectDistance(player) self.network:sendToClient(player, "client_receiveDetectDistance", self.server_detectDistance) end
function RocketDetector:server_onCreate()
    self.tick_counter = 0
    self.server_detectDistance = 300
end
function RocketDetector:server_onFixedUpdate()
    if not sm.exists(self.interactable) then return end
    local distance_pulse = false
    local temp_distance = 300
    for id, interactable in pairs(self.interactable:getParents()) do
        local shape_color = tostring(interactable.shape.color)
        if interactable.type == "scripted" and tostring(interactable.shape.uuid) ~= "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07" then
            if shape_color == "eeeeeeff" and interactable.power > 0 then
                temp_distance = interactable.power
            end
        else
            if interactable.active then distance_pulse = true end
        end
    end
    if temp_distance ~= self.server_detectDistance then
        self.server_detectDistance = temp_distance
        self.network:sendToClients("client_receiveDetectDistance", self.server_detectDistance)
    end
    local norm_dist = math.min(self.nearest_distance, self.server_detectDistance) / self.server_detectDistance
    self.tick_counter = (self.tick_counter + (1 - norm_dist)) % math.pi
    local interval = math.abs(math.sin(self.tick_counter))
    local pu = interval >= 0.5 or norm_dist < 0.2 or not distance_pulse
    self.interactable:setActive(self.nearest_distance <= self.server_detectDistance and pu)
end
function RocketDetector:client_onFixedUpdate()
    if not sm.exists(self.interactable) then return end
    if SmartRocket and SmartRocket.projectiles then
        self.nearest_distance = math.huge
        for id, s_rocket in pairs(SmartRocket.projectiles) do
            local norm_dir = s_rocket.pos + s_rocket.dir:normalize()
            local rocket_sees_sensor = CP.isObjectVisible(s_rocket.pos, norm_dir, self.shape.worldPosition, 1.22173, 1.22173)
            local sensor_sees_rocket = CP.isObjectVisible(self.shape.worldPosition, self.shape.worldPosition + self.shape.up, s_rocket.pos, 1.39626, 1.39626)
            if rocket_sees_sensor and sensor_sees_rocket then
                local distance = (self.shape.worldPosition - s_rocket.pos):length()
                if distance < self.nearest_distance then self.nearest_distance = distance end
            end
        end
        local f_distance = math.min(self.nearest_distance, self.client_detectDistance) / self.client_detectDistance
        self.interactable:setUvFrameIndex(580 - (f_distance * 580))
    end
end