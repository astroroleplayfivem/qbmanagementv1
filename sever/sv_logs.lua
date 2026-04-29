local QBCore = exports['qb-core']:GetCoreObject()

CreateThread(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS management_logs (
            id INT NOT NULL AUTO_INCREMENT,
            society_type VARCHAR(20) NOT NULL,
            society_name VARCHAR(100) NOT NULL,
            action VARCHAR(100) NOT NULL,
            actor_name VARCHAR(100) DEFAULT NULL,
            actor_citizenid VARCHAR(50) DEFAULT NULL,
            target_name VARCHAR(100) DEFAULT NULL,
            target_citizenid VARCHAR(50) DEFAULT NULL,
            details LONGTEXT DEFAULT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (id)
        )
    ]])
end)

local function GetPlayerNameBySource(src)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return 'Unknown', nil end
    local ci = Player.PlayerData.charinfo or {}
    return ((ci.firstname or 'Unknown') .. ' ' .. (ci.lastname or '')), Player.PlayerData.citizenid
end

function CreateLog(societyType, societyName, action, actorSrc, targetData, details)
    local actorName, actorCid = GetPlayerNameBySource(actorSrc)
    local targetName, targetCid = nil, nil

    if targetData then
        targetName = targetData.name
        targetCid = targetData.citizenid
    end

    MySQL.insert([[
        INSERT INTO management_logs (
            society_type, society_name, action, actor_name, actor_citizenid,
            target_name, target_citizenid, details
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        societyType,
        societyName,
        action,
        actorName,
        actorCid,
        targetName,
        targetCid,
        details and json.encode(details) or nil
    })
end

function GetLogsForUI(societyType, societyName)
    return MySQL.query.await(
        'SELECT * FROM management_logs WHERE society_type = ? AND society_name = ? ORDER BY id DESC LIMIT ?',
        { societyType, societyName, Config.MaxLogRows or 50 }
    ) or {}
end

exports('CreateLog', CreateLog)
exports('GetLogsForUI', GetLogsForUI)
