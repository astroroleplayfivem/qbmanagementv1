local QBCore = exports['qb-core']:GetCoreObject()

Businesses = Businesses or {}
Themes = Themes or {}

local FALLBACK_THEME = {
    id = 'default',
    label = 'Default',
    accent = '#3b82f6',
    accentSoft = 'rgba(59, 130, 246, 0.18)',
    panel = '#10151d',
    panel2 = '#151b24',
    text = '#f3f4f6',
    muted = '#9ca3af',
    icon = 'ðŸ¢'
}

local function SafeTheme(themeKey)
    if themeKey and Themes and Themes[themeKey] then
        return Themes[themeKey]
    end

    if Themes and Themes.mechanic then
        return Themes.mechanic
    end

    return FALLBACK_THEME
end

local function GetDefaultThemeForJob(jobName)
    if jobName == 'police' then
        return SafeTheme('emergency_police')
    elseif jobName == 'ambulance' then
        return SafeTheme('emergency_ems')
    elseif jobName == 'whitewidow' then
        return SafeTheme('dispensary')
    elseif jobName == 'catcafe' then
        return SafeTheme('cafe')
    elseif jobName == 'rideout' or jobName == 'harmony' then
        return SafeTheme('mechanic')
    elseif jobName == 'wattersonstowing' or jobName == 'wattersonstow' then
        return SafeTheme('towing')
    elseif jobName == 'tequilala' then
        return SafeTheme('tequilala')
    elseif jobName == 'burgershot' then
        return SafeTheme('burgershot')
    end

    return SafeTheme('mechanic')
end

local function BuildFallbackBusiness(jobName)
    local label = (Config.BusinessLabels and Config.BusinessLabels[jobName]) or jobName or 'Business'
    local subtitle = 'Business Management'
    local employeeLabel = 'Employees'

    if jobName == 'police' then
        subtitle = 'Law Enforcement'
        employeeLabel = 'Officers'
    elseif jobName == 'ambulance' then
        subtitle = 'Emergency Medical Services'
        employeeLabel = 'Medics'
    elseif jobName == 'whitewidow' then
        subtitle = 'Weed Store'
        employeeLabel = 'Staff'
    elseif jobName == 'catcafe' then
        subtitle = 'UWU Cafe'
        employeeLabel = 'Team Members'
    elseif jobName == 'rideout' or jobName == 'harmony' then
        subtitle = 'Mechanic Shop'
        employeeLabel = 'Technicians'
    elseif jobName == 'wattersonstowing' or jobName == 'wattersonstow' then
        subtitle = 'Towing Department'
        employeeLabel = 'Operators'
    elseif jobName == 'tequilala' then
        subtitle = 'Nightclub'
        employeeLabel = 'Staff'
    elseif jobName == 'burgershot' then
        subtitle = 'Fast Food Restaurant'
        employeeLabel = 'Crew Members'
    end

    local theme = GetDefaultThemeForJob(jobName)

    return {
        job = jobName,
        label = label,
        subtitle = subtitle,
        theme = theme.id or 'default',
        employeeLabel = employeeLabel
    }
end

local function GetBusinessConfig(jobName)
    local business = Businesses and Businesses[jobName] or nil
    if business then
        if not business.job then business.job = jobName end
        if not business.label then business.label = (Config.BusinessLabels and Config.BusinessLabels[jobName]) or jobName end
        if not business.subtitle then business.subtitle = 'Business Management' end
        if not business.employeeLabel then business.employeeLabel = 'Employees' end
        if not business.theme then
            local t = GetDefaultThemeForJob(jobName)
            business.theme = t.id or 'default'
        end
        return business
    end

    return BuildFallbackBusiness(jobName)
end

local function BuildGarageSummary(jobName)
    if not (Config.Garages and Config.Garages.enabled) then
        return {
            enabled = false,
            garages = {},
            totalGarages = 0,
            message = 'Garage integration disabled.'
        }
    end

    if GetResourceState(Config.Garages.resource or 'jg-advancedgarages') ~= 'started' then
        return {
            enabled = false,
            garages = {},
            totalGarages = 0,
            message = 'JG Advanced Garages is not started.'
        }
    end

    local ok, garages = pcall(function()
        return exports[Config.Garages.resource or 'jg-advancedgarages']:getAllGarages()
    end)

    if not ok or type(garages) ~= 'table' then
        return {
            enabled = false,
            garages = {},
            totalGarages = 0,
            message = 'Unable to read JG garage data.'
        }
    end

    local matches = {}
    for garageId, garage in pairs(garages) do
        local data = type(garage) == 'table' and garage or {}
        local job = data.job or data.jobName or data.allowedJob or data.whitelistedJob or data.frameworkJob
        local gang = data.gang or data.gangName
        if job == jobName and not gang then
            matches[#matches + 1] = {
                id = garageId,
                label = data.label or data.name or garageId,
                type = data.type or data.garageType or 'garage',
                vehicleType = data.vehicleType or data.spawnType or 'car',
                notes = data.description or data.category or '',
                radius = data.radius or data.accessRadius or nil,
                raw = data
            }
        end
    end

    table.sort(matches, function(a, b)
        return tostring(a.label) < tostring(b.label)
    end)

    return {
        enabled = true,
        garages = matches,
        totalGarages = #matches,
        message = #matches > 0 and nil or 'No linked job garages were found in JG Advanced Garages.'
    }
end

function OpenManagementStash(src, societyType, societyName)
    if societyType ~= 'job' then
        return false, 'unsupported_society'
    end

    if not Config.Inventory or not Config.Inventory.enabled then
        return false, 'inventory_disabled'
    end

    local Player = QBCore.Functions.GetPlayer(src)
    if not Player or not Player.PlayerData or not Player.PlayerData.job then
        return false, 'player_missing'
    end

    local playerJob = Player.PlayerData.job
    if playerJob.name ~= societyName then
        return false, 'wrong_job'
    end

    if Config.Inventory.requireBoss and not playerJob.isboss then
        return false, 'not_boss'
    end

    local bossCoords = Config.BossMenus[playerJob.name]
    if not bossCoords then
        return false, 'no_coords'
    end

    local playerPed = GetPlayerPed(src)
    local playerCoords = GetEntityCoords(playerPed)
    local nearMenu = false

    for i = 1, #bossCoords do
        local coords = bossCoords[i]
        if #(playerCoords - coords) < ((Config.MenuDistance or 2.0) + 0.5) then
            nearMenu = true
            break
        end
    end

    if not nearMenu then
        return false, 'not_near_menu'
    end

local stashName = ('%s%s'):format(Config.Inventory.stashPrefix or 'boss_', playerJob.name)
local other = {
    maxWeight = Config.Inventory.maxweight or 700000,
    slots = Config.Inventory.slots or 100,
    label = ('%s Boss Stash'):format((Config.BusinessLabels and Config.BusinessLabels[playerJob.name]) or playerJob.name)
}

exports[Config.Inventory.resource or 'tgiann-inventory']:OpenInventory(src, 'stash', stashName, other)
return true
end

exports('OpenManagementStash', OpenManagementStash)

local function BuildFullPayload(src, jobName)
    local business = GetBusinessConfig(jobName)
    if not business then return nil end

    local access = exports['qb-management']:GetManagementAccess(src, jobName)
    if not access then return nil end

    local theme = SafeTheme(business.theme)
    local balance = exports['qb-management']:GetSocietyBalance('job', jobName) or 0
    local employees = exports['qb-management']:GetEmployeesForUI(jobName) or {}
    local logs = exports['qb-management']:GetLogsForUI('job', jobName) or {}
    local billings = exports['qb-management']:GetBillingsForUI(jobName) or {}
    local bonuses = exports['qb-management']:GetBonusesForUI(jobName) or {}
    local garage = BuildGarageSummary(jobName)

    local online = 0
    for _, emp in ipairs(employees) do
        if emp.online then online = online + 1 end
    end

    return {
        job = jobName,
        business = business,
        theme = theme,
        access = access,
        garage = garage,
        branding = {
            developedBy = 'Developed by Opie Winters'
        },
        stats = {
            balance = balance,
            totalEmployees = #employees,
            onlineEmployees = online,
            totalBillings = #billings,
            totalGarages = garage.totalGarages or 0
        },
        employees = employees,
        logs = logs,
        billings = billings,
        bonuses = bonuses
    }
end

RegisterNetEvent('qb-management:server:RequestOpenUI', function(jobName)
    local src = source
    local access = exports['qb-management']:GetManagementAccess(src, jobName)

    if not access then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.no_access'), 'error')
        return
    end

    local payload = BuildFullPayload(src, jobName)
    if not payload then
        TriggerClientEvent('QBCore:Notify', src, 'Failed to build business UI payload.', 'error')
        return
    end

    TriggerClientEvent('qb-management:client:OpenUI', src, payload)
end)

RegisterNetEvent('qb-management:server:OpenBossStash', function(jobName)
    local src = source
    local ok = OpenManagementStash(src, 'job', jobName)
    if not ok then
        TriggerClientEvent('QBCore:Notify', src, 'Could not open boss stash.', 'error')
    end
end)

RegisterNetEvent('qb-management:server:OpenBossStashUI', function(jobName)
    local src = source
    local ok = OpenManagementStash(src, 'job', jobName)
    if not ok then
        TriggerClientEvent('QBCore:Notify', src, 'Could not open boss stash.', 'error')
    end
end)
