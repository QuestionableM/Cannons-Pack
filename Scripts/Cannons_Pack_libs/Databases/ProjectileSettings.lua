--[[
	Copyright (c) 2022 Cannons Pack Team
	Questionable Mark
]]

ProjEnum =
{
	AircraftCannon       = 1,
	FlakCannon           = 2,
	HowitzerCannon       = 3,
	M1AbramsCannon       = 4,
	NavalCannon          = 5,
	NavalCannon2         = 6,
	RocketLauncher       = 7,
	SchwererGustavCannon = 8,
	TankCannon           = 9,
	TankCannon2          = 10,
	TankCannon3          = 11,
	OrbitalCannon        = 12,
	OrbitalCannonPowShot = 13,
	LaserCannon          = 14,
	EMPCannon            = 15,
	SmartRocketLauncher  = 16,
	Railgun              = 17,
	Railgun2             = 18,
	SmartCannon          = 19,
	SmallSmartCannon     = 20,
	RocketPod01          = 21
}

ShellEjectorEnum =
{
	SmallShell  = 1,
	MediumShell = 2,
	LargeShell  = 3,
	GiantShell  = 4
}

ProjSettingEnum =
{
	localPosition            = 1,
	localVelocity            = 2,
	position                 = 3,
	velocity                 = 4,
	friction                 = 5,
	gravity                  = 6,
	shellEffect              = 7,
	lifetime                 = 8,
	explosionEffect          = 9,
	explosionLevel           = 10,
	explosionRadius          = 11,
	explosionImpulseRadius   = 12,
	explosionImpulseStrength = 13,
	syncEffect               = 14,
	proxFuze                 = 15,
	keep_effect              = 16,
	collision_size           = 17,
	disconnectRadius         = 18,
	player                   = 19,
	mode                     = 20,
	speed                    = 21,
	count                    = 22,
	obstacleAvoidance        = 23
}

local function TranslateSettings(set_table)
	local output_table = {}

	for k, v in pairs(set_table) do
		local trans_key = ProjSettingEnum[k]
		output_table[trans_key] = v
	end

	return output_table
end

local ProjSettings = {
	[ProjEnum.AircraftCannon] = TranslateSettings({
		localPosition = true,			localVelocity = false,
		position = _newVec(0, 0, 0.2),	friction = 0.003,
		gravity = 10,					shellEffect = "AircraftCannon - Shell",
		lifetime = 15,					explosionEffect = ExplEffectEnum.AircraftCannon,
		explosionLevel = 1,				explosionRadius = 0.2,
		explosionImpulseRadius = 5,		explosionImpulseStrength = 900,
		syncEffect = true
	}),
	[ProjEnum.FlakCannon] = TranslateSettings({
		localPosition = true,			localVelocity = false,
		position = _newVec(0, 0, 0.8),	friction = 0.003,
		gravity = 10,					shellEffect = "FlakCannon - Shell",
		lifetime = 30,					explosionEffect = ExplEffectEnum.ExplSmall,
		explosionLevel = 5,				explosionRadius = 0.2,
		explosionImpulseRadius = 10,	explosionImpulseStrength = 5000,
		syncEffect = true
	}),
	[ProjEnum.HowitzerCannon] = TranslateSettings({
		localPosition = true,			localVelocity = false,
		position = _newVec(0, 0, 2.2),	friction = 0.003,
		gravity = 100,					shellEffect = "HowitzerCannon - Shell",
		lifetime = 30,					explosionEffect = ExplEffectEnum.ExplBig2,
		explosionLevel = 6000,			explosionRadius = 3,
		explosionImpulseRadius = 70,	explosionImpulseStrength = 25000,
		syncEffect = true
	}),
	[ProjEnum.M1AbramsCannon] = TranslateSettings({
		localPosition = true,			localVelocity = false,
		position = _newVec(0, 0, 1.3),	friction = 0.005,
		gravity = 10,					shellEffect = "M1AbramsCannon - Shell",
		lifetime = 30,					explosionEffect = ExplEffectEnum.ExplBig,
		explosionLevel = 8,				explosionRadius = 1.2,
		explosionImpulseRadius = 30,	explosionImpulseStrength = 15000,
		syncEffect = true
	}),
	[ProjEnum.NavalCannon] = TranslateSettings({
		localPosition = true,			localVelocity = false,
		position = _newVec(0, 0, 2.1),	friction = 0.005,
		gravity = 25,					shellEffect = "NavalCannon - Shell",
		lifetime = 30,					explosionEffect = ExplEffectEnum.ExplBig2,
		explosionLevel = 10,			explosionRadius = 2,
		explosionImpulseRadius = 60,	explosionImpulseStrength = 17000,
		syncEffect = true
	}),
	[ProjEnum.NavalCannon2] = TranslateSettings({
		localPosition = true,			localVelocity = false,
		position = _newVec(0, 0, 1),	friction = 0.003,
		gravity = 10,					shellEffect = "NavalCannon2 - Shell",
		lifetime = 30,					explosionEffect = ExplEffectEnum.ExplBig,
		explosionLevel = 7,				explosionRadius = 1.3,
		explosionImpulseRadius = 50,	explosionImpulseStrength = 15000,
		syncEffect = true
	}),
	[ProjEnum.RocketLauncher] = TranslateSettings({
		localPosition = true,			localVelocity = false,
		position = _newVec(0, 0, 0.6),	friction = 0.0,
		gravity = 1,					shellEffect = "RocketLauncher - Shell",
		lifetime = 15,					explosionEffect = ExplEffectEnum.ExplBig,
		explosionLevel = 10,			explosionRadius = 0.7,
		explosionImpulseRadius = 30,	explosionImpulseStrength = 8000,
		syncEffect = true,				keep_effect = true
	}),
	[ProjEnum.SchwererGustavCannon] = TranslateSettings({
		localPosition = true,			localVelocity = false,
		position = _newVec(0, 0, 3.5),	friction = 0.003,
		gravity = 40,					shellEffect = "DoraCannon - Shell",
		lifetime = 30,					explosionEffect = ExplEffectEnum.DoraCannon,
		explosionLevel = 15,			explosionRadius = 7,
		explosionImpulseRadius = 180,	explosionImpulseStrength = 25000,
		syncEffect = true
	}),
	[ProjEnum.TankCannon] = TranslateSettings({
		localPosition = true,			localVelocity = false,
		position = _newVec(0, 0, 0.4),	friction = 0.003,
		gravity = 10,					shellEffect = "TankCannon - Shell",
		lifetime = 30,					explosionEffect = ExplEffectEnum.ExplBig,
		explosionLevel = 6,				explosionRadius = 0.7,
		explosionImpulseRadius = 12,	explosionImpulseStrength = 6000,
		syncEffect = true
	}),
	[ProjEnum.TankCannon2] = TranslateSettings({
		localPosition = true,			localVelocity = false,
		position = _newVec(0, 0, 0.4),	friction = 0.003,
		gravity = 10,					shellEffect = "TankCannon - Shell",
		lifetime = 30,					explosionEffect = ExplEffectEnum.ExplBig,
		explosionLevel = 6,				explosionRadius = 0.7,
		explosionImpulseRadius = 12,	explosionImpulseStrength = 6000,
		syncEffect = true
	}),
	[ProjEnum.TankCannon3] = TranslateSettings({
		localPosition = true,			localVelocity = false,
		position = _newVec(0, 0, 1.2),	friction = 0.003,
		gravity = 10,					shellEffect = "M1AbramsCannon - Shell",
		lifetime = 30,					explosionEffect = ExplEffectEnum.ExplBig,
		explosionLevel = 8,				explosionRadius = 1.2,
		explosionImpulseRadius = 15,	explosionImpulseStrength = 10000,
		syncEffect = true
	}),
	[ProjEnum.OrbitalCannon] = TranslateSettings({
		localPosition = false,								localVelocity = false,
		friction = 0.003,									gravity = 15,
		shellEffect = "AircraftCannon - Shell",				lifetime = 30,
		explosionEffect = ExplEffectEnum.OrbitalCannonSmall,explosionLevel = 10,
		explosionRadius = 0.5,								explosionImpulseRadius = 10,
		explosionImpulseStrength = 5000,					syncEffect = true
	}),
	[ProjEnum.OrbitalCannonPowShot] = TranslateSettings({
		localPosition = false,			localVelocity = false,
		velocity = _newVec(0, 0, -250),	friction = 0.003,
		gravity = 15,					shellEffect = "AircraftCannon - Shell",
		lifetime = 30,					explosionEffect = ExplEffectEnum.OrbitalCannon,
		explosionLevel = 99999,			explosionRadius = 7,
		explosionImpulseRadius = 70,	explosionImpulseStrength = 40000,
		syncEffect = true
	}),
	[ProjEnum.LaserCannon] = TranslateSettings({
		position = _newVec(0, 0, 0.6),
		lifetime = 10
	}),
	[ProjEnum.EMPCannon] = TranslateSettings({
		position = _newVec(0, 0, 0),
		disconnectRadius = 1
	}),
	[ProjEnum.SmartRocketLauncher] = TranslateSettings({
		position = _newVec(0, 0, 0.6),
		speed = 100,
		proxFuze = 0,
		obstacleAvoidance = true
	}),
	[ProjEnum.Railgun] = TranslateSettings({
		position = _newVec(0, 0, 1.4),			velocity = _newVec(0, 0, 1000),
		shellEffect = "RailgunCannon - Shell",	explosionEffect = "ExplBig2",
		explosionLevel = 9999,					explosionRadius = 1.5,
		explosionImpulseRadius = 20,			explosionImpulseStrength = 10000,
		count = 5
	}),
	[ProjEnum.Railgun2] = TranslateSettings({
		position = _newVec(0, 0, 1.1),			velocity = _newVec(0, 0, 1000),
		shellEffect = "RailgunCannon - Shell",	explosionEffect = "ExplBig2",
		explosionLevel = 9999,					explosionRadius = 1.9,
		explosionImpulseRadius = 15,			explosionImpulseStrength = 15000,
		count = 7
	}),
	[ProjEnum.SmartCannon] = TranslateSettings({
		localPosition = true,						localVelocity = false,
		position = _newVec(0, 0, 0.1),				velocity = _newVec(0, 0, 0),
		friction = 0.003,							gravity = 10,
		shellEffect = "NumberLogicCannon - Shell",	lifetime = 15,
		explosionLevel = 5,							explosionRadius = 0.5,
		explosionImpulseRadius = 15,				explosionImpulseStrength = 2000,
		explosionEffect = ExplEffectEnum.ExplSmall,	proxFuze = 0,
		syncEffect = true
	}),
	[ProjEnum.SmallSmartCannon] = TranslateSettings({
		localPosition = true,						localVelocity = false,
		position = _newVec(0, 0, 0.1),				velocity = _newVec(0, 0, 0),
		friction = 0.003,							gravity = 10,
		shellEffect = "SmallSmartCannon - Shell",	lifetime = 15,
		explosionLevel = 5,							explosionRadius = 0.5,
		explosionImpulseRadius = 15,				explosionImpulseStrength = 2000,
		explosionEffect = ExplEffectEnum.ExplSmall,	proxFuze = 0,
		syncEffect = true
	}),
	[ProjEnum.RocketPod01] = TranslateSettings({
		localPosition = true,			localVelocity = false,
		position = _newVec(0, 0, 0.6),	friction = 0.0,
		gravity = 3,					shellEffect = "RocketPod01 - RocketProj",
		lifetime = 15,					explosionEffect = ExplEffectEnum.ExplSmall,
		explosionLevel = 10,			explosionRadius = 0.4,
		explosionImpulseRadius = 25,	explosionImpulseStrength = 6000,
		syncEffect = true,				keep_effect = true
	})
}

function _cpProj_GetProjectileSettings(id)
	local cur_settings = ProjSettings[id]

	if cur_settings ~= nil then
		local settings_copy = {}
		for k, v in pairs(cur_settings) do
			settings_copy[k] = v
		end

		return settings_copy
	else
		_cpPrint("Couldn't find any projectile data with an id of", id)
	end
end

function _cpProj_ClearNetworkData(data, id)
	local data_to_send = {}

	local proj_settings = _cpProj_GetProjectileSettings(id)
	if proj_settings then
		for k, v in pairs(data) do
			if proj_settings[k] ~= v then
				data_to_send[k] = v
			end
		end
	else
		data_to_send = data
	end

	return data_to_send
end

function _cpProj_CombineProjectileData(data, id)
	local proj_settings = _cpProj_GetProjectileSettings(id) or {}

	for k, v in pairs(data) do
		proj_settings[k] = v
	end

	return proj_settings
end

_cpPrint("Projectile Settings have been loaded!")