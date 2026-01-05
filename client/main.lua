local QBCore = exports['qb-core']:GetCoreObject()
local tabletOpen = false

-- [[ 1. COMANDO PARA ABRIR O TABLET ]] --

RegisterCommand('tabletgov', function()
    local PlayerData = QBCore.Functions.GetPlayerData()
    
    -- Verifica se o player tem o job de governo
    if PlayerData.job.name == Config.GovManagement.JobName then
        local grade = PlayerData.job.grade.level
        local perms = Config.GovManagement.Grades[grade]

        if perms then
            OpenGovernmentTablet(perms)
        else
            QBCore.Functions.Notify("Seu cargo não possui credenciais para o sistema.", "error")
        end
    else
        QBCore.Functions.Notify("Acesso restrito a membros do Governo.", "error")
    end
end)

-- [[ 2. LÓGICA DE ABERTURA E PERMISSÕES ]] --

function OpenGovernmentTablet(perms)
    tabletOpen = true
    
    -- 1. Animação do Player (Segurar Tablet)
    ExecuteCommand('e tablet') 
    
    -- 2. Envia as permissões para o NUI (HTML/JS) esconder os ícones bloqueados
    SendNUIMessage({
        action = "setupPermissions",
        allowedApps = perms.access,
        cargo = perms.cargo,
        dept = perms.dept
    })

    -- 3. Abre a interface
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "openTablet"
    })
    
    -- 4. Solicita os dados iniciais do servidor para popular o tablet
    TriggerServerEvent('nexun_government:server:requestSync')
end

-- [[ 3. CALLBACKS DO NUI (FECHAR E AÇÕES) ]] --

RegisterNUICallback('closeTablet', function(data, cb)
    tabletOpen = false
    StopAnimTask(PlayerPedId(), "amb@code_human_in_car_mp_idlestd@idle_a", "idle_a", 1.0)
    SetNuiFocus(false, false)
    cb('ok')
end)

-- Callback para Manutenção de Viatura (Solicitada pelo Batalhão)
-- Conforme regra: Requisitada pelo batalhão usando a verba deles
RegisterNUICallback('requestVehicleRepair', function(data, cb)
    QBCore.Functions.TriggerCallback('nexun_government:server:unitRepairVehicle', function(success, msg)
        if success then
            QBCore.Functions.Notify(msg, "success")
        else
            QBCore.Functions.Notify(msg, "error")
        end
    end, data.plate, data.cost)
    cb('ok')
end)

-- [[ 4. SINCRONIZAÇÃO DE DADOS ]] --

RegisterNetEvent('nexun_government:client:syncData', function(payload)
    if tabletOpen then
        SendNUIMessage({
            action = "updateFinanceData",
            payload = payload
        })
    end
end)

-- Sync de Saldo da Unidade (Batalhão/Hospital)
RegisterNetEvent('nexun_government:client:updateUnitBudget', function(budget)
    if tabletOpen then
        SendNUIMessage({
            action = "updateUnitBudget",
            budget = budget
        })
    end
end)