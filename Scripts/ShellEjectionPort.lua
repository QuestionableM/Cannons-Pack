--[[
	Copyright (c) 2021 Cannons Pack Team
	Questionable Mark
]]

if ShellEjector then return end
dofile("Cannons_Pack_libs/ScriptLoader.lua")
ShellEjector = class(GLOBAL_SCRIPT)
ShellEjector.maxParentCount = 1
ShellEjector.maxChildCount = 0
ShellEjector.connectionInput = _connectionType.logic
ShellEjector.connectionOutput = _connectionType.none
ShellEjector.poseWeightCount = 1
ShellEjector.colorNormal = _colorNew(0x8a0038ff)
ShellEjector.colorHighlight = _colorNew(0xff0067ff)

function ShellEjector:client_onCreate()
	self:client_injectScript("BulletShell")
	self.anim = {door_state = false, value = 0.0, speed = 1.5, wait_clock = 0.0}
end

function ShellEjector:server_onCreate()
	local config = _cpCannons_loadCannonInfo(self)
	self.server_effectTable = config.effect_table
	self.projectileConfiguration = config.proj_config
	self.settings_table = config.settings_table
	self.server_shell_queue = {}
end

function ShellEjector:server_onFixedUpdate()
	if not _smExists(self.interactable) then return end

	local parent = self.interactable:getSingleParent()

	if parent then
		local effect_data = self.server_effectTable[tostring(parent.shape.uuid)]
		if effect_data == nil then
			parent:disconnect(self.interactable)
		else
			if self.interactable.active then
				self.interactable:setActive(false)
				self.network:sendToClients("client_changeAnimState")
				_tableInsert(self.server_shell_queue, effect_data)
			end
		end
	end

	if #self.server_shell_queue > 0 and not self.shell_launch_delay and self.anim.value == 1.0 then
		self.shell_launch_delay = 1
		
		local _cur_shell = self.server_shell_queue[1]
		local proj_settings = self.settings_table[_cur_shell]
		self.projectileConfiguration.shellEffect = _cur_shell
		self.projectileConfiguration.collision_size = proj_settings.collision
		self.network:sendToClients("client_changeAnimState")

		BulletShell:server_sendProjectile(self, self.projectileConfiguration)
		_tableRemove(self.server_shell_queue, 1)
	end

	if self.shell_launch_delay then
		self.shell_launch_delay = (self.shell_launch_delay > 1 and self.shell_launch_delay - 1) or nil
	end
end

function ShellEjector:client_onUpdate(dt)
	if not _smExists(self.interactable) then return end

	if self.anim.door_state then
		self.anim.wait_clock = self.anim.wait_clock + dt
		if self.anim.wait_clock >= 2.0 then
			self.anim.door_state = false
			self.anim.wait_clock = 0.0
		end
	end

	local _Changer = self.anim.door_state and self.anim.speed or -self.anim.speed
	local _ChangedValue = _mathMin(_mathMax(self.anim.value + _Changer * dt, 0), 1)

	if _ChangedValue ~= self.anim.value then
		self.anim.value = _ChangedValue
		self.interactable:setPoseWeight(0, self.anim.value)
	end
end

function ShellEjector:client_changeAnimState(data)
	self.anim.door_state = true
	self.anim.wait_clock = 0.0
end