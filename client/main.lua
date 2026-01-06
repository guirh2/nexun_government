-- local QBCore = exports['qb-core']:GetCoreObject()
-- local tabletOpen = false

-- -- [[ 1. COMANDO PARA ABRIR O TABLET ]] --

-- RegisterCommand('tabletgov', function()
--     local PlayerData = QBCore.Functions.GetPlayerData()
    
--     -- Verifica se o player tem o job de governo
--     if PlayerData.job.name == Config.GovManagement.JobName then
--         local grade = PlayerData.job.grade.level
--         local perms = Config.GovManagement.Grades[grade]

--         if perms then
--             OpenGovernmentTablet(perms)
--         else
--             QBCore.Functions.Notify("Seu cargo não possui credenciais para o sistema.", "error")
--         end
--     else
--         QBCore.Functions.Notify("Acesso restrito a membros do Governo.", "error")
--     end
-- end)

-- -- [[ 2. LÓGICA DE ABERTURA E PERMISSÕES ]] --

-- function OpenGovernmentTablet(perms)
--     tabletOpen = true
    
--     -- 1. Animação do Player (Segurar Tablet)
--     ExecuteCommand('e tablet') 
    
--     -- 2. Envia as permissões para o NUI (HTML/JS) esconder os ícones bloqueados
--     SendNUIMessage({
--         action = "setupPermissions",
--         allowedApps = perms.access,
--         cargo = perms.cargo,
--         dept = perms.dept
--     })

--     -- 3. Abre a interface
--     SetNuiFocus(true, true)
--     SendNUIMessage({
--         action = "openTablet"
--     })
    
--     -- 4. Solicita os dados iniciais do servidor para popular o tablet
--     TriggerServerEvent('nexun_government:server:requestSync')
-- end

-- -- [[ 3. CALLBACKS DO NUI (FECHAR E AÇÕES) ]] --

-- RegisterNUICallback('closeTablet', function(data, cb)
--     tabletOpen = false
--     StopAnimTask(PlayerPedId(), "amb@code_human_in_car_mp_idlestd@idle_a", "idle_a", 1.0)
--     SetNuiFocus(false, false)
--     cb('ok')
-- end)

-- -- Callback para Manutenção de Viatura (Solicitada pelo Batalhão)
-- -- Conforme regra: Requisitada pelo batalhão usando a verba deles
-- RegisterNUICallback('requestVehicleRepair', function(data, cb)
--     QBCore.Functions.TriggerCallback('nexun_government:server:unitRepairVehicle', function(success, msg)
--         if success then
--             QBCore.Functions.Notify(msg, "success")
--         else
--             QBCore.Functions.Notify(msg, "error")
--         end
--     end, data.plate, data.cost)
--     cb('ok')
-- end)

-- -- [[ 4. SINCRONIZAÇÃO DE DADOS ]] --

-- RegisterNetEvent('nexun_government:client:syncData', function(payload)
--     if tabletOpen then
--         SendNUIMessage({
--             action = "updateFinanceData",
--             payload = payload
--         })
--     end
-- end)

-- -- Sync de Saldo da Unidade (Batalhão/Hospital)
-- RegisterNetEvent('nexun_government:client:updateUnitBudget', function(budget)
--     if tabletOpen then
--         SendNUIMessage({
--             action = "updateUnitBudget",
--             budget = budget
--         })
--     end
-- end)

-- client/main.lua
-- Cliente principal do Sistema de Governo

local QBCore = exports['qb-core']:GetCoreObject()

-- ============================================
-- VARIÁVEIS DO CLIENTE
-- ============================================
local GovernmentData = {
    state = {},
    secretaries = {},
    playerData = {}
}

local HasTablet = false
local TabletObject = nil
local IsGovEmployee = false
local PlayerGrade = 0

-- ============================================
-- FUNÇÕES PRINCIPAIS
-- ============================================

-- Verificar se jogador é do governo
function CheckGovernmentStatus()
    local Player = QBCore.Functions.GetPlayerData()
    
    if not Player or not Player.job then
        IsGovEmployee = false
        PlayerGrade = 0
        return
    end
    
    IsGovEmployee = Player.job.name == Config.JobName
    PlayerGrade = Player.job.grade.level or 0
    
    -- Atualizar dados se for do governo
    if IsGovEmployee then
        RequestSync()
        
        -- Dar tablet se tiver permissão
        if PlayerGrade >= 1 then -- Assessor+
            GiveGovernmentTablet()
        end
    else
        RemoveGovernmentTablet()
    end
end

-- Solicitar sincronização de dados
function RequestSync()
    TriggerServerEvent('government:server:requestSync')
end

-- Receber dados do estado
RegisterNetEvent('government:client:syncState', function(stateData)
    GovernmentData.state = stateData
    
    -- Debug
    if Config.ModoTeste then
        print('[GOV-CLIENT] Estado sincronizado')
        print(string.format('Saldo: R$ %.2f', stateData.balance or 0))
    end
end)

-- Receber dados dos secretários
RegisterNetEvent('government:client:syncSecretaries', function(secretariesData)
    GovernmentData.secretaries = secretariesData
end)

-- Receber dados pessoais
RegisterNetEvent('government:client:syncPlayerData', function(playerData)
    GovernmentData.playerData = playerData
    
    -- Notificar sobre dívidas
    if playerData.taxes and #playerData.taxes > 0 then
        ShowTaxNotifications(playerData.taxes)
    end
end)

-- ============================================
-- TABLET DO GOVERNO
-- ============================================

function GiveGovernmentTablet()
    if HasTablet then return end
    
    HasTablet = true
    
    -- Criar item no inventário (se usando qb-inventory)
    if Config.Integrations.qb_inventory then
        TriggerServerEvent('government:server:giveTabletItem')
    end
    
    -- Adicionar command para abrir tablet
    RegisterCommand('govtablet', function()
        OpenGovernmentTablet()
    end, false)
    
    -- Keybind (F6 por exemplo)
    RegisterKeyMapping('govtablet', 'Abrir Tablet do Governo', 'keyboard', 'F6')
    
    print('[GOV-CLIENT] Tablet do governo disponível (F6)')
end

function RemoveGovernmentTablet()
    if not HasTablet then return end
    
    HasTablet = false
    
    -- Remover command
    -- Nota: Não é possível remover commands dinamicamente no FiveM
    -- Mas podemos desativar a funcionalidade
    
    print('[GOV-CLIENT] Tablet do governo removido')
end

function OpenGovernmentTablet()
    if not IsGovEmployee then
        QBCore.Functions.Notify('Você não é funcionário do governo.', 'error')
        return
    end
    
    if PlayerGrade < 1 then
        QBCore.Functions.Notify('Apenas assessores ou superiores podem acessar o tablet.', 'error')
        return
    end
    
    -- Verificar se tem o item (se usando inventário)
    if Config.Integrations.qb_inventory then
        QBCore.Functions.TriggerCallback('government:server:hasTabletItem', function(hasItem)
            if hasItem then
                ShowTabletUI()
            else
                QBCore.Functions.Notify('Você não possui o tablet do governo.', 'error')
            end
        end)
    else
        ShowTabletUI()
    end
end

function ShowTabletUI()
    -- Fechar qualquer UI aberta
    SetNuiFocus(false, false)
    
    -- Abrir NUI
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'showTablet',
        playerData = {
            grade = PlayerGrade,
            name = GetPlayerName(),
            department = GetPlayerDepartment()
        },
        stateData = GovernmentData.state,
        permissions = GetPlayerPermissions()
    })
    
    -- Animação de abrir tablet
    RequestAnimDict('amb@world_human_tourist_map@male@base')
    while not HasAnimDictLoaded('amb@world_human_tourist_map@male@base') do
        Wait(100)
    end
    
    TabletObject = CreateObject(GetHashKey('prop_cs_tablet'), 0, 0, 0, true, true, true)
    AttachEntityToEntity(TabletObject, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), 28422), 0.0, 0.0, 0.03, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
    TaskPlayAnim(PlayerPedId(), 'amb@world_human_tourist_map@male@base', 'base', 8.0, -8.0, -1, 50, 0, false, false, false)
end

function CloseTabletUI()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'hideTablet' })
    
    -- Limpar animação
    if TabletObject then
        DeleteObject(TabletObject)
        TabletObject = nil
    end
    
    ClearPedTasks(PlayerPedId())
end

-- ============================================
-- FUNÇÕES DE PERMISSÃO
-- ============================================

function GetPlayerPermissions()
    local permissions = {
        canViewState = PlayerGrade >= 0,
        canViewTaxes = PlayerGrade >= 4,
        canModifyTaxes = PlayerGrade >= 4,
        canViewFinance = PlayerGrade >= 4,
        canModifyFinance = PlayerGrade >= 5,
        canViewHealth = PlayerGrade >= 2,
        canModifyHealth = PlayerGrade >= 2,
        canViewSecurity = PlayerGrade >= 3,
        canModifySecurity = PlayerGrade >= 3,
        canAppointSecretary = PlayerGrade >= 5,
        isGovernor = PlayerGrade == 6,
        isViceGovernor = PlayerGrade == 5,
        isSecretary = PlayerGrade >= 2 and PlayerGrade <= 4
    }
    
    return permissions
end

function GetPlayerDepartment()
    if PlayerGrade == 2 then
        return 'health'
    elseif PlayerGrade == 3 then
        return 'security'
    elseif PlayerGrade == 4 then
        return 'finance'
    elseif PlayerGrade >= 5 then
        return 'governor'
    else
        return 'staff'
    end
end

function GetPlayerName()
    local Player = QBCore.Functions.GetPlayerData()
    if Player and Player.charinfo then
        return Player.charinfo.firstname .. ' ' .. Player.charinfo.lastname
    end
    return 'Cidadão'
end

-- ============================================
-- NOTIFICAÇÕES
-- ============================================

function ShowTaxNotifications(taxes)
    for _, tax in ipairs(taxes) do
        if tax.status == 'overdue' then
            QBCore.Functions.Notify(
                string.format('⚠️ DÍVIDA VENCIDA: %s - R$ %.2f', tax.description, tax.amount),
                'error',
                10000
            )
        elseif tax.status == 'pending' then
            QBCore.Functions.Notify(
                string.format('📅 Dívida pendente: %s - R$ %.2f (Vence: %s)', 
                    tax.description, tax.amount, tax.due_date),
                'warning',
                8000
            )
        end
    end
end

-- ============================================
-- NUI CALLBACKS
-- ============================================

RegisterNUICallback('closeTablet', function(data, cb)
    CloseTabletUI()
    cb('ok')
end)

RegisterNUICallback('requestData', function(data, cb)
    if data.type == 'state' then
        cb(GovernmentData.state)
    elseif data.type == 'player' then
        cb({
            grade = PlayerGrade,
            name = GetPlayerName(),
            department = GetPlayerDepartment(),
            permissions = GetPlayerPermissions()
        })
    elseif data.type == 'secretaries' then
        cb(GovernmentData.secretaries)
    else
        cb({})
    end
end)

RegisterNUICallback('executeAction', function(data, cb)
    -- Verificar permissão
    if not HasPermissionForAction(data.action) then
        cb({ success = false, message = 'Sem permissão' })
        return
    end
    
    -- Encaminhar para o servidor
    TriggerServerEvent('government:server:' .. data.action, data.params)
    
    cb({ success = true, message = 'Ação executada' })
end)

RegisterNUICallback('switchApp', function(data, cb)
    -- Mudar para app específico
    SendNUIMessage({
        action = 'loadApp',
        appName = data.appName,
        appData = data.appData or {}
    })
    
    cb('ok')
end)

function HasPermissionForAction(action)
    local permissions = GetPlayerPermissions()
    
    local actionPermissions = {
        ['updateTax'] = permissions.canModifyTaxes,
        ['transferFunds'] = permissions.canModifyFinance,
        ['appointSecretary'] = permissions.canAppointSecretary,
        ['createManifest'] = permissions.isSecretary or permissions.isGovernor or permissions.isViceGovernor,
        ['purchaseItems'] = permissions.isSecretary or permissions.isGovernor or permissions.isViceGovernor
    }
    
    return actionPermissions[action] or false
end

-- ============================================
-- EVENTOS
-- ============================================

-- Quando jogador carrega
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Citizen.Wait(5000)
    CheckGovernmentStatus()
end)

-- Quando job muda
RegisterNetEvent('QBCore:Client:OnJobUpdate', function()
    CheckGovernmentStatus()
end)

-- Quando receber notificação do servidor
RegisterNetEvent('government:client:notify', function(message, type, duration)
    QBCore.Functions.Notify(message, type or 'primary', duration or 5000)
end)

-- Quando dados são atualizados
RegisterNetEvent('government:client:dataUpdated', function(dataType)
    -- Solicitar nova sincronização
    RequestSync()
    
    -- Notificar
    QBCore.Functions.Notify('Dados do governo atualizados', 'success')
end)

-- ============================================
-- THREADS
-- ============================================

-- Verificar status periodicamente
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(30000) -- 30 segundos
        
        CheckGovernmentStatus()
    end
end)

-- Debug (apenas em modo teste)
if Config.ModoTeste then
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(60000) -- 1 minuto
            
            print('[GOV-CLIENT DEBUG]')
            print('É funcionário: ' .. tostring(IsGovEmployee))
            print('Grade: ' .. PlayerGrade)
            print('Tem tablet: ' .. tostring(HasTablet))
            print('Saldo do estado: R$ ' .. (GovernmentData.state.balance or 0))
        end
    end)
end

print('[GOV-CLIENT] Sistema de governo carregado')