--[[
	Copyright (c) 2023 Cannons Pack Team
	Questionable Mark
]]

if emp then return end

dofile("Libs/ScriptLoader.lua")

emp = class()
emp.maxParentCount = 1
emp.maxChildCount  = 0
emp.connectionInput  = _connectionType.logic
emp.connectionOutput = _connectionType.none
emp.colorNormal    = _colorNew(0xb1d900ff)
emp.colorHighlight = _colorNew(0xd0ff00ff)

function emp:client_onCreate()
	self.effects = _cpEffect_cl_loadEffects(self)
	self.uv = {}
end

function emp:client_onDestroy()
	if self.effects then
		self:client_clearData()

		self.effects[EffectEnum.crg]:destroy()
		self.effects[EffectEnum.lit]:destroy()
	end
end

function emp:server_onCreate()
	self.options =
	{
		[1] = { reload = 120, uv = 24   , radius = 0.5, toAdd = 280 },
		[2] = { reload = 180, uv = 49.5 , radius = 1  , toAdd = 250 },
		[3] = { reload = 260, uv = 75   , radius = 1.5, toAdd = 230 },
		[4] = { reload = 320, uv = 99   , radius = 2  , toAdd = 190 },
		[5] = { reload = 360, uv = 124.5, radius = 2.5, toAdd = 125 },
		[6] = { reload = 420, uv = 150  , radius = 3  , toAdd = 50  }
	}

	self.projectileConfiguration = _cpCannons_loadCannonInfo(self)
end

local EMP_ModeEnum = {
	crg = 1,
	rld = 2,
	col = 3,
	clr = 4
}

function emp:server_onFixedUpdate()
	if not _smExists(self.interactable) then return end

	local parent = self.interactable:getSingleParent()
	local active = parent and parent.active

	if not self.reload then
		if active then
			if not self.charge then
				self.network:sendToClients("client_getUvData", {EMP_ModeEnum.crg})
			end

			self.charge = _mathMin((self.charge or 0) + 0.005, 1)
		end

		local chargeLvl = _mathFloor((self.charge or 0) * 6)
		if (chargeLvl > 0 and not active) or chargeLvl == 6 then
			local cur_opt = self.options[chargeLvl]

			if cur_opt then
				self.projectileConfiguration[ProjSettingEnum.disconnectRadius] = cur_opt.radius
				self.projectileConfiguration[ProjSettingEnum.velocity] = _cp_calculateSpread(self, 0, 500)

				self.reload = _cp_Shoot(self, cur_opt.reload, "client_getData", EffectEnum.sht)

				EMPProjectile:server_sendProjectile(self, self.projectileConfiguration, ProjEnum.EMPCannon)
				self.network:sendToClients("client_getUvData", {EMP_ModeEnum.rld, self.charge * 150, cur_opt.reload + cur_opt.toAdd})
				self.charge = nil
			end
		elseif self.charge and chargeLvl == 0 and not active then
			self.network:sendToClients("client_getUvData", {EMP_ModeEnum.col})
			self.charge = nil
		end
	else
		if self.reload == 30 then
			self.network:sendToClients("client_getData", EffectEnum.rld)
		elseif self.reload == 1 then
			self.network:sendToClients("client_getUvData", {EMP_ModeEnum.clr})
		end

		self.reload = (self.reload > 1 and self.reload - 1) or nil
	end
end

function emp:client_onFixedUpdate()
	local _CurMode = self.uv.mode
	local _OldIndex = (self.uv.index or 0)

	if _CurMode == nil then return end

	if _CurMode == EMP_ModeEnum.rld then
		self.uv.index = _mathMax(_OldIndex - (180 / self.uv.rldTime), 0)
		self:client_setEffectVal(self.uv.index / 150, self.uv.index / 75, self.uv.index + 291)
		if self.uv.index == 0 then self:client_clearData() end
	elseif _CurMode == EMP_ModeEnum.crg then
		self.uv.index = _mathMin(_OldIndex + 0.005, 1)
		self:client_setEffectVal(self.uv.index, self.uv.index * 3, self.uv.index * 150)
	elseif _CurMode == EMP_ModeEnum.col then
		self.uv.index = _mathMax(_OldIndex - 0.005, 0)
		self:client_setEffectVal(self.uv.index, self.uv.index * 3, self.uv.index * 150)
		if self.uv.index == 0 then self:client_clearData() end
	end
end

function emp:client_setEffectVal(rpm_val, lit_val, uv_val)
	self.effects[EffectEnum.crg]:setParameter("rpm", rpm_val)
	self.effects[EffectEnum.lit]:setParameter("intensity", lit_val)

	self.interactable:setUvFrameIndex(uv_val)
end

function emp:client_clearData()
	if _smExists(self.interactable) then
		self.interactable:setUvFrameIndex(0)
	end

	local crg_eff = self.effects[EffectEnum.crg]
	local lit_eff = self.effects[EffectEnum.lit]

	crg_eff:setParameter("rpm", 0)
	crg_eff:stop()

	lit_eff:setParameter("intensity", 0)
	lit_eff:stop()

	self.uv = {}
end

function emp:client_getUvData(data)
	local mode = data[1]

	if mode == EMP_ModeEnum.clr then
		self:client_clearData()
	else
		self.uv.mode = mode

		local crg_eff = self.effects[EffectEnum.crg]
		local lit_eff = self.effects[EffectEnum.lit]

		if not crg_eff:isPlaying() then crg_eff:start() end
		if not lit_eff:isPlaying() then lit_eff:start() end
	end

	if mode ~= EMP_ModeEnum.col then
		self.uv.index = data[2]
	end

	self.uv.rldTime = data[3]
end

function emp:client_getData(effect)
	_cp_spawnOptimizedEffect(self.shape, self.effects[effect], 75)
end