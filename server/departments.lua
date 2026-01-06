-- server/departments.lua - Sistema de secretarias
local QBCore = exports['qb-core']:GetCoreObject()
local Departments = {}

-- ============================================
-- INICIALIZAÇÃO
-- ============================================

function Departments.InitializeSecretaries()
    print('[GOV-DEPARTMENTS] Inicializando secretarias...')
    
    -- Criar tabela se não existir
    MySQL.Sync.execute([[
        CREATE TABLE IF NOT EXISTS government_secretaries (
            id INT AUTO_INCREMENT PRIMARY KEY,
            department VARCHAR(50) NOT NULL,
            department_label VARCHAR(100) NOT NULL,
            secretary_citizenid VARCHAR(11),
            secretary_name VARCHAR(100),
            secretary_grade INT,
            appointed_by VARCHAR(100),
            appointed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            removed_at TIMESTAMP NULL,
            removed_by VARCHAR(100),
            removal_reason TEXT,
            is_active BOOLEAN DEFAULT true,
            metadata JSON,
            INDEX idx_department (department),
            INDEX idx_active (is_active)
        )
    ]])
    
    -- Verificar secretarias padrão
    local defaultDepartments = {
        { department = 'health', label = 'Secretaria de Saúde', grade = 2 },
        { department = 'security', label = 'Secretaria de Segurança', grade = 3 },
        { department = 'finance', label = 'Secretaria da Fazenda', grade = 4 }
    }
    
    for _, dept in ipairs(defaultDepartments) do
        local exists = MySQL.Sync.fetchSingle(
            'SELECT id FROM government_secretaries WHERE department = ? AND is_active = 1',
            {dept.department}
        )
        
        if not exists then
            MySQL.Sync.insert([[
                INSERT INTO government_secretaries 
                (department, department_label, secretary_grade, is_active, appointed_by)
                VALUES (?, ?, ?, 1, 'SISTEMA')
            ]], { dept.department, dept.label, dept.grade })
        end
    end
    
    print('[GOV-DEPARTMENTS] Secretarias inicializadas')
end

-- ============================================
-- FUNÇÕES DE SECRETARIAS
-- ============================================

function Departments.AppointSecretary(department, citizenid, playerName, appointedBy)
    -- Validar department
    if not (department == 'health' or department == 'security' or department == 'finance') then
        return false, "Departamento inválido"
    end
    
    -- Verificar secretário atual
    local current = Departments.GetCurrentSecretary(department)
    if current then
        MySQL.Sync.execute(
            'UPDATE government_secretaries SET is_active = 0, removed_at = NOW(), removed_by = ? WHERE id = ?',
            {appointedBy, current.id}
        )
    end
    
    -- Obter grade
    local grade = Departments.GetSecretaryGrade(department)
    
    -- Inserir novo
    local success = MySQL.Sync.insert([[
        INSERT INTO government_secretaries 
        (department, department_label, secretary_citizenid, secretary_name, 
         secretary_grade, appointed_by, appointed_at, is_active)
        VALUES (?, ?, ?, ?, ?, ?, NOW(), 1)
    ]], {
        department,
        Departments.GetDepartmentLabel(department),
        citizenid,
        playerName,
        grade,
        appointedBy
    })
    
    if success then
        -- Atualizar job
        Departments.UpdatePlayerJob(citizenid, grade)
        
        -- Log
        LogDepartmentAction('nomeacao_cargo', appointedBy, {
            department = department,
            citizenid = citizenid,
            player_name = playerName,
            grade = grade
        })
        
        return true, "Secretário nomeado com sucesso"
    end
    
    return false, "Erro ao nomear secretário"
end

function Departments.GetCurrentSecretary(department)
    return MySQL.Sync.fetchSingle(
        'SELECT * FROM government_secretaries WHERE department = ? AND is_active = 1',
        {department}
    )
end

function Departments.GetSecretaryGrade(department)
    if department == 'health' then return 2
    elseif department == 'security' then return 3
    elseif department == 'finance' then return 4
    end
    return 0
end

function Departments.GetDepartmentLabel(department)
    if department == 'health' then return 'Secretaria de Saúde'
    elseif department == 'security' then return 'Secretaria de Segurança'
    elseif department == 'finance' then return 'Secretaria da Fazenda'
    elseif department == 'governor' then return 'Governadoria'
    end
    return department
end

function Departments.UpdatePlayerJob(citizenid, grade)
    local jobData = {
        name = Config.JobName,
        label = Config.JobLabel,
        grade = grade,
        onduty = true
    }
    
    MySQL.Sync.execute(
        'UPDATE players SET job = ? WHERE citizenid = ?',
        {json.encode(jobData), citizenid}
    )
    
    local Player = QBCore.Functions.GetPlayerByCitizenId(citizenid)
    if Player then
        Player.Functions.SetJob(Config.JobName, grade)
    end
end

-- ============================================
-- FUNÇÕES DE MANIFESTOS
-- ============================================

function Departments.CreateManifest(manifestData)
    local manifestNumber = GenerateManifestNumber(manifestData.manifest_type)
    
    local success = MySQL.Sync.insert([[
        INSERT INTO government_manifests 
        (manifest_number, manifest_type, department, origin, destination, 
         items_data, total_items, total_value, created_by, created_by_cid, status)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        manifestNumber,
        manifestData.manifest_type,
        manifestData.department or manifestData.manifest_type,
        manifestData.origin,
        manifestData.destination,
        json.encode(manifestData.items or {}),
        manifestData.total_items or 0,
        manifestData.total_value or 0,
        manifestData.created_by,
        manifestData.created_by_cid,
        'pending'
    })
    
    if success then
        LogDepartmentAction('manifesto_gerado', manifestData.created_by, {
            manifest_number = manifestNumber,
            manifest_type = manifestData.manifest_type,
            items_count = manifestData.total_items,
            total_value = manifestData.total_value
        })
        
        return manifestNumber
    end
    
    return nil
end

function GenerateManifestNumber(manifestType)
    local prefix = manifestType == 'health' and 'MF-SAUDE' or 'MF-SEG'
    local year = os.date('%Y')
    
    local lastNumber = MySQL.Sync.fetchSingle(
        'SELECT manifest_number FROM government_manifests WHERE manifest_number LIKE ? ORDER BY id DESC LIMIT 1',
        {prefix .. '-' .. year .. '-%'}
    )
    
    local nextNumber = 1
    if lastNumber then
        local lastNumStr = string.match(lastNumber.manifest_number, '%d+$')
        if lastNumStr then
            nextNumber = tonumber(lastNumStr) + 1
        end
    end
    
    return string.format('%s-%s-%03d', prefix, year, nextNumber)
end

-- ============================================
-- FUNÇÕES DE COMPRAS
-- ============================================

function Departments.PurchaseItems(department, items, purchasedBy)
    local totalCost = 0
    for _, item in ipairs(items) do
        totalCost = totalCost + (item.price * item.quantity)
    end
    
    -- Verificar saldo
    local balance = exports['nexun_government']:GetDepartmentBalance(department)
    if balance < totalCost then
        return false, "Saldo insuficiente"
    end
    
    -- Debitar do departamento
    local columnMap = {
        health = 'health_balance',
        security = 'security_balance',
        finance = 'finance_balance'
    }
    
    local column = columnMap[department]
    if column then
        MySQL.Sync.execute(
            'UPDATE government_state SET ' .. column .. ' = ' .. column .. ' - ? WHERE id = 1',
            {totalCost}
        )
    end
    
    -- Adicionar ao tesouro
    MySQL.Sync.execute(
        'UPDATE government_state SET account_balance = account_balance + ? WHERE id = 1',
        {totalCost}
    )
    
    -- Adicionar ao estoque
    for _, item in ipairs(items) do
        Departments.AddToStock(department, item.name, item.quantity, item.price)
    end
    
    -- Log
    LogDepartmentAction('compra_realizada', purchasedBy, {
        department = department,
        items_count = #items,
        total_cost = totalCost
    })
    
    exports['nexun_government']:SyncStateData()
    
    return true, "Compra realizada com sucesso"
end

function Departments.AddToStock(department, itemName, quantity, unitPrice)
    MySQL.Sync.insert([[
        INSERT INTO government_stocks 
        (department, unit_name, unit_code, item_name, item_label, 
         current_quantity, unit_cost, total_value)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE 
        current_quantity = current_quantity + VALUES(current_quantity),
        total_value = total_value + VALUES(total_value)
    ]], {
        department,
        'Depósito Central',
        'DEP-001',
        itemName,
        itemName,
        quantity,
        unitPrice,
        quantity * unitPrice
    })
end

-- ============================================
-- PERMISSÕES
-- ============================================

function Departments.CanTransferFunds(citizenid, fromAcc, toAcc)
    local Player = QBCore.Functions.GetPlayerByCitizenId(citizenid)
    if not Player then return false end
    
    local grade = Player.PlayerData.job.grade.level
    
    -- Governador pode tudo
    if grade >= 6 then return true end
    
    -- Vice pode tudo exceto estado
    if grade >= 5 then
        return fromAcc ~= 'state' and toAcc ~= 'state'
    end
    
    -- Secretários só sua secretaria
    if grade == 4 then -- Fazenda
        return fromAcc == 'finance' or toAcc == 'finance'
    elseif grade == 3 then -- Segurança
        return fromAcc == 'security' or toAcc == 'security'
    elseif grade == 2 then -- Saúde
        return fromAcc == 'health' or toAcc == 'health'
    end
    
    return false
end

function Departments.CanCreateManifest(citizenid, manifestType)
    local Player = QBCore.Functions.GetPlayerByCitizenId(citizenid)
    if not Player then return false end
    
    local grade = Player.PlayerData.job.grade.level
    
    if manifestType == 'health' then
        return grade == 2 or grade >= 5
    elseif manifestType == 'security' then
        return grade == 3 or grade >= 5
    end
    
    return false
end

-- ============================================
-- LOGS
-- ============================================

function LogDepartmentAction(action, author, details)
    MySQL.Sync.insert([[
        INSERT INTO government_logs 
        (log_type, log_category, title, description, player_name, metadata)
        VALUES (?, ?, ?, ?, ?, ?)
    ]], {
        'admin',
        action,
        GetDepartmentActionTitle(action),
        GetDepartmentActionDescription(action, details),
        author,
        json.encode(details)
    })
end

function GetDepartmentActionTitle(action)
    local titles = {
        nomeacao_cargo = "Nomeação para Cargo",
        manifesto_gerado = "Manifesto Gerado",
        compra_realizada = "Compra Realizada",
        transferencia = "Transferência de Fundos"
    }
    return titles[action] or "Ação Administrativa"
end

function GetDepartmentActionDescription(action, details)
    if action == 'nomeacao_cargo' then
        return string.format("%s nomeado como Secretário de %s", 
            details.player_name, details.department)
    elseif action == 'manifesto_gerado' then
        return string.format("Manifesto %s gerado com %d itens", 
            details.manifest_number, details.items_count)
    end
    return "Ação administrativa registrada"
end

-- ============================================
-- EVENTOS
-- ============================================

RegisterNetEvent('government:server:appointSecretary', function(department, targetId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local Target = QBCore.Functions.GetPlayer(tonumber(targetId))
    
    if not Player or not Target then
        TriggerClientEvent('QBCore:Notify', src, 'Jogador não encontrado', 'error')
        return
    end
    
    -- Verificar permissão
    if not exports['nexun_government']:HasPermission(Player.PlayerData.citizenid, 'appoint_secretary') then
        TriggerClientEvent('QBCore:Notify', src, 'Sem permissão para nomear secretários', 'error')
        return
    end
    
    local success, message = Departments.AppointSecretary(
        department,
        Target.PlayerData.citizenid,
        Target.PlayerData.charinfo.firstname .. ' ' .. Target.PlayerData.charinfo.lastname,
        Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    )
    
    TriggerClientEvent('QBCore:Notify', src, message, success and 'success' or 'error')
    
    if success then
        TriggerClientEvent('QBCore:Notify', Target.PlayerData.source, 
            string.format('Você foi nomeado Secretário de %s!', Departments.GetDepartmentLabel(department)), 
            'success')
    end
end)

RegisterNetEvent('government:server:createManifest', function(manifestData)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Verificar permissão
    if not Departments.CanCreateManifest(Player.PlayerData.citizenid, manifestData.manifest_type) then
        TriggerClientEvent('QBCore:Notify', src, 'Sem permissão para criar manifesto', 'error')
        return
    end
    
    manifestData.created_by = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    manifestData.created_by_cid = Player.PlayerData.citizenid
    
    local manifestNumber = Departments.CreateManifest(manifestData)
    
    if manifestNumber then
        TriggerClientEvent('QBCore:Notify', src, 'Manifesto criado: ' .. manifestNumber, 'success')
    else
        TriggerClientEvent('QBCore:Notify', src, 'Erro ao criar manifesto', 'error')
    end
end)

-- ============================================
-- INICIALIZAÇÃO
-- ============================================

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        Citizen.Wait(3000)
        Departments.InitializeSecretaries()
    end
end)

-- ============================================
-- EXPORTS
-- ============================================

exports('AppointSecretary', Departments.AppointSecretary)
exports('GetCurrentSecretary', Departments.GetCurrentSecretary)
exports('CreateManifest', Departments.CreateManifest)
exports('PurchaseItems', Departments.PurchaseItems)
exports('CanTransferFunds', Departments.CanTransferFunds)
exports('CanCreateManifest', Departments.CanCreateManifest)

return Departments