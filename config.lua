Config = Config or {}

Config.UseTarget = GetConvar('UseTarget', 'false') == 'true'
Config.Debug = false

Config.OpenCommand = 'bossui'
Config.DefaultOpenKey = 38
Config.MenuDistance = 2.0
Config.TargetDistance = 2.0
Config.HireDistance = 3.0

Config.AllowBonuses = true
Config.AllowBillingView = true
Config.AllowLogs = true
Config.AllowSocietyWithdraw = true
Config.AllowSocietyDeposit = true
Config.AllowJobStash = true

Config.MaxBillingRows = 25
Config.MaxLogRows = 50
Config.MaxEmployeesShown = 200
Config.MaxBonusAmount = 250000

Config.Wardrobe = {
    enabled = true,
    event = 'qb-clothing:client:openOutfitMenu'
}

Config.Inventory = {
    enabled = true,
    export = 'tgiann-inventory',
    method = 'OpenInventory'
}

Config.BossMenus = {
    police = {
        vector3(-568.47, -418.85, 39.63),
    },
    ambulance = {
        vector3(329.9, -580.57, 43.23),
    },
    rideout = {
        vector3(564.81, -178.54, 59.07),
    },
    whitewidow = {
        vector3(182.39, -251.43, 54.07),
    },
    harmony = {
        vector3(1194.01, 2647.85, 38.37),
    },
    hayes = {
        vector3(-1427.68, -458.41, 35.91),
    },
    wattersonstowing = {
        vector3(462.59, -1146.78, 29.61),
    },
    tequilala = {
        vector3(-560.06, 288.96, 88.11),
    },
    burgershot = {
        vector3(-1198.32, -897.49, 13.8),
    },
    vanilla = {
        vector3(97.69, -1298.28, 35.58),
    },
    catcafe = {
        vector3(-577.31, -1067.49, 26.61),
    },
}

Config.BusinessLabels = {
    whitewidow = 'White Widow',
    catcafe = 'Cat Cafe',
    rideout = 'Rideout',
    harmony = 'Harmony',
    ambulance = 'EMS',
    police = 'Police Department',
    tequilala = 'Tequilala',
    wattersonstowing = 'Wattersons Towing'
}