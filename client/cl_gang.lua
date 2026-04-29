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

local function IsPlayerGangBoss(gangName)
    return PlayerData.gang and PlayerData.gang.name == gangName and PlayerData.gang.isboss == true
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

RegisterNetEvent('qb-management:client:HireGangMember', function(gangName)
    local closestPlayer, closestDistance = GetClosestPlayer()
    if closestPlayer == -1 or closestDistance > (Config.HireDistance or 3.0) then
        QBCore.Functions.Notify(Lang:t('error.no_player'), 'error')
        return
    end

    local input = exports['qb-input']:ShowInput({
        header = 'Recruit Member',
        submitText = 'Recruit',
        inputs = {
            { text = 'Grade', name = 'grade', type = 'number', isRequired = true, default = 0 }
        }
    })
    if not input then return end

    TriggerServerEvent('qb-management:server:HireGangMember', GetPlayerServerId(closestPlayer), gangName, input.grade)
end)

RegisterNetEvent('qb-management:client:SetGangMemberGrade', function(data)
    local input = exports['qb-input']:ShowInput({
        header = ('Set Rank - %s'):format(data.member.name),
        submitText = 'Save',
        inputs = {
            { text = 'Grade', name = 'grade', type = 'number', isRequired = true, default = data.member.grade or 0 }
        }
    })
    if not input then return end
    TriggerServerEvent('qb-management:server:SetGangMemberGrade', data.gang, data.member.citizenid, input.grade)
end)

RegisterNetEvent('qb-management:client:FireGangMember', function(data)
    local input = exports['qb-input']:ShowInput({
        header = ('Remove Member - %s'):format(data.member.name),
        submitText = 'Confirm',
        inputs = {
            { text = 'Reason', name = 'reason', type = 'text', isRequired = false }
        }
    })
    if not input then return end
    TriggerServerEvent('qb-management:server:FireGangMember', data.gang, data.member.citizenid, input.reason or 'No reason given')
end)

RegisterNetEvent('qb-management:client:OpenGangMembers', function(gangName)
    QBCore.Functions.TriggerCallback('qb-management:server:GetGangMembers', function(members)
        local menu = {
            { header = ('Members - %s'):format(gangName), txt = ('Total: %s'):format(#members), isMenuHeader = true }
        }

        for _, member in ipairs(members) do
            menu[#menu + 1] = {
                header = member.name,
                txt = ('Grade: %s | CID: %s'):format(member.grade, member.citizenid),
                params = {
                    event = 'qb-management:client:OpenGangMemberOptions',
                    args = { gang = gangName, member = member }
                }
            }
        end

        if #members == 0 then
            menu[#menu + 1] = { header = 'No Members Found', txt = '', disabled = true }
        end

        menu[#menu + 1] = {
            header = '? Back',
            txt = '',
            params = { event = 'qb-management:client:OpenGangMenu', args = gangName }
        }

        exports['qb-menu']:openMenu(menu)
    end, gangName)
end)

RegisterNetEvent('qb-management:client:OpenGangMemberOptions', function(data)
    local menu = {
        { header = data.member.name, txt = ('CID: %s | Grade: %s'):format(data.member.citizenid, data.member.grade), isMenuHeader = true },
        {
            header = 'Set Rank',
            txt = 'Promote or demote member',
            params = { event = 'qb-management:client:SetGangMemberGrade', args = data }
        },
        {
            header = 'Remove Member',
            txt = 'Kick member from gang',
            params = { event = 'qb-management:client:FireGangMember', args = data }
        },
        {
            header = '? Back',
            txt = '',
            params = { event = 'qb-management:client:OpenGangMembers', args = data.gang }
        }
    }

    exports['qb-menu']:openMenu(menu)
end)

RegisterNetEvent('qb-management:client:OpenGangMenu', function(gangName)
    if not IsPlayerGangBoss(gangName) then
        QBCore.Functions.Notify(Lang:t('error.not_gang_boss'), 'error')
        return
    end

    local menu = {
        { header = ('Gang Menu - %s'):format(gangName), txt = '', isMenuHeader = true },
        {
            header = 'Member Management',
            txt = 'Recruit, rank, and remove gang members',
            params = { event = 'qb-management:client:OpenGangMembers', args = gangName }
        },
        {
            header = 'Recruit Member',
            txt = 'Recruit nearest player',
            params = { event = 'qb-management:client:HireGangMember', args = gangName }
        }
    }

    if Config.AllowGangStash then
        menu[#menu + 1] = {
            header = 'Gang Stash',
            txt = 'Open gang stash',
            params = { isServer = true, event = 'qb-management:server:OpenGangStash', args = gangName }
        }
    end

    local extraActions = exports['qb-management']:GetGangActions(gangName)
    for _, action in ipairs(extraActions) do
        menu[#menu + 1] = {
            header = action.label,
            txt = action.description or '',
            params = { event = action.event, args = action.args or {} }
        }
    end

    menu[#menu + 1] = { header = 'Close', txt = '', params = { event = 'qb-menu:closeMenu' } }

    exports['qb-menu']:openMenu(menu)
end)

local function CreateGangTargets()
    if not Config.UseTarget then return end

    for gangName, coordsList in pairs(Config.GangMenus or {}) do
        for i = 1, #coordsList do
            local coords = coordsList[i]
            local zoneName = ('qb-management-gang-%s-%s'):format(gangName, i)

            exports['qb-target']:AddCircleZone(zoneName, coords, 0.75, {
                name = zoneName,
                debugPoly = Config.Debug,
                useZ = true
            }, {
                options = {
                    {
                        icon = 'fas fa-skull-crossbones',
                        label = ('Open %s Management'):format(gangName),
                        canInteract = function()
                            return IsPlayerGangBoss(gangName)
                        end,
                        action = function()
                            TriggerEvent('qb-management:client:OpenGangMenu', gangName)
                        end
                    }
                },
                distance = Config.TargetDistance or 2.0
            })
        end
    end
end

local function GangDistanceLoop()
    CreateThread(function()
        while true do
            local sleep = 1500
            local coords = GetEntityCoords(PlayerPedId())

            for gangName, coordsList in pairs(Config.GangMenus or {}) do
                if IsPlayerGangBoss(gangName) then
                    for i = 1, #coordsList do
                        local dist = #(coords - coordsList[i])
                        if dist < 10.0 then
                            sleep = 0
                            if dist < (Config.MenuDistance or 2.0) then
                                DrawText3D(coordsList[i].x, coordsList[i].y, coordsList[i].z, '[E] Open Gang Management')
                                if IsControlJustReleased(0, Config.DefaultOpenKey or 38) then
                                    TriggerEvent('qb-management:client:OpenGangMenu', gangName)
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

RegisterNetEvent('QBCore:Client:OnGangUpdate', function(gang)
    PlayerData.gang = gang
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(data)
    PlayerData = data
end)

CreateThread(function()
    PlayerData = QBCore.Functions.GetPlayerData()
    if Config.UseTarget then
        CreateGangTargets()
    else
        GangDistanceLoop()
    end
end)
