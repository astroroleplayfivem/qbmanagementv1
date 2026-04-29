local function GetSocietyBalance(_, jobName)
    if GetResourceState('qb-banking') ~= 'started' then
        return 0
    end
    local balance = exports['qb-banking']:GetAccountBalance(jobName)
    return tonumber(balance) or 0
end

local function AddSocietyMoney(_, jobName, amount, reason)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end
    return exports['qb-banking']:AddMoney(jobName, amount, reason or 'management deposit')
end

local function RemoveSocietyMoney(_, jobName, amount, reason)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end
    local balance = GetSocietyBalance('job', jobName)
    if balance < amount then return false end
    return exports['qb-banking']:RemoveMoney(jobName, amount, reason or 'management withdraw')
end

exports('GetSocietyBalance', GetSocietyBalance)
exports('AddSocietyMoney', AddSocietyMoney)
exports('RemoveSocietyMoney', RemoveSocietyMoney)

RegisterNetEvent('qb-management:server:SocietyDeposit', function(_, jobName, amount)
    local src = source
    local QBCore = exports['qb-core']:GetCoreObject()
    local Player = QBCore.Functions.GetPlayer(src)
    local access = exports['qb-management']:GetManagementAccess(src, jobName)
    amount = math.floor(tonumber(amount) or 0)

    if not Player or amount <= 0 then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.invalid_amount'), 'error')
        return
    end

    if not access or not access.canDeposit then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.no_access'), 'error')
        return
    end

    local removed = Player.Functions.RemoveMoney('cash', amount, 'society-deposit')
    if not removed then
        local bankMoney = (Player.PlayerData.money and Player.PlayerData.money.bank) or 0
        if bankMoney >= amount then
            removed = Player.Functions.RemoveMoney('bank', amount, 'society-deposit')
        end
    end

    if not removed then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.invalid_amount'), 'error')
        return
    end

    AddSocietyMoney('job', jobName, amount, 'Management deposit')
    exports['qb-management']:CreateLog('job', jobName, 'deposit', src, nil, { amount = amount })
    TriggerClientEvent('QBCore:Notify', src, Lang:t('success.society_deposit'), 'success')
    TriggerClientEvent('qb-management:client:NotifyRefresh', src, jobName)
end)

RegisterNetEvent('qb-management:server:SocietyWithdraw', function(_, jobName, amount)
    local src = source
    local QBCore = exports['qb-core']:GetCoreObject()
    local Player = QBCore.Functions.GetPlayer(src)
    local access = exports['qb-management']:GetManagementAccess(src, jobName)
    amount = math.floor(tonumber(amount) or 0)

    if not Player or amount <= 0 then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.invalid_amount'), 'error')
        return
    end

    if not access or not access.canWithdraw then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.no_access'), 'error')
        return
    end

    if not RemoveSocietyMoney('job', jobName, amount, 'Management withdraw') then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.insufficient_funds'), 'error')
        return
    end

    Player.Functions.AddMoney('bank', amount, 'society-withdraw')
    exports['qb-management']:CreateLog('job', jobName, 'withdraw', src, nil, { amount = amount })
    TriggerClientEvent('QBCore:Notify', src, Lang:t('success.society_withdraw'), 'success')
    TriggerClientEvent('qb-management:client:NotifyRefresh', src, jobName)
end)
