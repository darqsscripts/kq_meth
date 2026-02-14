Config = {}
Config.debug = false
-- Pour redémarrer le script sans crash serveur/joueurs, utilisez la commande : /kq_meth_restart

Config.recipe = {
    cookingTemperature = 50, -- Toujours en Celsius (min 40, max 200)
    cookingDifficulty = 1,   -- Difficulté entre 1 et 10
    cookingSpeed = 10,        -- Vitesse de cuisson (0.1 à 10)
    coolingSpeed = 10,        -- Vitesse de refroidissement
}

Config.production = {
    -- Quantité maximale de méthamphétamine lors d’un batch parfait
    maxItemAmountPerBatch = 10,

    -- Items produits selon la pureté minimale atteinte (le plus haut possible sera choisi)
    itemPerPurity = {
        {
            minimumPurity = 10,
            item = 'kq_meth_low',
        },
        {
            minimumPurity = 75,
            item = 'kq_meth_mid',
        },
        {
            minimumPurity = 95,
            item = 'kq_meth_high',
        },
    },

    dontSaveItemMetadata = false,

    -- Interdit de cuisiner sous terre / tunnels
    disallowCookingWhenUnderground = true,
}

-- Véhicules désactivés pour la cuisson (false = autorisé)
Config.vehicles = {
    journey = { disabled =  false },
    journey2 = { disabled = false },
    camper = { disabled = false },

    -- Pack d’extension
    kqrumpo = { disabled = false },
    kqrumpo2 = { disabled = false },

    -- Camper VooDoo
    vdcamper = { disabled = false },
}

-- Unité sur le thermomètre : 'c' = Celsius, 'f' = Fahrenheit
Config.units = {
    temperature = 'c',
}

-- Apparence du texte
Config.textScale = 1.0
Config.textFont = 4

Config.display = {
    drawResourceLabelOnHover = true,

    pot = {
        displayRawMethPurity = true,
        displayMethPurity = true,
    },

    tray = {
        displayMethPurity = true,
        displayMethCoolingPercentage = true,
    },
}

Config.colors = {
    liquidMeth = {96, 169, 179, 5},   -- Couleur liquide
    cooledMeth = {46, 218, 242, 80},  -- Couleur solide
}

-- Options de fumée
Config.smoke = {
    enabled = true,
    color = 'blue',
    alternativeColor = 'white',
    scale = 1.5,
    keepSmoking = true,
}

-- Explosion possible si mauvaise cuisson + lithium
Config.explosion = {
    enabled = true,
    dealsDamage = false,
}

-- Alertes police
Config.policeAlerts = {
    enabled = true,
    maxDistance = 120.0,
    chancePerPed = 100,

    policeJobs = {
        'lspd',
        'lssd',
        'bcso',
        'noose',
    },

    dispatchTitles = { 
        'Fourgon suspect',
        'Fourgon fumant',
        'Fumée bleue',
        'Fourgon étrange',
    },

    dispatchMessages = {
        'Il y a une camionnette avec de la fumée bleue qui en sort. Ça a l’air vraiment louche !',
        'Quelqu’un est à l’intérieur de cette camionnette, de la fumée bleue en sort !',
        'Cette camionnette est garée ici en train de fumer depuis un moment, veuillez venir voir !',
        'Camionnette très suspecte, de la fumée bleue en sort, quelqu’un cuisine quelque chose d’étrange ici',
    },

    blip = {
        sprite = 636,
        color = 1,
        scale = 1.5,
        text = 'Fourgonnette suspecte',
        flash = true,
    },
}

-- Mappage des items
Config.items = {
    meth_lab_kit = 'kq_meth_lab_kit',
    ammonia = 'kq_ammonia',
    acetone = 'kq_acetone',
    ethanol = 'kq_ethanol',
    lithium = 'kq_lithium',
    pills = 'kq_meth_pills',
}

-- Masque à gaz
Config.gasMask = {
    enabled = true,
    effectType = 'HUFFIN',
    effectStrengthMultiplier = 1.0,
    maskReductionMultiplier = 0.1,

    ids = {
        -- Homme
        ['mp_m_freemode_01'] = {
            36, 38, 46, 107, 129, 130, 166, 175,
        },
        -- Femme
        ['mp_f_freemode_01'] = {
            36, 38, 46, 107, 129, 130, 166, 175,
        },
    },
}

Config.finish = {
    showBigAnnouncement = true,
}


Config.itemCollection = {
    ammonia = {
        -- Model of the ammonia tank
        model = 'kq_ammonia_tank',
        
        -- Spawn offset of the tank
        offset = vector3(0, 2.0, 0),
        
        -- Spawn offsets of the interactable valve (You do not need to touch these at all!)
        valve = {
            model = 'kq_valve',
            offset = {
                coords = vector3(2.4, -0.25, 0.0),
                rotation = vector3(0, 0, 90)
            }
        },
        
        -- The amount of ammonia which can be taken out of the tanks is limited
        ammoniaAmount = 4, -- the amount of ammonia each tank can output per refill
        
        -- Ammonia tanks will tasked to be refilled once no ammonia is left inside.
        refillTime = 20, -- refill time in minutes
        
        -- Blip settings of the ammonia tanks
        -- Find out more: https://docs.fivem.net/docs/game-references/blips/
        blip = {
            sprite = 851,
            color = 39,
            alpha = 255, -- 0 to 255
            scale = 0.5,
            label = 'Ammonia tank'
        },
        
        locations = {
            { -- Humane labs A
                coords = vector3(3561.24, 3648.0, 41.34),
                rotation = vector3(0, 0, 350),
                blip = true,
            },
            { -- Humane labs B
                coords = vector3(3418.28, 3679.89, 41.34),
                rotation = vector3(0, 0, 80),
                blip = true,
            },
            { -- Humane labs C
                coords = vector3(3458.36, 3641.99, 42.62),
                rotation = vector3(0, 0, 170),
                blip = true,
            },
            { -- Docks
                coords = vector3(334.61, -2679.0, 6.0),
                rotation = vector3(0, 0, 0),
                blip = true,
            },
        },
    },
    simple = {
        {
            enabled = true,
            label = 'a car battery',
            
            model = 'kq_battery_stack',
            offset = vector3(0, 0, 0),
            interactionDistance = 2.5,
            
            item = 'kq_lithium',
            amount = 6,
            
            animation = {
                dict = 'anim@heists@load_box',
                name = 'lift_box',
                
                attachment = {
                    holdModel = 'prop_car_battery_01',
                    
                    delay = 1200,
                    bone = 57005,
                    offset = vector3(0.05, 0.1, -0.25),
                    rotation = vector3(0, 90, 120),
                }
            },
            
            -- Blip settings of the ammonia tanks
            -- Find out more: https://docs.fivem.net/docs/game-references/blips/
            blip = {
                sprite = 653,
                color = 39,
                alpha = 255, -- 0 to 255
                scale = 0.5,
                label = 'Battery pile'
            },
            
            -- All locations of where the loot should spawn at
            locations = {
                {
                    coords = vector3(-551.0, -1712.5, 17.74),
                    rotation = vector3(0, 0, 40),
                    blip = true,
                },
                {
                    coords = vector3(-179.59, 6242.13, 30.4),
                    rotation = vector3(0, 0, 0),
                    blip = true,
                },
                {
                    coords = vector3(2355.24, 3116.08, 47.1),
                    rotation = vector3(0, 0, 30),
                    blip = true,
                },
            },
        },
        {
            enabled = true,
            label = 'ethanol',
            
            model = 'kq_ethanol',
            offset = vector3(0, 0, 0),
            interactionDistance = 1.5,
            
            item = 'kq_ethanol',
            amount = 1,
            
            animation = {
                dict = 'mp_take_money_mg',
                name = 'put_cash_into_bag_loop',
                
                attachment = {
                    holdModel = 'kq_ethanol',
                    
                    delay = 400,
                    bone = 57005,
                    offset = vector3(0.1, 0.08, -0.13),
                    rotation = vector3(0, 15, 0),
                }
            },
            
            -- Blip settings of the ammonia tanks
            -- Find out more: https://docs.fivem.net/docs/game-references/blips/
            blip = {
                sprite = 653,
                color = 39,
                alpha = 255, -- 0 to 255
                scale = 0.5,
                label = 'Ethanol'
            },
            
            -- All locations of where the loot should spawn at
            locations = {
                {
                    coords = vector3(1393.06, 3607.85, 33.99),
                    rotation = vector3(0, 0, 32),
                    blip = true,
                },
            },
        },
        {
            enabled = true,
            label = 'acetone',
            
            model = 'kq_acetone',
            offset = vector3(0, 0, 0),
            interactionDistance = 1.5,
            
            item = 'kq_acetone',
            amount = 1,
            
            animation = {
                dict = 'mp_take_money_mg',
                name = 'put_cash_into_bag_loop',
                
                attachment = {
                    holdModel = 'kq_acetone',
                    
                    delay = 400,
                    bone = 57005,
                    offset = vector3(0.1, 0.1, -0.07),
                    rotation = vector3(0, 15, 0),
                }
            },
            
            -- Blip settings of the ammonia tanks
            -- Find out more: https://docs.fivem.net/docs/game-references/blips/
            blip = {
                sprite = 653,
                color = 39,
                alpha = 255, -- 0 to 255
                scale = 0.5,
                label = 'Acetone'
            },
            
            -- All locations of where the loot should spawn at
            locations = {
                {
                    coords = vector3(1387.46, 3607.65, 33.99),
                    rotation = vector3(0, 0, 250),
                    blip = true,
                },
                {
                    coords = vector3(1392.87, 3600.58, 38.24),
                    rotation = vector3(0, 0, 40),
                    blip = true,
                },
            },
        },
        {
            enabled = true,
            label = 'pseudoephedrine',
            
            model = 'ex_office_swag_pills2',
            offset = vector3(0, 0, 0),
            interactionDistance = 1.5,
            
            item = 'kq_meth_pills',
            amount = 1,
            
            animation = {
                dict = 'mp_take_money_mg',
                name = 'put_cash_into_bag_loop',
                
                attachment = {
                    holdModel = 'prop_cs_pills',
                    
                    delay = 400,
                    bone = 57005,
                    offset = vector3(0.06, 0.06, -0.06),
                    rotation = vector3(0, 20, 0),
                }
            },
            
            -- Blip settings of the ammonia tanks
            -- Find out more: https://docs.fivem.net/docs/game-references/blips/
            blip = {
                sprite = 51,
                color = 39,
                alpha = 255, -- 0 to 255
                scale = 0.5,
                label = 'Pseudoephedrine'
            },
            
            -- All locations of where the loot should spawn at
            locations = {
                {
                    coords = vector3(1398.0, 3611.27, 35.22),
                    rotation = vector3(0, 0, 250),
                    blip = true,
                },
            },
        },
        {
            enabled = true,
            label = 'meth cooking kit',
            
            model = 'bkr_prop_meth_bigbag_01a',
            offset = vector3(0, 0, 0),
            interactionDistance = 1.5,
            
            item = 'kq_meth_lab_kit',
            amount = 1,
            
            animation = {
                dict = 'anim@heists@load_box',
                name = 'lift_box',
                
                attachment = {
                    holdModel = 'prop_kitch_pot_huge',
                    
                    delay = 1200,
                    bone = 57005,
                    offset = vector3(0.05, 0.1, -0.3),
                    rotation = vector3(0, 90, 120),
                }
            },
            
            -- Blip settings of the ammonia tanks
            -- Find out more: https://docs.fivem.net/docs/game-references/blips/
            blip = {
                sprite = 653,
                color = 39,
                alpha = 255, -- 0 to 255
                scale = 0.5,
                label = 'Meth cooking kit'
            },
            
            -- All locations of where the loot should spawn at
            locations = {
                {
                    coords = vector3(156.01, 3130.21, 42.53),
                    rotation = vector3(0, 0, 99),
                    blip = true,
                },
            },
        },
    },
}


Config.guards = {
    enabled = false,
    peds = {
        {
            coords = vector3(1391.41, 3606.02, 34.98),
            heading = 198.0,
            model = 'ig_mrk',
            respawnTime = 300,
            zone = {
                coords = vector3(1391.39, 3609.3, 34.98),
                radius = 2.5,
            },
            weapon = 'WEAPON_FLASHLIGHT',
            animation = {
                dict = 'switch@michael@talks_to_guard',
                name = '001393_02_mics3_3_talks_to_guard_idle_guard',
            },
        },
        {
            coords = vector3(164.64, 3132.45, 42.31),
            heading = 189.0,
            model = 'u_m_y_caleb',
            respawnTime = 300,
            zone = {
                coords = vector3(157.88, 3130.80, 43.5),
                radius = 2.75,
            },
            weapon = 'WEAPON_KNIFE',
            animation = {
                dict = 'amb@world_human_sunbathe@female@back@base',
                name = 'base',
            },
        },
    }
}

Config.keybinds = {
    interact = {
        label = 'E',
        name = 'INPUT_PICKUP',
        input = 38,
    },
    enter = {
        label = 'F',
        input = 23,
        name = 'INPUT_ENTER',
    },
    exit = {
        label = 'F',
        input = 23,
        name = 'INPUT_ENTER',
    },
    drag = {
        label = 'LMB',
        input = 24,
        name = 'INPUT_ATTACK',
    },
    stove = {
        label = 'LMB',
        input = 24,
        name = 'INPUT_ATTACK',
    },
    rotateLeft = {
        label = 'Scroll up',
        input = 96,
        name = 'INPUT_VEH_CINEMATIC_UP_ONLY',
    },
    rotateRight = {
        label = 'Scroll down',
        input = 97,
        name = 'INPUT_VEH_CINEMATIC_DOWN_ONLY',
    },
}

Config.removeSponge = true