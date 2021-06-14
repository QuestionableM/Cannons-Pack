--[[
	Copyright (c) 2021 Cannons Pack Team
	Questionable Mark
]]

if emp then return end
dofile("Cannons_Pack_libs/ScriptLoader.lua")
emp = class(GLOBAL_SCRIPT)
emp.maxParentCount = 1
emp.maxChildCount = 0
emp.connectionInput = _connectionType.logic
emp.connectionOutput = _connectionType.none
emp.colorNormal = _colorNew(0xb1d900ff)
emp.colorHighlight = _colorNew(0xd0ff00ff)

function emp:client_onCreate()
	self.effects = _cpEffect_cl_loadEffects(self)
	self.uv = {}
	self:client_injectScript("EMPProjectile")
end

function emp:client_onDestroy()
	if self.effects then
		self:client_clearData()
		self.effects.crg:destroy()
		self.effects.lit:destroy()
	end
end

function emp:server_onCreate()
	self.options = {
		[1] = {reload = 120, uv = 24, radius = 0.5, toAdd = 280, recoil = 2500},
		[2] = {reload = 180, uv = 49.5, radius = 1, toAdd = 250, recoil = 4000},
		[3] = {reload = 260, uv = 75, radius = 1.5, toAdd = 230, recoil = 6000},
		[4] = {reload = 320, uv = 99, radius = 2, toAdd = 190, recoil = 8000},
		[5] = {reload = 360, uv = 124.5, radius = 2.5, toAdd = 125, recoil = 10000},
		[6] = {reload = 420, uv = 150, radius = 3, toAdd = 50, recoil = 12000}
	}
	self.projectileConfiguration = _cpCannons_loadCannonInfo(self)
end

function emp:server_onFixedUpdate()
	if not _smExists(self.interactable) then return end

	local parent = self.interactable:getSingleParent()
	local active = parent and parent.active

	if not self.reload then
		if active then
			if not self.charge then
				self.network:sendToClients("client_getUvData", {mode = "crg"})
			end
			self.charge = _mathMin((self.charge or 0) + 0.005, 1)
		end

		local chargeLvl = _mathFloor((self.charge or 0) * 6)
		if (chargeLvl > 0 and not active) or chargeLvl == 6 then
			local cur_opt = self.options[chargeLvl]

			if cur_opt then
				self.projectileConfiguration.disconnectRadius = cur_opt.radius
				self.projectileConfiguration.velocity = _cp_calculateSpread(self, 0, 500)
				local c_recoil = _newVec(0, 0, -cur_opt.recoil)

				self.reload = _cp_Shoot(self, cur_opt.reload, "client_getData", "sht", c_recoil)

				EMPProjectile:server_sendProjectile(self, self.projectileConfiguration)
				self.network:sendToClients("client_getUvData", {mode = "rld", index = self.charge * 150, rldTime = cur_opt.reload + cur_opt.toAdd})
				self.charge = nil
			end
		elseif self.charge and chargeLvl == 0 and not active then
			self.network:sendToClients("client_getUvData", {mode = "col"})
			self.charge = nil
		end
	else
		if self.reload == 30 then
			self.network:sendToClients("client_getData", "rld")
		elseif self.reload == 1 then
			self.network:sendToClients("client_getUvData", {mode = "clr"})
		end

		self.reload = (self.reload > 1 and self.reload - 1) or nil
	end
end

function emp:client_onFixedUpdate()
	local _CurMode = self.uv.mode
	local _OldIndex = (self.uv.index or 0)

	if _CurMode == nil then return end

	if _CurMode == "rld" then
		self.uv.index = _mathMax(_OldIndex - (180 / self.uv.rldTime), 0)
		self:client_setEffectVal(self.uv.index / 150, self.uv.index / 75, self.uv.index + 291)
		if self.uv.index == 0 then self:client_clearData() end
	elseif _CurMode == "crg" then
		self.uv.index = _mathMin(_OldIndex + 0.005, 1)
		self:client_setEffectVal(self.uv.index, self.uv.index * 3, self.uv.index * 150)
	elseif _CurMode == "col" then
		self.uv.index = _mathMax(_OldIndex - 0.005, 0)
		self:client_setEffectVal(self.uv.index, self.uv.index * 3, self.uv.index * 150)
		if self.uv.index == 0 then self:client_clearData() end
	end
end

function emp:client_setEffectVal(rpm_val, lit_val, uv_val)
	self.effects.crg:setParameter("rpm", rpm_val)
	self.effects.lit:setParameter("intensity", lit_val)
	self.interactable:setUvFrameIndex(uv_val)
end

function emp:client_clearData()
	if _smExists(self.interactable) then
		self.interactable:setUvFrameIndex(0)
	end
	
	self.effects.crg:setParameter("rpm", 0)
	self.effects.lit:setParameter("intensity", 0)
	self.effects.crg:stop()
	self.effects.lit:stop()
	self.uv = {}
end

function emp:client_getUvData(data)
	if data.mode == "clr" then self:client_clearData()
	else
		self.uv.mode = data.mode
		if not self.effects.crg:isPlaying() then self.effects.crg:start() end
		if not self.effects.lit:isPlaying() then self.effects.lit:start() end
	end
	if data.mode ~= "col" then self.uv.index = data.index end
	self.uv.rldTime = data.rldTime
end

function emp:client_getData(effect)
	_cp_spawnOptimizedEffect(self.shape, self.effects[effect], 75)
end