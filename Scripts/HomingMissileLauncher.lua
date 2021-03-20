--[[
    Copyright (c) 2021 Cannons Pack Team
    Questionable Mark
]]

if HomingMissile then return end
dofile("Cannons_Pack_libs/ScriptLoader.lua")
HomingMissile = class(GLOBAL_SCRIPT)
HomingMissile.maxParentCount = 4
HomingMissile.maxChildCount = 0
HomingMissile.connectionInput = sm.interactable.connectionType.logic + sm.interactable.connectionType.power
HomingMissile.connectionOutput = sm.interactable.connectionType.none
HomingMissile.colorNormal = sm.color.new(0x00538aff)
HomingMissile.colorHighlight = sm.color.new(0x0099ffff)
function HomingMissile:server_onCreate()
	self:GS_init()
	self.settings = {}
	self.rocketConfig = CP_Cannons.load_cannon_info(self)
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
function HomingMissile:server_onFixedUpdate()
	if not sm.exists(self.interactable) then return end
	self.player = nil
	self.settings.mode = "seek"
	local launcher_active = false
	local proximityFuse = 0
	for l,gate in pairs(self.interactable:getParents()) do
		local gate_col = tostring(gate:getShape():getColor())
		if gate:getType() == "scripted" and tostring(gate.shape.shapeUuid) ~= "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07" then --The Modpack Number logic check
			if gate_col == "eeeeeeff" then
				self.player = math.max(math.min(gate.power, #sm.player.getAllPlayers() - 1), 0)
			elseif gate_col == "7f7f7fff" then
				if gate.power > 0 then proximityFuse = math.min(gate.power, 20) end
			end
		else --Vanilla logic
			if gate_col == "222222ff" then
				if gate.active then self.settings.mode = "cam" end
			elseif gate_col == "4a4a4aff" then
				if gate.active then self.settings.mode = "dirCam" end
			else
				if gate.active then launcher_active = true end
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
		self.settings.player = self.target or (self.player and sm.player.getAllPlayers()[self.player + 1])
		self.cameraPlayer = nil
	end
	if self.settings.mode == "cam" or self.settings.mode == "dirCam" then
		self.target = nil
		if self.player ~= nil and self.cameraPlayer ~= nil then 
			self.cameraPlayer = nil 
		end
		self.settings.player = self.cameraPlayer or (self.player and sm.player.getAllPlayers()[self.player + 1])
	end
	if launcher_active and not self.reload then
		local hit = false
		local bool, result = sm.physics.raycast(self.shape.worldPosition, self.shape.worldPosition - self.shape.up / 1.58)
		if not bool or (bool and result.type == "character") then
			hit = true
		end
		self.reload = CP.shoot(self, 280, "client_onChange", {case = "sht", hit = hit, eff = "sht"}, sm.vec3.new(0, 0, -1000))
		self.rocketConfig.proxFuze = proximityFuse
		self.rocketConfig.position = self.shape.worldPosition + self.shape.worldRotation * sm.vec3.new(0, 0, 0.7 + (math.abs(self.shape.up:dot(self.shape.velocity)) / 24))
		self.rocketConfig.direction = CP.calculate_spread(self, 0.2, 100)
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
	self.effects = CP_Effects.client_loadEffect(self)
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
			CP.spawn_optimized_effect(self.shape, self.effects[data.eff], 75)
		end
		if data.hit then
			CP.spawn_optimized_effect(self.shape, self.effects.fms, 150)
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
	if state then
		if not self.logic then
			if not self.clientCamera then
				local crouchValue = character:isCrouching() and -1 or 1
				local valLimit = #sm.player.getAllPlayers() + #self.modes
				self.victim = (self.victim + crouchValue) % valLimit
				if (self.victim + 1) <= #self.modes then
					CP.info_output("GUI Item drag", true, ("#ffff00Mode#ffffff: #ffff00%s#ffffff"):format(self.modes[self.victim + 1].name))
					self.network:sendToServer("server_networking", {mode = "victim"})
				else
					CP.info_output("GUI Item drag", true, ("#ffff00Mode#ffffff: Targeting #ff0000%s#ffffff"):format(sm.player.getAllPlayers()[self.victim + 1 - #self.modes].name), 2)
					self.network:sendToServer("server_networking", {mode = "victim", player = sm.player.getAllPlayers()[self.victim + 1 - #self.modes]})
				end
			else
				self.network:sendToServer("server_networking", {mode = "camPlayer", player = sm.localPlayer.getPlayer()})
				CP.info_output("Blueprint - Camera", true, "You are controlling the rockets now", 2)
			end
		else
			CP.info_output("GUI Item released", true, "You can't change stuff while number logic is connected to the rocket launcher")
		end
	end
end
function HomingMissile:client_canInteract()
	if not self.logic then
		local _UseKey = sm.gui.getKeyBinding("Use")
		if not self.clientCamera then
			local _CrawlKey = sm.gui.getKeyBinding("Crawl")
			sm.gui.setInteractionText("Press", _UseKey, "or", ("%s + %s"):format(_CrawlKey, _UseKey), "to chose the target")
		else
			sm.gui.setInteractionText("Press", _UseKey, "to control the rockets")
		end
	else
		sm.gui.setInteractionText("", "You can't change any settings while number logic is connected to the rocket launcher")
		return false
	end
	sm.gui.setInteractionText("","check the workshop page of \"Cannons Pack\" for instructions")
	return true
end