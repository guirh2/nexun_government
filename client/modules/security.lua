-- client/modules/security.lua
-- Módulo de segurança do cliente

local QBCore = exports['qb-core']:GetCoreObject()
local Security = {}

-- ============================================
-- VARIÁVEIS
-- ============================================
local SecurityData = {
    balance = 0,
    policeUnits = {},
    arsenal = {},
    vehicles = {},
    manifests = {},
    maintenance = {}
}

-- ============================================
-- FUNÇÕES PRINCIPAIS
-- ============================================

function Security.GetSecurityData()
    return SecurityData
end

function Security.UpdateSecurityData(data)
    if data.balance then
        SecurityData.balance = data.balance
    end
    
    if data.vehicles then
        SecurityData.vehicles = data.vehicles
    end
    
    if data.manifests then
        SecurityData.manifests = data.manifests
    end
end

-- ============================================
-- FUNÇÕES DE ARSENAL
-- ============================================

function Security.GetArsenalStock()
    TriggerServerEvent('government:server:getArsenalStock')
end

function Security.PurchaseWeapons(weapons)
    if not weapons or #weapons == 0 then
        QBCore.Functions.Notify('Nenhuma arma selecionada', 'error')
        return false
    end
    
    local total = 0
    for _, weapon in ipairs(weapons) do
        total = total + (weapon.price * weapon.quantity)
    end
    
    TriggerServerEvent('government:server:purchaseWeapons', weapons, total)
    
    return true
end

-- ============================================
-- FUNÇÕES DE VIATURAS
-- ============================================

function Security.GetPoliceVehicles()
    TriggerServerEvent('government:server:getPoliceVehicles')
end

function Security.RequestVehicleMaintenance(vehiclePlate, issue, estimatedCost)
    if not vehiclePlate or not issue then
        QBCore.Functions.Notify('Dados incompletos', 'error')
        return false
    end
    
    TriggerServerEvent('government:server:requestVehicleMaintenance', {
        vehicle_plate = vehiclePlate,
        issue_description = issue,
        estimated_cost = estimatedCost or 0
    })
    
    return true
end

function Security.PurchasePoliceVehicle(model, price)
    TriggerServerEvent('government:server:purchasePoliceVehicle', model, price)
end

-- ============================================
-- FUNÇÕES DE MANIFESTOS
-- ============================================

function Security.CreateSecurityManifest(items, destination)
    if not items or #items == 0 then
        QBCore.Functions.Notify('Nenhum item para manifesto', 'error')
        return false
    end
    
    local totalItems = 0
    local totalValue = 0
    
    for _, item in ipairs(items) do
        totalItems = totalItems + item.quantity
        totalValue = totalValue + (item.price * item.quantity)
    end
    
    local manifestData = {
        manifest_type = 'security',
        items = items,
        total_items = totalItems,
        total_value = totalValue,
        destination = destination or 'Delegacia Central',
        origin = 'Arsenal Estadual'
    }
    
    TriggerServerEvent('government:server:createManifest', manifestData)
    
    return true
end

-- ============================================
-- FUNÇÕES DE EFETIVO
-- ============================================

function Security.GetPoliceOnline()
    TriggerServerEvent('government:server:getPoliceOnline')
end

-- ============================================
-- EVENTOS
-- ============================================

RegisterNetEvent('government:client:receiveSecurityData', function(data)
    Security.UpdateSecurityData(data)
    
    SendNUIMessage({
        action = 'updateSecurityData',
        data = SecurityData
    })
end)

RegisterNetEvent('government:client:receiveArsenalStock', function(stockData)
    SecurityData.arsenal = stockData
    
    SendNUIMessage({
        action = 'updateArsenalStock',
        stock = stockData
    })
end)

RegisterNetEvent('government:client:receivePoliceVehicles', function(vehicles)
    SecurityData.vehicles = vehicles
    
    SendNUIMessage({
        action = 'updatePoliceVehicles',
        vehicles = vehicles
    })
end)

RegisterNetEvent('government:client:receivePoliceOnline', function(onlineData)
    SecurityData.policeUnits = onlineData
    
    SendNUIMessage({
        action = 'updatePoliceOnline',
        online = onlineData
    })
end)

RegisterNetEvent('government:client:securityPurchaseComplete', function(success, message)
    QBCore.Functions.Notify(message, success and 'success' or 'error')
    
    if success then
        Security.GetArsenalStock()
    end
end)

-- ============================================
-- NUI CALLBACKS PARA SEGURANÇA
-- ============================================

RegisterNUICallback('security/getData', function(data, cb)
    cb(Security.GetSecurityData())
end)

RegisterNUICallback('security/getArsenal', function(data, cb)
    Security.GetArsenalStock()
    cb({ success = true, message = 'Solicitado' })
end)

RegisterNUICallback('security/purchaseWeapons', function(data, cb)
    if data.weapons then
        local success = Security.PurchaseWeapons(data.weapons)
        cb({ success = success, message = success and 'Compra solicitada' or 'Erro na compra' })
    else
        cb({ success = false, message = 'Nenhuma arma especificada' })
    end
end)

RegisterNUICallback('security/getVehicles', function(data, cb)
    Security.GetPoliceVehicles()
    cb({ success = true, message = 'Solicitado' })
end)

RegisterNUICallback('security/requestMaintenance', function(data, cb)
    if data.vehiclePlate and data.issue then
        local success = Security.RequestVehicleMaintenance(data.vehiclePlate, data.issue, data.estimatedCost)
        cb({ success = success, message = success and 'Solicitação enviada' or 'Erro na solicitação' })
    else
        cb({ success = false, message = 'Dados incompletos' })
    end
end)

RegisterNUICallback('security/createManifest', function(data, cb)
    if data.items and data.destination then
        local success = Security.CreateSecurityManifest(data.items, data.destination)
        cb({ success = success, message = success and 'Manifesto criado' or 'Erro no manifesto' })
    else
        cb({ success = false, message = 'Dados incompletos' })
    end
end)

RegisterNUICallback('security/getOnline', function(data, cb)
    Security.GetPoliceOnline()
    cb({ success = true, message = 'Solicitado' })
end)

-- ============================================
-- EXPORTS
-- ============================================

exports('GetSecurityModule', function()
    return Security
end)

print('[GOV-SECURITY] Módulo de segurança carregado')