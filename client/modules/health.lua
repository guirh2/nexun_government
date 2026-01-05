local QBCore = exports['qb-core']:GetCoreObject()
Health = {}

-- Cache de dados da Unidade Médica
local unitAssets = {
    fleet = {},
    inventory = {},
    budget = 0 -- Saldo específico enviado pelo Secretário para este Hospital
}

-- [[ 1. GESTÃO FINANCEIRA DA UNIDADE (Hospital/Clínica) ]] --

--- Recebe a atualização de verba enviada pelo Secretário de Saúde
RegisterNetEvent('nexun_government:client:updateUnitBudget', function(amount)
    unitAssets.budget = amount
    SendNUIMessage({
        action = "updateHealthUnitBudget",
        budget = amount
    })
end)

-- [[ 2. GESTÃO DE FROTA E MANUTENÇÃO ]] --

--- Requisição de Manutenção (O Diretor do Hospital paga com a verba da Unidade)
RegisterNUICallback('requestAmbulanceRepair', function(data, cb)
    -- data.plate: Placa da ambulância
    -- data.cost: Custo do reparo
    
    if unitAssets.budget >= data.cost then
        TriggerServerEvent('nexun_government:server:repairHealthVehicle', data.plate, data.cost)
        Utils.PlaySound("click")
        cb({status = 'ok'})
    else
        Utils.Notify("O Hospital não tem verba suficiente para este reparo!", "error")
        cb({status = 'error'})
    end
end)

-- [[ 3. COMPRAS E LOGÍSTICA (Insumos) ]] --

--- Compra de Equipamentos/Consumíveis (Pelo Diretor da Unidade)
RegisterNUICallback('purchaseHealthSupplies', function(data, cb)
    -- data.items: Lista de itens (macas, kits, etc)
    -- data.totalCost: Custo total
    
    if unitAssets.budget >= data.totalCost then
        -- Inicia o processo que gera a entrega no HUB selecionado
        TriggerServerEvent('nexun_government:server:processHealthUnitPurchase', data)
        cb({status = 'ok'})
    else
        Utils.Notify("Verba hospitalar insuficiente!", "error")
        cb({status = 'error'})
    end
end)

-- [[ 4. SINCRONIZAÇÃO DE PATRIMÔNIO ]] --

--- Atualiza a lista de equipamentos permanentes (com serial SES) do hospital
RegisterNetEvent('nexun_government:client:syncHealthAssets', function(assets)
    unitAssets.inventory = assets
    SendNUIMessage({
        action = "updateHealthInventoryUI",
        assets = assets
    })
end)

-- [[ 5. ABA DO SECRETÁRIO DE SAÚDE ]] --

--- Função para o Secretário enviar verba para um Batalhão/Hospital específico
RegisterNUICallback('allocateBudgetToUnit', function(data, cb)
    -- data.unitId: ID do Hospital/Batalhão
    -- data.amount: Quantia a transferir
    
    local PlayerData = QBCore.Functions.GetPlayerData()
    if PlayerData.job.name == Config.GovManagement.JobName and PlayerData.job.grade.level >= 0 then
        TriggerServerEvent('nexun_government:server:transferBudgetToUnit', 'saude', data.unitId, data.amount)
        cb('ok')
    else
        Utils.Notify("Apenas o Secretário de Saúde pode alocar verbas.", "error")
        cb('error')
    end
end)