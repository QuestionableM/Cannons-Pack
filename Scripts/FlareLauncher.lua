--[[
	Copyright (c) 2021 Cannons Pack Team
	Questionable Mark
]]

if flare then return end
dofile("Cannons_Pack_libs/ScriptLoader.lua")
flare = class(GLOBAL_SCRIPT)
flare.maxParentCount = 1
flare.maxChildCount = 0
flare.connectionInput = _connectionType.logic
flare.connectionOutput = _connectionType.none
flare.colorNormal = _colorNew(0x000396ff)
flare.colorHighlight = _colorNew(0x0004c7ff)

function flare:server_onCreate()
	self.o = {bulPerShot = 6}
	self.projectileConfiguration = _cpCannons_loadCannonInfo(self)
end

local _l_recoil = _newVec(0, 0, -250)
function flare:server_onFixedUpdate()
	if not _smExists(self.interactable) then return end

	local parent = self.interactable:getSingleParent()
	local active = parent and parent.active

	if active and not self.o.reload and self.o.bulPerShot > 0 then
		local rel_time = (self.o.bulPerShot > 1 and 8) or 300

		self.o.reload = _cp_Shoot(self, rel_time, "client_net", "sht", _l_recoil)
		self.o.bulPerShot = self.o.bulPerShot - 1
		self.projectileConfiguration.dir = _cp_calculateSpread(self, 10, 25)

		FlareProjectile:server_sendProjectile(self, self.projectileConfiguration)
	end

	if self.o.reload then
		if self.o.reload == 30 and not active then self.network:sendToClients("client_net", "rld") end
		self.o.reload = (self.o.reload > 1 and self.o.reload - 1) or nil
		self.o.bulPerShot = ((self.o.reload == 1 and self.o.bulPerShot == 0) and 6) or self.o.bulPerShot
	end
end

function flare:client_onCreate()
	self.effects = _cpEffect_cl_loadEffects(self)
	self:client_injectScript("FlareProjectile")
end

function flare:client_net(data)
	_cp_spawnOptimizedEffect(self.shape, self.effects[data], 75)
end