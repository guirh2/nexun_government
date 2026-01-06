-- server/sync.lua - Sistema de sincronização
local QBCore = exports['qb-core']:GetCoreObject()

local SyncedData = {
    state = {},
    taxes = {},
    departments = {},
    secretaries = {}
}

-- ============================================
-- FUNÇÕES PRINCIPAIS
-- ============================================

function SyncStateData()
    local stateData = MySQL.Sync.fetchSingle('SELECT * FROM government_state WHERE id = 1')
    
    if stateData then
        SyncedData.state = {
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
        -- Criar estado inicial
        CreateInitialState()
        SyncStateData() -- Recursivo para carregar dados
    end
end

function CreateInitialState()
    MySQL.Sync.execute([[
        INSERT INTO government_state 
        (account_balance, health_balance, security_balance, finance_balance,
         tax_iptu, tax_ipva, tax_inss, tax_fuel, tax_business, tax_iss, tax_iof, tax_icms)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        10000000.00, 2000000.00, 2000000.00, 6000000.00,
        Config.IPTU.taxaPadrao, Config.IPVA.taxaPadrao, Config.INSS.taxaEmpregado,
        Config.Combustivel.taxaPadrao, Config.Empresas.taxaPadrao,
        Config.ISS.taxaPadrao, Config.IOF.taxaPadrao, Config.ICMS.taxaPadrao
    })
    print('[GOV-SYNC] Estado inicial criado')
end

function SyncSecretaries()
    local secretaries = MySQL.Sync.fetchAll([[
        SELECT * FROM government_secretaries WHERE is_active = 1
    ]])
    
    SyncedData.secretaries = {}
    for _, sec in ipairs(secretaries) do
        SyncedData.secretaries[sec.department] = {
            citizenid = sec.secretary_citizenid,
            name = sec.secretary_name,
            grade = sec.secretary_grade,
            appointed_by = sec.appointed_by
        }
    end
end

function SyncAllData()
    SyncStateData()
    SyncSecretaries()
    print('[GOV-SYNC] Todos dados sincronizados')
end

-- ============================================
-- GETTERS
-- ============================================

function GetSyncedData(dataType)
    if dataType == 'state' then
        return SyncedData.state
    elseif dataType == 'taxes' then
        return SyncedData.state.taxes
    elseif dataType == 'secretaries' then
        return SyncedData.secretaries
    end
    return SyncedData
end

function GetStateBalance()
    return SyncedData.state.balance or 0
end

function GetCurrentTaxes()
    return SyncedData.state.taxes or {}
end

function GetDepartmentBalance(department)
    if department == 'health' then
        return SyncedData.state.health_balance or 0
    elseif department == 'security' then
        return SyncedData.state.security_balance or 0
    elseif department == 'finance' then
        return SyncedData.state.finance_balance or 0
    end
    return 0
end

-- ============================================
-- PERMISSÕES
-- ============================================

function HasPermission(citizenid, permission)
    local Player = QBCore.Functions.GetPlayerByCitizenId(citizenid)
    if not Player or Player.PlayerData.job.name ~= Config.JobName then
        return false
    end
    
    local grade = Player.PlayerData.job.grade.level
    local permissions = {
        ['view_state'] = grade >= 0,
        ['view_taxes'] = grade >= 4,
        ['modify_taxes'] = grade >= 4,
        ['view_finance'] = grade >= 4,
        ['modify_finance'] = grade >= 5,
        ['view_health'] = grade >= 2,
        ['modify_health'] = grade >= 2,
        ['view_security'] = grade >= 3,
        ['modify_security'] = grade >= 3,
        ['appoint_secretary'] = grade >= 5
    }
    
    return permissions[permission] or false
end

-- ============================================
-- EVENTOS
-- ============================================

RegisterNetEvent('government:server:requestSync', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player and Player.PlayerData.job.name == Config.JobName then
        TriggerClientEvent('government:client:syncState', src, SyncedData.state)
        TriggerClientEvent('government:client:syncSecretaries', src, SyncedData.secretaries)
    end
end)

-- ============================================
-- INICIALIZAÇÃO
-- ============================================

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        Citizen.Wait(5000)
        SyncAllData()
    end
end)

-- Timer de sincronização
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(300000) -- 5 minutos
        SyncAllData()
    end
end)

-- ============================================
-- EXPORTS
-- ============================================

exports('SyncStateData', SyncStateData)
exports('GetSyncedData', GetSyncedData)
exports('GetStateBalance', GetStateBalance)
exports('GetCurrentTaxes', GetCurrentTaxes)
exports('GetDepartmentBalance', GetDepartmentBalance)
exports('HasPermission', HasPermission)

print('[GOV-SYNC] Módulo de sincronização carregado')