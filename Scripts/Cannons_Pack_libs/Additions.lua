--[[
    Copyright (c) 2021 Cannons Pack Team
    Questionable Mark
]]

if (CP and CP_Cannons and CP_Projectile and CP_GUI) then return end

CP_Cannons = class()

local cannon_settings = {
    ["86b45499-9a8f-45ce-b9f9-80b6912fcc06"] = { --AircraftCannon
        server_settings = {
            proj_config = {
                localPosition = true,                   localVelocity = false,
                position = sm.vec3.new(0, 0, 0.2),      velocity = sm.vec3.new(0, 0, 700),
                rotationAxis = sm.vec3.new(1, 0, 0),    friction = 0.003,
                gravity = 10,                           shellEffect = "AircraftCannon - Shell",
                lifetime = 15,                          explosionEffect = "AircraftCannon - Explosion",
                explosionLevel = 1,                     explosionRadius = 0.2,
                explosionImpulseRadius = 5,             explosionImpulseStrength = 900,
                syncEffect = true
            },
            cannon_config = {
                port_uuid = "5164495e-b681-4647-b622-031317e6f6b4",
                impulse_dir = sm.vec3.new(0, 0, -1),
                auto_reload = true,
                impulse_str = 700,
                velocity = 700,
                spread = 0.2,
                reload = 8
            }
        },
        client_settings = {
            dot_normal = 0x7fe378ff,
            dot_highlight = 0x8dff85ff,
            effect_distance = 75
        }
    },
    ["e442535e-e75e-4079-9acc-9005e5ba0c08"] = { --EMPCannon
        position = sm.vec3.new(0, 0, 0),
        velocity = sm.vec3.new(0, 0, 0),
        disconnectRadius = 1
    },
    ["49de462c-2f36-4ad5-802c-c4add235dc53"] = { --FlakCannon
        server_settings = {
            proj_config = {
                localPosition = true,                   localVelocity = false,
                position = sm.vec3.new(0, 0, 0.8),      velocity = sm.vec3.new(0, 0, 400),
                rotationAxis = sm.vec3.new(1, 0, 0),    friction = 0.003,
                gravity = 10,                           shellEffect = "FlakCannon - Shell",
                lifetime = 30,                          explosionEffect = "ExplSmall",
                explosionLevel = 5,                     explosionRadius = 0.2,
                explosionImpulseRadius = 10,            explosionImpulseStrength = 5000,
                syncEffect = true
            },
            cannon_config = {
                port_uuid = "5164495e-b681-4647-b622-031317e6f6b4",
                impulse_dir = sm.vec3.new(0, 0, -1),
                auto_reload = true,
                impulse_str = 800,
                velocity = 400,
                spread = 0.5,
                reload = 10
            }
        },
        client_settings = {
            dot_normal = 0x73a800ff,
            dot_highlight = 0x81bd00ff,
            effect_distance = 75
        }
    },
    ["b86bc11c-8922-47c2-b5bc-e184d3378a81"] = { --FlareLauncher
        dir = sm.vec3.new(0, 0, 25),
        lifetime = 5
    },
    ["e8a8a8ce-7b00-4e2b-b417-75e8995a02d8"] = { --SmartRocketLauncher
        position = sm.vec3.new(0, 0, 0.7),
        rocketSettings = {mode = "seek", player = nil},
        velocity = 100,
        proxFuze = 0
    },
    ["bd428d5e-c519-43fe-a75f-76cfddb5b700"] = { --HowitzerCannon
        server_settings = {
            proj_config = {
                localPosition = true,                   localVelocity = false,
                position = sm.vec3.new(0, 0, 2.2),      velocity = sm.vec3.new(0, 0, 400),
                rotationAxis = sm.vec3.new(1, 0, 0),    friction = 0.003,
                gravity = 100,                          shellEffect = "HowitzerCannon - Shell",
                lifetime = 30,                          explosionEffect = "ExplBig2",
                explosionLevel = 6000,                  explosionRadius = 3,
                explosionImpulseRadius = 70,            explosionImpulseStrength = 25000,
                syncEffect = true
            },
            cannon_config = {
                port_uuid = "5164495e-b681-4647-b622-031317e6f6b4",
                impulse_dir = sm.vec3.new(0, 0, -1),
                auto_reload = false,
                impulse_str = 50000,
                velocity = 400,
                spread = 3,
                reload = 360,
                rld_sound = 190
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
            proj_config = {
                localPosition = true,                   localVelocity = false,
                position = sm.vec3.new(0, 0, 1.3),      velocity = sm.vec3.new(0, 0, 400),
                rotationAxis = sm.vec3.new(1, 0, 0),    friction = 0.005,
                gravity = 10,                           shellEffect = "M1AbramsCannon - Shell",
                lifetime = 30,                          explosionEffect = "ExplBig",
                explosionLevel = 8,                     explosionRadius = 1.2,
                explosionImpulseRadius = 30,            explosionImpulseStrength = 15000,
                syncEffect = true
            },
            cannon_config = {
                port_uuid = "5164495e-b681-4647-b622-031317e6f6b4",
                impulse_dir = sm.vec3.new(0, 0, -1),
                auto_reload = false,
                impulse_str = 7000,
                velocity = 450,
                spread = 1.5,
                reload = 280,
                rld_sound = 30
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
            proj_config = {
                localPosition = true,                   localVelocity = false,
                position = sm.vec3.new(0, 0, 2.1),      velocity = sm.vec3.new(0, 0, 350),
                rotationAxis = sm.vec3.new(1, 0, 0),    friction = 0.005,
                gravity = 25,                           shellEffect = "NavalCannon - Shell",
                lifetime = 30,                          explosionEffect = "ExplBig2",
                explosionLevel = 10,                    explosionRadius = 2,
                explosionImpulseRadius = 60,            explosionImpulseStrength = 17000,
                syncEffect = true
            },
            cannon_config = {
                port_uuid = "5164495e-b681-4647-b622-031317e6f6b4",
                impulse_dir = sm.vec3.new(0, 0, -1),
                auto_reload = false,
                impulse_str = 42000,
                velocity = 350,
                spread = 2,
                reload = 400,
                rld_sound = 30
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
            proj_config = {
                localPosition = true,                   localVelocity = false,
                position = sm.vec3.new(0, 0, 1),        velocity = sm.vec3.new(0, 0, 400),
                rotationAxis = sm.vec3.new(1, 0, 0),    friction = 0.003,
                gravity = 10,                           shellEffect = "NavalCannon2 - Shell",
                lifetime = 30,                          explosionEffect = "ExplBig",
                explosionLevel = 7,                     explosionRadius = 1.3,
                explosionImpulseRadius = 50,            explosionImpulseStrength = 15000,
                syncEffect = true
            },
            cannon_config = {
                port_uuid = "5164495e-b681-4647-b622-031317e6f6b4",
                impulse_dir = sm.vec3.new(0, 0, -1),
                auto_reload = false,
                impulse_str = 20000,
                velocity = 400,
                spread = 1,
                reload = 320,
                rld_sound = 30
            }
        },
        client_settings = {
            dot_normal = 0xd60e00ff,
            dot_highlight = 0xff1100ff,
            effect_distance = 150
        }
    },
    ["35203ea3-8cc8-4ec9-9a26-c62c6eb5544d"] = { --SmartCannon
        localPosition = true,                   localVelocity = false,
        position = sm.vec3.new(0, 0, 0),        velocity = sm.vec3.new(0, 0, 0),
        rotationAxis = sm.vec3.new(1, 0, 0),    friction = 0.0,
        gravity = 0,                            shellEffect = "NumberLogicCannon - Shell",
        lifetime = 0,                           explosionLevel = 0,
        explosionRadius = 0,                    explosionImpulseRadius = 0,
        explosionImpulseStrength = 0,           explosionEffect = "ExplSmall",
        proxFuze = 0,                           syncEffect = true,
        proj_types = {
            [1] = "potato",     [2] = "smallpotato", [3] = "fries",
            [4] = "tomato",     [5] = "carrot",      [6] = "redbeet",
            [7] = "broccoli",   [8] = "pineapple",   [9] = "orange",
            [10] = "blueberry", [11] = "banana",     [12] = "tape",
            [13] = "water",     [14] = "fertilizer", [15] = "chemical",
            [16] = "pesticide", [17] = "seed"
        }
    },
    ["fd6130e4-261d-4875-a418-96fe33bb2714"] = { --SmallSmartCannon
        localPosition = true,                   localVelocity = false,
        position = sm.vec3.new(0, 0, 0),        velocity = sm.vec3.new(0, 0, 0),
        rotationAxis = sm.vec3.new(1, 0, 0),    friction = 0.0,
        gravity = 0,                            shellEffect = "SmallSmartCannon - Shell",
        lifetime = 0,                           explosionLevel = 0,
        explosionRadius = 0,                    explosionImpulseRadius = 0,
        explosionImpulseStrength = 0,           explosionEffect = "ExplSmall",
        proxFuze = 0,                           syncEffect = true,
        proj_types = {
            [1] = "potato",     [2] = "smallpotato", [3] = "fries",
            [4] = "tomato",     [5] = "carrot",      [6] = "redbeet",
            [7] = "broccoli",   [8] = "pineapple",   [9] = "orange",
            [10] = "blueberry", [11] = "banana",     [12] = "tape",
            [13] = "water",     [14] = "fertilizer", [15] = "chemical",
            [16] = "pesticide", [17] = "seed"
        }
    },
    ["2bcd658f-6344-4e37-9fb5-ced1e2249c7b"] = { --OrbitalCannon
        localPosition = false,                  localVelocity = false,
        position = sm.vec3.new(0, 0, 0),        velocity = sm.vec3.new(0, 0, 0),
        rotationAxis = sm.vec3.new(1, 0, 0),    friction = 0.003,
        gravity = 15,                           shellEffect = "AircraftCannon - Shell",
        lifetime = 30,                          explosionEffect = "ExplSmall",
        explosionLevel = 10,                    explosionRadius = 0.5,
        explosionImpulseRadius = 10,            explosionImpulseStrength = 50,
        syncEffect = true
    },
    ["fac1f66a-a01c-4d8d-a838-e887455c38ae"] = { --Railgun
        position = sm.vec3.new(0, 0, 1.4),      velocity = sm.vec3.new(0, 0, 1000),
        shellEffect = "RailgunCannon - Shell",  explosionEffect = "ExplBig2",
        explosionLevel = 9999,                  explosionRadius = 1.5,
        explosionImpulseRadius = 20,            explosionImpulseStrength = 10000,
        count = 5
    },
    ["75e1e5a3-acc5-48cf-b4c1-bb8795940002"] = { --Railgun2
        position = sm.vec3.new(0, 0, 1.1),      velocity = sm.vec3.new(0, 0, 1000),
        shellEffect = "RailgunCannon - Shell",  explosionEffect = "ExplBig2",
        explosionLevel = 9999,                  explosionRadius = 1.9,
        explosionImpulseRadius = 15,            explosionImpulseStrength = 15000,
        count = 7
    },
    ["04c1c87f-da87-4f5e-8d70-1ca452314728"] = { --RocketLauncher
        server_settings = {
            proj_config = {
                localPosition = true,                   localVelocity = false,
                position = sm.vec3.new(0, 0, 0.6),      velocity = sm.vec3.new(0, 0, 105),
                rotationAxis = sm.vec3.new(1, 0, 0),    friction = 0.0,
                gravity = 1,                            shellEffect = "RocketLauncher - Shell",
                lifetime = 15,                          explosionEffect = "ExplBig",
                explosionLevel = 10,                    explosionRadius = 0.7,
                explosionImpulseRadius = 30,            explosionImpulseStrength = 8000,
                syncEffect = true,                      keep_effect = true
            },
            cannon_config = {
                port_uuid = nil,
                impulse_dir = sm.vec3.new(0, 0, -1),
                auto_reload = true,
                impulse_str = 2625,
                velocity = 200,
                spread = 0.3,
                reload = 120,
                rld_sound = 30,
                no_snd_on_hold = true
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
            proj_config = {
                localPosition = true,                   localVelocity = false,
                position = sm.vec3.new(0, 0, 3.5),      velocity = sm.vec3.new(0, 0, 250),
                rotationAxis = sm.vec3.new(1, 0, 0),    friction = 0.003,
                gravity = 40,                           shellEffect = "DoraCannon - Shell",
                lifetime = 30,                          explosionEffect = "DoraCannon - Explosion",
                explosionLevel = 15,                    explosionRadius = 7,
                explosionImpulseRadius = 180,           explosionImpulseStrength = 25000,
                syncEffect = true
            },
            cannon_config = {
                port_uuid = "5164495e-b681-4647-b622-031317e6f6b4",
                impulse_dir = sm.vec3.new(0, 0, -1),
                auto_reload = false,
                impulse_str = 200000,
                velocity = 250,
                spread = 2,
                reload = 800,
                rld_sound = 190
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
            proj_config = {
                localPosition = true,                   localVelocity = false,
                position = sm.vec3.new(0, 0, 0.4),      velocity = sm.vec3.new(0, 0, 400),
                rotationAxis = sm.vec3.new(1, 0, 0),    friction = 0.003,
                gravity = 10,                           shellEffect = "TankCannon - Shell",
                lifetime = 30,                          explosionEffect = "ExplBig",
                explosionLevel = 6,                     explosionRadius = 0.7,
                explosionImpulseRadius = 12,            explosionImpulseStrength = 6000,
                syncEffect = true
            },
            cannon_config = {
                port_uuid = "5164495e-b681-4647-b622-031317e6f6b4",
                impulse_dir = sm.vec3.new(0, 0, -1),
                auto_reload = false,
                impulse_str = 4000,
                velocity = 400,
                spread = 2,
                reload = 160,
                rld_sound = 30
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
            proj_config = {
                localPosition = true,                   localVelocity = false,
                position = sm.vec3.new(0, 0, 0.4),      velocity = sm.vec3.new(0, 0, 400),
                rotationAxis = sm.vec3.new(1, 0, 0),    friction = 0.003,
                gravity = 10,                           shellEffect = "TankCannon - Shell",
                lifetime = 30,                          explosionEffect = "ExplBig",
                explosionLevel = 6,                     explosionRadius = 0.7,
                explosionImpulseRadius = 12,            explosionImpulseStrength = 6000,
                syncEffect = true
            },
            cannon_config = {
                port_uuid = "5164495e-b681-4647-b622-031317e6f6b4",
                impulse_dir = sm.vec3.new(0, 0, -1),
                auto_reload = false,
                impulse_str = 4000,
                velocity = 400,
                spread = 2,
                reload = 160,
                rld_sound = 30
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
            proj_config = {
                localPosition = true,                   localVelocity = false,
                position = sm.vec3.new(0, 0, 1.2),      velocity = sm.vec3.new(0, 0, 400),
                rotationAxis = sm.vec3.new(1, 0, 0),    friction = 0.003,
                gravity = 10,                           shellEffect = "M1AbramsCannon - Shell",
                lifetime = 30,                          explosionEffect = "ExplBig",
                explosionLevel = 8,                     explosionRadius = 1.2,
                explosionImpulseRadius = 15,            explosionImpulseStrength = 10000,
                syncEffect = true
            },
            cannon_config = {
                port_uuid = "5164495e-b681-4647-b622-031317e6f6b4",
                impulse_dir = sm.vec3.new(0, 0, -1),
                auto_reload = false,
                impulse_str = 6000,
                velocity = 450,
                spread = 2,
                reload = 280,
                rld_sound = 30
            }
        },
        client_settings = {
            dot_normal = 0xcc5200ff,
            dot_highlight = 0xff6700ff,
            effect_distance = 150
        }
    },
    ["5164495e-b681-4647-b622-031317e6f6b4"] = { --ShellEjector
        proj_config = {
            position = sm.vec3.new(0, 0.15, 0),     velocity = sm.vec3.new(0, 0, 7),
            friction = 0.007,                       gravity = 10,
            shellEffect = "AircraftCannon - Case",  lifetime = 8,
            collision_size = 2
        },
        effect_table = {
            ["86b45499-9a8f-45ce-b9f9-80b6912fcc06"] = "AircraftCannon - Case", --AircraftCannon
            ["35203ea3-8cc8-4ec9-9a26-c62c6eb5544d"] = "AircraftCannon - Case", --SmartCannon
            ["fd6130e4-261d-4875-a418-96fe33bb2714"] = "AircraftCannon - Case", --SmallSmartCannon
            ["49de462c-2f36-4ad5-802c-c4add235dc53"] = "AircraftCannon - Case", --FlakCannon
            ["bd428d5e-c519-43fe-a75f-76cfddb5b700"] = "BigCannonCase", --HowitzerCannon
            ["bc8178a9-8a38-4c43-a0d0-8a0f242a59c7"] = "BigCannonCase", --TankCannon
            ["4295196d-cbd6-40c6-badc-ff9011208ad5"] = "BigCannonCase", --TankCannon2
            ["388ccd57-1be9-40cc-b96b-69dd16eb4f32"] = "BigCannonCase", --TankCannon3
            ["03e1ecbd-17ee-4045-a5d8-366f6e656555"] = "BigCannonCase", --M1AbramsCannon
            ["6c0bbf06-364f-4d51-98c2-1631b2d09cd5"] = "BigCannonCase", --NavalCannon
            ["d0352961-c071-4278-8f23-99fcb8a7a377"] = "BigCannonCase", --NavalCannon2
            ["f85af057-f779-4eca-ad1c-58d2828d3404"] = "GiantCannonCase" --SchwererGustavCannon
        },
        settings_table = {
            ["GiantCannonCase"] = {collision = 8},
            ["BigCannonCase"] = {collision = 4},
            ["AircraftCannon - Case"] = {collision = 2}
        }
    },
    ["0d30954b-4f81-4e4b-99c6-cbdef5eb6c76"] = { --LaserCannon
        script_type = "LaserProjectile",
        server_settings = {
            proj_config = {
                position = sm.vec3.new(0, 0, 0.6),
                velocity = sm.vec3.new(0, 0, 250),
                shellEffect = "LaserCannon - Shell",
                lifetime = 10
            },
            cannon_config = {
                impulse_dir = sm.vec3.new(0, 0, -1),
                auto_reload = true,
                impulse_str = 6000,
                velocity = 250,
                spread = 3,
                reload = 4,
                rld_sound = 30
            }
        },
        client_settings = {
            dot_normal = 0xcc5200ff,
            dot_highlight = 0xff6700ff,
            effect_distance = 150
        }
    }
}

function CP_Cannons.load_cannon_info(self)
    if self.shape.uuid == nil then return end
    local _CSettings = cannon_settings[tostring(self.shape.uuid)]

    if _CSettings then
        local _ConstructedTable = {}
        for k, v in pairs(_CSettings) do _ConstructedTable[k] = v end

        return _ConstructedTable
    else
        CP.print(("Cannon \"%s\" doesn't exist in the database!"):format(obj_uuid))
    end
end

function CP_Cannons.server_load_CannonInfo(self)
    if self.shape.uuid == nil then return end
    local _CSettings = cannon_settings[tostring(self.shape.uuid)]

    if _CSettings and _CSettings.server_settings then
        local _ConstructedTable = {}
        for k, v in pairs(_CSettings.server_settings) do _ConstructedTable[k] = v end
        _ConstructedTable.t_script = _CSettings.script_type or "CPProjectile"

        return _ConstructedTable
    else
        CP.print(("Cannon \"%s\" doesn't have any server info!"):format(obj_uuid))
    end
end

function CP_Cannons.client_load_CannonInfo(self)
    if self.shape.uuid == nil then return end
    local _CSettings = cannon_settings[tostring(self.shape.uuid)]

    if _CSettings and _CSettings.client_settings then
        local _ConstructedTable = {}
        for k, v in pairs(_CSettings.client_settings) do _ConstructedTable[k] = v end
        _ConstructedTable.t_script = _CSettings.script_type or "CPProjectile"

        return _ConstructedTable
    else
        CP.print(("Cannon \"%s\" doesn't have any client info!"):format(obj_uuid))
    end
end

CP_Effects = class()

local cannon_effects = {
    ["86b45499-9a8f-45ce-b9f9-80b6912fcc06"] = {sht = "AircraftCannon - Shoot"}, --AircraftCannon
    ["49de462c-2f36-4ad5-802c-c4add235dc53"] = {sht = "FlakCannon - Shoot"}, --FlakCannon
    ["bc8178a9-8a38-4c43-a0d0-8a0f242a59c7"] = {sht = "TankCannon - Shoot", rld = "Reloading"}, --TankCannon
    ["4295196d-cbd6-40c6-badc-ff9011208ad5"] = {sht = "TankCannon - Shoot", rld = "Reloading"}, --TankCannon2
    ["04c1c87f-da87-4f5e-8d70-1ca452314728"] = {sht = "RocketLauncher - Shoot", rld = "Reloading"}, --RocketLauncher
    ["e8a8a8ce-7b00-4e2b-b417-75e8995a02d8"] = {rld = "Reloading", sht = "RocketLauncher2 - Shoot", fms = "SmartRocketLauncher - Fumes"}, --SmartRocketLauncher
    ["388ccd57-1be9-40cc-b96b-69dd16eb4f32"] = {sht = "TankCannon3 - Shoot", rld = "Reloading"}, --TankCannon3
    ["03e1ecbd-17ee-4045-a5d8-366f6e656555"] = {sht = "M1AbramsCannon - Shoot", rld = "Reloading"}, --M1AbramsCannon
    ["6c0bbf06-364f-4d51-98c2-1631b2d09cd5"] = {sht = "NavalCannon - Shoot", rld = "Reloading"}, --NavalCannon
    ["d0352961-c071-4278-8f23-99fcb8a7a377"] = {sht = "NavalCannon2 - Shoot", rld = "Reloading"}, --NavalCannon2
    ["fac1f66a-a01c-4d8d-a838-e887455c38ae"] = {eff = "Railgun - Charge", sht = "Railgun - Shoot", sht2 = "Railgun - Shoot2", rld = "Reloading"}, --Railgun
    ["75e1e5a3-acc5-48cf-b4c1-bb8795940002"] = {eff = "Railgun2 - Charge", sht = "Railgun2Cannon - Shoot", rld = "Reloading"}, --Railgun2
    ["e442535e-e75e-4079-9acc-9005e5ba0c08"] = {sht = "EMPCannon - Shoot", rld = "Reloading", crg = "EMPCannon - Charge", lit = "EMPCannon - Light"}, --EMPCannon
    ["bd428d5e-c519-43fe-a75f-76cfddb5b700"] = {sht = "HowitzerCannon - Shoot", rld = "HeavyReloading"}, --HowitzerCannon
    ["f85af057-f779-4eca-ad1c-58d2828d3404"] = {sht = "DoraCannon - Shoot", rld = "HeavyReloading"}, --SchwererGustavCannon
    ["fd6130e4-261d-4875-a418-96fe33bb2714"] = {rld = "Reloading", sht_snd = "NumberLogicCannon - Shoot", sht = "SmartCannon - MuzzleFlash1"}, --SmallSmartCannon
    ["35203ea3-8cc8-4ec9-9a26-c62c6eb5544d"] = {rld = "Reloading", sht_snd = "NumberLogicCannon - Shoot", sht = "SmartCannon - MuzzleFlash1"}, --SmartCannon
    ["2bcd658f-6344-4e37-9fb5-ced1e2249c7b"] = {rld = "Reloading", pnt = "OrbitalCannon - Point", err = "OrbitalCannon - Error"}, --OrbitalCannon
    ["b86bc11c-8922-47c2-b5bc-e184d3378a81"] = {sht = "FlareCannon - Shoot", rld = "Reloading"}, --FlareLauncher
    ["0d30954b-4f81-4e4b-99c6-cbdef5eb6c76"] = {sht = "LaserCannon - Shoot"}
}

function CP_Effects.client_loadEffect(self)
    if self.shape.uuid == nil then return end
    local obj_uuid = tostring(self.shape.uuid)
    local obj_effects = cannon_effects[obj_uuid]
    if obj_effects ~= nil then
        if type(obj_effects) == "table" then
            local effect_set = {}
            for id, effect in pairs(obj_effects) do
                local success, eff = pcall(sm.effect.createEffect, effect, self.interactable)
                if success then
                    effect_set[id] = eff
                else
                    CP.print("Couldn't load an effect. Error message: "..eff)
                end
            end
            return effect_set
        else
            local success, eff = pcall(sm.effect.createEffect, effect, self.interactable)
            if success then
                return eff
            else
                CP.print("Couldn't load an effect. Error message: "..eff)
            end
        end
    else
        CP.print(("A set of effects for object \"%s\" doesn't exist!"):format(self.shape.uuid))
    end
end

if not CP then
    CP = class()
    CP.g_script = {}
end

function CP.print(...) print("[CannonsPack]", ...) end

local _pi = math.pi
local _2pi = math.pi * 2
local _Atan2 = math.atan2
local _Asin = math.asin
function CP.isObjectVisible(v1, v1Pred, v2, LimiterXY, LimiterZ)
    local NormalizedObjectPos = (v1 - v1Pred):normalize()
    local NormalizedTargetPos = (v1 - v2):normalize()
    local ObjectXYAngle = _Atan2(NormalizedObjectPos.y, NormalizedObjectPos.x)
    local TargetXYAngle = _Atan2(NormalizedTargetPos.y, NormalizedTargetPos.x)
    local AngleXY = ObjectXYAngle - TargetXYAngle
    AngleXY = (AngleXY > _pi and AngleXY - _2pi) or (AngleXY < -_pi and AngleXY + _2pi) or AngleXY
    local ObjectZAngle = _Asin(NormalizedObjectPos.z)
    local TargetZAngle = _Asin(NormalizedTargetPos.z)
    local AngleZ = ObjectZAngle - TargetZAngle
    local isVisible = (AngleXY < LimiterXY and AngleXY > -LimiterXY and AngleZ < LimiterZ and AngleZ > -LimiterZ)
    return isVisible
end

function CP.exists(object)
    if object then
        local success, error = pcall(sm.exists, object)
        if (success and type(error) == "boolean" and error == true) then return true end
    end
    return false
end

function CP.spawn_optimized_effect(shape, effect, renderDistance)
    local render_distance = renderDistance or 40
    local distance = (shape.worldPosition - sm.camera.getPosition()):length()
    
    if distance < render_distance then
        if type(effect) == "table" then
            for k, index in pairs(effect) do index:start() end
        else
            effect:start()
        end
    end
end

function CP.calculate_spread(self, spread_degree, velocity, ignore_momentum)
    if ignore_momentum then
        local angle = sm.noise.gunSpread(self.shape.up, spread_degree)
        return angle * velocity
    else
        local angle = sm.noise.gunSpread(self.shape.up, spread_degree)
        local linear_velocity = math.min(self.shape.up:dot(self.shape.velocity), 0)
        local final_linear_velocity = velocity + math.abs(linear_velocity)

        return angle * final_linear_velocity + self.shape.velocity
    end
end

local _ShapeFire = sm.projectile.shapeFire
function CP.shoot_projectile(shape, projectile, offset, direction, ignoreRotation)
    if not ignoreRotation then
        _ShapeFire(shape, projectile, offset, direction)
    else
        _ShapeFire(shape, projectile, shape:transformPoint(shape.worldPosition + offset), direction)
    end
end

function CP.shoot(self, reloadTime, callBackName, data, impulse)
    self.network:sendToClients(callBackName, data)

    if impulse then sm.physics.applyImpulse(self.shape, impulse) end

    if type(reloadTime) == "number" then return reloadTime end
end

function CP.Shoot(self, reloadTime, callback, data, impulse_dir, impulse_str)
    if callback then self.network:sendToClients(callback, data) end

    if impulse_dir and impulse_str then
        local impulse = impulse_dir * impulse_str
        sm.physics.applyImpulse(self.shape, impulse)
    end

    if type(reloadTime) == "number" then return reloadTime end
end

function CP.calculate_reload(reload, auto_reloading, active)
    local reload_result = nil
    if auto_reloading then
        reload_result = (reload > 1 and reload - 1) or nil
    else
        reload_result = (reload > 1 and reload - 1) or (active and 0 or nil)
    end
    return reload_result
end

function CP.info_output(sound, globalSound, text, duration)
	if globalSound then
		sm.audio.play(sound)
	else
		sm.audio.play(sound, sm.camera.getPosition())
	end
	if text then sm.gui.displayAlertText(text,duration or 3) end
end

function CP.get_all_units() return {} end
if sm.unit then
    if sm.unit.getAllUnits then
        CP.get_all_units = sm.unit.getAllUnits
    elseif sm.unit.HACK_getAllUnits_HACK then
        CP.get_all_units = sm.unit.HACK_getAllUnits_HACK
    end
end

CP_Projectile = class()

function CP_Projectile.better_explosion(position, expl_level, expl_radius, expl_impulse, expl_magnitude, effect, pushPlayers)
    sm.physics.explode(position, expl_level, expl_radius, 1, 1, effect)

    for k, body in pairs(sm.body.getAllBodies()) do
        local res_pos = position - body.worldPosition
        local distance_to_shape = res_pos:length()
        if distance_to_shape < expl_magnitude and body:isDynamic() then
            local impulse_direction = res_pos:normalize()
            local impulse_strength = math.max(expl_impulse * (1 - (distance_to_shape / expl_magnitude)), 0)
            if impulse_strength > 0 then
                sm.physics.applyImpulse(body, -(impulse_direction * impulse_strength), true)
            end
        end
    end

    if pushPlayers then
        for k, player in pairs(sm.player.getAllPlayers()) do
            if player.character then
                local result_pos = position - player.character.worldPosition
                local distance_to_player = result_pos:length()
                if distance_to_player < expl_magnitude then
                    local impulse_dir = result_pos:normalize()
                    local impulse_str = math.max(expl_impulse * (1 - (distance_to_player / expl_magnitude)), 0)
                    local final_impulse = (impulse_dir * impulse_str) / 10
                    sm.physics.applyImpulse(player.character, -final_impulse, false)
                end
            end
        end
        local limited_impulse_radius = expl_magnitude * 0.6
        for k, unit in pairs(CP.get_all_units()) do
            if unit.character and CP.exists(unit.character) then
                local result_pos = position - unit.character.worldPosition
                local distance_to_unit = result_pos:length()
                if distance_to_unit < expl_magnitude then
                    local impulse_dir = result_pos:normalize()
                    local impulse_str = math.max(expl_impulse * (1 - (distance_to_unit / expl_magnitude)), 0)
                    local final_impusle = (impulse_dir * impulse_str) / 5
                    if distance_to_unit < limited_impulse_radius then
                        unit.character:setTumbling(true)
                        unit.character:applyTumblingImpulse(-final_impusle)
                    else
                        sm.physics.applyImpulse(unit.character, -final_impusle, false)
                    end
                end
            end
        end
    end
end

function CP_Projectile.client_onProjHit(proj_effect, keep_effect)
    if proj_effect == nil then return end

    if sm.exists(proj_effect) then
        proj_effect:setPosition(sm.vec3.new(0, 0, 10000))
        proj_effect:stop()
        if not keep_effect then proj_effect:destroy() end
    end
end

function CP_Projectile.proximity_fuze_ignore(cannon_pos, proximityFuze)
    if cannon_pos == nil or proximityFuze <= 0 then return end

    local players_to_ignore = {}
    for k, player in pairs(sm.player.getAllPlayers()) do
        if player.character then
            local distance = (cannon_pos - player.character.worldPosition):length()
            if distance < proximityFuze then
                players_to_ignore[#players_to_ignore + 1] = player
            end
        end
    end
    return players_to_ignore
end

function CP_Projectile.client_destroyProjectiles(projectile_table)
    local deleted_projectiles = 0
    for k, projectile in pairs(projectile_table) do
        if projectile.effect ~= nil and sm.exists(projectile.effect) then
            projectile.effect:setPosition(sm.vec3.new(0, 0, 10000))
            projectile.effect:stop()
            projectile.effect:destroy()
            deleted_projectiles = deleted_projectiles + 1
        end
    end
    return deleted_projectiles
end

function CP_Projectile.client_whitelistTest(player, whitelist)
    if type(whitelist) ~= "table" then return end

    for i = 0, #whitelist, 1 do
        if whitelist[i] == player then return true end
    end
end

function CP_Projectile.client_proximity_fuze(proxFuze, bulletPos, whitelist)
    if proxFuze <= 0 then return end

    for k,player in pairs(sm.player.getAllPlayers()) do
        if player.character then
            local distance = (bulletPos - player.character.worldPosition):length()
            if not CP_Projectile.client_whitelistTest(player, whitelist) and distance < proxFuze then
                return true
            end
        end
    end
end

function CP_Projectile.get_nearest_visible_flare(flare_table, rocket_pos, rocket_p_pos)
    if flare_table == nil then return end

    local ClosestFlare = nil
    local ClosestDistance = math.huge

    for k, flare in pairs(flare_table) do
        local isFlareVisible = CP.isObjectVisible(rocket_pos, rocket_p_pos, flare.pos, 1.22173, 1.22173)
        local flare_dist = (rocket_pos - flare.pos):length()
        if isFlareVisible and ClosestDistance > flare_dist then
            ClosestFlare = flare.pos
            ClosestDistance = flare_dist
        end
    end
    return ClosestFlare
end

function CP_Projectile.kill_nearest_flares(flare_table, rocket_pos, radius)
    if flare_table == nil then return end

    for k, flare in pairs(flare_table) do
        local distance = (flare.pos - rocket_pos):length()
        if distance < radius then flare_table[k].hit = true end
    end
end

function CP_Projectile.is_flare_near(flare_table, rocket_pos, radius)
    if flare_table == nil then return end

    for k, flare in pairs(flare_table) do
        local distance = (flare.pos - rocket_pos):length()
        if distance < radius then return true end
    end
end

CP_GUI = class()

local _PathToLayouts = "$CONTENT_c0344d93-7492-46c8-88be-a61699e57041/Gui/Layouts/"
local _GuiSupported = (sm.gui and type(sm.gui.createGuiFromLayout) == "function")

function CP_GUI.GuiSupported() return _GuiSupported end

function CP_GUI.CreateGUI(path)
    if not CP_GUI.GuiSupported() then return end

    return sm.gui.createGuiFromLayout(_PathToLayouts..path)
end

print("[CannonsPack] Additions library has been loaded!")