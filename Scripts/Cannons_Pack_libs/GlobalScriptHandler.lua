--[[
    Copyright (c) 2021 Cannons Pack Team
    Questionable Mark
]]

if GLOBAL_SCRIPT then return end
GLOBAL_SCRIPT = class()

function GLOBAL_SCRIPT.server_onFixedUpdate(self, dt) end
function GLOBAL_SCRIPT.client_onFixedUpdate(self, dt) end
function GLOBAL_SCRIPT.client_onDestroy(self) end

local _SpawnPosition = sm.vec3.new(0, 0, 5000)
local _ActiveScripts = {}

function GLOBAL_SCRIPT.client_injectScript(self, script)
    local _sUuid = self.shape:getShapeUuid()
    local _ShapePos = self.shape:getWorldPosition()

    local _GScript = CP.g_script[script]
    if _GScript == nil then
        CP.print("The specified script \""..script.."\" doesn't exist!")
        return
    end

    if self._GS_ATTACHED or _ActiveScripts[script] then return end

    if (_ShapePos - _SpawnPosition):length() > 50 then
        local _OldServer = self.server_onFixedUpdate
        function self.server_onFixedUpdate(self, dt)
            sm.shape.createPart(_sUuid, _SpawnPosition, sm.quat.identity(), false, true)
            _OldServer(self, dt)
            self.server_onFixedUpdate = _OldServer
        end
    else
        function self.client_onDestroy() end
        function self.client_onFixedUpdate() end
        function self.server_onFixedUpdate() end

        for k, v in pairs(_GScript) do
            if self[k] == nil then self[k] = v end
        end

        _ActiveScripts[script] = true
        self._GS_ATTACHED = script

        local _ClientOnDestroy = self.client_onScriptDestroy
        function self.client_onDestroy(self)
            _ActiveScripts[self._GS_ATTACHED] = nil
            if _ClientOnDestroy then _ClientOnDestroy(self) end
        end

        local _ClientOnFixedUpdate = self.client_onScriptUpdate
        if _ClientOnFixedUpdate then
            function self.client_onFixedUpdate(self, dt) _ClientOnFixedUpdate(self, dt) end
        end

        local _ServerOnFixedUpdate = self.server_onScriptUpdate
        if _ServerOnFixedUpdate then
            function self.server_onFixedUpdate(self, dt) _ServerOnFixedUpdate(self, dt) end
        end

        if self.client_onScriptCreate then self.client_onScriptCreate(self) end

        CP.print(script.." script has been initialized")
    end
end

print("[CannonsPack] Global Script has been loaded!")