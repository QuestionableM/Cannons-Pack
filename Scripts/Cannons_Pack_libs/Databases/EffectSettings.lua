--[[
	Copyright (c) 2022 Cannons Pack Team
	Questionable Mark
]]

EffectEnum = {
	sht     = 1,
	rld     = 2,
	sht2    = 3,
	crg     = 4,
	pnt     = 5,
	err     = 6,
	sht_snd = 7,
	fms     = 8,
	eff     = 9,
	lit     = 10
}

ExplEffectEnum = {
	AircraftCannon     = 1,
	ExplSmall          = 2,
	ExplBig            = 3,
	ExplBig2           = 4,
	DoraCannon         = 5,
	OrbitalCannonSmall = 6,
	OrbitalCannon      = 7,
	EMPCannon          = 8
}

ExplEffectEnumTrans = {
	[ExplEffectEnum.AircraftCannon]     = "AircraftCannon - Explosion",
	[ExplEffectEnum.ExplSmall]          = "ExplSmall",
	[ExplEffectEnum.ExplBig]            = "ExplBig",
	[ExplEffectEnum.ExplBig2]           = "ExplBig2",
	[ExplEffectEnum.DoraCannon]         = "DoraCannon - Explosion",
	[ExplEffectEnum.OrbitalCannonSmall] = "OrbitalCannon - ExplosionSmall",
	[ExplEffectEnum.OrbitalCannon]      = "OrbitalCannon - Explosion",
	[ExplEffectEnum.EMPCannon]          = "EMPCannon - Explosion"
}

local function TranslateEffects(eff_table)
	local output_table = {}

	for k, v in pairs(eff_table) do
		local repl_key = EffectEnum[k]
		output_table[repl_key] = v
	end

	return output_table
end

local cannon_effects = {
	["86b45499-9a8f-45ce-b9f9-80b6912fcc06"] = TranslateEffects({ --AircraftCannon
		sht = "AircraftCannon - Shoot"
	}),
	["49de462c-2f36-4ad5-802c-c4add235dc53"] = TranslateEffects({ --FlakCannon
		sht = "FlakCannon - Shoot"
	}),
	["bc8178a9-8a38-4c43-a0d0-8a0f242a59c7"] = TranslateEffects({ --TankCannon
		sht = "TankCannon - Shoot",
		rld = "Reloading"
	}),
	["4295196d-cbd6-40c6-badc-ff9011208ad5"] = TranslateEffects({ --TankCannon2
		sht = "TankCannon - Shoot",
		rld = "Reloading"
	}),
	["04c1c87f-da87-4f5e-8d70-1ca452314728"] = TranslateEffects({ --RocketLauncher
		sht = {name = "RocketLauncher - Shoot", offset = _newVec(0.0, 0.0, 0.65)},
		rld = "Reloading"
	}),
	["e8a8a8ce-7b00-4e2b-b417-75e8995a02d8"] = TranslateEffects({ --SmartRocketLauncher
		rld = "Reloading",
		sht = {name = "RocketLauncher - Shoot", offset = _newVec(0.0, 0.0, 0.65)},
		fms = "SmartRocketLauncher - Fumes"
	}),
	["388ccd57-1be9-40cc-b96b-69dd16eb4f32"] = TranslateEffects({ --TankCannon3
		sht = "TankCannon3 - Shoot",
		rld = "Reloading"
	}),
	["03e1ecbd-17ee-4045-a5d8-366f6e656555"] = TranslateEffects({ --M1AbramsCannon
		sht = "M1AbramsCannon - Shoot",
		rld = "Reloading"
	}),
	["6c0bbf06-364f-4d51-98c2-1631b2d09cd5"] = TranslateEffects({ --NavalCannon
		sht = "NavalCannon - Shoot",
		rld = "Reloading"
	}),
	["d0352961-c071-4278-8f23-99fcb8a7a377"] = TranslateEffects({ --NavalCannon2
		sht = "NavalCannon2 - Shoot",
		rld = "Reloading"
	}),
	["fac1f66a-a01c-4d8d-a838-e887455c38ae"] = TranslateEffects({ --Railgun
		eff = "Railgun - Charge",
		sht = "Railgun - Shoot",
		sht2 = "Railgun - Shoot2",
		rld = "Reloading"
	}),
	["75e1e5a3-acc5-48cf-b4c1-bb8795940002"] = TranslateEffects({ --Railgun2
		eff = "Railgun2 - Charge",
		sht = "Railgun2Cannon - Shoot",
		rld = "Reloading"
	}),
	["e442535e-e75e-4079-9acc-9005e5ba0c08"] = TranslateEffects({ --EMPCannon
		sht = "EMPCannon - Shoot",
		rld = "Reloading",
		crg = "EMPCannon - Charge",
		lit = "EMPCannon - Light"
	}),
	["bd428d5e-c519-43fe-a75f-76cfddb5b700"] = TranslateEffects({ --HowitzerCannon
		sht = "HowitzerCannon - Shoot",
		rld = "HeavyReloading"
	}),
	["f85af057-f779-4eca-ad1c-58d2828d3404"] = TranslateEffects({ --SchwererGustavCannon
		sht = "DoraCannon - Shoot",
		rld = "HeavyReloading"
	}),
	["fd6130e4-261d-4875-a418-96fe33bb2714"] = TranslateEffects({ --SmallSmartCannon
		rld = "Reloading",
		sht_snd = "NumberLogicCannon - Shoot",
		sht = "SmartCannon - MuzzleFlash1"
	}),
	["35203ea3-8cc8-4ec9-9a26-c62c6eb5544d"] = TranslateEffects({ --SmartCannon
		rld = "Reloading",
		sht_snd = "NumberLogicCannon - Shoot",
		sht = "SmartCannon - MuzzleFlash1"
	}),
	["2bcd658f-6344-4e37-9fb5-ced1e2249c7b"] = TranslateEffects({ --OrbitalCannon
		rld = "Reloading",
		pnt = "OrbitalCannon - Point",
		err = "OrbitalCannon - Error"
	}),
	["b86bc11c-8922-47c2-b5bc-e184d3378a81"] = TranslateEffects({ --FlareLauncher
		sht = "FlareCannon - Shoot",
		rld = "Reloading"
	}),
	["0d30954b-4f81-4e4b-99c6-cbdef5eb6c76"] = TranslateEffects({ --LaserCannon
		sht = "LaserCannon - Shoot"
	}),
	["0dc868d7-5e01-4183-b3bb-63236595ba36"] = TranslateEffects({ --RocketPod01
		fms = "RocketPod01 - Fumes",
		sht = {name = "RocketLauncher - Shoot", offset = _newVec(0.0, 0.0, 0.8)}
	})
}

function _cpEffect_cl_loadEffects2(self)
	local obj_effects = cannon_effects[tostring(self.shape.uuid)]

	if obj_effects then
		local effect_set     = {}
		local effect_offsets = {}
		local s_interactable = self.interactable

		for id, effect in pairs(obj_effects) do
			if type(effect) == "table" then
				local eff_name = effect.name
				local eff_offset = effect.offset or _vecZero()

				local new_eff = _createEffect(effect.name, s_interactable)
				new_eff:setOffsetPosition(eff_offset)

				effect_set    [id] = new_eff
				effect_offsets[id] = eff_offset
			else
				effect_set[id] = _createEffect(effect, s_interactable)
			end
		end

		return effect_set, effect_offsets
	end
end

function _cpEffect_cl_loadEffects(self)
	local obj_effects = cannon_effects[tostring(self.shape.uuid)]
	if obj_effects then
		local effect_set = {}
		local s_Interactable = self.interactable

		for id, effect in pairs(obj_effects) do
			if type(effect) == "table" then
				local new_eff = _createEffect(effect.name, s_Interactable)
				new_eff:setOffsetPosition(effect.offset or _vecZero())

				effect_set[id] = new_eff
			else
				effect_set[id] = _createEffect(effect, s_Interactable)
			end
		end

		return effect_set
	end
end

_cpPrint("Effect Settings have been loaded!")