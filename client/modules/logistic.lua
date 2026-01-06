-- client/modules/logistic.lua
-- Módulo de logística (entregas de manifestos)

local QBCore = exports['qb-core']:GetCoreObject()
local Logistic = {}

-- ============================================
-- VARIÁVEIS
-- ============================================
local LogisticData = {
    activeManifests = {},
    availableManifests = {},
    myDeliveries = {},
    deliveryVehicles = {}
}

local CurrentDelivery = nil
local IsOnDelivery = false

-- ============================================
-- FUNÇÕES PRINCIPAIS
-- ============================================

function Logistic.GetLogisticData()
    return LogisticData
end

function Logistic.UpdateLogisticData(data)
    if data.availableManifests then
        LogisticData.availableManifests = data.availableManifests
    end
    
    if data.myDeliveries then
        LogisticData.myDeliveries = data.myDeliveries
    end
end

-- ============================================
-- FUNÇÕES DE ENTREGA
-- ============================================

function Logistic.GetAvailableManifests()
    TriggerServerEvent('government:server:getAvailableManifests')
end

function Logistic.AcceptManifest(manifestNumber)
    if not manifestNumber then
        QBCore.Functions.Notify('Número do manifesto inválido', 'error')
        return false
    end
    
    TriggerServerEvent('government:server:acceptManifest', manifestNumber)
    return true
end

function Logistic.StartDelivery(manifestNumber)
    if IsOnDelivery then
        QBCore.Functions.Notify('Já está em uma entrega', 'error')
        return false
    end
    
    TriggerServerEvent('government:server:startDelivery', manifestNumber)
    return true
end

function Logistic.CompleteDelivery(manifestNumber)
    if not IsOnDelivery or not CurrentDelivery then
        QBCore.Functions.Notify('Não está em uma entrega', 'error')
        return false
    end
    
    TriggerServerEvent('government:server:completeDelivery', manifestNumber)
    return true
end

function Logistic.CancelDelivery(manifestNumber, reason)
    TriggerServerEvent('government:server:cancelDelivery', manifestNumber, reason)
    return true
end

-- ============================================
-- FUNÇÕES DE VEÍCULO
-- ============================================

function Logistic.RequestDeliveryVehicle()
    TriggerServerEvent('government:server:requestDeliveryVehicle')
end

function Logistic.ReturnDeliveryVehicle(vehiclePlate)
    TriggerServerEvent('government:server:returnDeliveryVehicle', vehiclePlate)
end

-- ============================================
-- EVENTOS
-- ============================================

RegisterNetEvent('government:client:receiveAvailableManifests', function(manifests)
    LogisticData.availableManifests = manifests
    
    SendNUIMessage({
        action = 'updateAvailableManifests',
        manifests = manifests
    })
end)

RegisterNetEvent('government:client:manifestAccepted', function(manifestData)
    LogisticData.activeManifests[manifestData.manifest_number] = manifestData
    
    QBCore.Functions.Notify('Manifesto aceito: ' .. manifestData.manifest_number, 'success')
    
    SendNUIMessage({
        action = 'manifestAccepted',
        manifest = manifestData
    })
end)

RegisterNetEvent('government:client:deliveryStarted', function(manifestData)
    CurrentDelivery = manifestData
    IsOnDelivery = true
    
    -- Criar waypoints no mapa
    CreateDeliveryWaypoints(manifestData)
    
    QBCore.Functions.Notify('Entrega iniciada: ' .. manifestData.destination, 'success')
end)

RegisterNetEvent('government:client:deliveryCompleted', function(manifestNumber, reward)
    IsOnDelivery = false
    CurrentDelivery = nil
    
    -- Remover waypoints
    ClearDeliveryWaypoints()
    
    QBCore.Functions.Notify(string.format('Entrega completa! Recompensa: R$ %.2f', reward), 'success')
    
    -- Atualizar lista de manifestos
    Logistic.GetAvailableManifests()
end)

RegisterNetEvent('government:client:deliveryVehicleAssigned', function(vehicleData)
    LogisticData.deliveryVehicles = vehicleData
    
    QBCore.Functions.Notify('Veículo de entrega atribuído: ' .. vehicleData.plate, 'success')
end)

-- ============================================
-- FUNÇÕES DE WAYPOINT
-- ============================================

function CreateDeliveryWaypoints(manifestData)
    -- Implementar criação de waypoints no mapa GTA
    -- Esta é uma implementação básica
    
    SetNewWaypoint(0.0, 0.0) -- Coordenadas do destino
    
    -- Blip no mapa
    local blip = AddBlipForCoord(0.0, 0.0, 0.0)
    SetBlipSprite(blip, 478) -- Ícone de entrega
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 1.0)
    SetBlipColour(blip, 5)
    SetBlipAsShortRange(blip, false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Entrega: " .. manifestData.destination)
    EndTextCommandSetBlipName(blip)
    
    -- Guardar blip para remover depois
    CurrentDelivery.blip = blip
end

function ClearDeliveryWaypoints()
    if CurrentDelivery and CurrentDelivery.blip then
        RemoveBlip(CurrentDelivery.blip)
    end
end

-- ============================================
-- NUI CALLBACKS PARA LOGÍSTICA
-- ============================================

RegisterNUICallback('logistic/getManifests', function(data, cb)
    Logistic.GetAvailableManifests()
    cb({ success = true, message = 'Solicitado' })
end)

RegisterNUICallback('logistic/acceptManifest', function(data, cb)
    if data.manifestNumber then
        local success = Logistic.AcceptManifest(data.manifestNumber)
        cb({ success = success, message = success and 'Manifesto aceito' or 'Erro ao aceitar' })
    else
        cb({ success = false, message = 'Número do manifesto não especificado' })
    end
end)

RegisterNUICallback('logistic/startDelivery', function(data, cb)
    if data.manifestNumber then
        local success = Logistic.StartDelivery(data.manifestNumber)
        cb({ success = success, message = success and 'Entrega iniciada' or 'Erro ao iniciar' })
    else
        cb({ success = false, message = 'Número do manifesto não especificado' })
    end
end)

RegisterNUICallback('logistic/completeDelivery', function(data, cb)
    if data.manifestNumber then
        local success = Logistic.CompleteDelivery(data.manifestNumber)
        cb({ success = success, message = success and 'Entrega finalizada' or 'Erro ao finalizar' })
    else
        cb({ success = false, message = 'Número do manifesto não especificado' })
    end
end)

RegisterNUICallback('logistic/requestVehicle', function(data, cb)
    Logistic.RequestDeliveryVehicle()
    cb({ success = true, message = 'Veículo solicitado' })
end)

-- ============================================
-- EXPORTS
-- ============================================

exports('GetLogisticModule', function()
    return Logistic
end)

print('[GOV-LOGISTIC] Módulo de logística carregado')