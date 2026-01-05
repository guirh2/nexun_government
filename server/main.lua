local QBCore = exports['qb-core']:GetCoreObject()

-- [[ 1. CALLBACKS DE VERIFICAÇÃO ]] --

-- Verifica se a Secretaria tem saldo para compras macro (Viaturas/Lotes de Armas)
QBCore.Functions.CreateCallback('nexun_government:server:canSecretariaAfford', function(source, cb, dept, price)
    local treasury = MySQL.single.await('SELECT * FROM government_treasury WHERE id = 1')
    local balanceField = (dept == 'saude') and "budget_saude_balance" or "budget_seguranca_balance"
    
    if treasury[balanceField] >= price then
        cb(true)
    else
        cb(false)
    end
end)

-- [[ 2. GESTÃO DE TRANSFERÊNCIAS (SECRETÁRIO -> BATALHÃO) ]] --

RegisterNetEvent('nexun_government:server:transferToUnit', function(dept, unitId, amount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    amount = tonumber(amount)

    if not Player or amount <= 0 then return end

    -- 1. Retira do saldo da Secretaria
    local balanceField = (dept == 'saude') and "budget_saude_balance" or "budget_seguranca_balance"
    local treasury = MySQL.single.await('SELECT * FROM government_treasury WHERE id = 1')

    if treasury[balanceField] >= amount then
        -- 2. Deduz da Secretaria e adiciona ao Batalhão/Hospital
        MySQL.update('UPDATE government_treasury SET '..balanceField..' = '..balanceField..' - ? WHERE id = 1', {amount})
        MySQL.update('UPDATE government_units SET budget_balance = budget_balance + ? WHERE unit_id = ?', {amount, unitId})

        -- 3. Sync e Log
        TriggerEvent('nexun_government:server:syncAllFinance')
        TriggerEvent('nexun_government:server:syncUnitData', unitId, (dept == 'saude' and 'ambulance' or 'police'))
        
        TriggerEvent('nexun_government:server:DiscordLog', dept, 'Transferência de Verba', 
            string.format("O Secretário %s enviou R$ %s para a unidade %s", Player.PlayerData.charinfo.firstname, amount, unitId))
    else
        TriggerClientEvent('QBCore:Notify', src, "A Secretaria não possui este saldo disponível.", "error")
    end
end)

-- [[ 3. PROCESSAMENTO DE COMPRAS E LOGÍSTICA (HUBS) ]] --

RegisterNetEvent('nexun_government:server:processSecurityPurchase', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local price = tonumber(data.price)

    -- Deduz o valor da Secretaria de Segurança
    MySQL.update('UPDATE government_treasury SET budget_seguranca_balance = budget_seguranca_balance - ? WHERE id = 1', {price})

    -- Gera os dados dos itens (com seriais únicos se for arma)
    local itemsToDeliver = {}
    if data.type == 'weapon' then
        local serial = GenerateUniqueGovSerial('seguranca') -- Função que definimos antes
        table.insert(itemsToDeliver, {model = data.model, label = data.label, serial = serial})
    else
        table.insert(itemsToDeliver, {model = data.model, label = data.label})
    end

    -- Cria a entrega no Banco de Dados
    local deliveryId = MySQL.insert.await([[
        INSERT INTO government_deliveries (hub_origin, destiny_unit, items_data, status, type) 
        VALUES (?, ?, ?, 'waiting', 'seguranca')
    ]], {data.hubId, data.unitDestiny, json.encode(itemsToDeliver)})

    -- Gera o Manifesto Físico para o transportador
    local info = {
        deliveryId = deliveryId,
        origin = data.hubId,
        destiny = data.unitDestiny,
        items = itemsToDeliver
    }
    exports.ox_inventory:AddItem(src, 'manifesto_gov', 1, info)

    TriggerEvent('nexun_government:server:syncAllFinance')
    TriggerEvent('nexun_government:server:syncLogistics')
end)

-- [[ 4. MANUTENÇÃO REQUISITADA PELO BATALHÃO ]] --

QBCore.Functions.CreateCallback('nexun_government:server:unitRepairVehicle', function(source, cb, plate, cost)
    local Player = QBCore.Functions.GetPlayer(source)
    local unitId = GetPlayerUnitId(Player) -- Função auxiliar para identificar o batalhão do player
    
    local unit = MySQL.single.await('SELECT budget_balance FROM government_units WHERE unit_id = ?', {unitId})

    if unit and unit.budget_balance >= cost then
        -- Deduz da verba do batalhão
        MySQL.update('UPDATE government_units SET budget_balance = budget_balance - ? WHERE unit_id = ?', {cost, unitId})
        
        -- Aqui você integraria com seu script de mecânico ou apenas resetaria o dano no banco
        MySQL.update('UPDATE player_vehicles SET engine = 1000, body = 1000 WHERE plate = ?', {plate})
        
        TriggerEvent('nexun_government:server:syncUnitData', unitId, Player.PlayerData.job.name)
        cb(true, "Manutenção realizada com sucesso!")
    else
        cb(false, "Verba do batalhão insuficiente!")
    end
end)

-- [[ HELPERS ]] --

function GetPlayerUnitId(Player)
    -- Lógica simples: retorna o ID do batalhão baseado na configuração do job
    for id, unit in pairs(Config.SecurityDept.Units) do
        if unit.job == Player.PlayerData.job.name then return id end
    end
    return nil
end