local QBCore = exports['qb-core']:GetCoreObject()

local showUi = false

local isPlayerListActive = false

local activeOfficers = {} 

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerData = {}
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerData.job = JobInfo
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
    PlayerData = val
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        PlayerData = QBCore.Functions.GetPlayerData()
    end
end)

RegisterNUICallback("HideUserInterface", function()
    if showUi then
        SetNuiFocus(false, false)
        showUi = false
    end
end)

RegisterNUICallback('listActive', function(data, cb)
    if data.active == true then
        isPlayerListActive = true
        StartRefreshLoop()
    elseif data.active == false then
        isPlayerListActive = false
    end
    cb('ok')
end)

RegisterNUICallback('setCallsign', function(data, cb)
    TriggerServerEvent("4x-ActiveOfficers:SetCallsign", data.callsign)
    cb('ok')
end)

function UpdateActiveOfficersList()
    QBCore.Functions.TriggerCallback('4x-ActiveOfficers:GetOfficers', function(result)
        if #result ~= #activeOfficers or not IsSameOfficersList(result, activeOfficers) then
            activeOfficers = result 
            SendNUIMessage({
                action = 'RefreshList',
                activeOfficers = activeOfficers,
                colors = Config.Colors or {},
                useColors = Config.UseColors,
            })
        end
    end)
end

function IsSameOfficersList(list1, list2)
    if #list1 ~= #list2 then
        return false
    end
    for i = 1, #list1 do
        if not IsSameOfficer(list1[i], list2[i]) then
            return false
        end
    end
    return true
end

function IsSameOfficer(officer1, officer2)
    return officer1.name == officer2.name and officer1.badgeNumber == officer2.badgeNumber and officer1.rank == officer2.rank and officer1.gradeLevel == officer2.gradeLevel and officer1.onDuty == officer2.onDuty and officer1.radioChannel == officer2.radioChannel
end

function StartRefreshLoop()
    Citizen.CreateThread(function()
        while isPlayerListActive do
            if PlayerData.job.name == "police" then
                UpdateActiveOfficersList()
            else
                SendNUIMessage({
                    action = 'CloseList',
                })
                isPlayerListActive = false
            end
            Citizen.Wait(1000)
        end
    end)
end

RegisterKeyMapping(GetCurrentResourceName(), 'Active Officers', 'keyboard', '8')

RegisterCommand(GetCurrentResourceName(), function()
    if PlayerData.job.name == "police" then
        showUi = not showUi
        if showUi then
            UpdateActiveOfficersList()
            local playerName = PlayerData.charinfo.firstname .. " " .. PlayerData.charinfo.lastname
            SendNUIMessage({
                action = 'ShowUserInterface',
                playerName = playerName,
                playerRank = PlayerData.job.grade.name,
                playerCallsign = PlayerData.metadata.callsign,
                activeOfficers = activeOfficers,
                colors = Config.Colors or {},
                useColors = Config.UseColors,
            })
            SetNuiFocus(true, true)
        else
            SetNuiFocus(false, false)
        end
    end
end)