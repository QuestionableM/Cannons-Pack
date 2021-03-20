--[[
    Copyright (c) 2021 Cannons Pack Team
    Questionable Mark
]]

if GLOBAL_SCRIPT then return end
GLOBAL_SCRIPT = class()

function GLOBAL_SCRIPT.server_onFixedUpdate(self, dt) end
function GLOBAL_SCRIPT.client_onFixedUpdate(self, dt) end
function GLOBAL_SCRIPT.client_onDestroy(self) end
function GLOBAL_SCRIPT.client_networkCallBack(self, data) end
function GLOBAL_SCRIPT.server_networkCallBack(self, data) end

if not GLOBAL_SCRIPT_TABLE then
    GLOBAL_SCRIPT_TABLE = {
        GLOBAL_INFO = {
            client_lastTick = 0,
            server_lastTick = 0,
            executors = 0,
            GS_ready = false
        },
        SCRIPTS = {}
    }
end

function GLOBAL_SCRIPT.client_injectScript(scriptClass, script)
    if script then
        if GLOBAL_SCRIPT_TABLE.SCRIPTS[script] == nil then
            if _G[script] then
                GLOBAL_SCRIPT_TABLE.SCRIPTS[script] = _G[script]
                _G[script].scriptType = script
                _G[script].network = scriptClass.network
                print("[CannonsPack] Script class \""..script.."\" has been added!")
            else
                print("[CannonsPack] Script class \""..script.."\" doesn't exist!")
                return
            end
        end
        GLOBAL_SCRIPT_TABLE.GLOBAL_INFO.executors = GLOBAL_SCRIPT_TABLE.GLOBAL_INFO.executors + 1
    end
    
    if scriptClass.GLOBAL_SCRIPT_INJECTED then return end
    scriptClass.GLOBAL_SCRIPT_INJECTED = true

    local OLD_server_onFixedUpdate = scriptClass.server_onFixedUpdate
    local OLD_client_onFixedUpdate = scriptClass.client_onFixedUpdate
    local OLD_client_onDestroy = scriptClass.client_onDestroy

    function scriptClass.server_onFixedUpdate(self, dt)
        if OLD_server_onFixedUpdate then OLD_server_onFixedUpdate(self, dt) end

        local lastTick = sm.game.getCurrentTick()
        if lastTick > GLOBAL_SCRIPT_TABLE.GLOBAL_INFO.server_lastTick then
            GLOBAL_SCRIPT_TABLE.GLOBAL_INFO.server_lastTick = lastTick
            for k, script in pairs(GLOBAL_SCRIPT_TABLE.SCRIPTS) do
                if script.server_updateProjectile then script:server_updateProjectile(dt) end
            end
        end
    end

    function scriptClass.client_onFixedUpdate(self, dt)
        if OLD_client_onFixedUpdate then OLD_client_onFixedUpdate(self, dt) end

        local lastTick = sm.game.getCurrentTick()
        if lastTick > GLOBAL_SCRIPT_TABLE.GLOBAL_INFO.client_lastTick then
            GLOBAL_SCRIPT_TABLE.GLOBAL_INFO.client_lastTick = lastTick
            for k, script in pairs(GLOBAL_SCRIPT_TABLE.SCRIPTS) do
                if script.client_updateProjectile then
                    script.network = self.network
                    script:client_updateProjectile(dt)
                end
            end
        end
    end

    function scriptClass.client_onDestroy(self)
        if OLD_client_onDestroy then OLD_client_onDestroy(self) end
        if GLOBAL_SCRIPT_TABLE.GLOBAL_INFO.executors > 0 then
            GLOBAL_SCRIPT_TABLE.GLOBAL_INFO.executors = GLOBAL_SCRIPT_TABLE.GLOBAL_INFO.executors - 1
        end

        if GLOBAL_SCRIPT_TABLE.GLOBAL_INFO.executors == 0 and GLOBAL_SCRIPT_TABLE.GLOBAL_INFO.GS_ready then
            print("[CannonsPack] Global Script: shutting down...")
            for k, script in pairs(GLOBAL_SCRIPT_TABLE.SCRIPTS) do
                if script.client_onDestroy then script:client_onDestroy() end
            end
            GLOBAL_SCRIPT_TABLE.GLOBAL_INFO.GS_ready = false
        end
    end

    function scriptClass.client_networkCallBack(self, data)
        if _G[data.script] then
            if _G[data.script][data.location] then
                _G[data.script][data.location](_G[data.script], self, data.data)
            else
                print("[CannonsPack] Callback \""..data.location.."\" doesn't exist!")
            end
        end
    end

    function scriptClass.server_networkCallBack(self, data)
        if _G[data.script] then
            if _G[data.script][data.location] then
                _G[data.script][data.location](_G[data.script], self, data.data)
            else
                print("[CannonsPack] Callback \""..data.location.."\" doesn't exist!")
            end
        end
    end
end

local function DISPLAY_NETWORK_ERROR(scriptType, location, error, client_server)
    sm.log.error(
        "[CannonsPack] "..client_server.." NETWORK ERROR:\n"..
        "Couldn't send the data to "..scriptType.." at this location: "..location..
        "\nError: "..error
    )
end

function GLOBAL_SCRIPT.GS_sendToServer(self, location, data)
    if self.network and self.scriptType then
        local success, error = pcall(self.network.sendToServer, self.network, "server_networkCallBack", {script = self.scriptType, location = location, data = data})
        if success == false then
            DISPLAY_NETWORK_ERROR(self.scriptType, location, error, "CLIENT")
        end
    else
        print("[CannonsPack] couldn't send the data to server\nDebug info: network =",self.network,"script type =",self.scriptType)
    end
end

function GLOBAL_SCRIPT.GS_sendToClients(self, location, data)
    if self.network and self.scriptType then
        local success, error = pcall(self.network.sendToClients, self.network, "client_networkCallBack", {script = self.scriptType, location = location, data = data})
        if success == false then
            DISPLAY_NETWORK_ERROR(self.scriptType, location, error, "SERVER")
        end
    else
        print("[CannonsPack] couldn't send the data to clients\nDebug info: network =",self.network,"script type =",self.scriptType)
    end
end

function GLOBAL_SCRIPT.GS_init(instance)
    if GLOBAL_SCRIPT_TABLE.GLOBAL_INFO.GS_ready then return end 
    local position = instance.shape.worldPosition
    if position.x ~= 0 and position.y ~= 0 and position.z ~= 10000 then
        sm.shape.createPart(instance.shape.uuid, sm.vec3.new(0, 0, 10000), sm.quat.identity(), false, false)
    end
    print("[CannonsPack] Global Script initialized")
    GLOBAL_SCRIPT_TABLE.GLOBAL_INFO.GS_ready = true
end

function GLOBAL_SCRIPT.updateScript(script)
    if GLOBAL_SCRIPT_TABLE.SCRIPTS[script] ~= nil then
        GLOBAL_SCRIPT_TABLE.SCRIPTS[script] = _G[script]
        _G[script].scriptType = script
    end
end
print("[CannonsPack] Global Script has been loaded!")