--[[
	Copyright (c) 2022 Cannons Pack Team
	Questionable Mark
]]

if CP_SCRIPTLOADER_SCRIPTS_LOADED then return end
CP_SCRIPTLOADER_SCRIPTS_LOADED = true

print("[CannonsPack] Version: 4.87")
print("[CannonsPack] Loading libraries...")

dofile("FunctionReferences.lua")
dofile("Databases/EffectSettings.lua")
dofile("Databases/ProjectileSettings.lua")
dofile("Databases/CannonSettings.lua")
dofile("Additions.lua")
dofile("GlobalScriptHandler.lua")
dofile("Global_Scripts/CPProjectile.lua")
dofile("Global_Scripts/EMPProjectile.lua")
dofile("Global_Scripts/RailgunProjectile.lua")
dofile("Global_Scripts/SmartRocket.lua")
dofile("Global_Scripts/FlareProjectile.lua")
dofile("Global_Scripts/LaserProjectile.lua")

_cpPrint("Libraries have been successfully loaded!")