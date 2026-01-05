local QBCore = exports['qb-core']:GetCoreObject()

-- [[ 1. SINCRONIZAÇÃO GLOBAL DE FINANÇAS ]] --

-- Evento interno para disparar atualização para todos os membros do governo online
RegisterNetEvent('nexun_government:server:syncAllFinance', function()
    local treasuryData = MySQL.single.await('SELECT * FROM government_treasury WHERE id = 1')
    local taxes = MySQL.query.await('SELECT * FROM government_taxes')
    
    local syncPayload = {
        treasuryBalance = treasuryData.balance,
        saudeBalance = treasuryData.budget_saude_balance,
        saudePerc = treasuryData.budget_saude_perc,
        segBalance = treasuryData.budget_seguranca_balance,
        segPerc = treasuryData.budget_seguranca_perc,
        taxes = taxes
    }

    -- Envia apenas para quem tem o job de governo ou é gestor de unidade
    local players = QBCore.Functions.GetQBPlayers()
    for _, Player in pairs(players) do
        if Player.PlayerData.job.name == Config.GovManagement.JobName or IsPlayerUnitManager(Player) then
            TriggerClientEvent('nexun_government:client:syncFinanceData', Player.PlayerData.source, syncPayload)
        end
    end
end)

-- [[ 2. SINCRONIZAÇÃO DE UNIDADES (BATALHÕES/HOSPITAIS) ]] --

-- Sincroniza a verba específica de um batalhão ou hospital
RegisterNetEvent('nexun_government:server:syncUnitData', function(unitId, jobName)
    local result = MySQL.single.await('SELECT budget_balance FROM government_units WHERE unit_id = ?', {unitId})
    
    if result then
        local players = QBCore.Functions.GetQBPlayers()
        for _, Player in pairs(players) do
            -- Se o player trabalha naquela unidade e tem cargo de gestão
            if Player.PlayerData.job.name == jobName then
                TriggerClientEvent('nexun_government:client:updateUnitBudget', Player.PlayerData.source, result.budget_balance)
            end
        end
    end
end)

-- [[ 3. SINCRONIZAÇÃO DE LOGÍSTICA (HUBS) ]] --

-- Atualiza as missões de transporte ativas para as secretarias correspondentes
RegisterNetEvent('nexun_government:server:syncLogistics', function(type)
    local deliveries = MySQL.query.await('SELECT * FROM government_deliveries WHERE status != "delivered"')
    
    TriggerClientEvent('nexun_government:client:updateLogistics', -1, deliveries)
end)

-- [[ 4. HELPERS DE VERIFICAÇÃO ]] --

-- Verifica se o player é um gestor de unidade (Coronel, Diretor, etc)
function IsPlayerUnitManager(Player)
    local job = Player.PlayerData.job.name
    local grade = Player.PlayerData.job.grade.level

    -- Checa na config de Segurança
    for _, unit in pairs(Config.SecurityDept.Units) do
        if unit.job == job and grade >= unit.grade_gestor then return true end
    end

    -- Checa na config de Saúde
    for _, unit in pairs(Config.HealthDept.Units) do
        if unit.job == job and grade >= unit.grade_gestor then return true end
    end

    return false
end

-- [[ 5. AUTO-REFRESH AO ENTRAR ]] --

-- Quando o player carrega o personagem, se ele for do governo, recebe os dados
RegisterNetEvent('QBCore:Server:PlayerLoaded', function(Player)
    if Player.PlayerData.job.name == Config.GovManagement.JobName or IsPlayerUnitManager(Player) then
        Wait(5000) -- Aguarda o carregamento completo
        TriggerEvent('nexun_government:server:syncAllFinance')
    end
end)

-- Export para forçar sync via outros scripts
exports('ForceSyncFinance', function()
    TriggerEvent('nexun_government:server:syncAllFinance')
end)