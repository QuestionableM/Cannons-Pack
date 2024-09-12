--[[
	Copyright (c) 2025 Cannons Pack Team
	Questionable Mark
]]

if OrbitalCannon then return end

dofile("Cannons_Pack_libs/ScriptLoader.lua")

---@class OrbitalCannon : GlobalScriptHandler
OrbitalCannon = class(GLOBAL_SCRIPT)
OrbitalCannon.maxParentCount = 1
OrbitalCannon.maxChildCount  = 0
OrbitalCannon.connectionInput  = _connectionType.logic
OrbitalCannon.connectionOutput = _connectionType.none
OrbitalCannon.colorNormal    = _colorNew(0x638583ff)
OrbitalCannon.colorHighlight = _colorNew(0x99cfcbff)

function OrbitalCannon:client_onCreate()
	self.effects = _cpEffect_cl_loadEffects(self)
	self.uv = {}
	self:client_injectScript("CPProjectile")
end

function OrbitalCannon:server_onCreate()
	self.projectileConfiguration = _cpCannons_loadCannonInfo(self)
end

function OrbitalCannon:server_createEffects(position, p_shot)
	local proj_amount = p_shot and 1 or _mathRandom(40, 80)
	local point_effect = p_shot and "OrbitalCannon - PowerfulShot" or "OrbitalCannon - OrdinaryShot"
	local proj_data_id = p_shot and ProjEnum.OrbitalCannonPowShot or ProjEnum.OrbitalCannon

	local effectPos = _newVec(position.x, position.y, 950)
	self.projectileConfiguration[ProjSettingEnum.position] = effectPos

	_playEffect(point_effect, effectPos)
	_playEffect("OrbitalCannon - PointSound", position)

	if p_shot then
		self.projectileConfiguration[ProjSettingEnum.velocity] = _newVec(0, 0, -250)
	end

	self.network:sendToClients("client_dispEffect", EffectEnum.pnt)
	for i = 1, proj_amount do
		if not p_shot then
			local random_vel = _mathRandom(-250, -400)
			self.projectileConfiguration[ProjSettingEnum.velocity] = _gunSpread(_newVec(0, 0, random_vel), 10)
		end

		CPProjectile:server_sendProjectile(self, self.projectileConfiguration, proj_data_id)
	end
end

local OC_ModeEnum = {rld = 1, hld = 2, clr = 3}

function OrbitalCannon:server_setValues(reload, sendData, is_error)
	self.reload = reload
	self.hold = nil
	self.error = is_error

	if sendData then
		self.network:sendToClients("client_getUvData", {OC_ModeEnum.rld, reload})
	end
end

function OrbitalCannon:server_onFixedUpdate()
	if not _smExists(self.interactable) then return end

	local parent = self.interactable:getSingleParent()
	local active = parent and parent.active

	if not self.reload then
		local s_WorldPos = self.shape.worldPosition
		local hit, result = _physRaycast(s_WorldPos, s_WorldPos + self.shape.up * 2500)
		if hit and result.type ~= "limiter" and result.pointWorld.z < 900 then
			if active then
				if not self.hold then
					self.network:sendToClients("client_getUvData", {OC_ModeEnum.hld})
				end

				self.hold = _mathMin((self.hold or 0) + 0.02, 1)
			end

			if self.hold and self.hold == 1 then
				self:server_createEffects(result.pointWorld, true)
				self:server_setValues(800, true)
			elseif self.hold and self.hold > 0 and not active then
				self:server_createEffects(result.pointWorld, false)
				self:server_setValues(450, true)
			end
		else
			if active then
				self.network:sendToClients("client_dispEffect", EffectEnum.err)
				self:server_setValues(0, false, true)
			end
		end
	else
		if self.reload == 30 then
			self.network:sendToClients("client_dispEffect", EffectEnum.rld)
		elseif self.reload == 1 and not self.error then
			self.network:sendToClients("client_getUvData", {OC_ModeEnum.clr})
		end

		self.reload = (self.reload > 1 and self.reload - 1) or (active and 0 or nil)

		if self.reload == nil then self.error = nil end
	end
end

function OrbitalCannon:client_getUvData(data)
	local mode = data[1]
	if mode == OC_ModeEnum.clr then
		self.interactable:setUvFrameIndex(0)
		self.uv = {}
	else
		self.uv.mode = mode
	end

	self.uv.rld = data[2]
	self.uv.index = nil
end

function OrbitalCannon:client_onFixedUpdate()
	local uv_mode = self.uv.mode

	if uv_mode == OC_ModeEnum.rld then
		self.uv.index = _mathMax((self.uv.index or 295) - (295 / self.uv.rld), 0)
		self.interactable:setUvFrameIndex(self.uv.index)
		if self.uv.index == 0 then
			self.uv = {}
		end
	elseif uv_mode == OC_ModeEnum.hld then
		self.uv.index = _mathMin((self.uv.index or 0) + 0.02, 1)
		self.interactable:setUvFrameIndex(self.uv.index * 295)
		if self.uv.index == 1 then
			self.uv = {}
		end
	end
end

function OrbitalCannon:client_onInteract(character, state)
	if not state then return end

	_cp_infoOutput("GUI Item drag", true, "A little advice:#ff0000 don't target the walls of the world", 2)
end

function OrbitalCannon:client_dispEffect(data)
	self.effects[data]:start()
end