local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}

local function DebugPrint(msg)
    if Config.Debug then
        print(('^3[qb-management:client]^7 %s'):format(msg))
    end
end

local function IsBossForJob(jobName)
    return PlayerData.job and PlayerData.job.name == jobName and PlayerData.job.isboss == true
end

local function TryOpenJobUI(jobName)
    if not jobName or jobName == '' then
        QBCore.Functions.Notify('No job was provided.', 'error')
        return
    end

    if not IsBossForJob(jobName) then
        DebugPrint(('Access denied for %s'):format(jobName))
        QBCore.Functions.Notify(Lang:t('error.no_access'), 'error')
        return
    end

    TriggerServerEvent('qb-management:server:RequestOpenUI', jobName)
end

RegisterCommand(Config.OpenCommand or 'bossui', function(_, args)
    local requestedJob = args and args[1]

    if requestedJob and requestedJob ~= '' then
        TryOpenJobUI(requestedJob)
        return
    end

    if PlayerData.job and PlayerData.job.isboss then
        TryOpenJobUI(PlayerData.job.name)
    else
        QBCore.Functions.Notify(Lang:t('error.no_access'), 'error')
    end
end, false)

local function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry('STRING')
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    local factor = string.len(text) / 370
    DrawRect(0.0, 0.0125, 0.017 + factor, 0.03, 0, 0, 0, 120)
    ClearDrawOrigin()
end

local function CreateBossTargets()
    if not Config.UseTarget then return end
    if GetResourceState('qb-target') ~= 'started' then return end

    for jobName, coordsList in pairs(Config.BossMenus or {}) do
        for i = 1, #coordsList do
            local coords = coordsList[i]
            local zoneName = ('qb-management-ui-%s-%s'):format(jobName, i)

            exports['qb-target']:AddCircleZone(zoneName, coords, 0.8, {
                name = zoneName,
                useZ = true,
                debugPoly = Config.Debug
            }, {
                options = {
                    {
                        icon = 'fas fa-building',
                        label = ('Open %s Management'):format(Config.BusinessLabels[jobName] or jobName),
                        canInteract = function()
                            return IsBossForJob(jobName)
                        end,
                        action = function()
                            TryOpenJobUI(jobName)
                        end
                    }
                },
                distance = Config.TargetDistance or 2.0
            })
        end
    end
end

local function DistanceLoop()
    CreateThread(function()
        while true do
            local sleep = 1500
            local coords = GetEntityCoords(PlayerPedId())

            for jobName, coordsList in pairs(Config.BossMenus or {}) do
                if IsBossForJob(jobName) then
                    for i = 1, #coordsList do
                        local dist = #(coords - coordsList[i])
                        if dist < 10.0 then
                            sleep = 0
                            if dist < (Config.MenuDistance or 2.0) then
                                DrawText3D(coordsList[i].x, coordsList[i].y, coordsList[i].z, '[E] Open Management')
                                if IsControlJustReleased(0, Config.DefaultOpenKey or 38) then
                                    TryOpenJobUI(jobName)
                                end
                            end
                        end
                    end
                end
            end

            Wait(sleep)
        end
    end)
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    PlayerData.job = job
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(data)
    PlayerData = data
end)

CreateThread(function()
    Wait(1000)
    PlayerData = QBCore.Functions.GetPlayerData()

    if Config.UseTarget then
        CreateBossTargets()
    else
        DistanceLoop()
    end
end)
