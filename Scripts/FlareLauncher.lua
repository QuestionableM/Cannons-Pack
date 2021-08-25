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
	self.bul_counter = 6
end

function flare:client_onCreate()
	self.effects = _cpEffect_cl_loadEffects(self)
	self:client_injectScript("FlareProjectile")
end

local _l_recoil = _newVec(0, 0, -250)
function flare:server_onFixedUpdate()
	if not _smExists(self.interactable) then return end

	local parent = self.interactable:getSingleParent()
	local active = parent and parent.active

	if active and not self.reload and self.bul_counter > 0 then
		local rel_time = (self.bul_counter > 1 and 8) or 300

		self.reload = _cp_Shoot(self, rel_time, "client_net", EffectEnum.sht, _l_recoil)
		self.bul_counter = self.bul_counter - 1

		FlareProjectile:server_sendProjectile(self, _cp_calculateSpread(self, 10, 25))
	end

	if self.reload then
		if self.reload == 30 and not active then
			self.network:sendToClients("client_net", EffectEnum.rld)
		end

		self.reload = (self.reload > 1 and self.reload - 1) or nil
		self.bul_counter = ((self.reload == 1 and self.bul_counter == 0) and 6) or self.bul_counter
	end
end

function flare:client_net(data)
	_cp_spawnOptimizedEffect(self.shape, self.effects[data], 75)
end