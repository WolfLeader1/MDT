local isVisible = false
local tabletObject = nil

RegisterNetEvent('envyrp:playerSpawned')
AddEventHandler('envyrp:playerSpawned', function()
    TriggerServerEvent("emsmdt:getOffensesAndOfficer")
end)

RegisterNetEvent("emsmdt:sendNUIMessage")
AddEventHandler("emsmdt:sendNUIMessage", function(messageTable)
    SendNUIMessage(messageTable)
end)

RegisterNetEvent("emsmdt:toggleVisibilty")
AddEventHandler("emsmdt:toggleVisibilty", function(reports, warrants, officer, switch)
        local playerPed = PlayerPedId()
        if not isVisible then
            local dict = "amb@world_human_seat_wall_tablet@female@base"
            RequestAnimDict(dict)
            if tabletObject == nil then
                tabletObject = CreateObject(GetHashKey('prop_cs_tablet'), GetEntityCoords(playerPed), 1, 1, 1)
                AttachEntityToEntity(tabletObject, playerPed, GetPedBoneIndex(playerPed, 28422), 0.0, 0.0, 0.03, 0.0, 0.0, 0.0, 1, 1, 0, 1, 0, 1)
            end
            while not HasAnimDictLoaded(dict) do Citizen.Wait(100) end
            if not IsEntityPlayingAnim(playerPed, dict, 'base', 3) then
                TaskPlayAnim(playerPed, dict, "base", 8.0, 1.0, -1, 49, 1.0, 0, 0, 0)
            end
        else
            DeleteEntity(tabletObject)
            ClearPedTasks(playerPed)
            tabletObject = nil
        end
    if #warrants == 0 then warrants = false end
    if #reports == 0 then reports = false end
    SendNUIMessage({
        type = "recentReportsAndWarrantsLoaded",
        reports = reports,
        warrants = warrants,
        officer = officer
    })
    if switch == false then
        SendNUIMessage({
            type = "HOME"
        })
    else
        ToggleGUI()
    end
end)

RegisterNetEvent("emsmdt:offduty")
AddEventHandler("emsmdt:offduty", function(officer)
    if officer then
        SendNUIMessage({ type = "sendOfficerName", name = officer })
        ToggleGUI()
    end
    SendNUIMessage({ type = "imoffduty" })
end)


RegisterNUICallback("logOff", function(data, cb)
    TriggerServerEvent('erp-emsmdt:switchDuty')
    cb('ok')
end)

RegisterNUICallback("close", function(data, cb)
    local playerPed = PlayerPedId()
    DeleteEntity(tabletObject)
    ClearPedTasks(playerPed)
    tabletObject = nil
    ToggleGUI(false)
    cb('ok')
end)

RegisterNUICallback("performOffenderSearch", function(data, cb)
    TriggerServerEvent("emsmdt:performOffenderSearch", data.query)
    cb('ok')
end)

RegisterNUICallback("viewOffender", function(data, cb)
    TriggerServerEvent("emsmdt:getOffenderDetails", data.offender)
    cb('ok')
end)

RegisterNUICallback("saveOffenderChanges", function(data, cb)
    TriggerServerEvent("emsmdt:saveOffenderChanges", data.id, data.changes)
    cb('ok')
end)

RegisterNUICallback("submitNewReport", function(data, cb)
    TriggerServerEvent("emsmdt:submitNewReport", data)
    cb('ok')
end)

RegisterNUICallback("submitNewBolo", function(data, cb)
    TriggerServerEvent("emsmdt:submitNewBolo", data)
    cb('ok')
end)

RegisterNUICallback("performReportSearch", function(data, cb)
    TriggerServerEvent("emsmdt:performReportSearch", data.query)
    cb('ok')
end)

RegisterNUICallback("performBoloSearch", function(data, cb)
    TriggerServerEvent("emsmdt:performBoloSearch", data.query)
    cb('ok')
end)

RegisterNUICallback("getOffender", function(data, cb)
    TriggerServerEvent("emsmdt:getOffenderDetailsById", data.char_id)
    cb('ok')
end)

RegisterNUICallback("deleteReport", function(data, cb)
    TriggerServerEvent("emsmdt:deleteReport", data.id)
    cb('ok')
end)

RegisterNUICallback("deleteBolo", function(data, cb)
    TriggerServerEvent("emsmdt:deleteBolo", data.id)
    cb('ok')
end)

RegisterNUICallback("saveReportChanges", function(data, cb)
    TriggerServerEvent("emsmdt:saveReportChanges", data)
    cb('ok')
end)

RegisterNUICallback("saveBoloChanges", function(data, cb)
    TriggerServerEvent("emsmdt:saveBoloChanges", data)
    cb('ok')
end)


RegisterNUICallback("vehicleSearch", function(data, cb)
    TriggerServerEvent("emsmdt:performVehicleSearch", data.plate)
    cb('ok')
end)

RegisterNUICallback("getVehicle", function(data, cb)
    TriggerServerEvent("emsmdt:getVehicle", data.vehicle)
    cb('ok')
end)

RegisterNUICallback("getWarrants", function(data, cb)
    TriggerServerEvent("emsmdt:getWarrants")
    cb('ok')
end)

RegisterNUICallback("submitNewWarrant", function(data, cb)
    TriggerServerEvent("emsmdt:submitNewWarrant", data)
    cb('ok')
end)

RegisterNUICallback("deleteWarrant", function(data, cb)
    TriggerServerEvent("emsmdt:deleteWarrant", data.id)
    cb('ok')
end)

RegisterNUICallback("deleteWarrant", function(data, cb)
    TriggerServerEvent("emsmdt:deleteWarrant", data.id)
    cb('ok')
end)

RegisterNUICallback("getReport", function(data, cb)
    TriggerServerEvent("emsmdt:getReportDetailsById", data.id)
    cb('ok')
end)

RegisterNUICallback("sentencePlayer", function(data, cb)
    local players = {}
    for i = 0, 256 do
        if GetPlayerServerId(i) ~= 0 then
            table.insert(players, GetPlayerServerId(i))
        end
    end
    TriggerServerEvent("emsmdt:sentencePlayer", data.jailtime, data.charges, data.char_id, data.fine, players)
    cb('ok')
    --TriggerServerEvent("tp:addChatSystem", "You have fined a player")
    exports['mythic_notify']:SendAlert('inform', 'You have fined a player')
    PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
end)

RegisterNetEvent("emsmdt:returnOffenderSearchResults")
AddEventHandler("emsmdt:returnOffenderSearchResults", function(results)
    SendNUIMessage({
        type = "returnedPersonMatches",
        matches = results
    })
end)

RegisterNetEvent("emsmdt:returnOffenderDetails")
AddEventHandler("emsmdt:returnOffenderDetails", function(data)
    SendNUIMessage({
        type = "returnedOffenderDetails",
        details = data
    })
end)

RegisterNetEvent("emsmdt:returnOffensesAndOfficer")
AddEventHandler("emsmdt:returnOffensesAndOfficer", function(data, name)
    SendNUIMessage({
        type = "offensesAndOfficerLoaded",
        offenses = data,
        name = name
    })
end)

RegisterNetEvent("emsmdt:returnReportSearchResults")
AddEventHandler("emsmdt:returnReportSearchResults", function(results)
    SendNUIMessage({
        type = "returnedReportMatches",
        matches = results
    })
end)

RegisterNetEvent("emsmdt:returnBoloSearchResults")
AddEventHandler("emsmdt:returnBoloSearchResults", function(results)
    SendNUIMessage({
        type = "returnedBoloMatches",
        matches = results
    })
end)

RegisterNetEvent("emsmdt:returnVehicleSearchInFront")
AddEventHandler("emsmdt:returnVehicleSearchInFront", function(results, plate)
    SendNUIMessage({
        type = "returnedVehicleMatchesInFront",
        matches = results,
        plate = plate
    })
end)

RegisterNetEvent("emsmdt:returnVehicleSearchResults")
AddEventHandler("emsmdt:returnVehicleSearchResults", function(results)
    SendNUIMessage({
        type = "returnedVehicleMatches",
        matches = results
    })
end)

RegisterNetEvent("emsmdt:returnVehicleDetails")
AddEventHandler("emsmdt:returnVehicleDetails", function(data)
    data.model = GetLabelText(GetDisplayNameFromVehicleModel(data.model))
    SendNUIMessage({
        type = "returnedVehicleDetails",
        details = data
    })
end)

RegisterNetEvent("emsmdt:returnWarrants")
AddEventHandler("emsmdt:returnWarrants", function(data)
    SendNUIMessage({
        type = "returnedWarrants",
        warrants = data
    })
end)

RegisterNetEvent("emsmdt:completedWarrantAction")
AddEventHandler("emsmdt:completedWarrantAction", function(data)
    SendNUIMessage({
        type = "completedWarrantAction"
    })
end)

RegisterNetEvent("emsmdt:returnReportDetails")
AddEventHandler("emsmdt:returnReportDetails", function(data)
    SendNUIMessage({
        type = "returnedReportDetails",
        details = data
    })
end)

RegisterNetEvent("emsmdt:billPlayer")
AddEventHandler("emsmdt:billPlayer", function(src, sharedAccountName, label, amount)
    local lalbel = "EMS Bill"
    TriggerServerEvent('erp-billing:sendBill', src, amount, sharedAccountName, lalbel)
end)

function ToggleGUI(explicit_status)
  if explicit_status ~= nil then
    isVisible = explicit_status
  else
    isVisible = not isVisible
  end
  SetNuiFocus(isVisible, isVisible)
  SendNUIMessage({
    type = "enable",
    isVisible = isVisible
  })
end

function getVehicleInFront()
    local playerPed = PlayerPedId()
    local coordA = GetEntityCoords(playerPed, 1)
    local coordB = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 10.0, 0.0)
    local targetVehicle = getVehicleInDirection(coordA, coordB)
    return targetVehicle
end

function getVehicleInDirection(coordFrom, coordTo)
    local rayHandle = StartExpensiveSynchronousShapeTestLosProbe(coordFrom.x, coordFrom.y, coordFrom.z, coordTo.x, coordTo.y, coordTo.z, 10, PlayerPedId(), 0)
    local a, b, c, d, vehicle = GetRaycastResult(rayHandle)
    return vehicle
end

RegisterNetEvent("tp:mdtvehiclesearch")
AddEventHandler("tp:mdtvehiclesearch", function()
    local playerPed = PlayerPedId()
    local playerVeh = GetVehiclePedIsIn(playerPed, false)
    if not isVisible and IsPedInAnyPoliceVehicle(playerPed) and GetEntitySpeed(playerVeh) < 10.0 then
        if GetVehicleNumberPlateText(getVehicleInFront()) then
            TriggerServerEvent("emsmdt:performVehicleSearchInFront", GetVehicleNumberPlateText(getVehicleInFront()))
        end
    elseif IsControlJustPressed(0, 311) then
        TriggerServerEvent("emsmdt:hotKeyOpen")
    end
    if DoesEntityExist(playerPed) and IsPedUsingActionMode(playerPed) then -- disable action mode/combat stance when engaged in combat (thing which makes you run around like an idiot when shooting)
        SetPedUsingActionMode(playerPed, -1, -1, 1)
    end
end)
