-- client/modules/health.lua
-- Módulo de saúde do cliente

local QBCore = exports['qb-core']:GetCoreObject()
local Health = {}

-- ============================================
-- VARIÁVEIS
-- ============================================
local HealthData = {
    balance = 0,
    hospitals = {},
    stock = {},
    manifests = {},
    ambulances = {}
}

-- ============================================
-- FUNÇÕES PRINCIPAIS
-- ============================================

function Health.GetHealthData()
    return HealthData
end

function Health.UpdateHealthData(data)
    if data.balance then
        HealthData.balance = data.balance
    end
    
    if data.stock then
        HealthData.stock = data.stock
    end
    
    if data.manifests then
        HealthData.manifests = data.manifests
    end
end

-- ============================================
-- FUNÇÕES DE ESTOQUE
-- ============================================

function Health.GetMedicalStock()
    -- Solicitar estoque do servidor
    TriggerServerEvent('government:server:getMedicalStock')
end

function Health.PurchaseMedicalItems(items)
    -- Validar itens
    if not items or #items == 0 then
        QBCore.Functions.Notify('Nenhum item selecionado', 'error')
        return false
    end
    
    -- Calcular total
    local total = 0
    for _, item in ipairs(items) do
        total = total + (item.price * item.quantity)
    end
    
    -- Confirmar compra
    TriggerServerEvent('government:server:purchaseMedicalItems', items, total)
    
    return true
end

-- ============================================
-- FUNÇÕES DE MANIFESTOS
-- ============================================

function Health.CreateManifest(items, destination)
    if not items or #items == 0 then
        QBCore.Functions.Notify('Nenhum item para manifesto', 'error')
        return false
    end
    
    -- Calcular totais
    local totalItems = 0
    local totalValue = 0
    
    for _, item in ipairs(items) do
        totalItems = totalItems + item.quantity
        totalValue = totalValue + (item.price * item.quantity)
    end
    
    local manifestData = {
        manifest_type = 'health',
        items = items,
        total_items = totalItems,
        total_value = totalValue,
        destination = destination or 'Hospital Central',
        origin = 'Depósito de Saúde'
    }
    
    TriggerServerEvent('government:server:createManifest', manifestData)
    
    return true
end

function Health.GetActiveManifests()
    -- Solicitar manifestos ativos
    TriggerServerEvent('government:server:getHealthManifests')
end

-- ============================================
-- FUNÇÕES DE AMBULÂNCIAS
-- ============================================

function Health.RequestAmbulanceMaintenance(vehiclePlate, issue, estimatedCost)
    if not vehiclePlate or not issue then
        QBCore.Functions.Notify('Dados incompletos', 'error')
        return false
    end
    
    TriggerServerEvent('government:server:requestAmbulanceMaintenance', {
        vehicle_plate = vehiclePlate,
        issue_description = issue,
        estimated_cost = estimatedCost or 0
    })
    
    return true
end

function Health.PurchaseAmbulance(model, price)
    TriggerServerEvent('government:server:purchaseAmbulance', model, price)
end

-- ============================================
-- EVENTOS
-- ============================================

-- Receber dados de saúde
RegisterNetEvent('government:client:receiveHealthData', function(data)
    Health.UpdateHealthData(data)
    
    SendNUIMessage({
        action = 'updateHealthData',
        data = HealthData
    })
end)

-- Receber estoque médico
RegisterNetEvent('government:client:receiveMedicalStock', function(stockData)
    HealthData.stock = stockData
    
    SendNUIMessage({
        action = 'updateMedicalStock',
        stock = stockData
    })
end)

-- Receber manifestos
RegisterNetEvent('government:client:receiveHealthManifests', function(manifests)
    HealthData.manifests = manifests
    
    SendNUIMessage({
        action = 'updateManifests',
        manifests = manifests
    })
end)

-- Confirmação de compra
RegisterNetEvent('government:client:medicalPurchaseComplete', function(success, message)
    QBCore.Functions.Notify(message, success and 'success' or 'error')
    
    if success then
        -- Atualizar estoque
        Health.GetMedicalStock()
    end
end)

-- ============================================
-- NUI CALLBACKS PARA SAÚDE
-- ============================================

RegisterNUICallback('health/getData', function(data, cb)
    cb(Health.GetHealthData())
end)

RegisterNUICallback('health/getStock', function(data, cb)
    Health.GetMedicalStock()
    cb({ success = true, message = 'Solicitado' })
end)

RegisterNUICallback('health/purchaseItems', function(data, cb)
    if data.items then
        local success = Health.PurchaseMedicalItems(data.items)
        cb({ success = success, message = success and 'Compra solicitada' or 'Erro na compra' })
    else
        cb({ success = false, message = 'Nenhum item especificado' })
    end
end)

RegisterNUICallback('health/createManifest', function(data, cb)
    if data.items and data.destination then
        local success = Health.CreateManifest(data.items, data.destination)
        cb({ success = success, message = success and 'Manifesto criado' or 'Erro no manifesto' })
    else
        cb({ success = false, message = 'Dados incompletos' })
    end
end)

RegisterNUICallback('health/getManifests', function(data, cb)
    Health.GetActiveManifests()
    cb({ success = true, message = 'Solicitado' })
end)

RegisterNUICallback('health/requestMaintenance', function(data, cb)
    if data.vehiclePlate and data.issue then
        local success = Health.RequestAmbulanceMaintenance(data.vehiclePlate, data.issue, data.estimatedCost)
        cb({ success = success, message = success and 'Solicitação enviada' or 'Erro na solicitação' })
    else
        cb({ success = false, message = 'Dados incompletos' })
    end
end)

-- ============================================
-- EXPORTS
-- ============================================

exports('GetHealthModule', function()
    return Health
end)

print('[GOV-HEALTH] Módulo de saúde carregado')