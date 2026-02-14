local difficulty = math.min(10, Config.recipe.cookingDifficulty)
difficulty = math.max(1, difficulty)

local baseTemp = Config.recipe.cookingTemperature
local minTemp = baseTemp + 34 - math.floor(difficulty * 1.5)
local maxTemp = minTemp + (10 - difficulty)

Reactions = {
    {
        input = {
            { liquid = "acetone", amount = 5 },
            { liquid = "ammonia", amount = 2.5 },
            { liquid = "lithium", amount = 1.5 },
            { liquid = "pills", amount = 0.5 }
        },
        temperature = {
            min = baseTemp,
            max = maxTemp,
            change = 0.35 + (difficulty / 100)
        },
        output = { liquid = "ace_lith_mix", amount = 9 },
        particles = {
            { name = "ent_anim_welder", size = 0.17, alpha = 0.3, offset = "random" },
            { name = "ent_amb_steam_vent_open_lgt", size = 1.0, alpha = 1.0, duration = 1000 }
        }
    },
    {
        input = {
            { liquid = "ace_lith_mix", amount = Config.recipe.cookingSpeed }
        },
        temperature = {
            min = baseTemp,
            max = maxTemp,
            change = 0.0
        },
        output = { liquid = "cooked_ace_lith", amount = Config.recipe.cookingSpeed },
        particles = {
            { name = "ent_amb_steam_vent_open_lgt", size = 1.0, alpha = 0.5, duration = 1000 }
        },
        smoke = true
    },
    {
        input = {
            { liquid = "cooked_ace_lith", amount = 10 },
            { liquid = "ethanol", amount = 1 }
        },
        temperature = {
            min = 15,
            max = maxTemp,
            change = 0.0
        },
        output = { liquid = "liquid_meth", amount = 10 },
        particles = {
            { name = "ent_amb_steam_vent_open_lgt", size = 1.0, alpha = 0.5, duration = 1000 }
        },
        smoke = true
    },
    {
        input = {
            { liquid = "cooked_ace_lith", amount = 1 },
            { liquid = "ethanol", amount = 0.1 }
        },
        temperature = {
            min = 15,
            max = maxTemp,
            change = 0.0
        },
        output = { liquid = "liquid_meth", amount = 1 },
        smoke = true
    },
    {
        input = {
            { liquid = "ethanol", amount = 3 }
        },
        temperature = {
            min = 10,
            max = 1000,
            change = 0.0
        },
        without = {
            { liquid = "cooked_ace_lith", amount = 3 }
        }
    },
    {
        input = {
            { liquid = "ethanol", amount = 1 }
        },
        temperature = {
            min = 10,
            max = 1000,
            change = 0.0
        },
        without = {
            { liquid = "cooked_ace_lith", amount = 1 }
        }
    },
    {
        input = {
            { liquid = "liquid_meth", amount = Config.recipe.coolingSpeed }
        },
        temperature = {
            min = -100,
            max = 15,
            change = 0.0
        },
        output = { liquid = "meth", amount = Config.recipe.coolingSpeed }
    },
    {
        input = {
            { liquid = "liquid_meth", amount = 0.1 }
        },
        temperature = {
            min = -100,
            max = 15,
            change = 0.0
        },
        output = { liquid = "meth", amount = 0.1 }
    },
    {
        input = {
            { liquid = "ace_lith_mix", amount = 1 }
        },
        chance = 5,
        temperature = {
            min = baseTemp,
            max = 1000
        }
    },
    {
        input = {
            { liquid = "cooked_ace_lith", amount = 1 }
        },
        temperature = {
            min = minTemp,
            max = 1000
        }
    },
    {
        input = {
            { liquid = "ammonia", amount = 1 }
        },
        temperature = {
            min = minTemp,
            max = 1000
        },
        without = {
            { liquid = "sulfuric_acid", amount = 1 }
        }
    },
    {
        input = {
            { liquid = "acetone", amount = 1 }
        },
        temperature = {
            min = minTemp,
            max = 1000
        },
        without = {
            { liquid = "sulfuric_acid", amount = 1 }
        },
        particles = {
            { name = "ent_amb_waterfall_pool", size = 0.09, alpha = 0.4 }
        }
    },
    {
        input = {
            { liquid = "lithium", amount = 10 }
        },
        temperature = {
            min = maxTemp,
            max = maxTemp + 40,
            change = 2.5
        },
        output = { liquid = "trash", amount = 10 },
        particles = {
            { name = "sp_ent_sparking_wires", size = 0.25, alpha = 0.3, offset = "random" },
            { name = "ent_amb_acid_bath", size = 0.13, alpha = 1.0, offset = vector3(0.0, 0.0, 0.1), duration = 300 }
        }
    },
    {
        input = {
            { liquid = "lithium", amount = 1 }
        },
        temperature = {
            min = maxTemp + 40,
            max = 1000,
            change = 5
        },
        output = { liquid = "trash", amount = 1 },
        particles = {
            { name = "sp_ent_sparking_wires", size = 0.4, alpha = 1.0, offset = "random" },
            { name = "ent_amb_acid_bath", size = 0.2, alpha = 1.0, offset = vector3(0.0, 0.0, 0.1), duration = 300 }
        }
    },
    {
        input = {
            { liquid = "lithium", amount = 50 }
        },
        temperature = {
            min = maxTemp,
            max = maxTemp + 5,
            change = 15
        },
        output = { liquid = "trash", amount = 100 }
    },
    {
        input = {
            { liquid = "lithium", amount = 25 }
        },
        temperature = {
            min = maxTemp * 2,
            max = 1000,
            change = 50
        },
        explosion = true
    }
}

if difficulty >= 2 then
    table.insert(Reactions, {
        input = {
            { liquid = "acetone", amount = 10 },
            { liquid = "ammonia", amount = 10 }
        },
        temperature = {
            min = maxTemp + 10,
            max = 1000
        },
        output = { liquid = "trash", amount = 10 },
        without = {
            { liquid = "sulfuric_acid", amount = 1 }
        },
        particles = {
            { name = "ent_amb_acid_bath", size = 0.13, alpha = 1.0, offset = vector3(0.0, 0.0, 0.1), duration = 300 }
        }
    })
end

function AddReaction(index, reaction)
    Reactions[index] = reaction
end
exports("AddReaction", AddReaction)

if difficulty >= 3 then
    table.insert(Reactions, {
        input = {
            { liquid = "ace_lith_mix", amount = 2 }
        },
        temperature = {
            min = 0,
            max = baseTemp - 2
        },
        output = { liquid = "trash", amount = 2 }
    })
end

if difficulty >= 4 then
    table.insert(Reactions, {
        input = {
            { liquid = "ace_lith_mix", amount = 5 }
        },
        temperature = {
            min = maxTemp + 5,
            max = 1000
        },
        output = { liquid = "trash", amount = 5 },
        particles = {
            { name = "ent_amb_acid_bath", size = 0.13, alpha = 1.0, offset = vector3(0.0, 0.0, 0.1), duration = 300 }
        }
    })
    
    table.insert(Reactions, {
        input = {
            { liquid = "ethanol", amount = 5 }
        },
        temperature = {
            min = baseTemp - 5,
            max = 1000
        },
        output = { liquid = "trash", amount = 3 },
        particles = {
            { name = "ent_amb_acid_bath", size = 0.13, alpha = 1.0, offset = vector3(0.0, 0.0, 0.1), duration = 300 }
        }
    })
    
    table.insert(Reactions, {
        input = {
            { liquid = "acetone", amount = 2.5 },
            { liquid = "ammonia", amount = 1.25 },
            { liquid = "lithium", amount = 0.75 }
        },
        without = {
            { liquid = "pills", amount = 0.5 }
        },
        temperature = {
            min = baseTemp,
            max = maxTemp,
            change = 1
        },
        output = { liquid = "trash", amount = 4.5 },
        particles = {
            { name = "sp_ent_sparking_wires", size = 0.3, alpha = 0.3, offset = "random" },
            { name = "ent_amb_acid_bath", size = 0.13, alpha = 1.0, offset = vector3(0.0, 0.0, 0.1), duration = 300 }
        }
    })
end

if difficulty >= 8 then
    table.insert(Reactions, {
        input = {
            { liquid = "ethanol", amount = 1 }
        },
        temperature = {
            min = 0,
            max = baseTemp
        },
        without = {
            { liquid = "cooked_ace_lith", amount = 1 }
        },
        output = { liquid = "solid_ethanol", amount = 1 }
    })
    
    table.insert(Reactions, {
        input = {
            { liquid = "solid_ethanol", amount = 2 }
        },
        temperature = {
            min = baseTemp,
            max = 1000
        },
        particles = {
            { name = "ent_amb_steam_vent_open_lgt", size = 1.0, alpha = 0.5, duration = 1000 }
        },
        smoke = true
    })
    
    table.insert(Reactions, {
        input = {
            { liquid = "ace_lith_mix", amount = 3 }
        },
        temperature = {
            min = 0,
            max = baseTemp - 1
        },
        output = { liquid = "trash", amount = 3 }
    })
end

if difficulty >= 9 then
    table.insert(Reactions, {
        input = {
            { liquid = "ace_lith_mix", amount = 4 }
        },
        temperature = {
            min = maxTemp + 5,
            max = 10000
        },
        output = { liquid = "trash", amount = 4 }
    })
end