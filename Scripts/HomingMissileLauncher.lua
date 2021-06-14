--[[
	Copyright (c) 2021 Cannons Pack Team
	Questionable Mark
]]

if HomingMissile then return end
dofile("Cannons_Pack_libs/ScriptLoader.lua")
HomingMissile = class(GLOBAL_SCRIPT)
HomingMissile.maxParentCount = 4
HomingMissile.maxChildCount = 0
HomingMissile.connectionInput = _connectionType.logic + _connectionType.power
HomingMissile.connectionOutput = _connectionType.none
HomingMissile.colorNormal = _colorNew(0x00538aff)
HomingMissile.colorHighlight = _colorNew(0x0099ffff)

function HomingMissile:server_onCreate()
	self.settings = {}
	self.rocketConfig = _cpCannons_loadCannonInfo(self)
end

function HomingMissile:server_networking(data)
	if data.mode == "victim" then
		self.target = data.player
	elseif data.mode == "camPlayer" then
		self.cameraPlayer = data.player
	elseif data.mode == "req" then
		self.network:sendToClients("client_onChange", {case = "reveiveData", uv = self.reload ~= nil, logic = self.player ~= nil, camera = self.settings.mode == "cam" or self.settings.mode == "dirCam"})
	end
end


local _recoil = _newVec(0, 0, -1000)
function HomingMissile:server_onFixedUpdate()
	if not _smExists(self.interactable) then return end

	self.player = nil
	self.settings.mode = "seek"
	local launcher_active = false
	local proximityFuse = 0

	local Parents = self.interactable:getParents()
	for l, gate in pairs(Parents) do
		local gate_col = tostring(gate:getShape():getColor())

		if _cp_isNumberLogic(gate) then
			if gate_col == "eeeeeeff" then
				self.player = _mathMax(_mathMin(gate.power, #_getAllPlayers() - 1), 0)
			elseif gate_col == "7f7f7fff" then
				if gate.power > 0 then proximityFuse = _mathMin(gate.power, 20) end
			end
		else
			if _cp_isLogic(gate) then
				if gate_col == "222222ff" then
					if gate.active then self.settings.mode = "cam" end
				elseif gate_col == "4a4a4aff" then
					if gate.active then self.settings.mode = "dirCam" end
				else
					if gate.active then launcher_active = true end
				end
			end
		end
	end

	if self.number ~= self.player then
		self.number = self.player
		self.network:sendToClients("client_onChange", {case = "numb", logic = self.player ~= nil})
	end

	if self.bool ~= self.settings.mode then
		self.bool = self.settings.mode
		self.network:sendToClients("client_onChange", {case = "camera", bool = self.settings.mode == "cam" or self.settings.mode == "dirCam"})
	end

	if self.settings.mode ~= "cam" and self.settings.mode ~= "dirCam" then
		self.settings.player = self.target or (self.player and _getAllPlayers()[self.player + 1])
		self.cameraPlayer = nil
	end

	if self.settings.mode == "cam" or self.settings.mode == "dirCam" then
		self.target = nil
		if self.player ~= nil and self.cameraPlayer ~= nil then 
			self.cameraPlayer = nil 
		end
		self.settings.player = self.cameraPlayer or (self.player and _getAllPlayers()[self.player + 1])
	end
	
	if launcher_active and not self.reload then
		local hit = false
		local bool, result = _physRaycast(self.shape.worldPosition, self.shape.worldPosition - self.shape.up / 1.58)
		if not bool or (bool and result.type == "character") then
			hit = true
		end

		self.reload = _cp_Shoot(self, 280, "client_onChange", {case = "sht", hit = hit, eff = "sht"}, _recoil)
		self.rocketConfig.proxFuze = proximityFuse
		self.rocketConfig.position = self.shape.worldPosition + self.shape.worldRotation * _newVec(0, 0, 0.7 + (_mathAbs(self.shape.up:dot(self.shape.velocity)) / 24))
		self.rocketConfig.direction = _cp_calculateSpread(self, 0.2, 100)
		self.rocketConfig.rocketSettings = {
			mode = self.settings.mode or "seek",
			player = self.settings.player
		}

		SmartRocket:server_sendProjectile(self, self.rocketConfig)
	end

	if self.reload then
		if self.reload == 30 then
			self.network:sendToClients("client_onChange", {case = "sht", eff = "rld", act = launcher_active})
		end
		self.reload = (self.reload > 1 and self.reload - 1) or nil
	end
end

function HomingMissile:client_onCreate()
	self.effects = _cpEffect_cl_loadEffects(self)
	self:client_injectScript("SmartRocket")
	self.network:sendToServer("server_networking", {mode = "req"})
	self.victim = 0
	self.logic = false
	self.clientCamera = false
	self.modes = {
		[1] = {name = "Targeting closest visible player", id = "clpl"}
	}
end

function HomingMissile:client_onChange(data)
	if data.case == "camera" then
		self.clientCamera = data.bool
		if data.bool then 
			self.victim = 0
		end
	elseif data.case == "numb" then
		self.logic = data.logic
	elseif data.case == "sht" then
		self.interactable:setUvFrameIndex(data.eff ~= "rld" and 70 or 0)

		if not data.act then
			_cp_spawnOptimizedEffect(self.shape, self.effects[data.eff], 75)
		end

		if data.hit then
			_cp_spawnOptimizedEffect(self.shape, self.effects.fms, 150)
		end
	elseif data.case == "reveiveData" then
		self.logic = data.logic
		self.clientCamera = data.camera
		if data.uv then
			self.interactable:setUvFrameIndex(70)
		end
	end
end

function HomingMissile:client_onInteract(character, state)
	if not state then return end

	if not self.logic then
		if not self.clientCamera then
			local pl_list = _getAllPlayers()
			local mode_count = #self.modes

			local crouchValue = character:isCrouching() and -1 or 1
			local valLimit = #pl_list + mode_count
			self.victim = (self.victim + crouchValue) % valLimit

			if (self.victim + 1) <= mode_count then
				_cp_infoOutput("GUI Item drag", true, ("#ffff00Mode#ffffff: #ffff00%s#ffffff"):format(self.modes[self.victim + 1].name))
				self.network:sendToServer("server_networking", {mode = "victim"})
			else
				local cur_player = pl_list[self.victim + 1 - mode_count]
				_cp_infoOutput("GUI Item drag", true, ("#ffff00Mode#ffffff: Targeting #ff0000%s#ffffff"):format(cur_player.name), 2)
				self.network:sendToServer("server_networking", {mode = "victim", player = cur_player})
			end
		else
			self.network:sendToServer("server_networking", {mode = "camPlayer", player = _getLocalPlayer()})
			_cp_infoOutput("Blueprint - Camera", true, "You are controlling the rockets now", 2)
		end
	else
		_cp_infoOutput("GUI Item released", true, "You can't change stuff while number logic is connected to the rocket launcher")
	end
end

function HomingMissile:client_canInteract()
	if self.logic then
		_setInteractionText("", "You can't change any settings while number logic is connected to the rocket launcher")
		return false
	end

	local use_key = _getKeyBinding("Use")
		
	if self.clientCamera then
		_setInteractionText("Press", use_key, "to control the rockets")
	else
		local crawl_key = _getKeyBinding("Crawl")

		_setInteractionText("Press", crawl_key, "or", ("%s + %s"):format(crawl_key, use_key), "to choose the target")
	end

	_setInteractionText("", "Check the workshop page of \"Cannons Pack\" for instructions")

	return true
end