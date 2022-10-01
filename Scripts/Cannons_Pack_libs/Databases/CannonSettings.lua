--[[
	Copyright (c) 2022 Cannons Pack Team
	Questionable Mark
]]

local port_cp_shell_ejector = "5164495e-b681-4647-b622-031317e6f6b4" --Shell ejector from Cannons Pack
local port_mgp_breech01     = "3d410289-0079-4989-ba21-b211562147d5" --Breech from Machine Guns Pack
local port_mgp_breech02     = "379449f7-27ca-4aea-b723-f841406bbacc" --Breech from Machine Guns Pack
local port_mgp_breech03     = "54b7c549-4b12-4be1-b73d-4d62db371394"

local port_whitelist_normal =
{
	[port_cp_shell_ejector] = true,
	[port_mgp_breech01] = true,
	[port_mgp_breech02] = true,
	[port_mgp_breech03] = true
}

local cannon_settings = {
	["86b45499-9a8f-45ce-b9f9-80b6912fcc06"] = { --AircraftCannon
		server_settings = {
			cannon_config = {
				ejected_shell_id = ShellEjectorEnum.SmallShell,
				port_uuids = port_whitelist_normal,
				impulse_dir = _newVec(0, 0, -1),
				auto_reload = true,
				impulse_str = 700,
				velocity = 700,
				spread = 0.2,
				reload = 8,
				proj_data_id = ProjEnum.AircraftCannon
			}
		},
		client_settings = {
			dot_normal = 0x7fe378ff,
			dot_highlight = 0x8dff85ff,
			effect_distance = 75
		}
	},
	["e442535e-e75e-4079-9acc-9005e5ba0c08"] = {}, --EMPCannon
	["49de462c-2f36-4ad5-802c-c4add235dc53"] = { --FlakCannon
		server_settings = {
			cannon_config = {
				ejected_shell_id = ShellEjectorEnum.MediumShell,
				port_uuids = {
					[port_cp_shell_ejector] = true
				},
				impulse_dir = _newVec(0, 0, -1),
				auto_reload = true,
				impulse_str = 800,
				velocity = 400,
				spread = 0.5,
				reload = 10,
				proj_data_id = ProjEnum.FlakCannon
			}
		},
		client_settings = {
			dot_normal = 0x73a800ff,
			dot_highlight = 0x81bd00ff,
			effect_distance = 75
		}
	},
	["b86bc11c-8922-47c2-b5bc-e184d3378a81"] = {}, --FlareLauncher
	["e8a8a8ce-7b00-4e2b-b417-75e8995a02d8"] = {}, --SmartRocketLauncher
	["bd428d5e-c519-43fe-a75f-76cfddb5b700"] = { --HowitzerCannon
		server_settings = {
			cannon_config = {
				ejected_shell_id = ShellEjectorEnum.LargeShell,
				port_uuids = port_whitelist_normal,
				impulse_dir = _newVec(0, 0, -1),
				auto_reload = false,
				impulse_str = 50000,
				velocity = 400,
				spread = 3,
				reload = 360,
				rld_sound = 190,
				proj_data_id = ProjEnum.HowitzerCannon
			}
		},
		client_settings = {
			dot_normal = 0x000000ff,
			dot_highlight = 0x363636ff,
			effect_distance = 250
		}
	},
	["03e1ecbd-17ee-4045-a5d8-366f6e656555"] = { --M1AbramsCannon
		server_settings = {
			cannon_config = {
				ejected_shell_id = ShellEjectorEnum.LargeShell,
				port_uuids = port_whitelist_normal,
				impulse_dir = _newVec(0, 0, -1),
				auto_reload = false,
				impulse_str = 7000,
				velocity = 450,
				spread = 1.5,
				reload = 280,
				rld_sound = 30,
				proj_data_id = ProjEnum.M1AbramsCannon
			}
		},
		client_settings = {
			dot_normal = 0xcc5200ff,
			dot_highlight = 0xff6700ff,
			effect_distance = 150
		}
	},
	["6c0bbf06-364f-4d51-98c2-1631b2d09cd5"] = { --NavalCannon
		server_settings = {
			cannon_config = {
				ejected_shell_id = ShellEjectorEnum.LargeShell,
				port_uuids = port_whitelist_normal,
				impulse_dir = _newVec(0, 0, -1),
				auto_reload = false,
				impulse_str = 42000,
				velocity = 350,
				spread = 2,
				reload = 400,
				rld_sound = 30,
				proj_data_id = ProjEnum.NavalCannon
			}
		},
		client_settings = {
			dot_normal = 0xd60e00ff,
			dot_highlight = 0xff1100ff,
			effect_distance = 150
		}
	},
	["d0352961-c071-4278-8f23-99fcb8a7a377"] = { --NavalCannon2
		server_settings = {
			cannon_config = {
				ejected_shell_id = ShellEjectorEnum.LargeShell,
				port_uuids = port_whitelist_normal,
				impulse_dir = _newVec(0, 0, -1),
				auto_reload = false,
				impulse_str = 20000,
				velocity = 400,
				spread = 1,
				reload = 320,
				rld_sound = 30,
				proj_data_id = ProjEnum.NavalCannon2
			}
		},
		client_settings = {
			dot_normal = 0xd60e00ff,
			dot_highlight = 0xff1100ff,
			effect_distance = 150
		}
	},
	["35203ea3-8cc8-4ec9-9a26-c62c6eb5544d"] = { --SmartCannon
		ejected_shell_id = ShellEjectorEnum.MediumShell,
		proj_data_id = ProjEnum.SmartCannon,
		port_uuids = port_whitelist_normal
	},
	["fd6130e4-261d-4875-a418-96fe33bb2714"] = { --SmallSmartCannon
		ejected_shell_id = ShellEjectorEnum.SmallShell,
		proj_data_id = ProjEnum.SmallSmartCannon,
		port_uuids = port_whitelist_normal
	},
	["2bcd658f-6344-4e37-9fb5-ced1e2249c7b"] = {}, --OrbitalCannon
	["fac1f66a-a01c-4d8d-a838-e887455c38ae"] = {}, --Railgun
	["75e1e5a3-acc5-48cf-b4c1-bb8795940002"] = {}, --Railgun2
	["04c1c87f-da87-4f5e-8d70-1ca452314728"] = { --RocketLauncher
		server_settings = {
			cannon_config = {
				impulse_dir = _newVec(0, 0, -1),
				auto_reload = true,
				impulse_str = 2625,
				velocity = 200,
				spread = 0.3,
				reload = 120,
				rld_sound = 30,
				no_snd_on_hold = true,
				proj_data_id = ProjEnum.RocketLauncher
			}
		},
		client_settings = {
			dot_normal = 0xebb400ff,
			dot_highlight = 0xffc300ff,
			effect_distance = 75
		}
	},
	["f85af057-f779-4eca-ad1c-58d2828d3404"] = { --SchwererGustavCannon
		server_settings = {
			cannon_config = {
				ejected_shell_id = ShellEjectorEnum.GiantShell,
				port_uuids = {
					[port_cp_shell_ejector] = true
				},
				impulse_dir = _newVec(0, 0, -1),
				auto_reload = false,
				impulse_str = 200000,
				velocity = 250,
				spread = 2,
				reload = 800,
				rld_sound = 190,
				proj_data_id = ProjEnum.SchwererGustavCannon
			}
		},
		client_settings = {
			dot_normal = 0x000000ff,
			dot_highlight = 0x363636ff,
			effect_distance = 300
		}
	},
	["bc8178a9-8a38-4c43-a0d0-8a0f242a59c7"] = { --TankCannon
		server_settings = {
			cannon_config = {
				ejected_shell_id = ShellEjectorEnum.LargeShell,
				port_uuids = {
					[port_cp_shell_ejector] = true
				},
				impulse_dir = _newVec(0, 0, -1),
				auto_reload = false,
				impulse_str = 4000,
				velocity = 400,
				spread = 2,
				reload = 160,
				rld_sound = 30,
				proj_data_id = ProjEnum.TankCannon
			}
		},
		client_settings = {
			dot_normal = 0xd9d900ff,
			dot_highlight = 0xf5f500ff,
			effect_distance = 150
		}
	},
	["4295196d-cbd6-40c6-badc-ff9011208ad5"] = { --TankCannon2
		server_settings = {
			cannon_config = {
				ejected_shell_id = ShellEjectorEnum.LargeShell,
				port_uuids = {
					[port_cp_shell_ejector] = true
				},
				impulse_dir = _newVec(0, 0, -1),
				auto_reload = false,
				impulse_str = 4000,
				velocity = 400,
				spread = 2,
				reload = 160,
				rld_sound = 30,
				proj_data_id = ProjEnum.TankCannon2
			}
		},
		client_settings = {
			dot_normal = 0xd9d900ff,
			dot_highlight = 0xf5f500ff,
			effect_distance = 150
		}
	},
	["388ccd57-1be9-40cc-b96b-69dd16eb4f32"] = { --TankCannon3
		server_settings = {
			cannon_config = {
				ejected_shell_id = ShellEjectorEnum.LargeShell,
				port_uuids = port_whitelist_normal,
				impulse_dir = _newVec(0, 0, -1),
				auto_reload = false,
				impulse_str = 6000,
				velocity = 450,
				spread = 2,
				reload = 280,
				rld_sound = 30,
				proj_data_id = ProjEnum.TankCannon3
			}
		},
		client_settings = {
			dot_normal = 0xcc5200ff,
			dot_highlight = 0xff6700ff,
			effect_distance = 150
		}
	},
	[port_cp_shell_ejector] = {}, --ShellEjector
	["0d30954b-4f81-4e4b-99c6-cbdef5eb6c76"] = { --LaserCannon
		script_type = "LaserProjectile",
		server_settings = {
			cannon_config = {
				impulse_dir = _newVec(0, 0, -1),
				auto_reload = true,
				impulse_str = 200,
				velocity = 250,
				spread = 3,
				reload = 4,
				rld_sound = 30,
				proj_data_id = ProjEnum.LaserCannon
			}
		},
		client_settings = {
			dot_normal = 0xcc5200ff,
			dot_highlight = 0xff6700ff,
			effect_distance = 150
		}
	},
	["0dc868d7-5e01-4183-b3bb-63236595ba36"] = { --RocketPod01
		cannon_config = {
			full_reload_time = 450,
			shoot_delay = 5,
			proj_set_id = ProjEnum.RocketPod01,
			spread = 5,
			velocity = 200
		},
		effect_config = {
			ammo_effect = "RocketPod01 - Rocket",
			shoot_order = { 10, 5, 9, 14, 15, 11, 6, 2, 1, 4, 8, 13, 17, 18, 19, 16, 12, 7, 3 },
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
			}
		}
	},
	["51356e94-23be-488e-af0c-5ef1d0129854"] = { --SmallRocketPod
		cannon_config = {
			full_reload_time = 250,
			shoot_delay = 5,
			proj_set_id = ProjEnum.SmallRocketPod,
			spread = 5,
			velocity = 200
		},
		effect_config = {
			ammo_effect = "SmallRocketPod - Rocket",
			shoot_order = { 4, 1, 2, 5, 7, 6, 3 },
			effect_positions =
			{
				--Row 1
				_newVec(-0.032, -0.054, 0), --1
				_newVec(0.032, -0.054, 0),  --2

				--Row 0
				_newVec(-0.063, 0, 0),      --3
				_newVec(0, 0, 0),           --4
				_newVec(0.063, 0, 0),       --5

				--Row -1
				_newVec(-0.032, 0.054, 0),  --6
				_newVec(0.032, 0.054, 0)    --7
			}
		}
	}
}

function _cpCannons_loadCannonInfo(self)
	local _CSettings = cannon_settings[tostring(self.shape.uuid)]
	if _CSettings then
		local _ConstructedTable = {}
		for k, v in pairs(_CSettings) do _ConstructedTable[k] = v end

		return _ConstructedTable
	else
		_cpPrint(("Cannon \"%s\" doesn't exist in the database!"):format(obj_uuid))
	end
end

function _cpCannons_sv_loadCannonInfo(self)
	local _CSettings = cannon_settings[tostring(self.shape.uuid)]
	if _CSettings and _CSettings.server_settings then
		local _ConstructedTable = {}
		for k, v in pairs(_CSettings.server_settings) do _ConstructedTable[k] = v end
		_ConstructedTable.t_script = _CSettings.script_type or "CPProjectile"

		return _ConstructedTable
	else
		_cpPrint(("Cannon \"%s\" doesn't have any server info!"):format(obj_uuid))
	end
end

function _cpCannons_cl_loadCannonInfo(self)
	local _CSettings = cannon_settings[tostring(self.shape.uuid)]
	if _CSettings and _CSettings.client_settings then
		local _ConstructedTable = {}
		for k, v in pairs(_CSettings.client_settings) do _ConstructedTable[k] = v end
		_ConstructedTable.t_script = _CSettings.script_type or "CPProjectile"

		return _ConstructedTable
	else
		_cpPrint(("Cannon \"%s\" doesn't have any client info!"):format(obj_uuid))
	end
end

_cpPrint("Cannon Settings have been loaded!")