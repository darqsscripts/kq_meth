Types = {}

exports("AddResourceType", function(typeName, typeData)
    Types[typeName] = typeData
end)

Types.sponge = {
    label = L("Sponge"),
    model = "v_res_fa_sponge01",
    draggable = true,
    rotatable = true,
    size = 0.06,
    height = 0.1,
    offset = {
        coords = vector3(0.0, 0.0, 0.02),
        rotation = vector3(0.0, 0.0, 30.0)
    }
}

Types.acetone = {
    label = L("Acetone"),
    model = "kq_acetone",
    draggable = true,
    rotatable = true,
    refundable = true,
    size = 0.08,
    height = 0.21,
    offset = {
        coords = vector3(0.0, 0.0, 0.0),
        rotation = vector3(0.0, 0.0, 0.0)
    },
    interaction = {
        speed = 3,
        animation = "pour",
        offset = vector3(0, 0.12, 0.14),
        canPourOut = true
    }
}

Types.pills = {
    label = L("Pseudoephedrine"),
    model = "prop_cs_pills",
    draggable = true,
    rotatable = true,
    refundable = true,
    size = 0.04,
    height = 0.15,
    offset = {
        coords = vector3(0.0, 0.0, 0.03),
        rotation = vector3(0.0, 0.0, 0.0)
    },
    interaction = {
        speed = 1,
        animation = "pour",
        offset = vector3(0, 0.03, 0.03),
        canPourOut = true
    }
}

Types.ammonia = {
    label = L("Ammonia"),
    model = "kq_ammonia",
    draggable = true,
    rotatable = true,
    refundable = true,
    size = 0.09,
    height = 0.23,
    offset = {
        coords = vector3(0.0, 0.0, 0.0),
        rotation = vector3(0.0, 0.0, -0.03)
    },
    interaction = {
        speed = 3,
        animation = "pour",
        offset = vector3(0, 0.18, 0.125),
        canPourOut = true
    }
}

Types.ethanol = {
    label = L("Ethanol"),
    model = "kq_ethanol",
    draggable = true,
    rotatable = true,
    refundable = true,
    size = 0.08,
    height = 0.23,
    offset = {
        coords = vector3(0.0, 0.0, 0.0),
        rotation = vector3(0.0, 0.0, 0.0)
    },
    interaction = {
        speed = 3,
        animation = "pour",
        offset = vector3(-0.05, 0.16, 0.14),
        canPourOut = true
    }
}

Types.lithium = {
    label = L("Lithium plate"),
    model = "prop_phone_proto_battery",
    draggable = true,
    rotatable = true,
    refundable = true,
    size = 0.04,
    height = 0.1,
    offset = {
        coords = vector3(0.0, 0.0, 0.03),
        rotation = vector3(0.0, 0.0, 15.0)
    },
    ignores = {"lithium"},
    interaction = {
        speed = 3,
        animation = "drop",
        offset = vector3(0, 0, 0),
        canPourOut = true
    }
}

Types.pot = {
    label = L("Pot"),
    model = "kq_pot",
    draggable = true,
    rotatable = false,
    alwaysFacePlayer = true,
    size = 0.13,
    height = 0.27,
    shufflingEfficiency = 0.1,
    offset = {
        coords = vector3(0.0, 0.0, 0.02),
        rotation = vector3(0.0, 0.0, 5.0)
    },
    interaction = {
        storesLiquids = true,
        speed = 3,
        animation = "pour",
        offset = vector3(-0.05, 0.16, 0.14),
        canPourOut = true
    },
    temperature = {
        min = 25
    },
    liquid = {
        shuffles = true,
        sizeX = 0.102,
        sizeY = 0.102,
        maxVolume = 3000,
        marker = 28,
        coords = {
            min = vector3(0.0, 0.0, 0.034),
            max = vector3(0.0, 0.0, 0.11)
        }
    },
    info = {
        drawTemp = true,
        drawPurityRaw = Config.display.pot.displayRawMethPurity,
        drawPurity = Config.display.pot.displayMethPurity
    },
    children = {
        {
            model = "kq_thermometer",
            offset = vector3(0.0, 0.065, 0.08),
            rotation = vector3(-20.0, -5.0, 0.0)
        }
    }
}

Types.tray = {
    label = L("Tray"),
    model = "kq_tray",
    draggable = true,
    rotatable = true,
    size = 0.25,
    height = 0.15,
    offset = {
        coords = vector3(0.0, 0.0, 0.02),
        rotation = vector3(0.0, 0.0, 90.0)
    },
    interaction = {
        storesLiquids = true,
        canPourOut = false,
        interactsWith = {"pot", "ehtanol"}
    },
    info = {
        drawTemp = false,
        drawPurityRaw = false,
        drawPurity = Config.display.tray.displayMethPurity,
        drawCooling = Config.display.tray.displayMethCoolingPercentage
    },
    temperature = {
        min = 0
    },
    liquid = {
        shuffles = false,
        sizeX = 0.27,
        sizeY = 0.45,
        maxVolume = 3000,
        usePoly = true,
        coords = {
            min = vector3(0.0, 0.0, 0.01),
            max = vector3(0.0, 0.0, 0.02)
        }
    }
}

Types.portable_stove = {
    label = "",
    model = "kq_portable_stove",
    draggable = false,
    ignore = true,
    size = 0.0,
    height = 0.0,
    offset = {
        coords = vector3(0.0, 0.0, 0.0),
        rotation = vector3(0.0, 0.0, 0.0)
    }
}

Types.lamp = {
    label = "",
    model = "xm_prop_x17_sub_lampa_small_white",
    draggable = false,
    ignore = true,
    size = 0.0,
    height = 0.6,
    offset = {
        coords = vector3(0.0, 0.0, 0.25),
        rotation = vector3(0.0, 0.0, 180.0)
    },
    callback = function(entity)
        SetEntityLights(entity, false)
    end
}

Liquids = {}

exports("AddLiquidType", function(liquidName, liquidData)
    Liquids[liquidName] = liquidData
end)

Liquids.acetone = {
    color = {142, 154, 191, 60},
    baseTemperature = 15
}

Liquids.pills = {
    color = {171, 102, 212, 140},
    baseTemperature = 15
}

Liquids.ammonia = {
    color = {199, 164, 90, 70},
    baseTemperature = 15
}

Liquids.lithium = {
    color = {76, 84, 84, 150},
    baseTemperature = 50
}

Liquids.ace_lith_mix = {
    color = {111, 66, 245, 110}
}

Liquids.cooked_ace_lith = {
    color = {148, 185, 247, 5}
}

Liquids.liquid_meth = {
    color = Config.colors.liquidMeth
}

Liquids.meth = {
    color = Config.colors.cooledMeth
}

Liquids.ethanol = {
    color = {58, 161, 224, 40},
    baseTemperature = 15
}

Liquids.solid_ethanol = {
    color = {255, 255, 255, 120}
}

Liquids.trash = {
    color = {41, 24, 5, 120}
}