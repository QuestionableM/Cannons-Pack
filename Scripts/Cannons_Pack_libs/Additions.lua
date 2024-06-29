--[[
	Copyright (c) 2022 Cannons Pack Team
	Questionable Mark
]]

if _CP_gScript then return end

---@class GlobalScript : GlobalScriptHandler
---@field m_ref_count integer
---@field sv_last_update integer
---@field cl_last_update integer

---@class ProjectileInstance
---@field effect Effect
---@field alive number
---@field pos Vec3
---@field dir Vec3

---@class GlobalScriptStorage
---@field CPProjectile CPProjectile
---@field EMPProjectile EMPProjectile
---@field FlareProjectile FlareProjectile
---@field LaserProjectile LaserProjectile
---@field RailgunProjectile RailgunProjectile
---@field SmartRocket SmartRocket

---@type GlobalScriptStorage
---@diagnostic disable-next-line
_CP_gScript = {}

---@param interactable Interactable
---@return boolean
function _cp_isLogic(interactable)
	return interactable:getConnectionOutputType() == _connectionType.logic
end

local number_or_logic = bit.bor(_connectionType.logic, _connectionType.power)

---@param interactable Interactable
---@return boolean
function _cp_isNumberLogic(interactable)
	return interactable:getConnectionOutputType() == number_or_logic
end

---@param pos Vec3
---@param dir Vec3
---@param target_pos Vec3
---@param angle number
---@return boolean
function _cp_isObjectVisible(pos, dir, target_pos, angle)
	local target_dir = (target_pos - pos):normalize()
	local dot_value = dir:dot(target_dir) - 1

	return (dot_value > angle)
end

---@param shape Shape
---@param effect table|Effect
---@param renderDistance number
function _cp_spawnOptimizedEffect(shape, effect, renderDistance)
	local render_distance = renderDistance or 40
	local distance = (shape.worldPosition - _getCamPosition()):length()
	
	if distance < render_distance then
		if type(effect) == "table" then
			for k, index in pairs(effect) do index:start() end
		else
			effect:start()
		end
	end
end

---@param self ShapeClass
---@param spread_degree number
---@param velocity number
---@param ignore_momentum? boolean
---@return Vec3
function _cp_calculateSpread(self, spread_degree, velocity, ignore_momentum)
	if ignore_momentum then
		local angle = _gunSpread(self.shape.up, spread_degree)
		return angle * velocity
	else
		local angle = _gunSpread(self.shape.up, spread_degree)
		local linear_velocity = _mathMin(self.shape.up:dot(self.shape.velocity), 0)
		local final_linear_velocity = velocity + _mathAbs(linear_velocity)

		return angle * final_linear_velocity + self.shape.velocity
	end
end

---@param shape Shape
---@param projectile Uuid
---@param damage number
---@param offset Vec3
---@param direction Vec3
---@param ignoreRotation boolean
function _cp_shootProjectile(shape, projectile, damage, offset, direction, ignoreRotation)
	if not ignoreRotation then
		_shapeProjAttack(projectile, damage, offset, direction, shape)
	else
		_shapeProjAttack(projectile, damage, shape:transformPoint(shape.worldPosition + offset), direction, shape)
	end
end

---@param self ShapeClass
---@param reloadTime? integer
---@param callback string
---@param data any
---@param impulse? Vec3
---@return integer|nil
function _cp_Shoot(self, reloadTime, callback, data, impulse)
	if callback then
		self.network:sendToClients(callback, data)
	end

	if impulse then
		_applyImpulse(self.shape, impulse)
	end

	if type(reloadTime) == "number" then
		return reloadTime
	end
end

---@param reload number
---@param auto_reloading boolean
---@param active boolean
---@return number
function _cp_calculateReload(reload, auto_reloading, active)
	local reload_result
	if auto_reloading then
		reload_result = (reload > 1 and reload - 1) or nil
	else
		reload_result = (reload > 1 and reload - 1) or (active and 0 or nil)
	end

	---@cast reload_result number
	return reload_result
end

---@param sound string
---@param globalSound boolean
---@param text string
---@param duration? number
function _cp_infoOutput(sound, globalSound, text, duration)
	_audioPlay(sound, not globalSound and _getCamPosition() or nil)

	if text then
		_displayAlertText(text,duration or 3)
	end
end

---@param position Vec3
---@param expl_level number
---@param expl_radius number
---@param expl_impulse number
---@param expl_magnitude number
---@param effect? string
---@param pushPlayers boolean
function _cpProj_betterExplosion(position, expl_level, expl_radius, expl_impulse, expl_magnitude, effect, pushPlayers)
	_physExplode(position, expl_level, expl_radius, 1, 1, effect)

	local s_Contacts = _getSphereContacts(position, expl_magnitude)
	for k, body in pairs(s_Contacts.bodies) do
		if _cpExists(body) then
			local b_Vector = position - body.worldPosition
			local s_Distance = b_Vector:length()
			if s_Distance < expl_magnitude and body:isDynamic() then
				local imp_dir = b_Vector:normalize()
				local imp_str = _mathMax(expl_impulse * (1 - (s_Distance / expl_magnitude)), 0)

				_applyImpulse(body, -(imp_dir * imp_str), true)
			end
		end
	end

	if not pushPlayers then return end

	for k, char in pairs(s_Contacts.characters) do
		if _cpExists(char) then
			local c_Vector = position - char.worldPosition
			local c_Distance = c_Vector:length()

			if c_Distance < expl_magnitude then
				local imp_dir = c_Vector:normalize()
				local imp_str = _mathMax(expl_impulse * (1 - (c_Distance / expl_magnitude)), 0)

				_applyImpulse(char, -(imp_dir * imp_str) / 10, false)
			end
		end
	end
end

local _cpProj_TPPos = _newVec(0, 0, 10000)

---@param proj_effect Effect
---@param keep_effect? boolean
function _cpProj_cl_onProjHit(proj_effect, keep_effect)
	if proj_effect == nil then return end

	if _smExists(proj_effect) then
		if keep_effect then
			proj_effect:stop()
			proj_effect:setPosition(_cpProj_TPPos)
		else
			proj_effect:stopImmediate()
			proj_effect:destroy()
		end
	end
end

---@param cannon_pos Vec3
---@param proximityFuze number
---@return Player[]
function _cpProj_proxFuzeIgnore(cannon_pos, proximityFuze)
	if cannon_pos == nil or proximityFuze <= 0 then return {} end

	local players_to_ignore = {}
	for k, player in pairs(_getAllPlayers()) do
		local pl_char = player.character
		if _cpExists(pl_char) then
			local distance = (cannon_pos - pl_char.worldPosition):length()

			if distance < proximityFuze then
				_tableInsert(players_to_ignore, player)
			end
		end
	end

	return players_to_ignore
end


---@param proj_table ProjectileInstance[]
---@return integer
function _cpProj_cl_destroyProjectiles(proj_table)
	local deleted_projectiles = 0

	for k, projectile in pairs(proj_table) do
		local proj_effect = projectile.effect

		if _cpExists(proj_effect) then
			proj_effect:setPosition(_cpProj_TPPos)
			proj_effect:stopImmediate()
			proj_effect:destroy()
			deleted_projectiles = deleted_projectiles + 1
		end
	end

	return deleted_projectiles
end

---@param player Player
---@param whitelist? Player[]
function _cpProj_cl_whitelistText(player, whitelist)
	if type(whitelist) ~= "table" then return end

	for i = 0, #whitelist, 1 do
		if whitelist[i] == player then return true end
	end
end

---@param proxFuze number
---@param bulletPos Vec3
---@param whitelist? Player[]
function _cpProj_cl_proxFuze(proxFuze, bulletPos, whitelist)
	if proxFuze <= 0 then return false end

	for k,player in pairs(_getAllPlayers()) do
		local p_Char = player.character
		if _cpExists(p_Char) then
			local distance = (bulletPos - p_Char.worldPosition):length()
			if not _cpProj_cl_whitelistText(player, whitelist) and distance < proxFuze then
				return true
			end
		end
	end
end

---@param flare_table FlareProjectileInstance[]
---@param rocket_pos Vec3
---@param rocket_dir Vec3
function _cpProj_getNearestVisibleFlare(flare_table, rocket_pos, rocket_dir)
	if flare_table == nil then return end

	local ClosestFlare = nil
	local ClosestDistance = math.huge

	for k, flare in pairs(flare_table) do
		local f_Pos = flare.pos
		local isFlareVisible = _cp_isObjectVisible(rocket_pos, rocket_dir, f_Pos, -0.66)
		local flare_dist = (rocket_pos - f_Pos):length()

		if isFlareVisible and ClosestDistance > flare_dist then
			ClosestFlare = f_Pos
			ClosestDistance = flare_dist
		end
	end

	return ClosestFlare
end

---@param flare_table FlareProjectileInstance[]
---@param rocket_pos Vec3
---@param radius number
function _cpProj_killNearestFlares(flare_table, rocket_pos, radius)
	if flare_table == nil then return end

	for k, flare in pairs(flare_table) do
		local distance = (flare.pos - rocket_pos):length()
		if distance < radius then flare_table[k].hit = true end
	end
end

---@param flare_table FlareProjectileInstance[]
---@param rocket_pos Vec3
---@param radius number
function _cpProj_isFlareNear(flare_table, rocket_pos, radius)
	if flare_table == nil then return end

	for k, flare in pairs(flare_table) do
		local distance = (flare.pos - rocket_pos):length()
		if distance < radius then return true end
	end
end

---@param path string
---@return GuiInterface
---@diagnostic disable-next-line
function _cpCreateGui(path) return nil end

if sm.gui then
	local create_layout_func = sm.gui.createGuiFromLayout

	if type(create_layout_func) == "function" then
		_cpGuiSupported = true

		_cpCreateGui = function(path)
			return create_layout_func("$CONTENT_c0344d93-7492-46c8-88be-a61699e57041/Gui/Layouts/"..path, false, { backgroundAlpha = 0.5, hidesHotbar = true })
		end
	end
end

_cpPrint("Additions library has been loaded!")