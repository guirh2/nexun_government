-- server/main.lua - VERSÃO FUNCIONAL SIMPLES
local QBCore = exports['qb-core']:GetCoreObject()

print('[GOV-MAIN] Sistema de governo iniciando...')

-- ============================================
-- FUNÇÕES BÁSICAS
-- ============================================

function GetStateInfo()
    local stateData = MySQL.Sync.fetchSingle('SELECT * FROM government_state WHERE id = 1')
    
    if stateData then
        return {
            balance = stateData.account_balance or 0,
            health_balance = stateData.health_balance or 0,
            security_balance = stateData.security_balance or 0,
            finance_balance = stateData.finance_balance or 0,
            taxes = {
                iptu = stateData.tax_iptu or 1.0,
                ipva = stateData.tax_ipva or 4.0,
                inss = stateData.tax_inss or 8.0,
                fuel = stateData.tax_fuel or 25.0,
                business = stateData.tax_business or 15.0,
                iss = stateData.tax_iss or 5.0,
                iof = stateData.tax_iof or 0.38,
                icms = stateData.tax_icms or 18.0
            }
        }
    else
        return {
            balance = 10000000.00,
            health_balance = 2000000.00,
            security_balance = 2000000.00,
            finance_balance = 6000000.00,
            taxes = {
                iptu = 1.0,
                ipva = 4.0,
                inss = 8.0,
                fuel = 25.0,
                business = 15.0,
                iss = 5.0,
                iof = 0.38,
                icms = 18.0
            }
        }
    end
end

function GetStateBalance()
    local state = GetStateInfo()
    return state.balance or 0
end

function GetCurrentTaxes()
    local state = GetStateInfo()
    return state.taxes or {}
end

function UpdateTaxRate(taxType, newRate, authorizedBy)
    if not taxType or not newRate then
        return false, "Parâmetros inválidos"
    end
    
    -- Mapear colunas
    local columnMap = {
        iptu = 'tax_iptu',
        ipva = 'tax_ipva',
        inss = 'tax_inss',
        fuel = 'tax_fuel',
        business = 'tax_business',
        iss = 'tax_iss',
        iof = 'tax_iof',
        icms = 'tax_icms'
    }
    
    local column = columnMap[taxType]
    if not column then
        return false, "Tipo de imposto inválido"
    end
    
    local success = MySQL.Sync.execute(
        'UPDATE government_state SET ' .. column .. ' = ? WHERE id = 1',
        {newRate}
    )
    
    if success then
        -- Log
        MySQL.Sync.insert([[
            INSERT INTO government_logs 
            (log_type, log_category, title, description, player_name)
            VALUES (?, ?, ?, ?, ?)
        ]], {
            'impostos',
            'alteracao_taxa',
            'Alteração de Taxa',
            string.format('%s alterou %s para %.2f%%', authorizedBy, taxType, newRate),
            authorizedBy
        })
        
        return true, "Taxa atualizada com sucesso"
    end
    
    return false, "Erro ao atualizar taxa"
end

-- ============================================
-- EVENTOS
-- ============================================

RegisterNetEvent('government:server:getStateInfo', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Verificar se é do governo
    if Player.PlayerData.job.name ~= Config.JobName then
        TriggerClientEvent('QBCore:Notify', src, 'Apenas funcionários do governo', 'error')
        return
    end
    
    local stateInfo = GetStateInfo()
    TriggerClientEvent('government:client:receiveStateInfo', src, stateInfo)
end)

RegisterNetEvent('government:server:updateTaxRate', function(taxType, newRate)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Verificar permissão (apenas Sec. Fazenda+)
    local grade = Player.PlayerData.job.grade.level
    if grade < 4 then
        TriggerClientEvent('QBCore:Notify', src, 'Apenas Secretário da Fazenda+', 'error')
        return
    end
    
    local success, message = UpdateTaxRate(
        taxType, 
        newRate, 
        Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    )
    
    TriggerClientEvent('QBCore:Notify', src, message, success and 'success' or 'error')
end)

-- ============================================
-- COMANDOS DE TESTE
-- ============================================

RegisterCommand('govtest', function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player then
        TriggerClientEvent('QBCore:Notify', src, 'Sistema de Governo OK!', 'success')
        
        -- Mostrar saldo
        local balance = GetStateBalance()
        TriggerClientEvent('QBCore:Notify', src, 
            string.format('Saldo do Estado: R$ %.2f', balance), 
            'primary')
    end
end, false)

-- ============================================
-- INICIALIZAÇÃO
-- ============================================

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        print('[GOV-MAIN] Sistema inicializado')
        
        -- Verificar/Criar estado
        local stateData = MySQL.Sync.fetchSingle('SELECT * FROM government_state WHERE id = 1')
        if not stateData then
            MySQL.Sync.execute([[
                INSERT INTO government_state 
                (account_balance, health_balance, security_balance, finance_balance,
                 tax_iptu, tax_ipva, tax_inss, tax_fuel, tax_business, tax_iss, tax_iof, tax_icms)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ]], {
                10000000.00, 2000000.00, 2000000.00, 6000000.00,
                1.0, 4.0, 8.0, 25.0, 15.0, 5.0, 0.38, 18.0
            })
            print('[GOV-MAIN] Estado inicial criado')
        end
        
        print('[GOV-MAIN] Pronto para uso')
    end
end)

-- ============================================
-- EXPORTS
-- ============================================

exports('GetStateInfo', GetStateInfo)
exports('GetStateBalance', GetStateBalance)
exports('GetCurrentTaxes', GetCurrentTaxes)
exports('UpdateTaxRate', UpdateTaxRate)

print('[GOV-MAIN] Carregado com sucesso')