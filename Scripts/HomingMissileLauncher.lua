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
	self.rocketConfig = _cpCannons_loadCannonInfo(self)
	self.cam_bool = false
	self.num_logic_bool = false
end

function HomingMissile:client_onCreate()
	self.effects = _cpEffect_cl_loadEffects(self)
	self:client_injectScript("SmartRocket")

	self.client_cam = false
	self.client_num_logic = false
	self.client_pl_page = 0

	self.network:sendToServer("server_requestData")
end

function HomingMissile:server_requestData(data, caller)
	self.network:sendToClient(caller, "client_receiveData", {self.reload ~= nil, self.num_logic_bool, self.cam_bool})
end

function HomingMissile:client_receiveData(data)
	self:client_updateUvAnim(data[1])
	self.client_num_logic = data[2]
	self.client_cam = data[3]
end

function HomingMissile:server_updateNumLogicBool(state)
	if self.num_logic_bool ~= state then
		self.num_logic_bool = state
		self.network:sendToClients("client_setNumLogicMode", self.num_logic_bool)
	end
end

function HomingMissile:server_updateCamBool(state)
	if self.cam_bool ~= state then
		self.cam_bool = state

		if not self.cam_bool then
			self.operator = nil
		end

		self.network:sendToClients("client_setCamMode", self.cam_bool)
	end
end

function HomingMissile:server_setTarget(target)
	self.target = target
end

function HomingMissile:server_setOperator(data, operator)
	self.operator = operator
end

function HomingMissile:server_getFinalTarget(pl_target)
	local final_target = nil

	if self.cam_bool then
		final_target = self.operator or pl_target
	else
		final_target = self.target or pl_target
	end

	return final_target
end

function HomingMissile:server_updateReload(can_shoot)
	if self.reload then
		if self.reload == 30 then
			self.network:sendToClients("client_onEffect", {EffectEnum.rld, can_shoot})
		end

		self.reload = (self.reload > 1 and self.reload - 1) or nil
	end
end

function HomingMissile:server_tryShootProjectile(can_shoot, rocket_mode, target_player, proximityFuze)
	if can_shoot and not self.reload then
		local s_Pos = self.shape.worldPosition
		local bool, result = _physRaycast(s_Pos, s_Pos - self.shape.up / 1.58)
		local hit = (not bool or (bool and result.type == "character"))

		self.reload = _cp_Shoot(self, 280, "client_onEffect", {EffectEnum.sht, hit}, _recoil)

		self.rocketConfig[ProjSettingEnum.velocity] = _cp_calculateSpread(self, 0.2, 100)
		self.rocketConfig[ProjSettingEnum.player] = self:server_getFinalTarget(target_player)
		self.rocketConfig[ProjSettingEnum.mode] = rocket_mode
		self.rocketConfig[ProjSettingEnum.proxFuze] = proximityFuze

		SmartRocket:server_sendProjectile(self, self.rocketConfig, ProjEnum.SmartRocketLauncher)
	end
end

local _recoil = _newVec(0, 0, -1000)
function HomingMissile:server_onFixedUpdate()
	if not _smExists(self.interactable) then return end

	local can_shoot = false
	local target_player = nil
	local player_list = _getAllPlayers()
	local rocket_mode = nil
	local proximityFuze = 0

	local parent_list = self.interactable:getParents()
	for k, p in pairs(parent_list) do
		local p_Color = tostring(p.shape.color)

		if _cp_isNumberLogic(p) then
			local p_Power = p.power
			if p_Color == "eeeeeeff" then
				target_player = player_list[_mathMax(_mathMin(p_Power, #player_list - 1), 0) + 1]
			elseif p_Color == "7f7f7fff" then
				if p_Power > 0 then proximityFuze = _mathMin(p_Power, 20) end
			end
		else
			if _cp_isLogic(p) then
				local p_Active = p.active
				if p_Color == "222222ff" then
					if p_Active then rocket_mode = SR_ModeEnum.cam end
				elseif p_Color == "4a4a4aff" then
					if p_Active then rocket_mode = SR_ModeEnum.dirCam end
				else
					if p_Active then can_shoot = true end
				end
			end
		end
	end

	self:server_updateCamBool(rocket_mode ~= nil)
	self:server_updateNumLogicBool(target_player ~= nil)

	self:server_tryShootProjectile(can_shoot, rocket_mode, target_player, proximityFuze)

	self:server_updateReload(can_shoot)
end

function HomingMissile:client_onEffect(data)
	local eff_idx = data[1]
	local active = data[2]

	local is_ShootEff = (eff_idx == EffectEnum.sht)
	self:client_updateUvAnim(is_ShootEff)

	if (not is_ShootEff and not active) or is_ShootEff then
		_cp_spawnOptimizedEffect(self.shape, self.effects[eff_idx], 75)
	end

	if is_ShootEff and active then
		_cp_spawnOptimizedEffect(self.shape, self.effects[EffectEnum.fms], 150)
	end
end

function HomingMissile:client_setCamMode(state)
	self.client_cam = state
end

function HomingMissile:client_setNumLogicMode(state)
	self.client_num_logic = state
end

function HomingMissile:client_updateUvAnim(is_shoot)
	self.interactable:setUvFrameIndex(is_shoot and 70 or 0)
end

local HM_NumLogicConnectedMsg = "You can't change any settings while number logic is connected to the rocket launcher"
function HomingMissile:client_onInteract(character, state)
	if not state then return end

	if self.client_num_logic then
		_cp_infoOutput("GUI Item released", true, HM_NumLogicConnectedMsg)
		return
	end

	if self.client_cam then
		self.network:sendToServer("server_setOperator")
		_cp_infoOutput("Blueprint - Camera", true, "You are controlling the rockets now!", 2)
	else
		local pl_list = _getAllPlayers()
		
		local c_Value = character:isCrouching() and -1 or 1
		self.client_pl_page = (self.client_pl_page + c_Value) % (#pl_list + 1)
		
		if self.client_pl_page == 0 then
			_cp_infoOutput("GUI Item drag", true, "#ffff00Mode#ffffff: #ffff00Targeting closest visible player#ffffff")
			self.network:sendToServer("server_setTarget")
		else
			local cur_player = pl_list[self.client_pl_page]
			_cp_infoOutput("GUI Item drag", true, ("#ffff00Mode:#ffffff: Targeting #ff0000%s#ffffff"):format(cur_player.name))
			self.network:sendToServer("server_setTarget", cur_player)
		end
	end
end

function HomingMissile:client_canInteract()
	if self.client_num_logic then
		_setInteractionText("", HM_NumLogicConnectedMsg)
		return false
	end

	local use_key = _getKeyBinding("Use")

	if self.client_cam then
		_setInteractionText("Press", use_key, "to control the rockets")
	else
		local crawl_key = _getKeyBinding("Crawl")

		_setInteractionText("Press", crawl_key, "or", ("%s + %s"):format(crawl_key, use_key), "to choose the target")
	end

	_setInteractionText("", "Check the workshop page of \"Cannons Pack\" for instructions")

	return true
end