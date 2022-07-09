--[[
	Copyright (c) 2022 Cannons Pack Team
	Questionable Mark
]]

dofile("Cannons_Pack_libs/ScriptLoader.lua")
RocketPod = class(GLOBAL_SCRIPT)
RocketPod.maxParentCount = 1
RocketPod.maxChildCount  = 0
RocketPod.connectionInput  = _connectionType.logic
RocketPod.connectionOutput = _connectionType.none
RocketPod.colorNormal    = _colorNew(0x4ebf61ff)
RocketPod.colorHighlight = _colorNew(0x65fc7eff)

function RocketPod:client_onCreate()
	local rocket_pod_data =
	{
		ammo_effect = "RocketPod01 - Rocket",
		effect_positions =
		{
			--Row 2
			_newVec(-0.087, 0.15, 0),   --1
			_newVec(0, 0.15, 0),        --2
			_newVec(0.087, 0.15, 0),    --3

			--Row 1
			_newVec(-0.132, 0.075, 0),  --4
			_newVec(-0.045, 0.075, 0),  --5
			_newVec(0.045, 0.075, 0),   --6
			_newVec(0.132, 0.075, 0),   --7

			--Row 0
			_newVec(-0.174, 0, 0),      --8
			_newVec(-0.087, 0, 0),      --9
			_newVec(0, 0, 0),           --10
			_newVec(0.087, 0, 0),       --11
			_newVec(0.174, 0, 0),       --12

			--Row -1
			_newVec(-0.132, -0.075, 0), --13
			_newVec(-0.045, -0.075, 0), --14
			_newVec(0.045, -0.075, 0),  --15
			_newVec(0.132, -0.075, 0),  --16

			--Row -2
			_newVec(-0.087, -0.15, 0),  --17
			_newVec(0, -0.15, 0),       --18
			_newVec(0.087, -0.15, 0)    --19
		},
		shoot_order = { 10, 5, 9, 14, 15, 11, 6, 2, 1, 4, 8, 13, 17, 18, 19, 16, 12, 7, 3 }
	}

	self.effects = {}

	local s_interactable = self.interactable
	local eff_scale = sm.vec3.new(0.25, 0.25, 0.25)
	local eff_name = rocket_pod_data.ammo_effect
	local shoot_pos_data = rocket_pod_data.effect_positions

	self.cl_effect_pos_data = {}

	for k, v in ipairs(rocket_pod_data.shoot_order) do
		local shoot_offset = shoot_pos_data[v]

		local cur_effect = _createEffect(eff_name, s_interactable)
		cur_effect:setOffsetPosition(shoot_pos_data[v])
		cur_effect:setScale(eff_scale)
		cur_effect:start()

		_tableInsert(self.effects, cur_effect)
		_tableInsert(self.cl_effect_pos_data, shoot_offset)
	end

	self.cl_effect_count = #self.effects

	self.shoot_effect = _createEffect("RocketLauncher - Shoot", s_interactable)
	self.shoot_fumes = _createEffect("SmartRocketLauncher - Fumes", s_interactable)
end

function RocketPod:client_onFixedUpdate(dt)
	if self.cl_reload_timer then
		self.cl_reload_timer = (self.cl_reload_timer - 1)

		local timer_frac = 1 - (self.cl_reload_timer / self.cl_reload_total)
		local effect_id = math.floor(timer_frac * self.cl_effect_count)
		
		if self.cl_eff_cache ~= effect_id then
			self.cl_eff_cache = effect_id

			if effect_id > 0 then
				self.effects[effect_id]:start()
			end
		end

		if self.cl_reload_timer <= 0 then
			self.cl_reload_timer = nil
			self.cl_reload_total = nil
			self.cl_eff_cache = nil
		end
	end
end

function RocketPod:client_onShoot(id)
	local eff_id = self.cl_effect_count - id + 1

	for i = 1, eff_id do
		local inv_eff_id = self.cl_effect_count - i

		self.effects[inv_eff_id + 1]:stopImmediate()
	end

	local cur_shoot_pos = self.cl_effect_pos_data[id]
	self.shoot_effect:setOffsetPosition(cur_shoot_pos)
	self.shoot_effect:start()

	self.shoot_fumes:start()
	--print(cur_shoot_pos)
	--self.shoot_effect
end

function RocketPod:client_onPodReload(reload_time)
	self.cl_reload_total = reload_time
	self.cl_reload_timer = reload_time

	for k, v in ipairs(self.effects) do
		if v:isPlaying() then
			v:stopImmediate()
		end
	end
end

function RocketPod:server_onCreate()
	self.sv_ammo_capacity = 19
	self.sv_ammo_counter = self.sv_ammo_capacity
end

function RocketPod:server_onFixedUpdate(dt)
	local s_inter = self.interactable
	if not sm.exists(s_inter) then return end

	local parent = s_inter:getSingleParent()
	local active = parent and parent.active

	if active and not self.reload then
		if self.sv_ammo_counter == 1 then
			self.reload = 30
		else
			self.reload = 5
		end

		self.network:sendToClients("client_onShoot", self.sv_ammo_counter)
		self.sv_ammo_counter = self.sv_ammo_counter - 1
	end

	if self.reload then
		self.reload = (self.reload > 1 and self.reload - 1) or nil

		if self.sv_ammo_counter == 0 and self.reload == nil then
			self.reload = 300
			self.sv_ammo_counter = self.sv_ammo_capacity
			self.network:sendToClients("client_onPodReload", self.reload)
		end
	end
end