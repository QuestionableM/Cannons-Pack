--[[
	Copyright (c) 2022 Cannons Pack Team
	Questionable Mark
]]

if CP_FUNCTION_REFERENCES_SCRIPT_LOADED then return end
CP_FUNCTION_REFERENCES_SCRIPT_LOADED = true

_newVec = sm.vec3.new
_vecZero = sm.vec3.zero
_vecOne = sm.vec3.one
_vecLerp = sm.vec3.lerp
_getVec3Rotation = sm.vec3.getRotation

_quatAngleAxis = sm.quat.angleAxis

_createEffect = sm.effect.createEffect
_smExists = sm.exists
_getCamPosition = sm.camera.getPosition
_gunSpread = sm.noise.gunSpread
_shapeFire = sm.projectile.shapeFire
_shapeProjAttack = sm.projectile.shapeProjectileAttack
_applyImpulse = sm.physics.applyImpulse
_audioPlay = sm.audio.play
_displayAlertText = sm.gui.displayAlertText
_createPart = sm.shape.createPart
_quatIdentity = sm.quat.identity
_createParticle = sm.particle.createParticle
_getSphereContacts = sm.physics.getSphereContacts
_logError = sm.log.error
_playEffect = sm.effect.playEffect
_playHostedEffect = sm.effect.playHostedEffect
_physRaycast = sm.physics.raycast
_getCurrentTick = sm.game.getCurrentTick
_octaveNoise = sm.noise.octaveNoise2d
_getItemQualityLevel = sm.item.getQualityLevel
_getShapesInSphere = sm.shape.shapesInSphere
_isItemBlock = sm.item.isBlock
_getLocalPlayer = sm.localPlayer.getPlayer
_getKeyBinding = sm.gui.getKeyBinding
_setInteractionText = sm.gui.setInteractionText
_utilClamp = sm.util.clamp
_colorNew = sm.color.new
_uuidNew = sm.uuid.new
_createDebris = sm.debris.createDebris

_connectionType = sm.interactable.connectionType

_tableInsert = table.insert
_tableRemove = table.remove

_getAllUnits = function() return {} end

local sm_unit = sm.unit
if sm_unit then
	if sm_unit.getAllUnits then
		_getAllUnits = sm_unit.getAllUnits
	elseif sm_unit.HACK_getAllUnits_HACK then
		_getAllUnits = sm_unit.HACK_getAllUnits_HACK
	end
end

_cpPrint = function(...)
	print("[CannonsPack]", ...)
end

---@param obj any
---@return boolean
---@overload fun(obj: nil): false
_cpExists = function(obj)
	if obj == nil then return false end

	local success, output = pcall(_smExists, obj)
	return (success and output == true)
end

_getAllPlayers = sm.player.getAllPlayers
_getAllBodies = sm.body.getAllBodies
_physExplode = sm.physics.explode

_mathMin = math.min
_mathMax = math.max
_mathAbs = math.abs
_mathCeil = math.ceil
_mathFloor = math.floor
_mathSin = math.sin
_mathAsin = math.asin
_mathAtan2 = math.atan2
_mathRandom = math.random
_mathRad = math.rad

_cpPrint("Function References have been loaded!")