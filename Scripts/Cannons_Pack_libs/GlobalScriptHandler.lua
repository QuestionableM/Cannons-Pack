--[[
	Copyright (c) 2022 Cannons Pack Team
	Questionable Mark
]]

if GLOBAL_SCRIPT then return end
GLOBAL_SCRIPT = class()

function GLOBAL_SCRIPT.server_onFixedUpdate(self, dt) end
function GLOBAL_SCRIPT.client_onFixedUpdate(self, dt) end
function GLOBAL_SCRIPT.client_onDestroy(self) end

--[[
local _SpawnPosition = _newVec(0, 0, 5000)
local _ActiveScripts = {}
]]

function GLOBAL_SCRIPT.client_injectScript(self, script)
	local g_script = _CP_gScript[script]
	if g_script == nil then
		_cpPrint("The specified script \""..script.."\" doesn't exist!")
		return
	end

	if not self._GS_ATTACHED then
		self._GS_ATTACHED = true

		self.projectiles = {}
		self.proj_queue = {}

		self.client_loadProjectile = g_script.client_loadProjectile

		local sv_onFixedUpdate_cpy = self.server_onFixedUpdate
		self.server_onFixedUpdate = function(self, dt)
			g_script.server_onScriptUpdate(self, dt)
			sv_onFixedUpdate_cpy(self, dt)
		end
		
		local cl_onFixedUpdate_cpy = self.client_onFixedUpdate
		self.client_onFixedUpdate = function(self, dt)
			g_script.client_onScriptUpdate(self, dt)
			cl_onFixedUpdate_cpy(self, dt)
		end

		local cl_onDestroy_cpy = self.client_onDestroy
		self.client_onDestroy = function(self)
			g_script.client_onScriptDestroy(self)
			cl_onDestroy_cpy(self)
		end
	end

	--Temporarily scrapped
	--[[local _sUuid = self.shape:getShapeUuid()
	local _ShapePos = self.shape:getWorldPosition()

	local _GScript = _CP_gScript[script]
	if _GScript == nil then
		_cpPrint("The specified script \""..script.."\" doesn't exist!")
		return
	end

	if self._GS_ATTACHED or _ActiveScripts[script] then return end

	if (_ShapePos - _SpawnPosition):length() > 50 then
		local _OldServer = self.server_onFixedUpdate
		function self.server_onFixedUpdate(self, dt)
			_createPart(_sUuid, _SpawnPosition, _quatIdentity(), false, true)
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

		_cpPrint(script.." script has been initialized")
	end]]
end

_cpPrint("Global Script has been loaded!")