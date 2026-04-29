local QBCore = exports['qb-core']:GetCoreObject()

CreateThread(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS management_employee_records (
            id INT NOT NULL AUTO_INCREMENT,
            society_type VARCHAR(20) NOT NULL,
            society_name VARCHAR(100) NOT NULL,
            citizenid VARCHAR(50) NOT NULL,
            employee_name VARCHAR(100) DEFAULT NULL,
            hired_by VARCHAR(100) DEFAULT NULL,
            hired_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            notes LONGTEXT DEFAULT NULL,
            last_grade INT DEFAULT 0,
            PRIMARY KEY (id),
            UNIQUE KEY unique_record (society_type, society_name, citizenid)
        )
    ]])
end)

local function GetFullName(ci)
    return ((ci.firstname or 'Unknown') .. ' ' .. (ci.lastname or ''))
end

local function EnsureEmployeeRecord(a, b, c, d, e, f)
    local societyType, societyName, citizenid, employeeName, hiredBy, grade

    if f ~= nil or (a == 'job' or a == 'gang') then
        societyType = a or 'job'
        societyName = b
        citizenid = c
        employeeName = d
        hiredBy = e
        grade = f
    else
        societyType = 'job'
        societyName = a
        citizenid = b
        employeeName = c
        hiredBy = d
        grade = e
    end

    local exists = MySQL.single.await(
        'SELECT id FROM management_employee_records WHERE society_type = ? AND society_name = ? AND citizenid = ?',
        { societyType, societyName, citizenid }
    )

    if not exists then
        MySQL.insert([[
            INSERT INTO management_employee_records (
                society_type, society_name, citizenid, employee_name, hired_by, notes, last_grade
            ) VALUES (?, ?, ?, ?, ?, ?, ?)
        ]], {
            societyType, societyName, citizenid, employeeName, hiredBy, json.encode({}), grade or 0
        })
    else
        MySQL.update(
            'UPDATE management_employee_records SET employee_name = ?, hired_by = COALESCE(?, hired_by), last_grade = ? WHERE society_type = ? AND society_name = ? AND citizenid = ?',
            { employeeName, hiredBy, grade or 0, societyType, societyName, citizenid }
        )
    end
end

local function BuildEmployeeEntry(societyType, societyName, citizenid, ci, job, online)
    local record = MySQL.single.await(
        'SELECT hired_by, hired_at, notes, last_grade FROM management_employee_records WHERE society_type = ? AND society_name = ? AND citizenid = ?',
        { societyType, societyName, citizenid }
    )

    local gradeLevel = (job.grade and (job.grade.level or job.grade)) or 0
    local shared = societyType == 'gang' and QBCore.Shared.Gangs or QBCore.Shared.Jobs
    local jobDef = shared and shared[societyName] or nil
    local gradeDef = jobDef and jobDef.grades and jobDef.grades[tostring(gradeLevel)] or nil
    local gradeName = gradeDef and gradeDef.name or (job.grade and job.grade.name) or tostring(gradeLevel)
    local roleLabel = job.isboss and 'Owner' or 'Employee'
    if not job.isboss and type(gradeName) == 'string' then
        local lowered = string.lower(gradeName)
        if string.find(lowered, 'manager', 1, true) or string.find(lowered, 'lead', 1, true) or string.find(lowered, 'coord', 1, true) or string.find(lowered, 'supervisor', 1, true) then
            roleLabel = 'Manager'
        end
    end

    return {
        citizenid = citizenid,
        name = GetFullName(ci or {}),
        grade = gradeLevel,
        gradeName = gradeName,
        roleLabel = roleLabel,
        isboss = job.isboss == true,
        online = online == true,
        hiredBy = record and record.hired_by or 'Unknown',
        hiredAt = record and record.hired_at or nil,
        notes = record and record.notes or '[]'
    }
end

local function GetEmployeesForUI(jobName)
    local rows = MySQL.query.await('SELECT citizenid, charinfo, job FROM players') or {}
    local results = {}
    local seen = {}

    for _, player in pairs(QBCore.Functions.GetQBPlayers() or {}) do
        local pdata = player.PlayerData or {}
        local job = pdata.job
        if job and job.name == jobName then
            local citizenid = pdata.citizenid
            if citizenid then
                results[#results + 1] = BuildEmployeeEntry('job', jobName, citizenid, pdata.charinfo or {}, job, true)
                seen[citizenid] = true
            end
        end
    end

    for _, row in ipairs(rows) do
        local ci = type(row.charinfo) == 'string' and json.decode(row.charinfo) or row.charinfo
        local job = type(row.job) == 'string' and json.decode(row.job) or row.job

        if job and job.name == jobName and not seen[row.citizenid] then
            results[#results + 1] = BuildEmployeeEntry('job', jobName, row.citizenid, ci or {}, job, false)
            seen[row.citizenid] = true
        end
    end

    table.sort(results, function(a, b)
        if (a.grade or 0) == (b.grade or 0) then
            return (a.name or '') < (b.name or '')
        end
        return (a.grade or 0) > (b.grade or 0)
    end)

    return results
end

exports('GetEmployeesForUI', GetEmployeesForUI)
exports('EnsureEmployeeRecord', EnsureEmployeeRecord)

RegisterNetEvent('qb-management:server:HireEmployee', function(targetId, jobName, grade)
    local src = source
    local access = exports['qb-management']:GetManagementAccess(src, jobName)
    if not access or not access.canHire then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.no_access'), 'error')
        return
    end

    local Boss = QBCore.Functions.GetPlayer(src)
    local Target = QBCore.Functions.GetPlayer(tonumber(targetId))
    if not Target then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.player_not_found'), 'error')
        return
    end

    grade = tonumber(grade) or 0
    Target.Functions.SetJob(jobName, grade)

    local bossCi = Boss.PlayerData.charinfo or {}
    local targetCi = Target.PlayerData.charinfo or {}
    local bossName = GetFullName(bossCi)
    local targetName = GetFullName(targetCi)

    EnsureEmployeeRecord(jobName, Target.PlayerData.citizenid, targetName, bossName, grade)
    exports['qb-management']:CreateLog('job', jobName, 'hire', src, {
        name = targetName,
        citizenid = Target.PlayerData.citizenid
    }, { grade = grade })

    TriggerClientEvent('QBCore:Notify', src, Lang:t('success.employee_hired'), 'success')
    TriggerClientEvent('qb-management:client:NotifyRefresh', src, jobName)
end)

RegisterNetEvent('qb-management:server:SetEmployeeGrade', function(jobName, citizenid, grade)
    local src = source
    local access = exports['qb-management']:GetManagementAccess(src, jobName)
    if not access or not access.canPromote then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.no_access'), 'error')
        return
    end

    grade = tonumber(grade)
    if not grade then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.invalid_grade'), 'error')
        return
    end

    local Target = QBCore.Functions.GetPlayerByCitizenId(citizenid)
    if Target and Target.PlayerData.job.name == jobName then
        Target.Functions.SetJob(jobName, grade)
        local ci = Target.PlayerData.charinfo or {}
        local targetName = GetFullName(ci)
        EnsureEmployeeRecord(jobName, citizenid, targetName, nil, grade)
        exports['qb-management']:CreateLog('job', jobName, 'grade_change', src, {
            name = targetName,
            citizenid = citizenid
        }, { grade = grade })
        TriggerClientEvent('QBCore:Notify', src, Lang:t('success.employee_updated'), 'success')
        TriggerClientEvent('qb-management:client:NotifyRefresh', src, jobName)
        return
    end

    local row = MySQL.single.await('SELECT charinfo, job FROM players WHERE citizenid = ?', { citizenid })
    if not row then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.player_not_found'), 'error')
        return
    end

    local ci = type(row.charinfo) == 'string' and json.decode(row.charinfo) or row.charinfo
    local job = type(row.job) == 'string' and json.decode(row.job) or row.job
    if not job or job.name ~= jobName then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.player_not_found'), 'error')
        return
    end

    local qbJob = QBCore.Shared.Jobs[jobName]
    if qbJob and qbJob.grades and qbJob.grades[tostring(grade)] then
        job.grade = {
            name = qbJob.grades[tostring(grade)].name,
            level = grade
        }
        job.payment = qbJob.grades[tostring(grade)].payment or 0
        job.isboss = qbJob.grades[tostring(grade)].isboss or false
    end

    MySQL.update('UPDATE players SET job = ? WHERE citizenid = ?', { json.encode(job), citizenid })
    local targetName = GetFullName(ci or {})
    EnsureEmployeeRecord(jobName, citizenid, targetName, nil, grade)
    exports['qb-management']:CreateLog('job', jobName, 'grade_change_offline', src, {
        name = targetName,
        citizenid = citizenid
    }, { grade = grade })
    TriggerClientEvent('QBCore:Notify', src, Lang:t('success.employee_updated'), 'success')
    TriggerClientEvent('qb-management:client:NotifyRefresh', src, jobName)
end)

RegisterNetEvent('qb-management:server:FireEmployee', function(jobName, citizenid, reason)
    local src = source
    local access = exports['qb-management']:GetManagementAccess(src, jobName)
    if not access or not access.canFire then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.no_access'), 'error')
        return
    end

    local Target = QBCore.Functions.GetPlayerByCitizenId(citizenid)
    if Target and Target.PlayerData.job.name == jobName then
        local ci = Target.PlayerData.charinfo or {}
        local targetName = GetFullName(ci)
        Target.Functions.SetJob('unemployed', 0)
        exports['qb-management']:CreateLog('job', jobName, 'fire', src, {
            name = targetName,
            citizenid = citizenid
        }, { reason = reason or 'No reason' })
        TriggerClientEvent('QBCore:Notify', src, Lang:t('success.employee_fired'), 'success')
        TriggerClientEvent('qb-management:client:NotifyRefresh', src, jobName)
        return
    end

    local unemployed = QBCore.Shared.Jobs['unemployed']
    local newJob = {
        name = 'unemployed',
        label = unemployed and unemployed.label or 'Unemployed',
        payment = 10,
        onduty = false,
        isboss = false,
        grade = { name = 'Freelancer', level = 0 }
    }

    local row = MySQL.single.await('SELECT charinfo FROM players WHERE citizenid = ?', { citizenid })
    if not row then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.player_not_found'), 'error')
        return
    end

    local ci = type(row.charinfo) == 'string' and json.decode(row.charinfo) or row.charinfo
    local targetName = GetFullName(ci or {})
    MySQL.update('UPDATE players SET job = ? WHERE citizenid = ?', { json.encode(newJob), citizenid })

    exports['qb-management']:CreateLog('job', jobName, 'fire_offline', src, {
        name = targetName,
        citizenid = citizenid
    }, { reason = reason or 'No reason' })

    TriggerClientEvent('QBCore:Notify', src, Lang:t('success.employee_fired'), 'success')
    TriggerClientEvent('qb-management:client:NotifyRefresh', src, jobName)
end)

RegisterNetEvent('qb-management:server:AddEmployeeNote', function(_, jobName, citizenid, note)
    local src = source
    local access = exports['qb-management']:GetManagementAccess(src, jobName)
    if not access or not access.canPromote then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.no_access'), 'error')
        return
    end

    local row = MySQL.single.await(
        'SELECT notes FROM management_employee_records WHERE society_type = ? AND society_name = ? AND citizenid = ?',
        { 'job', jobName, citizenid }
    )

    local notes = {}
    if row and row.notes then
        notes = type(row.notes) == 'string' and (json.decode(row.notes) or {}) or row.notes
    end

    notes[#notes + 1] = {
        note = note,
        time = os.time()
    }

    MySQL.update(
        'UPDATE management_employee_records SET notes = ? WHERE society_type = ? AND society_name = ? AND citizenid = ?',
        { json.encode(notes), 'job', jobName, citizenid }
    )

    exports['qb-management']:CreateLog('job', jobName, 'employee_note', src, {
        name = nil,
        citizenid = citizenid
    }, { note = note })

    TriggerClientEvent('QBCore:Notify', src, Lang:t('success.note_added'), 'success')
    TriggerClientEvent('qb-management:client:NotifyRefresh', src, jobName)
end)
