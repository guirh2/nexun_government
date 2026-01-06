local QBCore = exports['qb-core']:GetCoreObject()
local Config = {}

print('[GOV-SERVER] Sistema de Governo - Banco de Dados REAL')

-- ============================================
-- FUNÇÕES AUXILIARES
-- ============================================

-- Verificar se o jogador tem permissão
function HasPermission(source, minGrade)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    if Player.PlayerData.job.name ~= Config.JobName then
        TriggerClientEvent('QBCore:Notify', source, 'Acesso restrito ao governo', 'error')
        return false
    end
    
    if minGrade and Player.PlayerData.job.grade.level < minGrade then
        TriggerClientEvent('QBCore:Notify', source, 'Permissão insuficiente', 'error')
        return false
    end
    
    return true
end

-- Registrar log no banco
function LogAction(source, logType, category, title, description, amount, taxType)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    MySQL.Async.insert([[
        INSERT INTO government_logs 
        (log_type, log_category, title, description, citizenid_involved, 
         player_name, amount, tax_type, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW())
    ]], {
        logType,
        category,
        title,
        description,
        Player.PlayerData.citizenid,
        Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        amount,
        taxType
    })
end

-- ============================================
-- 1. DASHBOARD - DADOS REAIS DO BANCO
-- ============================================

QBCore.Functions.CreateCallback('government:server:getDashboardData', function(source, cb)
    if not HasPermission(source) then cb({}) return end
    
    local dashboardData = {}
    local today = os.date("%Y-%m-%d")
    local last30Days = os.date("%Y-%m-%d", os.time() - 30 * 24 * 60 * 60)
    
    -- 1. DADOS DO ESTADO (government_state)
    local stateData = MySQL.Sync.fetchSingle('SELECT * FROM government_state WHERE id = 1')
    
    if stateData then
        dashboardData.treasuryBalance = stateData.account_balance or 0
        dashboardData.totalCollected = stateData.total_collected or 0
        
        -- Saldos das secretarias
        dashboardData.healthBalance = stateData.health_balance or 0
        dashboardData.securityBalance = stateData.security_balance or 0
        dashboardData.financeBalance = stateData.finance_balance or 0
        
        -- Alíquotas atuais DO BANCO
        dashboardData.taxRates = {
            iptu = stateData.tax_iptu,
            ipva = stateData.tax_ipva,
            inss = stateData.tax_inss,
            fuel = stateData.tax_fuel,
            business = stateData.tax_business,
            iss = stateData.tax_iss,
            iof = stateData.tax_iof,
            icms = stateData.tax_icms
        }
    else
        print('[GOV-ERROR] Tabela government_state não encontrada!')
        cb({})
        return
    end
    
    -- 2. ARRECADAÇÃO TOTAL (últimos 30 dias)
    local revenueResult = MySQL.Sync.fetchScalar([[
        SELECT COALESCE(SUM(amount), 0) 
        FROM government_transactions 
        WHERE transaction_type IN ('tax_payment', 'license_fee', 'fine')
        AND DATE(created_at) BETWEEN ? AND ?
    ]], {last30Days, today})
    
    dashboardData.totalRevenue = revenueResult or 0
    
    -- 3. SERVIDORES ATIVOS (online e no governo)
    local activeEmployees = MySQL.Sync.fetchScalar([[
        SELECT COUNT(DISTINCT citizenid) 
        FROM players 
        WHERE job = ?
    ]], {Config.JobName})
    
    dashboardData.activeEmployees = activeEmployees or 0
    
    -- 4. ÚLTIMAS ATIVIDADES (government_logs)
    local recentActivities = MySQL.Sync.fetchAll([[
        SELECT 
            title, 
            description, 
            DATE_FORMAT(created_at, '%d/%m/%Y %H:%i') as date
        FROM government_logs 
        ORDER BY created_at DESC 
        LIMIT 5
    ]])
    
    dashboardData.recentActivities = recentActivities or {}
    
    -- 5. TOTAL DE IMPOSTOS PENDENTES
    local pendingTaxes = MySQL.Sync.fetchScalar([[
        SELECT COALESCE(SUM(current_amount), 0)
        FROM government_player_taxes
        WHERE status = 'pending'
    ]])
    
    dashboardData.pendingTaxes = pendingTaxes or 0
    
    -- 6. TOTAL DE VEÍCULOS GOVERNAMENTAIS
    local totalVehicles = MySQL.Sync.fetchScalar([[
        SELECT COUNT(*) 
        FROM government_vehicles
        WHERE status IN ('active', 'available')
    ]])
    
    dashboardData.totalVehicles = totalVehicles or 0
    
    -- 7. MANIFESTOS PENDENTES
    local pendingManifests = MySQL.Sync.fetchScalar([[
        SELECT COUNT(*) 
        FROM government_manifests
        WHERE status = 'pending'
    ]])
    
    dashboardData.pendingManifests = pendingManifests or 0
    
    cb(dashboardData)
end)

-- ============================================
-- 2. TESOURARIA - DADOS REAIS
-- ============================================

QBCore.Functions.CreateCallback('government:server:getTreasuryData', function(source, cb)
    if not HasPermission(source) then cb({}) return end
    
    local treasuryData = {}
    
    -- 1. SALDOS ATUAIS
    local stateData = MySQL.Sync.fetchSingle('SELECT * FROM government_state WHERE id = 1')
    
    if stateData then
        treasuryData.balance = stateData.account_balance
        treasuryData.healthBalance = stateData.health_balance
        treasuryData.securityBalance = stateData.security_balance
        treasuryData.financeBalance = stateData.finance_balance
    end
    
    -- 2. HISTÓRICO DE TRANSAÇÕES (government_transactions)
    local transactionHistory = MySQL.Sync.fetchAll([[
        SELECT 
            transaction_type,
            description,
            amount,
            from_account,
            to_account,
            DATE_FORMAT(created_at, '%d/%m/%Y %H:%i') as date,
            citizenid_from,
            player_name_from
        FROM government_transactions 
        ORDER BY created_at DESC 
        LIMIT 20
    ]])
    
    treasuryData.history = transactionHistory or {}
    
    -- 3. TOTAL GASTO EM REPASSES (este mês)
    local monthStart = os.date("%Y-%m-01")
    local totalTransfers = MySQL.Sync.fetchScalar([[
        SELECT COALESCE(SUM(amount), 0)
        FROM government_transactions 
        WHERE transaction_type = 'transfer'
        AND DATE(created_at) >= ?
    ]], {monthStart})
    
    treasuryData.totalTransfers = totalTransfers or 0
    
    -- 4. TOP 5 MAIORES TRANSAÇÕES
    local topTransactions = MySQL.Sync.fetchAll([[
        SELECT 
            description,
            amount,
            DATE_FORMAT(created_at, '%d/%m/%Y') as date
        FROM government_transactions 
        ORDER BY amount DESC 
        LIMIT 5
    ]])
    
    treasuryData.topTransactions = topTransactions or {}
    
    cb(treasuryData)
end)

RegisterNetEvent('government:server:transferFunds')
AddEventHandler('government:server:transferFunds', function(destination, amount, reason)
    local src = source
    if not HasPermission(src, 4) then return end -- Apenas Sec. Fazenda+
    
    amount = tonumber(amount)
    if not amount or amount <= 0 then
        TriggerClientEvent('QBCore:Notify', src, 'Valor inválido', 'error')
        return
    end
    
    -- Verificar saldo
    local stateData = MySQL.Sync.fetchSingle('SELECT account_balance FROM government_state WHERE id = 1')
    if not stateData or stateData.account_balance < amount then
        TriggerClientEvent('QBCore:Notify', src, 'Saldo insuficiente', 'error')
        return
    end
    
    -- Mapear destino
    local toAccount = 'other'
    if destination == 'Saúde' then
        toAccount = 'health'
    elseif destination == 'Segurança' then
        toAccount = 'security'
    end
    
    local Player = QBCore.Functions.GetPlayer(src)
    
    -- Registrar transação
    local transactionId = 'TR-' .. os.time() .. '-' .. math.random(1000, 9999)
    
    MySQL.Async.insert([[
        INSERT INTO government_transactions 
        (transaction_id, transaction_type, from_account, to_account, amount, 
         description, citizenid_from, player_name_from, authorized_by, 
         authorized_by_cid, details, previous_balance, new_balance, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())
    ]], {
        transactionId,
        'transfer',
        'state',
        toAccount,
        amount,
        reason,
        Player.PlayerData.citizenid,
        Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        Player.PlayerData.citizenid,
        'Destino: ' .. destination,
        stateData.account_balance,
        stateData.account_balance - amount
    })
    
    -- Atualizar saldos
    MySQL.Async.execute('UPDATE government_state SET account_balance = account_balance - ? WHERE id = 1', {amount})
    
    if toAccount == 'health' then
        MySQL.Async.execute('UPDATE government_state SET health_balance = health_balance + ? WHERE id = 1', {amount})
    elseif toAccount == 'security' then
        MySQL.Async.execute('UPDATE government_state SET security_balance = security_balance + ? WHERE id = 1', {amount})
    end
    
    -- Log
    LogAction(src, 'financeiro', 'transferencia', 
        'Transferência de Fundos',
        string.format('Transferiu R$ %.2f para %s: %s', amount, destination, reason),
        amount, nil)
    
    TriggerClientEvent('QBCore:Notify', src, 
        string.format('Transferência de R$ %.2f realizada!', amount), 'success')
end)

-- ============================================
-- 3. LEGISLAÇÃO - DADOS REAIS
-- ============================================

QBCore.Functions.CreateCallback('government:server:getLawsData', function(source, cb)
    if not HasPermission(source) then cb({}) return end
    
    local lawsData = {}
    
    -- Buscar leis do banco (se você tiver a tabela)
    -- Por enquanto, buscar logs relacionados
    lawsData.pendingLaws = MySQL.Sync.fetchAll([[
        SELECT 
            id,
            title,
            description,
            DATE_FORMAT(created_at, '%d/%m/%Y') as date
        FROM government_logs 
        WHERE log_category = 'legislacao' AND title LIKE '%Projeto%'
        ORDER BY created_at DESC 
        LIMIT 10
    ]]) or {}
    
    -- Buscar leis sancionadas (do seu HTML, seria do banco depois)
    lawsData.penalCode = MySQL.Sync.fetchAll([[
        SELECT 
            description,
            DATE_FORMAT(created_at, '%d/%m/%Y') as date
        FROM government_logs 
        WHERE log_category = 'legislacao' AND description LIKE '%sancion%'
        ORDER BY created_at DESC 
        LIMIT 5
    ]]) or {}
    
    cb(lawsData)
end)

RegisterNetEvent('government:server:processLaw')
AddEventHandler('government:server:processLaw', function(lawId, decision, justification)
    local src = source
    if not HasPermission(src, 5) then return end -- Apenas Governador/Vice
    
    local Player = QBCore.Functions.GetPlayer(src)
    
    -- Aqui você processaria a lei REAL no banco
    -- Por enquanto, apenas log
    
    LogAction(src, 'admin', 'legislacao',
        'Processamento de Lei',
        string.format('%s a lei. Decisão: %s. Justificativa: %s', 
            Player.PlayerData.charinfo.firstname, decision, justification or 'Sem justificativa'),
        0, nil)
    
    TriggerClientEvent('QBCore:Notify', src, 'Lei processada no Diário Oficial!', 'success')
end)

-- ============================================
-- 4. MEMBROS - DADOS REAIS DO BANCO
-- ============================================

QBCore.Functions.CreateCallback('government:server:getMembersData', function(source, cb)
    if not HasPermission(source) then cb({}) return end
    
    local membersData = {}
    
    -- 1. CONTAGEM POR CARGO (players table)
    local gradeCounts = MySQL.Sync.fetchAll([[
        SELECT 
            job.grade as grade_level,
            COUNT(*) as count
        FROM players 
        WHERE job = 'governo'
        GROUP BY job.grade
    ]])
    
    membersData.gradeCounts = {}
    local totalMembers = 0
    
    for _, countData in ipairs(gradeCounts or {}) do
        local grade = countData.grade_level
        local count = countData.count
        
        if grade >= 2 and grade <= 4 then
            membersData.gradeCounts.secretario = (membersData.gradeCounts.secretario or 0) + count
        elseif grade == 5 then
            membersData.gradeCounts.vice = count
        elseif grade == 6 then
            membersData.gradeCounts.governador = count
        else
            membersData.gradeCounts.outros = (membersData.gradeCounts.outros or 0) + count
        end
        
        totalMembers = totalMembers + count
    end
    
    membersData.totalMembers = totalMembers
    
    -- 2. LISTA DE SECRETÁRIOS ATIVOS (government_secretaries)
    local secretaries = MySQL.Sync.fetchAll([[
        SELECT 
            department_label,
            secretary_name,
            secretary_citizenid,
            DATE_FORMAT(appointed_at, '%d/%m/%Y') as appointed_date
        FROM government_secretaries 
        WHERE is_active = 1
        ORDER BY appointed_at DESC
    ]])
    
    membersData.secretaries = secretaries or {}
    
    -- 3. MEMBROS ONLINE AGORA
    local onlineMembers = {}
    local players = QBCore.Functions.GetPlayers()
    
    for _, playerId in ipairs(players) do
        local player = QBCore.Functions.GetPlayer(playerId)
        if player and player.PlayerData.job.name == Config.JobName then
            table.insert(onlineMembers, {
                name = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
                citizenid = player.PlayerData.citizenid,
                grade = player.PlayerData.job.grade.name,
                gradeLevel = player.PlayerData.job.grade.level,
                phone = player.PlayerData.charinfo.phone
            })
        end
    end
    
    membersData.onlineMembers = onlineMembers
    
    cb(membersData)
end)

RegisterNetEvent('government:server:appointMember')
AddEventHandler('government:server:appointMember', function(citizenid, cargoNome)
    local src = source
    if not HasPermission(src) then return end
    
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player.PlayerData.job.isboss then
        TriggerClientEvent('QBCore:Notify', src, 'Apenas cargos superiores', 'error')
        return
    end
    
    -- Converter cargo para grade
    local gradeLevel = 0
    local department = 'general'
    
    if cargoNome == "Secretário de Saúde" then 
        gradeLevel = 2
        department = 'health'
    elseif cargoNome == "Secretário de Segurança" then 
        gradeLevel = 3
        department = 'security'
    elseif cargoNome == "Secretário da Fazenda" then 
        gradeLevel = 4
        department = 'finance'
    elseif cargoNome == "Vice-Governador" then 
        gradeLevel = 5
        department = 'governor'
    else 
        gradeLevel = 1
    end
    
    -- Buscar jogador
    local TargetPlayer = QBCore.Functions.GetPlayerByCitizenId(citizenid)
    
    if TargetPlayer then
        -- Atualizar emprego
        TargetPlayer.Functions.SetJob("governo", gradeLevel)
        
        -- Registrar no banco
        MySQL.Async.insert([[
            INSERT INTO government_secretaries 
            (department, department_label, secretary_citizenid, secretary_name, 
             secretary_grade, appointed_by, appointed_at, is_active)
            VALUES (?, ?, ?, ?, ?, ?, NOW(), 1)
        ]], {
            department,
            cargoNome,
            citizenid,
            TargetPlayer.PlayerData.charinfo.firstname .. ' ' .. TargetPlayer.PlayerData.charinfo.lastname,
            gradeLevel,
            Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
        })
        
        LogAction(src, 'admin', 'nomeacao',
            'Nomeação de Secretário',
            string.format('Nomeou %s como %s', 
                TargetPlayer.PlayerData.charinfo.firstname, cargoNome),
            0, nil)
        
        TriggerClientEvent('QBCore:Notify', TargetPlayer.PlayerData.source, 
            'Você foi nomeado para o governo!', 'success')
        TriggerClientEvent('QBCore:Notify', src, 
            string.format('%s nomeado como %s!', 
                TargetPlayer.PlayerData.charinfo.firstname, cargoNome), 'success')
    else
        -- Jogador offline
        MySQL.Async.insert([[
            INSERT INTO government_secretaries 
            (department, department_label, secretary_citizenid, secretary_name, 
             secretary_grade, appointed_by, appointed_at, is_active)
            VALUES (?, ?, ?, ?, ?, ?, NOW(), 0)
        ]], {
            department,
            cargoNome,
            citizenid,
            'Aguardando entrada',
            gradeLevel,
            Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
        })
        
        TriggerClientEvent('QBCore:Notify', src, 
            'Nomeação agendada para quando o cidadão entrar.', 'info')
    end
end)

-- ============================================
-- 5. EMENDAS - DADOS REAIS
-- ============================================

QBCore.Functions.CreateCallback('government:server:getAmendmentsData', function(source, cb)
    if not HasPermission(source) then cb({}) return end
    
    local amendmentsData = {}
    
    -- Buscar emendas pendentes (do banco)
    amendmentsData.pending = MySQL.Sync.fetchAll([[
        SELECT 
            id,
            title,
            amount,
            description,
            DATE_FORMAT(created_at, '%d/%m/%Y') as date
        FROM government_requests 
        WHERE type = 'emenda' AND status = 'pending'
        ORDER BY created_at DESC
    ]]) or {}
    
    -- Buscar emendas aprovadas
    amendmentsData.approved = MySQL.Sync.fetchAll([[
        SELECT 
            title,
            amount,
            DATE_FORMAT(updated_at, '%d/%m/%Y') as date,
            processed_by
        FROM government_requests 
        WHERE type = 'emenda' AND status = 'approved'
        ORDER BY updated_at DESC 
        LIMIT 10
    ]]) or {}
    
    -- Buscar emendas reprovadas
    amendmentsData.rejected = MySQL.Sync.fetchAll([[
        SELECT 
            title,
            amount,
            DATE_FORMAT(updated_at, '%d/%m/%Y') as date,
            processed_by,
            rejection_reason
        FROM government_requests 
        WHERE type = 'emenda' AND status = 'rejected'
        ORDER BY updated_at DESC 
        LIMIT 10
    ]]) or {}
    
    cb(amendmentsData)
end)

RegisterNetEvent('government:server:processAmendment')
AddEventHandler('government:server:processAmendment', function(amendmentId, decision, justification)
    local src = source
    if not HasPermission(src, 4) then return end -- Sec. Fazenda+
    
    local Player = QBCore.Functions.GetPlayer(src)
    
    -- Aqui você atualizaria a tabela government_requests
    -- Por enquanto, log
    
    LogAction(src, 'admin', 'emendas',
        'Processamento de Emenda',
        string.format('%s a emenda ID %s. Justificativa: %s', 
            decision, amendmentId, justification or 'Sem justificativa'),
        0, nil)
    
    TriggerClientEvent('QBCore:Notify', src, 'Emenda processada!', 'success')
end)

-- ============================================
-- 6. DEMANDAS - DADOS REAIS
-- ============================================

QBCore.Functions.CreateCallback('government:server:getRequestsData', function(source, cb)
    if not HasPermission(source) then cb({}) return end
    
    local requestsData = {}
    
    -- Demandas de secretários
    requestsData.secretaryRequests = MySQL.Sync.fetchAll([[
        SELECT 
            id,
            title,
            description,
            requested_by,
            DATE_FORMAT(created_at, '%d/%m/%Y') as date,
            status
        FROM government_requests 
        WHERE type = 'secretary'
        ORDER BY created_at DESC 
        LIMIT 10
    ]]) or {}
    
    -- Demandas de cidadãos
    requestsData.citizenRequests = MySQL.Sync.fetchAll([[
        SELECT 
            id,
            title,
            description,
            citizenid,
            player_name,
            contact_info,
            DATE_FORMAT(created_at, '%d/%m/%Y') as date,
            status
        FROM government_requests 
        WHERE type = 'citizen'
        ORDER BY created_at DESC 
        LIMIT 10
    ]]) or {}
    
    cb(requestsData)
end)

RegisterNetEvent('government:server:closeRequest')
AddEventHandler('government:server:closeRequest', function(requestId, response)
    local src = source
    if not HasPermission(src) then return end
    
    local Player = QBCore.Functions.GetPlayer(src)
    
    -- Atualizar demanda no banco
    MySQL.Async.execute([[
        UPDATE government_requests 
        SET status = 'closed', 
            processed_by = ?,
            processed_at = NOW(),
            response = ?
        WHERE id = ?
    ]], {
        Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        response,
        requestId
    })
    
    LogAction(src, 'admin', 'demandas',
        'Demanda Finalizada',
        string.format('Respondeu demanda ID %s: %s', requestId, response),
        0, nil)
    
    TriggerClientEvent('QBCore:Notify', src, 'Demanda respondida!', 'success')
end)

-- ============================================
-- 7. ATUALIZAR ALÍQUOTAS
-- ============================================

RegisterNetEvent('government:server:updateTaxRate')
AddEventHandler('government:server:updateTaxRate', function(taxType, newRate)
    local src = source
    if not HasPermission(src, 4) then return end -- Sec. Fazenda+
    
    -- Mapear coluna no banco
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
        TriggerClientEvent('QBCore:Notify', src, 'Tipo de imposto inválido', 'error')
        return
    end
    
    -- Atualizar no banco
    MySQL.Async.execute(string.format('UPDATE government_state SET %s = ? WHERE id = 1', column), {newRate})
    
    local Player = QBCore.Functions.GetPlayer(src)
    LogAction(src, 'impostos', 'alteracao_taxa',
        'Alteração de Taxa',
        string.format('Alterou %s para %.2f%%', taxType:upper(), newRate),
        0, taxType)
    
    TriggerClientEvent('QBCore:Notify', src, 
        string.format('%s atualizado para %.2f%%', taxType:upper(), newRate), 'success')
end)

-- ============================================
-- INICIALIZAÇÃO
-- ============================================

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        print('[GOV-SERVER] Sistema de Governo iniciado com sucesso!')
        print('[GOV-SERVER] Conectado ao banco de dados REAL')
        
        -- Verificar tabelas essenciais
        local stateExists = MySQL.Sync.fetchScalar([[
            SELECT COUNT(*) 
            FROM information_schema.tables 
            WHERE table_schema = DATABASE() 
            AND table_name = 'government_state'
        ]])
        
        if stateExists == 0 then
            print('[GOV-ALERTA] Tabela government_state não encontrada! Execute o install.sql')
        else
            print('[GOV-SERVER] Banco de dados OK')
        end
    end
end)

-- ============================================
-- COMANDOS DE TESTE
-- ============================================

RegisterCommand('govtest', function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player and Player.PlayerData.job.name == 'governo' then
        -- Mostrar dados reais do banco
        local stateData = MySQL.Sync.fetchSingle('SELECT * FROM government_state WHERE id = 1')
        
        if stateData then
            TriggerClientEvent('QBCore:Notify', src, 
                string.format('Tesouro: R$ %.2f | Saúde: R$ %.2f | Segurança: R$ %.2f', 
                    stateData.account_balance, 
                    stateData.health_balance, 
                    stateData.security_balance), 
                'primary')
            
            -- Contar membros
            local memberCount = MySQL.Sync.fetchScalar([[
                SELECT COUNT(*) FROM players WHERE job = 'governo'
            ]])
            
            TriggerClientEvent('QBCore:Notify', src, 
                string.format('Membros do governo: %d', memberCount or 0), 
                'info')
        end
    end
end, false)

print('[GOV-SERVER] Sistema pronto para uso com dados REAIS do banco!')

    -- server/main.lua - Callbacks para dados REAIS
QBCore.Functions.CreateCallback('government:server:getDashboardData', function(source, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then cb({}) return end
    if Player.PlayerData.job.name ~= Config.JobName then cb({}) return end
    
    print('[GOV-SERVER] Dashboard solicitado por: ' .. Player.PlayerData.charinfo.firstname)
    
    local dashboardData = {}
    
    -- 1. DADOS DO ESTADO (REAIS DO BANCO)
    local stateData = MySQL.Sync.fetchSingle('SELECT * FROM government_state WHERE id = 1')
    
    if stateData then
        dashboardData.treasuryBalance = stateData.account_balance or 0
        dashboardData.healthBalance = stateData.health_balance or 0
        dashboardData.securityBalance = stateData.security_balance or 0
        dashboardData.financeBalance = stateData.finance_balance or 0
        
        -- IMPOSTOS REAIS DO BANCO
        dashboardData.taxRates = {
            iptu = stateData.tax_iptu,
            ipva = stateData.tax_ipva,
            inss = stateData.tax_inss,
            fuel = stateData.tax_fuel,
            business = stateData.tax_business,
            iss = stateData.tax_iss,
            iof = stateData.tax_iof,
            icms = stateData.tax_icms
        }
    else
        print('[GOV-ERROR] Tabela government_state não encontrada!')
        cb({})
        return
    end
    
    -- 2. ARRECADAÇÃO (REAL DO BANCO)
    local today = os.date("%Y-%m-%d")
    local last30Days = os.date("%Y-%m-%d", os.time() - 30 * 24 * 60 * 60)
    
    local revenueResult = MySQL.Sync.fetchScalar([[
        SELECT COALESCE(SUM(amount), 0) 
        FROM government_transactions 
        WHERE transaction_type IN ('tax_payment', 'license_fee', 'fine')
        AND DATE(created_at) BETWEEN ? AND ?
    ]], {last30Days, today})
    
    dashboardData.totalRevenue = revenueResult or 0
    
    -- 3. SERVIDORES ATIVOS (REAL)
    local activeEmployees = MySQL.Sync.fetchScalar([[
        SELECT COUNT(DISTINCT citizenid) 
        FROM players 
        WHERE job = ?
    ]], {Config.JobName})
    
    dashboardData.activeEmployees = activeEmployees or 0
    
    -- 4. ATIVIDADES RECENTES (REAIS)
    local recentActivities = MySQL.Sync.fetchAll([[
        SELECT title, description, DATE_FORMAT(created_at, '%d/%m/%Y %H:%i') as date
        FROM government_logs 
        ORDER BY created_at DESC 
        LIMIT 5
    ]])
    
    dashboardData.recentActivities = recentActivities or {}
    
    -- 5. DADOS ADICIONAIS
    dashboardData.pendingTaxes = MySQL.Sync.fetchScalar([[
        SELECT COALESCE(SUM(current_amount), 0)
        FROM government_player_taxes
        WHERE status = 'pending'
    ]]) or 0
    
    dashboardData.totalVehicles = MySQL.Sync.fetchScalar([[
        SELECT COUNT(*) 
        FROM government_vehicles
        WHERE status IN ('active', 'available')
    ]]) or 0
    
    cb(dashboardData)
end)

-- Tesouraria
QBCore.Functions.CreateCallback('government:server:getTreasuryData', function(source, cb)
    local treasuryData = {}
    
    -- Saldo atual
    local stateData = MySQL.Sync.fetchSingle('SELECT * FROM government_state WHERE id = 1')
    if stateData then
        treasuryData.balance = stateData.account_balance
    end
    
    -- Histórico de transações
    local transactions = MySQL.Sync.fetchAll([[
        SELECT transaction_type, description, amount, from_account, to_account,
               DATE_FORMAT(created_at, '%d/%m/%Y %H:%i') as date, player_name_from
        FROM government_transactions 
        ORDER BY created_at DESC 
        LIMIT 20
    ]])
    
    treasuryData.history = transactions or {}
    
    cb(treasuryData)
end)

-- Membros
QBCore.Functions.CreateCallback('government:server:getMembersData', function(source, cb)
    local membersData = {}
    
    -- Contagem por cargo
    local gradeCounts = MySQL.Sync.fetchAll([[
        SELECT job.grade as grade_level, COUNT(*) as count
        FROM players 
        WHERE job = 'governo'
        GROUP BY job.grade
    ]])
    
    membersData.gradeCounts = {}
    if gradeCounts then
        for _, countData in ipairs(gradeCounts) do
            local grade = countData.grade_level
            local count = countData.count
            
            if grade >= 2 and grade <= 4 then
                membersData.gradeCounts.secretario = (membersData.gradeCounts.secretario or 0) + count
            elseif grade == 5 then
                membersData.gradeCounts.vice = count
            elseif grade == 6 then
                membersData.gradeCounts.governador = count
            end
        end
    end
    
    -- Membros online
    local onlineMembers = {}
    local players = QBCore.Functions.GetPlayers()
    
    for _, playerId in ipairs(players) do
        local player = QBCore.Functions.GetPlayer(playerId)
        if player and player.PlayerData.job.name == Config.JobName then
            table.insert(onlineMembers, {
                name = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
                citizenid = player.PlayerData.citizenid,
                grade = player.PlayerData.job.grade.name,
                gradeLevel = player.PlayerData.job.grade.level
            })
        end
    end
    
    membersData.onlineMembers = onlineMembers
    
    cb(membersData)
end)