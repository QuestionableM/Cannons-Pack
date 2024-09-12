--[[
	Copyright (c) 2025 Cannons Pack Team
	Questionable Mark
]]

if RocketDetector then return end

dofile("Cannons_Pack_libs/ScriptLoader.lua")

---@class RocketDetector : ShapeClass
RocketDetector = class()
RocketDetector.connectionInput  = _connectionType.logic
RocketDetector.connectionOutput = _connectionType.logic
RocketDetector.maxChildCount  = -1
RocketDetector.maxParentCount = 2
RocketDetector.colorNormal    = _colorNew(0x009130ff)
RocketDetector.colorHighlight = _colorNew(0x00cf44ff)

function RocketDetector:client_onCreate()
	self.nearest_distance = math.huge
	self.client_detectDistance = 300

	self.network:sendToServer("server_getDetectDistance")
end

function RocketDetector:client_receiveDetectDistance(distance)
	self.client_detectDistance = distance
end

function RocketDetector:server_getDetectDistance(data, caller)
	self.network:sendToClient(caller, "client_receiveDetectDistance", self.server_detectDistance)
end

function RocketDetector:server_onCreate()
	self.tick_counter = 0
	self.server_detectDistance = 300
end

local number_or_logic = bit.bor(_connectionType.logic, _connectionType.power)
function RocketDetector:client_getAvailableParentConnectionCount(connectionType)
	if bit.band(connectionType, bit.bnot(number_or_logic)) == 0 then
		return 2 - #self.interactable:getParents(number_or_logic)
	end

	return 0
end

function RocketDetector:server_onFixedUpdate()
	if not _smExists(self.interactable) then return end

	local distance_pulse = false
	local temp_distance = 300

	local p_List = self.interactable:getParents()
	for k, inter in pairs(p_List) do
		local shape_color = tostring(inter.shape.color)
		if _cp_isNumberLogic(inter) then
			local i_Power = inter.power
			if shape_color == "eeeeeeff" and i_Power > 0 then
				temp_distance = i_Power
			end
		else
			if inter.active then distance_pulse = true end
		end
	end

	if temp_distance ~= self.server_detectDistance then
		self.server_detectDistance = temp_distance
		self.network:sendToClients("client_receiveDetectDistance", self.server_detectDistance)
	end

	local d_Distance = self.server_detectDistance

	local norm_dist = _mathMin(self.nearest_distance, d_Distance) / d_Distance
	self.tick_counter = (self.tick_counter + (1 - norm_dist)) % math.pi
	local interval = _mathAbs(_mathSin(self.tick_counter))
	local pu = interval >= 0.5 or norm_dist < 0.2 or not distance_pulse
	self.interactable:setActive(self.nearest_distance <= d_Distance and pu)
end


function RocketDetector:client_onFixedUpdate()
	if not _smExists(self.interactable) then return end

	if SmartRocket and SmartRocket.projectiles then
		self.nearest_distance = math.huge

		local shape_pos = self.shape.worldPosition
		local shape_up = self.shape.up
		for id, s_rocket in pairs(SmartRocket.projectiles) do
			local rocket_pos = s_rocket.pos
			local norm_dir = s_rocket.dir:normalize()

			local rocket_sees_sensor = _cp_isObjectVisible(rocket_pos, norm_dir, shape_pos, -0.66)
			local sensor_sees_rocket = _cp_isObjectVisible(shape_pos, shape_up, rocket_pos, -0.88)

			if rocket_sees_sensor and sensor_sees_rocket then
				local distance = (shape_pos - rocket_pos):length()
				if distance < self.nearest_distance then
					self.nearest_distance = distance
				end
			end
		end

		local f_distance = _mathMin(self.nearest_distance, self.client_detectDistance) / self.client_detectDistance
		self.interactable:setUvFrameIndex(580 - (f_distance * 580))
	end
end