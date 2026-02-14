Config.other = {
    disableJourneyCameras = false
}

Settings = {}

Settings.vehicles = {
    journey2 = {
        model = "journey2",
        animate = "journey",
        enabled = not Config.vehicles.journey2.disabled,
        player = {
            offset = vector3(0.06, -2.35, 0.91),
            rotation = vector3(0.0, 0.0, 90.0)
        },
        door = {
            offset = vector3(-2.2, -0.15, 0.5),
            exit = vector3(-1.4, -0.15, 0.0)
        },
        spaceCheck = {
            offsetStart = vector3(-1.4, -0.15, 0.5),
            offsetEnd = vector3(-3.2, -0.15, 0.5)
        },
        enterZone = {
            offset = vector3(-1.5, -1.5, 0.5),
            radius = 1.8
        },
        camera = {
            offset = vector3(0.1, -2.3, 1.7),
            rotation = vector3(-40.0, 0.0, 90.0)
        },
        counter = {
            boundA = vector3(-0.9, -3.15, 0.8115),
            boundB = vector3(-0.45, -1.52, 0.8115)
        }
    },
    journey = {
        model = "journey",
        animate = "journey",
        enabled = not Config.vehicles.journey.disabled,
        player = {
            offset = vector3(0.06, -2.35, 0.91),
            rotation = vector3(0.0, 0.0, 90.0)
        },
        door = {
            offset = vector3(-2.2, -0.15, 0.5),
            exit = vector3(-1.4, -0.15, 0.0)
        },
        spaceCheck = {
            offsetStart = vector3(-1.4, -0.15, 0.5),
            offsetEnd = vector3(-3.2, -0.15, 0.5)
        },
        enterZone = {
            offset = vector3(-1.5, -1.5, 0.5),
            radius = 1.8
        },
        camera = {
            offset = vector3(0.1, -2.3, 1.7),
            rotation = vector3(-40.0, 0.0, 90.0)
        },
        counter = {
            boundA = vector3(-0.9, -3.15, 0.8115),
            boundB = vector3(-0.45, -1.52, 0.8115)
        }
    },
    camper = {
        model = "camper",
        animate = "camper",
        enabled = not Config.vehicles.camper.disabled,
        player = {
            offset = vector3(-0.2, -1.0, 1.21),
            rotation = vector3(0.0, 0.0, 90.0)
        },
        door = {
            offset = vector3(2.5, -0.8, 0.5),
            exit = vector3(2.5, -0.8, -0.6)
        },
        spaceCheck = {
            offsetStart = vector3(1.7, -0.8, 0.5),
            offsetEnd = vector3(3.0, -0.8, 0.5)
        },
        enterZone = {
            offset = vector3(2.4, -2.2, 0.5),
            radius = 1.8
        },
        camera = {
            offset = vector3(-0.1, -1.0, 2.0),
            rotation = vector3(-40.0, 0.0, 90.0)
        },
        counter = {
            boundA = vector3(-1.112, -1.862, 1.1115),
            boundB = vector3(-0.662, -0.232, 1.1115)
        }
    },
    kqrumpo = {
        model = "kqrumpo",
        animate = "rumpo",
        enabled = not Config.vehicles.kqrumpo.disabled,
        player = {
            offset = vector3(0.2, -1.6, 0.36),
            rotation = vector3(0.0, 0.0, 90.0)
        },
        door = {
            offset = vector3(2.0, -0.15, -0.6),
            exit = vector3(1.7, -0.15, -0.6)
        },
        spaceCheck = {
            offsetStart = vector3(1.4, -0.15, 0.5),
            offsetEnd = vector3(2.3, -0.15, 0.5)
        },
        enterZone = {
            offset = vector3(1.5, -1.7, 0.0),
            radius = 1.75
        },
        camera = {
            offset = vector3(0.1, -1.6, 1.0),
            rotation = vector3(-42.0, 0.0, 90.0)
        },
        counter = {
            boundA = vector3(-0.805, -2.432, 0.316),
            boundB = vector3(-0.355, -0.802, 0.316)
        }
    },
    kqrumpo2 = {
        model = "kqrumpo2",
        animate = "rumpo",
        enabled = not Config.vehicles.kqrumpo2.disabled,
        player = {
            offset = vector3(0.2, -1.6, 0.36),
            rotation = vector3(0.0, 0.0, 90.0)
        },
        door = {
            offset = vector3(2.0, -0.15, -0.6),
            exit = vector3(1.7, -0.15, -0.6)
        },
        spaceCheck = {
            offsetStart = vector3(1.4, -0.15, 0.5),
            offsetEnd = vector3(2.3, -0.15, 0.5)
        },
        enterZone = {
            offset = vector3(1.5, -1.7, 0.0),
            radius = 1.75
        },
        camera = {
            offset = vector3(0.1, -1.6, 1.0),
            rotation = vector3(-42.0, 0.0, 90.0)
        },
        counter = {
            boundA = vector3(-0.805, -2.432, 0.316),
            boundB = vector3(-0.355, -0.802, 0.316)
        }
    },
    vdcamper = {
        model = "vdcamper",
        animate = false,
        enabled = not Config.vehicles.vdcamper.disabled,
        spawnStove = true,
        player = {
            offset = vector3(-0.16, -2.6, 1.16),
            rotation = vector3(0.0, 0.0, 90.0)
        },
        door = {
            offset = vector3(0.0, -2.6, -0.6),
            exit = vector3(0.0, -2.6, -0.6)
        },
        spaceCheck = {
            offsetStart = vector3(0.0, -0.15, 0.5),
            offsetEnd = vector3(0.0, -0.15, 0.5)
        },
        enterZone = {
            offset = vector3(0.0, -2.4, 1.0),
            radius = 1.5
        },
        camera = {
            offset = vector3(-0.2, -2.6, 1.9),
            rotation = vector3(-42.0, 0.0, 90.0)
        },
        counter = {
            boundA = vector3(-1.105, -3.432, 1.07),
            boundB = vector3(-0.655, -1.802, 1.07)
        }
    }
}