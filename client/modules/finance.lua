local QBCore = exports['qb-core']:GetCoreObject()
Finance = {}

-- Cache local para exibição rápida na NUI
local currentBudgets = {
    saude = { balance = 0, percentage = 0 },
    seguranca = { balance = 0, percentage = 0 },
    tesouro = 0
}

local currentTaxes = {}

-- [[ 1. SINCRONIZAÇÃO DE DADOS ]] --

--- Recebe os dados financeiros completos do servidor e injeta na NUI
RegisterNetEvent('nexun_government:client:syncFinanceData', function(data)
    currentBudgets.tesouro = data.treasuryBalance
    currentBudgets.saude = { balance = data.saudeBalance, percentage = data.saudePerc }
    currentBudgets.seguranca = { balance = data.segBalance, percentage = data.segPerc }
    currentTaxes = data.taxes

    SendNUIMessage({
        action = "updateFinanceUI",
        data = {
            treasury = currentBudgets.tesouro,
            budgets = currentBudgets.budgets,
            taxes = currentTaxes
        }
    })
end)

-- [[ 2. GESTÃO DE IMPOSTOS (Aba Fazenda) ]] --

--- Callback enviado pela NUI quando o Secretário da Fazenda altera uma alíquota
RegisterNUICallback('updateTaxRate', function(data, cb)
    -- data.taxName (ex: 'ipva')
    -- data.newValue (ex: 7.5)
    
    local PlayerData = QBCore.Functions.GetPlayerData()
    -- Verifica se é Secretário da Fazenda (3), Vice (4) ou Gov (5)
    if PlayerData.job.name == Config.GovManagement.JobName and PlayerData.job.grade.level >= 3 then
        Utils.PlaySound("click")
        TriggerServerEvent('nexun_government:server:updateTaxRate', data.taxName, data.newValue)
        cb({status = 'ok'})
    else
        Utils.Notify(Config.Locales['no_access'], "error")
        cb({status = 'error'})
    end
end)

-- [[ 3. GESTÃO ORÇAMENTÁRIA (Aba Governador/Fazenda) ]] --

--- Define a porcentagem da arrecadação que cada secretaria receberá
RegisterNUICallback('updateBudgetAllocation', function(data, cb)
    -- data.dept ('saude' ou 'seguranca')
    -- data.percentage (valor de 0 a 100)
    
    local PlayerData = QBCore.Functions.GetPlayerData()
    local grade = PlayerData.job.grade.level
    
    -- Apenas Secretário da Fazenda ou Governadoria podem mexer no orçamento
    if PlayerData.job.name == Config.GovManagement.JobName and grade >= 3 then
        
        -- Validação simples: a soma não pode ultrapassar 100%
        -- (Isso deve ser validado no servidor também por segurança)
        TriggerServerEvent('nexun_government:server:updateBudgetAllocation', data.dept, data.percentage)
        
        Utils.PlaySound("click")
        cb({status = 'ok'})
    else
        Utils.Notify("Apenas a alta cúpula pode alterar a distribuição de verbas.", "error")
        cb({status = 'error'})
    end
end)

--- Realiza um aporte extra (transferência direta do tesouro para uma secretaria)
RegisterNUICallback('emergencyFundTransfer', function(data, cb)
    -- data.targetDept ('saude' ou 'seguranca')
    -- data.amount (valor em dinheiro)
    
    QBCore.Functions.TriggerCallback('nexun_government:server:transferEmergencyFunds', function(success, msg)
        if success then
            Utils.Notify(msg, "success")
            Utils.PlaySound("click")
            cb({status = 'ok'})
        else
            Utils.Notify(msg, "error")
            cb({status = 'error'})
        end
    end, data.targetDept, data.amount)
end)

-- [[ 4. HELPERS EXPORTADOS ]] --

--- Export para outros módulos checarem se a secretaria tem dinheiro antes de abrir o menu de compras
Finance.CanSecretariaAfford = function(dept, price)
    if dept == 'saude' then
        return currentBudgets.saude.balance >= price
    elseif dept == 'seguranca' then
        return currentBudgets.seguranca.balance >= price
    end
    return false
end

exports('GetFinanceModule', function() return Finance end)