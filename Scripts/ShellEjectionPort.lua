--[[
	Copyright (c) 2025 Cannons Pack Team
	Questionable Mark
]]

if ShellEjector then return end

dofile("Cannons_Pack_libs/ScriptLoader.lua")

---@class ShellEjector : GlobalScriptHandler
ShellEjector = class(GLOBAL_SCRIPT)
ShellEjector.maxParentCount = 1
ShellEjector.maxChildCount  = 0
ShellEjector.connectionInput  = _connectionType.logic
ShellEjector.connectionOutput = _connectionType.none
ShellEjector.poseWeightCount = 1
ShellEjector.colorNormal    = _colorNew(0x8a0038ff)
ShellEjector.colorHighlight = _colorNew(0xff0067ff)

function ShellEjector:client_onCreate()
	self.cl_anim = false
	self.cl_anim_val = 0.0

	self.network:sendToServer("server_requestAnimData")
end

function ShellEjector:server_requestAnimData(data, caller)
	self.network:sendToClient(caller, "client_changeAnimState", self.sv_anim)
end

function ShellEjector:server_onCreate()
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

local proj_id_to_shell_data =
{
	[ShellEjectorEnum.SmallShell ] = { uuid = _uuidNew("c47f3479-9398-41ad-a75b-c4a254a14cff"), offset = 0.25, max_rot = 25 },
	[ShellEjectorEnum.MediumShell] = { uuid = _uuidNew("8d7c3cc8-864b-4ae6-ae3c-859d2fd72027"), offset = 0.25, max_rot = 20 },
	[ShellEjectorEnum.LargeShell ] = { uuid = _uuidNew("850d690c-b4df-48d2-943a-f04b9a57a8b0"), offset = 0.25, max_rot = 10 },
	[ShellEjectorEnum.GiantShell ] = { uuid = _uuidNew("6de55e3e-03ba-4b9c-80be-4fefa1f9a59b"), offset = 0.25, max_rot = 5  }
}

function ShellEjector:client_ejectShell(shell_id, dt)
	local shell_data = proj_id_to_shell_data[shell_id]

	--Calculate the shell rotation
	local angle_axis = _quatAngleAxis(math.rad(90), _newVec(0, 1, 0))
	local final_quat = self.shape.worldRotation * angle_axis

	local shape_velocity = self.shape.velocity
	--Calculate the shell position
	local dt_time = self.cl_delta_time or 0
	local pos_prediction = (shape_velocity * dt_time) * 1.9
	local shell_pos = (self.shape.worldPosition + self.shape.at * shell_data.offset) + pos_prediction

	--Calculate the shell velocity
	local shell_vel_val = math.random(40, 50) / 10
	local shell_vel = (_gunSpread(self.shape.at, 20) * shell_vel_val) + shape_velocity

	local max_rot = shell_data.max_rot
	local angular_vel = _newVec(0, math.random(-max_rot, max_rot), math.random(-max_rot, max_rot))
	local shell_lifetime = math.random(2, 10)

	_createDebris(shell_data.uuid, shell_pos, final_quat, shell_vel, angular_vel, _colorNew(0xffff00ff), shell_lifetime)
end

function ShellEjector:server_TryEjectShell()
	if self.sv_queue_size > 0 and not self.shell_launch_delay and self.cl_anim_val == 1.0 then
		self.shell_launch_delay = 1

		self.network:sendToClients("client_ejectShell", self.sv_shell_queue[1])
		self:server_resetAnimVals(true)

		_tableRemove(self.sv_shell_queue, 1)
		self.sv_queue_size = self.sv_queue_size - 1
	end

	if self.shell_launch_delay then
		self.shell_launch_delay = (self.shell_launch_delay > 1 and self.shell_launch_delay - 1) or nil
	end
end

function ShellEjector:server_updateParent(s_interactable)
	local parent = s_interactable:getSingleParent()
	if parent then
		if parent.type == "scripted" then
			local p_pub_data = parent.publicData
			if p_pub_data then
				local ejected_shell_id = p_pub_data.ejectedShellId
				if ejected_shell_id ~= nil then
					self.sv_cur_eff_data = ejected_shell_id
					return
				end
			end
		end

		parent:disconnect(s_interactable)
	else
		self.sv_cur_eff_data = nil
	end
end

function ShellEjector:server_onFixedUpdate(dt)
	local sInteractable = self.interactable
	if not _smExists(sInteractable) then return end

	self:server_updateParent(sInteractable)

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
	self.cl_delta_time = dt

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