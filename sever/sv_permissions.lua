local QBCore = exports['qb-core']:GetCoreObject()

local function GetJobDefinition(jobName)
    return QBCore.Shared.Jobs and QBCore.Shared.Jobs[jobName] or nil
end

local function GetSortedGradeLevels(jobName)
    local job = GetJobDefinition(jobName)
    if not job or not job.grades then return {} end

    local levels = {}
    for key in pairs(job.grades) do
        local level = tonumber(key)
        if level then
            levels[#levels + 1] = level
        end
    end

    table.sort(levels)
    return levels
end

local function GetManagerFallbackLevel(jobName)
    local levels = GetSortedGradeLevels(jobName)
    if #levels == 0 then return nil end

    local ownerLevel = levels[#levels]
    for i = #levels - 1, 1, -1 do
        local level = levels[i]
        local grade = GetJobDefinition(jobName).grades[tostring(level)]
        if not (grade and grade.isboss) then
            return level
        end
    end

    return ownerLevel
end

local function MatchesManagerKeyword(name)
    if type(name) ~= 'string' then return false end
    local lowered = string.lower(name)
    local keywords = (Config.ManagementRoles and Config.ManagementRoles.managerKeywords) or {}

    for i = 1, #keywords do
        if string.find(lowered, keywords[i], 1, true) then
            return true
        end
    end

    return false
end

function GetManagementAccess(src, jobName)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player or not Player.PlayerData or not Player.PlayerData.job then
        return nil
    end

    local playerJob = Player.PlayerData.job
    if playerJob.name ~= jobName then
        return nil
    end

    local gradeLevel = tonumber(playerJob.grade and (playerJob.grade.level or playerJob.grade)) or 0
    local gradeDef = GetJobDefinition(jobName) and GetJobDefinition(jobName).grades[tostring(gradeLevel)] or nil
    local gradeName = gradeDef and gradeDef.name or (playerJob.grade and playerJob.grade.name) or tostring(gradeLevel)
    local isOwner = playerJob.isboss == true or (gradeDef and gradeDef.isboss == true) or false

    local isManager = false
    if not isOwner then
        isManager = MatchesManagerKeyword(gradeName)
        if not isManager and Config.ManagementRoles and Config.ManagementRoles.managerFallbackToSecondHighest then
            local fallbackLevel = GetManagerFallbackLevel(jobName)
            isManager = fallbackLevel ~= nil and gradeLevel >= fallbackLevel
        end
    end

    local role = 'employee'
    if isOwner then
        role = 'owner'
    elseif isManager then
        role = 'manager'
    end

    return {
        job = jobName,
        gradeLevel = gradeLevel,
        gradeName = gradeName,
        isEmployee = true,
        isManager = isManager,
        isOwner = isOwner,
        canHire = isManager or isOwner,
        canFire = isManager or isOwner,
        canPromote = isManager or isOwner,
        canPayBonus = isManager or isOwner,
        canViewFinance = isManager or isOwner,
        canDeposit = isManager or isOwner,
        canWithdraw = isOwner,
        canOpenBossStash = isOwner or ((Config.Inventory and not Config.Inventory.requireBoss) and (isManager or isOwner)),
        canOpenWardrobe = Config.Wardrobe and Config.Wardrobe.enabled or false,
        canViewLogs = isOwner,
        canViewGarage = Config.Garages and Config.Garages.enabled or false,
        role = role
    }
end

function HasBossAccess(src, jobName)
    local access = GetManagementAccess(src, jobName)
    return access and access.isOwner == true or false
end

exports('HasBossAccess', HasBossAccess)
exports('GetManagementAccess', GetManagementAccess)
