--[[
    Copyright (c) 2021 Cannons Pack Team
    Questionable Mark
]]

if CP_SCRIPTLOADER_SCRIPTS_LOADED then return end
CP_SCRIPTLOADER_SCRIPTS_LOADED = true

print("[CannonsPack] Loading libraries...")

dofile("Additions.lua")
dofile("GlobalScriptHandler.lua")
dofile("Global_Scripts/CPProjectile.lua")
dofile("Global_Scripts/EMPProjectile.lua")
dofile("Global_Scripts/RailgunProjectile.lua")
dofile("Global_Scripts/SmartRocket.lua")
dofile("Global_Scripts/FlareProjectile.lua")
dofile("Global_Scripts/BulletShell.lua")

print("[CannonsPack] Libraries have been successfully loaded!")