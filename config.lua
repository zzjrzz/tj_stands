Config = {}

-- Item Images Path
Config.ItemImages = "nui://ox_inventory/web/images"

-- Stand Configuration
Config.Stands = {
    -- Example stand locations
    {
        coords = vector3(-1395.9746, -1150.7188, 3.2240),
        heading = 295.0879,
        prop = "prop_ven_market_table1",
        textOffset = vector3(0.0, 0.0, 0.5) -- Offset for text
    },
    {
        coords = vector3(-1394.6546, -1153.7188, 3.2912),
        heading = 295.0879,
        prop = "prop_ven_market_table1",
        textOffset = vector3(0.0, 0.0, 0.5)
    },
    {
        coords = vector3(-1393.3346, -1156.7188, 3.3584),
        heading = 295.0879,
        prop = "prop_ven_market_table1",
        textOffset = vector3(0.0, 0.0, 0.5)
    },
    {
        coords = vector3(-1392.0146, -1159.7188, 3.4256),
        heading = 295.0879,
        prop = "prop_ven_market_table1",
        textOffset = vector3(0.0, 0.0, 0.5)
    },
    {
        coords = vector3(-1390.6946, -1162.7188, 3.4928),
        heading = 295.0879,
        prop = "prop_ven_market_table1",
        textOffset = vector3(0.0, 0.0, 0.5)
    },
    {
        coords = vector3(-1389.3746, -1165.7188, 3.5600),
        heading = 295.0879,
        prop = "prop_ven_market_table1",
        textOffset = vector3(0.0, 0.0, 0.5)
    },
    {
        coords = vector3(-1389.3746, -1165.7188, 3.5600),
        heading = 295.0879,
        prop = "prop_ven_market_table1",
        textOffset = vector3(0.0, 0.0, 0.5)
    },
    {
        coords = vector3(-1392.3746, -1167.2188, 3.5600),
        heading = 295.0879,
        prop = "prop_ven_market_table1",
        textOffset = vector3(0.0, 0.0, 0.5)
    },
    {
        coords = vector3(-1393.6946, -1164.2188, 3.4928),
        heading = 295.0879,
        prop = "prop_ven_market_table1",
        textOffset = vector3(0.0, 0.0, 0.5)
    },
    {
        coords = vector3(-1395.0146, -1161.2188, 3.4256),
        heading = 295.0879,
        prop = "prop_ven_market_table1",
        textOffset = vector3(0.0, 0.0, 0.5)
    },
    {
        coords = vector3(-1396.3346, -1158.2188, 3.3584),
        heading = 295.0879,
        prop = "prop_ven_market_table1",
        textOffset = vector3(0.0, 0.0, 0.5)
    },
    {
        coords = vector3(-1397.6546, -1155.2188, 3.2912),
        heading = 295.0879,
        prop = "prop_ven_market_table1",
        textOffset = vector3(0.0, 0.0, 0.5)
    },
    {
        coords = vector3(-1398.9746, -1152.2188, 3.2240),
        heading = 295.0879,
        prop = "prop_ven_market_table1",
        textOffset = vector3(0.0, 0.0, 0.5)
    }
}

-- Rental Configuration
Config.Rental = {
    basePrice = 100, -- Price per hour
    minHours = 1,
    maxHours = 72,
    maxItems = 20 -- Maximum items per stand
}

-- Text Configuration
Config.Text = {
    available = "Available Stand",
    currency = "$"
}