local QBCore = exports['qb-core']:GetCoreObject()

CreateThread(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS management_bonuses (
            id INT NOT NULL AUTO_INCREMENT,
            society_name VARCHAR(100) NOT NULL,
            citizenid VARCHAR(50) NOT NULL,
            employee_name VARCHAR(100) DEFAULT NULL,
            amount BIGINT NOT NULL DEFAULT 0,
            reason VARCHAR(255) DEFAULT NULL,
            paid_by VARCHAR(100) DEFAULT NULL,
            paid_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (id)
        )
    ]])
end)

function GetBonusesForUI(jobName)
    return MySQL.query.await(
        'SELECT * FROM management_bonuses WHERE society_name = ? ORDER BY id DESC LIMIT 25',
        { jobName }
    ) or {}
end

exports('GetBonusesForUI', GetBonusesForUI)

RegisterNetEvent('qb-management:server:PayBonus', function(jobName, citizenid, amount, reason)
    local src = source
    if not exports['qb-management']:HasBossAccess(src, jobName) then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.no_access'), 'error')
        return
    end

    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 or amount > (Config.MaxBonusAmount or 250000) then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.invalid_amount'), 'error')
        return
    end

    if not exports['qb-management']:RemoveSocietyMoney('job', jobName, amount, 'Employee bonus') then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.insufficient_funds'), 'error')
        return
    end

    local Player = QBCore.Functions.GetPlayerByCitizenId(citizenid)
    local employeeName = 'Unknown'

    if Player then
        local ci = Player.PlayerData.charinfo or {}
        employeeName = ((ci.firstname or 'Unknown') .. ' ' .. (ci.lastname or ''))
        Player.Functions.AddMoney('bank', amount, 'employee-bonus')
    else
        local row = MySQL.single.await('SELECT charinfo, money FROM players WHERE citizenid = ?', { citizenid })
        if row then
            local ci = type(row.charinfo) == 'string' and json.decode(row.charinfo) or row.charinfo
            local money = type(row.money) == 'string' and json.decode(row.money) or row.money or {}
            employeeName = ((ci.firstname or 'Unknown') .. ' ' .. (ci.lastname or ''))
            money.bank = (money.bank or 0) + amount
            MySQL.update('UPDATE players SET money = ? WHERE citizenid = ?', { json.encode(money), citizenid })
        end
    end

    local boss = QBCore.Functions.GetPlayer(src)
    local bossCi = boss and boss.PlayerData.charinfo or {}
    local paidBy = ((bossCi.firstname or 'Unknown') .. ' ' .. (bossCi.lastname or ''))

    MySQL.insert(
        'INSERT INTO management_bonuses (society_name, citizenid, employee_name, amount, reason, paid_by) VALUES (?, ?, ?, ?, ?, ?)',
        { jobName, citizenid, employeeName, amount, reason or 'Bonus', paidBy }
    )

    exports['qb-management']:CreateLog('job', jobName, 'bonus_paid', src, {
        name = employeeName,
        citizenid = citizenid
    }, { amount = amount, reason = reason or 'Bonus' })

    TriggerClientEvent('QBCore:Notify', src, Lang:t('success.bonus_sent'), 'success')
    TriggerClientEvent('qb-management:client:NotifyRefresh', src, jobName)
end)
