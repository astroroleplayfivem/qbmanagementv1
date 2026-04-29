local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}

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

local function IsPlayerBoss(jobName)
    return PlayerData.job and PlayerData.job.name == jobName and PlayerData.job.isboss == true
end

local function GetClosestPlayer()
    local closestPlayer, closestDistance = -1, -1
    local coords = GetEntityCoords(PlayerPedId())
    local players = QBCore.Functions.GetPlayersFromCoords(coords)

    for _, player in ipairs(players) do
        if player ~= PlayerId() then
            local ped = GetPlayerPed(player)
            local dist = #(GetEntityCoords(ped) - coords)
            if closestDistance == -1 or dist < closestDistance then
                closestPlayer = player
                closestDistance = dist
            end
        end
    end

    return closestPlayer, closestDistance
end

local function OpenSocietyMenu(jobName)
    QBCore.Functions.TriggerCallback('qb-management:server:GetSocietyBalance', function(balance)
        local menu = {
            {
                header = ('Society - %s'):format(jobName),
                txt = ('$%s'):format(balance or 0),
                isMenuHeader = true
            },
            {
                header = 'Deposit Money',
                txt = 'Add money into business account',
                params = {
                    event = 'qb-management:client:SocietyDeposit',
                    args = {
                        societyType = 'job',
                        societyName = jobName
                    }
                }
            },
            {
                header = 'Withdraw Money',
                txt = 'Take money from business account',
                params = {
                    event = 'qb-management:client:SocietyWithdraw',
                    args = {
                        societyType = 'job',
                        societyName = jobName
                    }
                }
            },
            {
                header = 'View Logs',
                txt = 'Recent management actions',
                params = {
                    event = 'qb-management:client:OpenLogs',
                    args = {
                        societyType = 'job',
                        societyName = jobName
                    }
                }
            },
            {
                header = '? Back',
                txt = '',
                params = {
                    event = 'qb-management:client:OpenBossMenu',
                    args = jobName
                }
            }
        }

        exports['qb-menu']:openMenu(menu)
    end, 'job', jobName)
end

local function OpenEmployeeOptions(jobName, employee)
    local menu = {
        {
            header = employee.name,
            txt = ('CID: %s | Grade: %s'):format(employee.citizenid, employee.grade),
            isMenuHeader = true
        },
        {
            header = 'Set Grade',
            txt = 'Promote or demote employee',
            params = {
                event = 'qb-management:client:SetEmployeeGrade',
                args = {
                    job = jobName,
                    employee = employee
                }
            }
        },
        {
            header = 'Fire Employee',
            txt = 'Remove employee from the business',
            params = {
                event = 'qb-management:client:FireEmployee',
                args = {
                    job = jobName,
                    employee = employee
                }
            }
        },
        {
            header = 'Employee Record',
            txt = 'View notes and details',
            params = {
                event = 'qb-management:client:OpenEmployeeRecord',
                args = {
                    societyType = 'job',
                    societyName = jobName,
                    employee = employee
                }
            }
        },
        {
            header = 'Add Note',
            txt = 'Add management note',
            params = {
                event = 'qb-management:client:AddEmployeeNote',
                args = {
                    societyType = 'job',
                    societyName = jobName,
                    employee = employee
                }
            }
        },
        {
            header = '? Back',
            txt = '',
            params = {
                event = 'qb-management:client:OpenEmployees',
                args = jobName
            }
        }
    }

    exports['qb-menu']:openMenu(menu)
end

RegisterNetEvent('qb-management:client:OpenEmployeeRecord', function(data)
    QBCore.Functions.TriggerCallback('qb-management:server:GetEmployeeRecord', function(record)
        local menu = {
            {
                header = ('Record - %s'):format(data.employee.name),
                txt = '',
                isMenuHeader = true
            }
        }

        if record then
            menu[#menu + 1] = {
                header = 'Hire Info',
                txt = ('Hired By: %s | Last Grade: %s'):format(record.hired_by or 'Unknown', record.last_grade or 0),
                disabled = true
            }

            local notes = {}
            if record.notes then
                notes = type(record.notes) == 'string' and (json.decode(record.notes) or {}) or record.notes
            end

            if #notes == 0 then
                menu[#menu + 1] = {
                    header = 'No Notes',
                    txt = '',
                    disabled = true
                }
            else
                for i = #notes, 1, -1 do
                    local note = notes[i]
                    menu[#menu + 1] = {
                        header = ('Note #%s'):format(i),
                        txt = note.note or 'No text',
                        disabled = true
                    }
                end
            end
        else
            menu[#menu + 1] = {
                header = 'No record found',
                txt = '',
                disabled = true
            }
        end

        menu[#menu + 1] = {
            header = '? Back',
            txt = '',
            params = {
                event = 'qb-management:client:OpenEmployeeOptions',
                args = {
                    job = data.societyName,
                    employee = data.employee
                }
            }
        }

        exports['qb-menu']:openMenu(menu)
    end, data.societyType, data.societyName, data.employee.citizenid)
end)

RegisterNetEvent('qb-management:client:AddEmployeeNote', function(data)
    local input = exports['qb-input']:ShowInput({
        header = ('Add Note - %s'):format(data.employee.name),
        submitText = 'Save',
        inputs = {
            {
                text = 'Note',
                name = 'note',
                type = 'text',
                isRequired = true
            }
        }
    })

    if not input or not input.note then return end

    TriggerServerEvent(
        'qb-management:server:AddEmployeeNote',
        data.societyType,
        data.societyName,
        data.employee.citizenid,
        input.note
    )
end)

RegisterNetEvent('qb-management:client:SocietyDeposit', function(data)
    local input = exports['qb-input']:ShowInput({
        header = 'Deposit to Society',
        submitText = 'Deposit',
        inputs = {
            {
                text = 'Amount',
                name = 'amount',
                type = 'number',
                isRequired = true
            }
        }
    })

    if not input then return end
    TriggerServerEvent('qb-management:server:SocietyDeposit', data.societyType, data.societyName, input.amount)
end)

RegisterNetEvent('qb-management:client:SocietyWithdraw', function(data)
    local input = exports['qb-input']:ShowInput({
        header = 'Withdraw from Society',
        submitText = 'Withdraw',
        inputs = {
            {
                text = 'Amount',
                name = 'amount',
                type = 'number',
                isRequired = true
            }
        }
    })

    if not input then return end
    TriggerServerEvent('qb-management:server:SocietyWithdraw', data.societyType, data.societyName, input.amount)
end)

RegisterNetEvent('qb-management:client:OpenLogs', function(data)
    QBCore.Functions.TriggerCallback('qb-management:server:GetManagementLogs', function(logs)
        local menu = {
            {
                header = ('Logs - %s'):format(data.societyName),
                txt = '',
                isMenuHeader = true
            }
        }

        if not logs or #logs == 0 then
            menu[#menu + 1] = {
                header = 'No Logs Found',
                txt = '',
                disabled = true
            }
        else
            for _, log in ipairs(logs) do
                menu[#menu + 1] = {
                    header = ('%s - %s'):format(log.action or 'Unknown', log.actor_name or 'Unknown'),
                    txt = ('Target: %s'):format(log.target_name or 'N/A'),
                    disabled = true
                }
            end
        end

        menu[#menu + 1] = {
            header = '? Back',
            txt = '',
            params = {
                event = 'qb-management:client:OpenSocietyMenu',
                args = data.societyName
            }
        }

        exports['qb-menu']:openMenu(menu)
    end, data.societyType, data.societyName)
end)

RegisterNetEvent('qb-management:client:SetEmployeeGrade', function(data)
    local input = exports['qb-input']:ShowInput({
        header = ('Set Grade - %s'):format(data.employee.name),
        submitText = 'Save',
        inputs = {
            {
                text = 'Grade',
                name = 'grade',
                type = 'number',
                isRequired = true,
                default = data.employee.grade or 0
            }
        }
    })

    if not input then return end
    TriggerServerEvent('qb-management:server:SetEmployeeGrade', data.job, data.employee.citizenid, input.grade)
end)

RegisterNetEvent('qb-management:client:FireEmployee', function(data)
    local input = exports['qb-input']:ShowInput({
        header = ('Fire Employee - %s'):format(data.employee.name),
        submitText = 'Confirm',
        inputs = {
            {
                text = 'Reason',
                name = 'reason',
                type = 'text',
                isRequired = false
            }
        }
    })

    if not input then return end
    TriggerServerEvent('qb-management:server:FireEmployee', data.job, data.employee.citizenid, input.reason or 'No reason given')
end)

RegisterNetEvent('qb-management:client:HireEmployee', function(jobName)
    local closestPlayer, closestDistance = GetClosestPlayer()
    if closestPlayer == -1 or closestDistance > (Config.HireDistance or 3.0) then
        QBCore.Functions.Notify(Lang:t('error.no_player'), 'error')
        return
    end

    local input = exports['qb-input']:ShowInput({
        header = 'Hire Employee',
        submitText = 'Hire',
        inputs = {
            {
                text = 'Grade',
                name = 'grade',
                type = 'number',
                isRequired = true,
                default = 0
            }
        }
    })

    if not input then return end
    TriggerServerEvent('qb-management:server:HireEmployee', GetPlayerServerId(closestPlayer), jobName, input.grade)
end)

RegisterNetEvent('qb-management:client:OpenEmployees', function(jobName)
    QBCore.Functions.TriggerCallback('qb-management:server:GetEmployees', function(employees)
        local menu = {
            {
                header = ('Employees - %s'):format(jobName),
                txt = ('Total: %s'):format(#employees),
                isMenuHeader = true
            }
        }

        for _, employee in ipairs(employees) do
            menu[#menu + 1] = {
                header = employee.name,
                txt = ('Grade: %s | CID: %s'):format(employee.grade, employee.citizenid),
                params = {
                    event = 'qb-management:client:OpenEmployeeOptions',
                    args = {
                        job = jobName,
                        employee = employee
                    }
                }
            }
        end

        if #employees == 0 then
            menu[#menu + 1] = {
                header = 'No Employees Found',
                txt = '',
                disabled = true
            }
        end

        menu[#menu + 1] = {
            header = '? Back',
            txt = '',
            params = {
                event = 'qb-management:client:OpenBossMenu',
                args = jobName
            }
        }

        exports['qb-menu']:openMenu(menu)
    end, jobName)
end)

RegisterNetEvent('qb-management:client:OpenEmployeeOptions', function(data)
    OpenEmployeeOptions(data.job, data.employee)
end)

RegisterNetEvent('qb-management:client:OpenSocietyMenu', function(jobName)
    OpenSocietyMenu(jobName)
end)

RegisterNetEvent('qb-management:client:OpenBossMenu', function(jobName)
    if not IsPlayerBoss(jobName) then
        QBCore.Functions.Notify(Lang:t('error.not_boss'), 'error')
        return
    end

    local menu = {
        {
            header = ('Boss Menu - %s'):format(jobName),
            txt = '',
            isMenuHeader = true
        },
        {
            header = 'Employee Management',
            txt = 'View, promote, fire, and manage employee records',
            params = {
                event = 'qb-management:client:OpenEmployees',
                args = jobName
            }
        },
        {
            header = 'Hire Employee',
            txt = 'Hire nearest player',
            params = {
                event = 'qb-management:client:HireEmployee',
                args = jobName
            }
        }
    }

    if Config.AllowSocietyManagement then
        menu[#menu + 1] = {
            header = 'Society Management',
            txt = 'Business funds and financial actions',
            params = {
                event = 'qb-management:client:OpenSocietyMenu',
                args = jobName
            }
        }
    end

    if Config.AllowJobStash then
        menu[#menu + 1] = {
            header = 'Boss Stash',
            txt = 'Open management stash',
            params = {
                isServer = true,
                event = 'qb-management:server:OpenBossStash',
                args = jobName
            }
        }
    end

    if Config.AllowWardrobe and Config.Wardrobe and Config.Wardrobe.event then
        menu[#menu + 1] = {
            header = Config.Wardrobe.label or 'Wardrobe',
            txt = Config.Wardrobe.description or '',
            params = {
                event = Config.Wardrobe.event
            }
        }
    end

    menu[#menu + 1] = {
        header = 'Close',
        txt = '',
        params = {
            event = 'qb-menu:closeMenu'
        }
    }

    exports['qb-menu']:openMenu(menu)
end)

local function CreateBossTargets()
    if not Config.UseTarget then return end
    if GetResourceState('qb-target') ~= 'started' then return end

    for jobName, coordsList in pairs(Config.BossMenus or {}) do
        for i = 1, #coordsList do
            local coords = coordsList[i]
            local zoneName = ('qb-management-boss-%s-%s'):format(jobName, i)

            exports['qb-target']:AddCircleZone(zoneName, coords, 0.75, {
                name = zoneName,
                debugPoly = Config.Debug,
                useZ = true
            }, {
                options = {
                    {
                        icon = 'fas fa-briefcase',
                        label = ('Open %s Management'):format(jobName),
                        canInteract = function()
                            return IsPlayerBoss(jobName)
                        end,
                        action = function()
                            TriggerEvent('qb-management:client:OpenBossMenu', jobName)
                        end
                    }
                },
                distance = Config.TargetDistance or 2.0
            })
        end
    end
end

local function BossDistanceLoop()
    CreateThread(function()
        while true do
            local sleep = 1500
            local coords = GetEntityCoords(PlayerPedId())

            for jobName, coordsList in pairs(Config.BossMenus or {}) do
                if IsPlayerBoss(jobName) then
                    for i = 1, #coordsList do
                        local dist = #(coords - coordsList[i])
                        if dist < 10.0 then
                            sleep = 0
                            if dist < (Config.MenuDistance or 2.0) then
                                DrawText3D(coordsList[i].x, coordsList[i].y, coordsList[i].z, '[E] Open Management')
                                if IsControlJustReleased(0, Config.DefaultOpenKey or 38) then
                                    TriggerEvent('qb-management:client:OpenBossMenu', jobName)
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
    PlayerData = QBCore.Functions.GetPlayerData()

    if Config.UseTarget then
        CreateBossTargets()
    else
        BossDistanceLoop()
    end
end)
