local QBCore = exports['qb-core']:GetCoreObject()
Security = {}

-- Cache de dados da Unidade (Batalhão)
local unitData = {
    id = nil,
    label = "",
    budget = 0, -- Verba local do batalhão (atribuída pelo Secretário)
    fleet = {},
    deliveries = {}
}

-- [[ 1. GESTÃO FINANCEIRA DO BATALHÃO ]] --

--- Atualiza o saldo local do batalhão quando o Secretário envia verba
RegisterNetEvent('nexun_government:client:updateUnitBudget', function(newBudget)
    unitData.budget = newBudget
    SendNUIMessage({
        action = "updateSecurityUnitBudget",
        budget = newBudget
    })
end)

-- [[ 2. MANUTENÇÃO DE VIATURAS (REQUISITADA PELO BATALHÃO) ]] --

--- Callback para o Coronel/Gestor solicitar reparo usando a verba da unidade
RegisterNUICallback('requestVehicleRepair', function(data, cb)
    -- data.plate: Placa do veículo
    -- data.cost: Custo do conserto
    
    if unitData.budget >= data.cost then
        -- O servidor retira do saldo do Batalhão e não do Governo Central
        TriggerServerEvent('nexun_government:server:unitRepairVehicle', data.plate, data.cost)
        Utils.PlaySound("click")
        cb({status = 'ok'})
    else
        Utils.Notify("O Batalhão não tem verba suficiente para esta manutenção!", "error")
        cb({status = 'error'})
    end
end)

-- [[ 3. LOGÍSTICA E COMPRAS DO SECRETÁRIO ]] --

--- O Secretário de Segurança usa esta função para distribuir verba aos batalhões
RegisterNUICallback('allocateSecurityBudget', function(data, cb)
    -- data.targetUnit: ID do Batalhão (ex: 'pm_19bpm')
    -- data.amount: Quantia a ser enviada
    
    local PlayerData = QBCore.Functions.GetPlayerData()
    -- Verifica se é o Secretário de Segurança (Grade 1 no nosso config)
    if PlayerData.job.name == Config.GovManagement.JobName and PlayerData.job.grade.level >= 1 then
        TriggerServerEvent('nexun_government:server:transferToUnit', 'seguranca', data.targetUnit, data.amount)
        cb('ok')
    else
        Utils.Notify("Apenas o Secretário de Segurança pode distribuir verbas.", "error")
        cb('error')
    end
end)

--- Compra de ativos (Viaturas/Armas) pelo Secretário
RegisterNUICallback('purchaseSecurityAsset', function(data, cb)
    -- Verifica se a SECRETARIA (e não o batalhão) tem saldo para a compra macro
    QBCore.Functions.TriggerCallback('nexun_government:server:canSecretariaAfford', function(canAfford)
        if canAfford then
            -- Gera o manifesto e a missão no HUB (Porto, Aeroporto, etc)
            TriggerServerEvent('nexun_government:server:processSecurityPurchase', data)
            cb('ok')
        else
            Utils.Notify("A Secretaria de Segurança está sem verba!", "error")
            cb('error')
        end
    end, 'seguranca', data.price)
end)

-- [[ 4. GESTÃO DE ARSENAL E SERIAIS ]] --

--- Sincroniza as armas do batalhão (com seriais únicos SEC-SEG)
RegisterNetEvent('nexun_government:client:syncUnitArmory', function(armory)
    SendNUIMessage({
        action = "updateSecurityArmory",
        items = armory
    })
end)

--- Atribuir arma ao oficial (Rastreabilidade total)
RegisterNUICallback('assignWeapon', function(data, cb)
    -- data.serial: Serial da arma
    -- data.citizenid: ID do oficial
    TriggerServerEvent('nexun_government:server:assignWeaponToOfficer', data.serial, data.citizenid)
    cb('ok')
end)

-- [[ 5. RASTREAMENTO DE LOGÍSTICA ]] --

--- Monitora cargas em movimento para os Hubs
RegisterNetEvent('nexun_government:client:updateLogistics', function(deliveries)
    unitData.deliveries = deliveries
    SendNUIMessage({
        action = "updateLogisticsUI",
        deliveries = deliveries
    })
end)

RegisterNUICallback('trackLogistics', function(data, cb)
    local coords = data.coords
    SetNewWaypoint(coords.x, coords.y)
    Utils.Notify("Rastreio de carga governamental ativado.", "success")
    cb('ok')
end)

-- [[ HELPERS ]] --
exports('GetSecurityData', function() return unitData end)