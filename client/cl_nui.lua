local QBCore = exports['qb-core']:GetCoreObject()

local nuiOpen = false
local currentJob = nil

local function ForceCloseNui()
    nuiOpen = false
    currentJob = nil
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)

    SendNUIMessage({ action = 'forceClose' })
end

local function OpenNui(data)
    if not data then return end

    nuiOpen = true
    currentJob = data.job or nil

    SendNUIMessage({
        action = 'open',
        payload = data
    })

    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)
end

local function CloseNui()
    nuiOpen = false
    currentJob = nil
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    SendNUIMessage({ action = 'close' })
end

AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    Wait(250)
    ForceCloseNui()
end)

AddEventHandler('onClientResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    ForceCloseNui()
end)

RegisterNetEvent('qb-management:client:OpenUI', function(data)
    if not data then
        QBCore.Functions.Notify('Management UI failed to load data.', 'error')
        return
    end

    OpenNui(data)
end)

RegisterNetEvent('qb-management:client:RefreshUI', function(data)
    if not nuiOpen then return end
    SendNUIMessage({ action = 'hydrate', payload = data or {} })
end)

RegisterNetEvent('qb-management:client:NotifyRefresh', function(job)
    if nuiOpen and currentJob and job == currentJob then
        TriggerServerEvent('qb-management:server:RequestOpenUI', currentJob)
    end
end)

RegisterNUICallback('close', function(_, cb)
    CloseNui()
    cb('ok')
end)

RegisterNUICallback('requestRefresh', function(_, cb)
    if currentJob then
        TriggerServerEvent('qb-management:server:RequestOpenUI', currentJob)
    end
    cb('ok')
end)

RegisterNUICallback('setGrade', function(data, cb)
    if data and data.job and data.citizenid then
        TriggerServerEvent('qb-management:server:SetEmployeeGrade', data.job, data.citizenid, data.grade)
    end
    cb('ok')
end)

RegisterNUICallback('fireEmployee', function(data, cb)
    if data and data.job and data.citizenid then
        TriggerServerEvent('qb-management:server:FireEmployee', data.job, data.citizenid, data.reason or 'No reason given')
    end
    cb('ok')
end)

RegisterNUICallback('hireNearest', function(data, cb)
    local coords = GetEntityCoords(PlayerPedId())
    local players = QBCore.Functions.GetPlayersFromCoords(coords)
    local closestPlayer = nil
    local closestDistance = 9999.0

    for _, player in ipairs(players) do
        if player ~= PlayerId() then
            local ped = GetPlayerPed(player)
            local dist = #(GetEntityCoords(ped) - coords)
            if dist < closestDistance then
                closestPlayer = player
                closestDistance = dist
            end
        end
    end

    if not closestPlayer or closestDistance > (Config.HireDistance or 3.0) then
        QBCore.Functions.Notify(Lang:t('error.no_nearby_player'), 'error')
        cb('ok')
        return
    end

    TriggerServerEvent('qb-management:server:HireEmployee', GetPlayerServerId(closestPlayer), data.job, tonumber(data.grade) or 0)
    cb('ok')
end)

RegisterNUICallback('payBonus', function(data, cb)
    if data and data.job and data.citizenid then
        TriggerServerEvent('qb-management:server:PayBonus', data.job, data.citizenid, data.amount, data.reason or 'Bonus')
    end
    cb('ok')
end)

RegisterNUICallback('addNote', function(data, cb)
    if data and data.job and data.citizenid and data.note then
        TriggerServerEvent('qb-management:server:AddEmployeeNote', 'job', data.job, data.citizenid, data.note)
    end
    cb('ok')
end)

RegisterNUICallback('societyDeposit', function(data, cb)
    if data and data.job then
        TriggerServerEvent('qb-management:server:SocietyDeposit', 'job', data.job, data.amount)
    end
    cb('ok')
end)

RegisterNUICallback('societyWithdraw', function(data, cb)
    if data and data.job then
        TriggerServerEvent('qb-management:server:SocietyWithdraw', 'job', data.job, data.amount)
    end
    cb('ok')
end)

RegisterNUICallback('openWardrobe', function(_, cb)
    if Config.Wardrobe and Config.Wardrobe.enabled and Config.Wardrobe.event then
        TriggerEvent(Config.Wardrobe.event)
    end
    cb('ok')
end)

RegisterNUICallback('openBossStash', function(data, cb)
    if data and data.job then
        TriggerServerEvent('qb-management:server:OpenBossStash', data.job)
    end
    cb('ok')
end)

RegisterNUICallback('openGarage', function(data, cb)
    if not (Config.Garages and Config.Garages.enabled) then
        cb('ok')
        return
    end

    if GetResourceState(Config.Garages.resource or 'jg-advancedgarages') ~= 'started' then
        QBCore.Functions.Notify('JG Advanced Garages is not started.', 'error')
        cb('ok')
        return
    end

    if data and data.garageId then
        TriggerEvent('jg-advancedgarages:client:open-garage', data.garageId, data.vehicleType or 'car', nil)
    end

    cb('ok')
end)

CreateThread(function()
    while true do
        Wait(0)
        if nuiOpen and IsControlJustReleased(0, 322) then
            CloseNui()
        end
    end
end)
