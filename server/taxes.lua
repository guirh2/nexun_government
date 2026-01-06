-- server/taxes.lua - Sistema de impostos
local QBCore = exports['qb-core']:GetCoreObject()
local Taxes = {}

-- ============================================
-- FUNÇÕES PRINCIPAIS
-- ============================================

function Taxes.UpdateTaxRate(taxType, newRate, authorizedBy)
    if not taxType or not newRate then
        return false, "Parâmetros inválidos"
    end
    
    -- Verificar limites
    local limits = GetTaxLimits(taxType)
    if newRate < limits.min or newRate > limits.max then
        return false, string.format("Taxa deve estar entre %.2f%% e %.2f%%", limits.min, limits.max)
    end
    
    -- Atualizar no banco
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
        LogTaxAction('alteracao_taxa', authorizedBy, {
            tax_type = taxType,
            new_rate = newRate
        })
        
        -- Sincronizar
        exports['nexun_government']:SyncStateData()
        
        return true, "Taxa atualizada com sucesso"
    end
    
    return false, "Erro ao atualizar taxa"
end

function GetTaxLimits(taxType)
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
-- CÁLCULO DE IMPOSTOS
-- ============================================

function Taxes.CalculateIPTU(housePrice, citizenid)
    local taxRate = exports['nexun_government']:GetCurrentTaxes().iptu or Config.IPTU.taxaPadrao
    local annualTax = (housePrice * taxRate) / 100
    
    -- Verificar isenção
    if Config.IPTU.isencaoPrimeiraCasa then
        local playerHouses = MySQL.Sync.fetchAll(
            'SELECT * FROM player_houses WHERE citizenid = ?',
            {citizenid}
        )
        if #playerHouses == 0 and housePrice <= Config.IPTU.valorIsencao then
            return 0, "Isento (primeira casa)"
        end
    end
    
    return math.floor(annualTax), string.format("IPTU %.2f%%", taxRate)
end

function Taxes.CalculateIPVA(vehiclePrice, vehicleModel, citizenid)
    local baseRate = exports['nexun_government']:GetCurrentTaxes().ipva or Config.IPVA.taxaPadrao
    local finalRate = baseRate
    
    -- Verificar categoria
    for category, rate in pairs(Config.IPVA.categorias or {}) do
        -- Lógica simplificada de categorização
        if IsVehicleInCategory(vehicleModel, category) then
            finalRate = rate
            break
        end
    end
    
    -- Verificar isenção
    for _, exemptModel in ipairs(Config.IPVA.veiculosIsentos or {}) do
        if exemptModel == vehicleModel then
            return 0, "Veículo isento"
        end
    end
    
    local annualTax = (vehiclePrice * finalRate) / 100
    return math.floor(annualTax), string.format("IPVA %.2f%%", finalRate)
end

function IsVehicleInCategory(model, category)
    -- Lógica simplificada - você pode expandir isso
    local categories = {
        motos = { 'akuma', 'bagger', 'bati', 'bf400' },
        carros_populares = { 'asbo', 'blista', 'brioso', 'dilettante' },
        suv_caminhonetes = { 'baller', 'bjxl', 'cavalcade', 'contender' },
        carros_luxo = { 'adder', 'autarch', 'bullet', 'cheetah' }
    }
    
    local list = categories[category] or {}
    for _, vehicle in ipairs(list) do
        if vehicle == model then
            return true
        end
    end
    return false
end

-- ============================================
-- REGISTRO DE DÍVIDAS
-- ============================================

function Taxes.RegisterTaxDebt(citizenid, playerName, taxType, amount, description, referenceData)
    local dueDate = os.date("%Y-%m-%d", os.time() + 30 * 86400)
    
    local success = MySQL.Sync.insert([[
        INSERT INTO government_player_taxes 
        (citizenid, player_name, tax_type, description, original_amount, current_amount,
         issue_date, due_date, status, reference_data)
        VALUES (?, ?, ?, ?, ?, ?, CURDATE(), ?, ?, ?)
    ]], {
        citizenid,
        playerName,
        taxType,
        description,
        amount,
        amount,
        dueDate,
        'pending',
        json.encode(referenceData or {})
    })
    
    if success then
        LogTaxAction('divida_registrada', 'SISTEMA', {
            citizenid = citizenid,
            tax_type = taxType,
            amount = amount,
            description = description
        })
        
        -- Notificar jogador
        local src = GetSourceFromCitizenId(citizenid)
        if src then
            TriggerClientEvent('QBCore:Notify', src, 
                string.format('Dívida de %s registrada: R$ %.2f', taxType, amount), 
                'warning')
        end
        
        return true
    end
    
    return false
end

function GetSourceFromCitizenId(citizenid)
    local players = QBCore.Functions.GetPlayers()
    for _, src in ipairs(players) do
        local Player = QBCore.Functions.GetPlayer(src)
        if Player and Player.PlayerData.citizenid == citizenid then
            return src
        end
    end
    return nil
end

-- ============================================
-- COBERTURA AUTOMÁTICA
-- ============================================

function Taxes.CollectAutomaticTaxes()
    local totalCollected = 0
    
    -- Coletar IPTU de casas
    if Config.Integrations.qb_houses then
        local houses = MySQL.Sync.fetchAll(
            'SELECT * FROM player_houses WHERE citizenid IS NOT NULL'
        )
        
        for _, house in ipairs(houses) do
            local houseData = MySQL.Sync.fetchSingle(
                'SELECT price FROM houselocations WHERE name = ?',
                {house.house}
            )
            
            if houseData then
                local taxAmount = Taxes.CalculateIPTU(houseData.price, house.citizenid)
                if taxAmount > 0 then
                    Taxes.RegisterTaxDebt(
                        house.citizenid,
                        GetPlayerName(house.citizenid) or "Jogador",
                        'IPTU',
                        taxAmount,
                        "IPTU anual da propriedade",
                        { house = house.house, price = houseData.price }
                    )
                    totalCollected = totalCollected + taxAmount
                end
            end
        end
    end
    
    -- Atualizar tesouro
    if totalCollected > 0 then
        MySQL.Sync.execute(
            'UPDATE government_state SET account_balance = account_balance + ?, total_collected = total_collected + ? WHERE id = 1',
            {totalCollected, totalCollected}
        )
        
        exports['nexun_government']:SyncStateData()
        LogTaxAction('coleta_automatica', 'SISTEMA', { amount = totalCollected })
    end
    
    return totalCollected
end

function GetPlayerName(citizenid)
    local result = MySQL.Sync.fetchSingle(
        'SELECT charinfo FROM players WHERE citizenid = ?',
        {citizenid}
    )
    if result and result.charinfo then
        local charinfo = json.decode(result.charinfo)
        return charinfo.firstname .. ' ' .. charinfo.lastname
    end
    return nil
end

-- ============================================
-- LOGS
-- ============================================

function LogTaxAction(action, author, details)
    MySQL.Sync.insert([[
        INSERT INTO government_logs 
        (log_type, log_category, title, description, citizenid_involved, player_name, metadata)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ]], {
        'impostos',
        action,
        GetTaxActionTitle(action),
        GetTaxActionDescription(action, details),
        details.citizenid,
        author,
        json.encode(details)
    })
end

function GetTaxActionTitle(action)
    local titles = {
        alteracao_taxa = "Alteração de Taxa",
        divida_registrada = "Dívida Registrada",
        pagamento_divida = "Pagamento de Dívida",
        coleta_automatica = "Coleta Automática"
    }
    return titles[action] or "Ação Fiscal"
end

function GetTaxActionDescription(action, details)
    if action == 'alteracao_taxa' then
        return string.format("%s alterou a taxa de %s para %.2f%%", 
            details.authorized_by or author, 
            details.tax_type, 
            details.new_rate)
    elseif action == 'divida_registrada' then
        return string.format("Dívida de %s registrada para %s no valor de R$ %.2f",
            details.tax_type, details.citizenid, details.amount)
    end
    return "Ação fiscal realizada"
end

-- ============================================
-- EVENTOS
-- ============================================

RegisterNetEvent('government:server:updateTaxRate', function(taxType, newRate)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Verificar permissão
    if not exports['nexun_government']:HasPermission(Player.PlayerData.citizenid, 'modify_taxes') then
        TriggerClientEvent('QBCore:Notify', src, 'Sem permissão para alterar impostos', 'error')
        return
    end
    
    local success, message = Taxes.UpdateTaxRate(
        taxType, 
        newRate, 
        Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    )
    
    TriggerClientEvent('QBCore:Notify', src, message, success and 'success' or 'error')
end)

RegisterNetEvent('government:server:collectIPTU', function(houseName)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local house = MySQL.Sync.fetchSingle(
        'SELECT * FROM player_houses WHERE house = ? AND citizenid = ?',
        {houseName, Player.PlayerData.citizenid}
    )
    
    if not house then
        TriggerClientEvent('QBCore:Notify', src, 'Você não é dono desta propriedade', 'error')
        return
    end
    
    local houseData = MySQL.Sync.fetchSingle(
        'SELECT * FROM houselocations WHERE name = ?',
        {houseName}
    )
    
    if not houseData then
        TriggerClientEvent('QBCore:Notify', src, 'Propriedade não encontrada', 'error')
        return
    end
    
    local taxAmount, description = Taxes.CalculateIPTU(houseData.price, Player.PlayerData.citizenid)
    
    if taxAmount > 0 then
        local success = Taxes.RegisterTaxDebt(
            Player.PlayerData.citizenid,
            Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
            'IPTU',
            taxAmount,
            description,
            { house = houseName, price = houseData.price }
        )
        
        TriggerClientEvent('QBCore:Notify', src, 
            string.format('IPTU calculado: R$ %.2f', taxAmount), 
            success and 'success' or 'error')
    else
        TriggerClientEvent('QBCore:Notify', src, 'Isento de IPTU', 'success')
    end
end)

-- ============================================
-- TIMER DE COLETA
-- ============================================

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(3600000) -- 1 hora (teste)
        if Config.ModoTeste then
            Taxes.CollectAutomaticTaxes()
        end
    end
end)

-- ============================================
-- EXPORTS
-- ============================================

exports('UpdateTaxRate', Taxes.UpdateTaxRate)
exports('CalculateIPTU', Taxes.CalculateIPTU)
exports('CalculateIPVA', Taxes.CalculateIPVA)
exports('RegisterTaxDebt', Taxes.RegisterTaxDebt)
exports('CollectAutomaticTaxes', Taxes.CollectAutomaticTaxes)

return Taxes