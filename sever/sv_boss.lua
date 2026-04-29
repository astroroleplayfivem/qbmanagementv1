local QBCore = exports['qb-core']:GetCoreObject()

local function Notify(src, msg, msgType)
    exports['qb-management']:NotifyManagement(src, msg, msgType)
end

local function GetPlayerName(player)
    return exports['qb-management']:GetPlayerName(player)
end

local function EnsureEmployeeRecord(...)
    return exports['qb-management']:EnsureEmployeeRecord(...)
end

local function LogAction(...)
    return exports['qb-management']:LogManagementAction(...)
end

local function IsPlayerBoss(src, jobName)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end
    if not Player.PlayerData.job then return false end
    if Player.PlayerData.job.name ~= jobName then return false end
    return Player.PlayerData.job.isboss == true
end

exports('IsPlayerBoss', IsPlayerBoss)

-- Employee management callbacks/events live in server/sv_employees.lua
-- Keeping them out of this file prevents duplicate handlers and stale UI data.

RegisterNetEvent('qb-management:server:OpenBossStashUI', function(jobName)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local playerJob = Player.PlayerData.job
    if not playerJob then return end
    if playerJob.name ~= jobName then return end
    if not playerJob.isboss then return end

    local bossCoords = Config.BossMenus[playerJob.name]
    if not bossCoords then return end
    if not Config.Inventory or not Config.Inventory.enabled then return end

    local playerPed = GetPlayerPed(src)
    local playerCoords = GetEntityCoords(playerPed)

    for i = 1, #bossCoords do
        local coords = bossCoords[i]
        if #(playerCoords - coords) < 2.5 then
            local stashName = 'boss_' .. playerJob.name

            if Config.Inventory.export == 'qb-inventory' and Config.Inventory.event == 'OpenInventory' then
                exports['qb-inventory']:OpenInventory(src, stashName, {
                    maxweight = 700000,
                    slots = 100,
                })

            elseif Config.Inventory.export == 'tgiann-inventory' and Config.Inventory.event == 'OpenInventory' then
                exports['tgiann-inventory']:OpenInventory(src, 'stash', stashName, {
                    maxweight = 700000,
                    slots = 100,
                    label = ('%s Boss Stash'):format(Config.BusinessLabels[playerJob.name] or playerJob.name),
                    coords = coords
                })
            end

            return
        end
    end
end)
