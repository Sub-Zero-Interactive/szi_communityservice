Config = {}

Config.Locale = 'en' -- Language to be used

Config.ServiceExtensionOnEscape	= 5 -- How many services a player's community service gets extended if they tries to escape

Config.MaxDistance = 50

Config.ServiceLocation 	= vector3(170.43, -990.70, 30.09) -- Where the player will be sent to do the community service
Config.ReleaseLocation = vector3(427.33, -979.51, 30.20) -- Where the player will be returned after they finish community service

Config.CleaningModel = 'prop_tool_broom'
Config.GardeningModel = 'bkr_prop_coke_spatula_04'

Config.ServiceLocations = {
	{ type = "cleaning", coords = vector3(170.0, -1006.0, 29.34) },
	{ type = "cleaning", coords = vector3(177.0, -1007.94, 29.33) },
	{ type = "cleaning", coords = vector3(181.58, -1009.46, 29.34) },
	{ type = "cleaning", coords = vector3(189.33, -1009.48, 29.34) },
	{ type = "cleaning", coords = vector3(195.31, -1016.0, 29.34) },
	{ type = "cleaning", coords = vector3(169.97, -1001.29, 29.34) },
	{ type = "cleaning", coords = vector3(164.74, -1008.0, 29.43) },
	{ type = "cleaning", coords = vector3(163.28, -1000.55, 29.35) },
	{ type = "gardening", coords = vector3(181.38, -1000.05, 29.29) },
	{ type = "gardening", coords = vector3(188.43, -1000.38, 29.29) },
	{ type = "gardening", coords = vector3(194.81, -1002.0, 29.29) },
	{ type = "gardening", coords = vector3(198.97, -1006.85, 29.29) },
	{ type = "gardening", coords = vector3(201.47, -1004.37, 29.29) }
}

Config.Uniforms = {
	prison_wear = {
		male = {
			['tshirt_1'] = 15,  ['tshirt_2'] = 0,
			['torso_1']  = 146, ['torso_2']  = 0,
			['decals_1'] = 0,   ['decals_2'] = 0,
			['bproof_1'] = 0,   ['bproof_2'] = 0,
			['arms']     = 63, ['pants_1']  = 3,
			['pants_2']  = 7,   ['shoes_1']  = 7,
			['shoes_2']  = 0,  ['chain_1']  = 0,
			['chain_2']  = 0
		},
		female = {
			['tshirt_1'] = 3,   ['tshirt_2'] = 0,
			['torso_1']  = 0,  ['torso_2']  =0,
			['decals_1'] = 0,   ['decals_2'] = 0,
			['bproof_1'] = 0,   ['bproof_2'] = 0,
			['arms']     = 72,  ['pants_1'] = 3,
			['pants_2']  = 15,  ['shoes_1']  = 36,
			['shoes_2']  = 0,   ['chain_1']  = 0,
			['chain_2']  = 0
		}
	}
}
