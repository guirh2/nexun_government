-- client/modules/finance.lua
-- Módulo de finanças do cliente

local QBCore = exports['qb-core']:GetCoreObject()
local Finance = {}

-- ============================================
-- VARIÁVEIS
-- ============================================
local FinanceData = {
    stateBalance = 0,
    departmentBalances = {},
    taxes = {},
    transactions = {}
}

-- ============================================
-- FUNÇÕES PRINCIPAIS
-- ============================================

function Finance.GetFinanceData()
    return FinanceData
end

function Finance.UpdateFinanceData(data)
    if data.state then
        FinanceData.stateBalance = data.state.balance or 0
        FinanceData.departmentBalances = {
            health = data.state.health_balance or 0,
            security = data.state.security_balance or 0,
            finance = data.state.finance_balance or 0
        }
        FinanceData.taxes = data.state.taxes or {}
    end
end

-- ============================================
-- FUNÇÕES DE IMPOSTOS
-- ============================================

function Finance.GetTaxRates()
    return FinanceData.taxes
end

function Finance.UpdateTaxRate(taxType, newRate)
    TriggerServerEvent('government:server:updateTaxRate', taxType, newRate)
end

function Finance.GetTaxLimits(taxType)
    -- Retornar limites da config
    if taxType == 'iptu' then
        return { min = Config.IPTU.min, max = Config.IPTU.max }
    elseif taxType == 'ipva' then
        return { min = Config.IPVA.min, max = Config.IPVA.max }
    elseif taxType == 'inss' then
        return { min = Config.INSS.min, max = Config.INSS.max }
    elseif taxType == 'fuel' then
        return { min = Config.Combustivel.min, max = Config.Combustivel.max }
    elseif taxType == 'business' then
        return { min = Config.Empresas.min, max = Config.Empresas.max }
    elseif taxType == 'iss' then
        return { min = Config.ISS.min, max = Config.ISS.max }
    elseif taxType == 'iof' then
        return { min = Config.IOF.min, max = Config.IOF.max }
    elseif taxType == 'icms' then
        return { min = Config.ICMS.min, max = Config.ICMS.max }
    end
    
    return { min = 0.1, max = 25.0 }
end

-- ============================================
-- FUNÇÕES DE TRANSFERÊNCIA
-- ============================================

function Finance.TransferFunds(fromAcc, toAcc, amount, reason)
    if not fromAcc or not toAcc or not amount or amount <= 0 then
        QBCore.Functions.Notify('Parâmetros inválidos', 'error')
        return false
    end
    
    TriggerServerEvent('government:server:transferFunds', fromAcc, toAcc, amount, reason)
    return true
end

function Finance.GetAccountBalance(account)
    if account == 'state' then
        return FinanceData.stateBalance
    elseif account == 'health' then
        return FinanceData.departmentBalances.health
    elseif account == 'security' then
        return FinanceData.departmentBalances.security
    elseif account == 'finance' then
        return FinanceData.departmentBalances.finance
    end
    
    return 0
end

-- ============================================
-- FUNÇÕES DE RELATÓRIO
-- ============================================

function Finance.GenerateReport(reportType)
    -- Solicitar relatório do servidor
    TriggerServerEvent('government:server:generateFinanceReport', reportType)
end

-- ============================================
-- EVENTOS
-- ============================================

-- Receber dados financeiros
RegisterNetEvent('government:client:receiveFinanceData', function(data)
    Finance.UpdateFinanceData(data)
    
    -- Notificar UI se estiver aberta
    SendNUIMessage({
        action = 'updateFinanceData',
        data = FinanceData
    })
end)

-- Receber relatório
RegisterNetEvent('government:client:receiveFinanceReport', function(reportData)
    -- Mostrar relatório na UI
    SendNUIMessage({
        action = 'showFinanceReport',
        report = reportData
    })
end)

-- ============================================
-- NUI CALLBACKS PARA FINANÇAS
-- ============================================

RegisterNUICallback('finance/getData', function(data, cb)
    cb(Finance.GetFinanceData())
end)

RegisterNUICallback('finance/updateTax', function(data, cb)
    if data.taxType and data.newRate then
        local limits = Finance.GetTaxLimits(data.taxType)
        
        if data.newRate >= limits.min and data.newRate <= limits.max then
            Finance.UpdateTaxRate(data.taxType, data.newRate)
            cb({ success = true, message = 'Taxa atualizada' })
        else
            cb({ success = false, message = string.format('Taxa fora dos limites (%.2f-%.2f)', limits.min, limits.max) })
        end
    else
        cb({ success = false, message = 'Dados inválidos' })
    end
end)

RegisterNUICallback('finance/transfer', function(data, cb)
    if data.from and data.to and data.amount then
        local success = Finance.TransferFunds(data.from, data.to, data.amount, data.reason)
        cb({ success = success, message = success and 'Transferência solicitada' or 'Erro na transferência' })
    else
        cb({ success = false, message = 'Dados incompletos' })
    end
end)

RegisterNUICallback('finance/generateReport', function(data, cb)
    if data.reportType then
        Finance.GenerateReport(data.reportType)
        cb({ success = true, message = 'Relatório solicitado' })
    else
        cb({ success = false, message = 'Tipo de relatório não especificado' })
    end
end)

-- ============================================
-- EXPORTS
-- ============================================

exports('GetFinanceModule', function()
    return Finance
end)

print('[GOV-FINANCE] Módulo de finanças carregado')