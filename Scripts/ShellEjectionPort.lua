--[[
	Copyright (c) 2022 Cannons Pack Team
	Questionable Mark
]]

if ShellEjector then return end
dofile("Cannons_Pack_libs/ScriptLoader.lua")
ShellEjector = class(GLOBAL_SCRIPT)
ShellEjector.maxParentCount = 1
ShellEjector.maxChildCount  = 0
ShellEjector.connectionInput  = _connectionType.logic
ShellEjector.connectionOutput = _connectionType.none
ShellEjector.poseWeightCount = 1
ShellEjector.colorNormal    = _colorNew(0x8a0038ff)
ShellEjector.colorHighlight = _colorNew(0xff0067ff)

function ShellEjector:client_onCreate()
	self:client_injectScript("BulletShell")

	self.cl_anim = false
	self.cl_anim_val = 0.0

	self.network:sendToServer("server_requestAnimData")
end

function ShellEjector:server_requestAnimData(data, caller)
	self.network:sendToClient(caller, "client_changeAnimState", self.sv_anim)
end

function ShellEjector:server_onCreate()
	local config = _cpCannons_loadCannonInfo(self)
	self.sv_eff_table = config.effect_table

	self.sv_shell_queue = {}
	self.sv_queue_size = 0

	self.sv_anim = false
	self.sv_anim_clock = 0
	self.animStateBool = false

	self.interactable.publicData = {}
end

function ShellEjector:server_resetAnimVals(state)
	self.sv_anim_clock = 0.0
	self.sv_anim = state
end

function ShellEjector:server_updateAnimVals(dt)
	if self.sv_anim then
		self.sv_anim_clock = self.sv_anim_clock + dt

		if self.sv_anim_clock >= 2.0 then
			self:server_resetAnimVals(false)
		end
	end

	if self.animStateBool ~= self.sv_anim then
		self.animStateBool = self.sv_anim

		self.network:sendToClients("client_changeAnimState", self.sv_anim)
	end
end

function ShellEjector:server_TryEjectShell()
	if self.sv_queue_size > 0 and not self.shell_launch_delay and self.cl_anim_val == 1.0 then
		self.shell_launch_delay = 1
		
		local _cur_shell = self.sv_shell_queue[1]
		BulletShell:server_sendProjectile(self, _cur_shell)

		self:server_resetAnimVals(true)

		_tableRemove(self.sv_shell_queue, 1)
		self.sv_queue_size = self.sv_queue_size - 1
	end

	if self.shell_launch_delay then
		self.shell_launch_delay = (self.shell_launch_delay > 1 and self.shell_launch_delay - 1) or nil
	end
end

function ShellEjector:server_onFixedUpdate(dt)
	local sInteractable = self.interactable
	if not _smExists(sInteractable) then return end

	local parent = sInteractable:getSingleParent()
	if self.sv_saved_parent ~= parent then
		self.sv_saved_parent = parent

		if parent then
			self.sv_cur_eff_data = self.sv_eff_table[tostring(parent.shape.uuid)]
			if self.sv_cur_eff_data == nil then
				self.sv_saved_parent = nil
				parent:disconnect(sInteractable)
			end
		else
			self.sv_cur_eff_data = nil
		end
	end

	local s_pub_data = sInteractable.publicData
	if s_pub_data.canShoot and self.sv_cur_eff_data then
		s_pub_data.canShoot = false
		self:server_resetAnimVals(true)

		_tableInsert(self.sv_shell_queue, self.sv_cur_eff_data)
		self.sv_queue_size = self.sv_queue_size + 1
	end

	self:server_updateAnimVals(dt)
	self:server_TryEjectShell()
end

function ShellEjector:client_onUpdate(dt)
	local sInteractable = self.interactable
	if not _smExists(sInteractable) then return end

	local a_Changer = self.cl_anim and 1.5 or -1.5
	local a_ChangedValue = _mathMin(_mathMax(self.cl_anim_val + a_Changer * dt, 0), 1)

	if a_ChangedValue ~= self.cl_anim_val then
		self.cl_anim_val = a_ChangedValue
		sInteractable:setPoseWeight(0, a_ChangedValue)
	end
end

function ShellEjector:client_changeAnimState(state)
	self.cl_anim = state
end