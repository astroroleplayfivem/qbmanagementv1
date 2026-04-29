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

local function IsPlayerGangBoss(src, gangName)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end
    if not Player.PlayerData.gang then return false end
    if Player.PlayerData.gang.name ~= gangName then return false end
    return Player.PlayerData.gang.isboss == true
end

exports('IsPlayerGangBoss', IsPlayerGangBoss)

QBCore.Functions.CreateCallback('qb-management:server:GetGangMembers', function(source, cb, gangName)
    if not IsPlayerGangBoss(source, gangName) then
        cb({})
        return
    end

    local rows = MySQL.query.await('SELECT citizenid, charinfo, gang FROM players') or {}
    local members = {}

    for _, row in ipairs(rows) do
        local gang = row.gang
        local charinfo = row.charinfo

        if type(gang) == 'string' then gang = json.decode(gang) end
        if type(charinfo) == 'string' then charinfo = json.decode(charinfo) end

        if gang and gang.name == gangName then
            members[#members + 1] = {
                citizenid = row.citizenid,
                name = ((charinfo.firstname or 'Unknown') .. ' ' .. (charinfo.lastname or '')),
                grade = (gang.grade and (gang.grade.level or gang.grade)) or 0,
                isboss = gang.isboss == true
            }
        end
    end

    table.sort(members, function(a, b)
        return a.grade > b.grade
    end)

    cb(members)
end)

RegisterNetEvent('qb-management:server:HireGangMember', function(targetId, gangName, grade)
    local src = source
    if not IsPlayerGangBoss(src, gangName) then
        Notify(src, Lang:t('error.not_gang_boss'), 'error')
        return
    end

    local Boss = QBCore.Functions.GetPlayer(src)
    local Target = QBCore.Functions.GetPlayer(tonumber(targetId))
    if not Target then
        Notify(src, Lang:t('error.player_not_found'), 'error')
        return
    end

    grade = tonumber(grade) or 0
    Target.Functions.SetGang(gangName, grade)

    local name = GetPlayerName(Target)
    EnsureEmployeeRecord('gang', gangName, Target.PlayerData.citizenid, name, GetPlayerName(Boss), grade)
    LogAction('gang', gangName, 'recruit', Boss, Target.PlayerData.citizenid, name, { grade = grade })

    Notify(src, 'Member recruited successfully.', 'success')
    Notify(Target.PlayerData.source, ('You joined %s'):format(gangName), 'success')
end)

RegisterNetEvent('qb-management:server:SetGangMemberGrade', function(gangName, citizenid, newGrade)
    local src = source
    if not IsPlayerGangBoss(src, gangName) then
        Notify(src, Lang:t('error.not_gang_boss'), 'error')
        return
    end

    newGrade = tonumber(newGrade)
    if not newGrade then
        Notify(src, Lang:t('error.invalid_grade'), 'error')
        return
    end

    local Boss = QBCore.Functions.GetPlayer(src)
    local Target = QBCore.Functions.GetPlayerByCitizenId(citizenid)

    if Target then
        if Target.PlayerData.gang.name ~= gangName then
            Notify(src, Lang:t('error.player_not_found'), 'error')
            return
        end

        Target.Functions.SetGang(gangName, newGrade)
        local targetName = GetPlayerName(Target)
        EnsureEmployeeRecord('gang', gangName, citizenid, targetName, nil, newGrade)
        LogAction('gang', gangName, 'rank_change', Boss, citizenid, targetName, { grade = newGrade })
        Notify(src, 'Member updated successfully.', 'success')
        return
    end

    local row = MySQL.single.await('SELECT charinfo, gang FROM players WHERE citizenid = ?', { citizenid })
    if not row then
        Notify(src, Lang:t('error.player_not_found'), 'error')
        return
    end

    local gang = type(row.gang) == 'string' and json.decode(row.gang) or row.gang
    local charinfo = type(row.charinfo) == 'string' and json.decode(row.charinfo) or row.charinfo

    if not gang or gang.name ~= gangName then
        Notify(src, Lang:t('error.player_not_found'), 'error')
        return
    end

    local qbGang = QBCore.Shared.Gangs[gangName]
    if qbGang and qbGang.grades and qbGang.grades[tostring(newGrade)] then
        gang.grade = {
            name = qbGang.grades[tostring(newGrade)].name,
            level = newGrade
        }
        gang.isboss = qbGang.grades[tostring(newGrade)].isboss or false
    else
        gang.grade = { name = 'Unknown', level = newGrade }
        gang.isboss = false
    end

    MySQL.update('UPDATE players SET gang = ? WHERE citizenid = ?', { json.encode(gang), citizenid })

    local targetName = ((charinfo.firstname or 'Unknown') .. ' ' .. (charinfo.lastname or ''))
    EnsureEmployeeRecord('gang', gangName, citizenid, targetName, nil, newGrade)
    LogAction('gang', gangName, 'rank_change_offline', Boss, citizenid, targetName, { grade = newGrade })
    Notify(src, 'Member updated successfully.', 'success')
end)

RegisterNetEvent('qb-management:server:FireGangMember', function(gangName, citizenid, reason)
    local src = source
    if not IsPlayerGangBoss(src, gangName) then
        Notify(src, Lang:t('error.not_gang_boss'), 'error')
        return
    end

    local Boss = QBCore.Functions.GetPlayer(src)
    local Target = QBCore.Functions.GetPlayerByCitizenId(citizenid)

    if Target and Target.PlayerData.gang.name == gangName then
        local targetName = GetPlayerName(Target)
        Target.Functions.SetGang('none', 0)
        LogAction('gang', gangName, 'kick', Boss, citizenid, targetName, { reason = reason or 'No reason' })
        Notify(src, 'Member removed successfully.', 'success')
        Notify(Target.PlayerData.source, ('You were removed from %s'):format(gangName), 'error')
        return
    end

    local row = MySQL.single.await('SELECT charinfo FROM players WHERE citizenid = ?', { citizenid })
    if not row then
        Notify(src, Lang:t('error.player_not_found'), 'error')
        return
    end

    local charinfo = type(row.charinfo) == 'string' and json.decode(row.charinfo) or row.charinfo

    local newGang = {
        name = 'none',
        label = 'No Gang',
        isboss = false,
        grade = {
            name = 'Unaffiliated',
            level = 0
        }
    }

    MySQL.update('UPDATE players SET gang = ? WHERE citizenid = ?', { json.encode(newGang), citizenid })

    local targetName = ((charinfo.firstname or 'Unknown') .. ' ' .. (charinfo.lastname or ''))
    LogAction('gang', gangName, 'kick_offline', Boss, citizenid, targetName, { reason = reason or 'No reason' })
    Notify(src, 'Member removed successfully.', 'success')
end)

RegisterNetEvent('qb-management:server:OpenGangStash', function(gangName)
    local src = source
    if not IsPlayerGangBoss(src, gangName) then
        Notify(src, Lang:t('error.not_gang_boss'), 'error')
        return
    end

    local ok = exports['qb-management']:OpenManagementStash(src, 'gang', gangName)
    if not ok then
        Notify(src, Lang:t('error.could_not_open_stash'), 'error')
    end
end)
