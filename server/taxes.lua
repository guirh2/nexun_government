local QBCore = exports['qb-core']:GetCoreObject()

-- [[ 1. LOOP DE COBRANÇA AUTOMÁTICA ]] --
CreateThread(function()
    while true do
        -- Intervalo definido no Config.Finance.TaxInterval (ex: 60 minutos)
        Wait(Config.Finance.TaxInterval * 60000)
        ProcessGovernmentTaxes()
    end
end)

-- [[ 2. LÓGICA DE PROCESSAMENTO DE IMPOSTOS ]] --
function ProcessGovernmentTaxes()
    local totalCollected = 0
    local players = QBCore.Functions.GetQBPlayers()
    
    -- Busca alíquotas e valores fixos do Banco de Dados
    local taxes = MySQL.query.await('SELECT * FROM government_taxes')
    local taxRates = {}
    for _, v in pairs(taxes) do 
        taxRates[v.tax_name] = tonumber(v.tax_value) 
    end

    for _, Player in pairs(players) do
        local citizenid = Player.PlayerData.citizenid
        local taxBill = 0
        local taxDetails = {}

        -- A. IMPOSTO DE RENDA / INSS (Sobre saldo bancário)
        local bankBalance = Player.PlayerData.money['bank']
        if bankBalance > 1000 then
            local inssAmount = math.floor(bankBalance * (taxRates['inss'] / 100))
            taxBill = taxBill + inssAmount
            table.insert(taxDetails, "INSS")
        end

        -- B. IPVA (Baseado em veículos na garagem)
        local vehicleCount = MySQL.scalar.await('SELECT COUNT(*) FROM player_vehicles WHERE citizenid = ?', {citizenid})
        if vehicleCount > 0 then
            local ipvaAmount = math.floor(vehicleCount * (taxRates['ipva'] * 20)) -- Ex: 5% = $100 por carro
            taxBill = taxBill + ipvaAmount
            table.insert(taxDetails, "IPVA")
        end

        -- C. TAXA EMPRESARIAL (Se for dono/boss de empresa)
        if Player.PlayerData.job.isboss then
            local companyTax = taxRates['empresas'] or 500
            taxBill = taxBill + companyTax
            table.insert(taxDetails, "Taxa Empresarial")
        end

        -- D. TAXA DE LICENÇAS (Armas e Motorista)
        local licenses = Player.PlayerData.metadata["licences"]
        if licenses then
            if licenses["weapon"] then
                taxBill = taxBill + (taxRates['porte_arma'] or 200)
                table.insert(taxDetails, "Licença de Arma")
            end
            if licenses["driver"] then
                taxBill = taxBill + (taxRates['licenca_motorista'] or 50)
                table.insert(taxDetails, "Licença de Direção")
            end
        end

        -- Execução da Cobrança
        if taxBill > 0 then
            if Player.Functions.RemoveMoney('bank', taxBill, "Impostos Estaduais") then
                totalCollected = totalCollected + taxBill
                TriggerClientEvent('QBCore:Notify', Player.PlayerData.source, "O Estado recolheu R$ "..taxBill.." ("..table.concat(taxDetails, ", ")..")", "info")
            end
        end
    end

    -- Distribuir o montante arrecadado e registrar logs
    if totalCollected > 0 then
        DistributeRevenue(totalCollected)
    end
end

-- [[ 3. DISTRIBUIÇÃO E AUDITORIA ]] --
function DistributeRevenue(amount)
    -- Busca porcentagens definidas pelo Governador
    local govData = MySQL.single.await('SELECT * FROM government_treasury WHERE id = 1')
    
    local toSaude = math.floor(amount * (govData.budget_saude_perc / 100))
    local toSeguranca = math.floor(amount * (govData.budget_seguranca_perc / 100))
    local toReserva = amount - (toSaude + toSeguranca)

    -- Atualiza Saldos no Banco
    MySQL.update([[
        UPDATE government_treasury 
        SET budget_saude_balance = budget_saude_balance + ?, 
            budget_seguranca_balance = budget_seguranca_balance + ?,
            balance = balance + ?,
            total_collected = total_collected + ?
        WHERE id = 1
    ]], {toSaude, toSeguranca, toReserva, amount})

    -- REGISTRO DE LOG NO BANCO DE DADOS (Auditoria)
    MySQL.insert('INSERT INTO government_logs (dept, author_name, action, details, amount) VALUES (?, ?, ?, ?, ?)', {
        'fazenda', 'Sistema Fiscal', 'Arrecadação de Ciclo', 
        string.format("Arrecadação dividida: Saúde (R$ %s), Segurança (R$ %s), Reserva (R$ %s)", toSaude, toSeguranca, toReserva),
        amount
    })

    -- Sync Global para todos os Tablets
    TriggerEvent('nexun_government:server:syncAllFinance')
end

-- [[ 4. ATUALIZAÇÃO DE TAXAS PELO SECRETÁRIO DA FAZENDA ]] --
RegisterNetEvent('nexun_government:server:updateTaxRate', function(taxName, newValue)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    -- Segurança: Apenas Secretário da Fazenda (Grade 2), Vice (3) ou Governador (4)
    if Player.PlayerData.job.name == Config.GovManagement.JobName and Player.PlayerData.job.grade.level >= 2 then
        local label = ""
        for _, v in pairs(Config.Finance.Taxes) do -- Busca o label na config
            if v.tax_name == taxName then label = v.label break end
        end

        MySQL.update('UPDATE government_taxes SET tax_value = ?, updated_by = ? WHERE tax_name = ?', {
            newValue, Player.PlayerData.charinfo.firstname.." "..Player.PlayerData.charinfo.lastname, taxName
        })

        -- Log de Auditoria da alteração
        MySQL.insert('INSERT INTO government_logs (dept, author_name, author_cid, action, details) VALUES (?, ?, ?, ?, ?)', {
            'fazenda', Player.PlayerData.charinfo.firstname.." "..Player.PlayerData.charinfo.lastname, 
            Player.PlayerData.citizenid, 'Alteração de Alíquota', 
            "Imposto "..taxName.." alterado para "..newValue.."%"
        })

        TriggerEvent('nexun_government:server:syncAllFinance')
        TriggerClientEvent('QBCore:Notify', src, "Alíquota de "..taxName.." atualizada para "..newValue.."%", "success")
    end
end)