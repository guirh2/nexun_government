-- client/tablet.lua
-- Controle do tablet (VERSÃO COMPLETA)

local QBCore = exports['qb-core']:GetCoreObject()
local tabletOpen = false

-- ====================
-- ABRIR TABLET
-- ====================
RegisterCommand('govtablet', function()
    local Player = QBCore.Functions.GetPlayerData()
    
    if not Player or not Player.job then
        QBCore.Functions.Notify('Você não é funcionário do governo', 'error')
        return
    end
    
    if Player.job.name ~= 'governo' then
        QBCore.Functions.Notify('Você não é funcionário do governo', 'error')
        return
    end
    
    if Player.job.grade.level < 1 then
        QBCore.Functions.Notify('Apenas assessores ou superior podem usar o tablet', 'error')
        return
    end
    
    -- Abrir NUI
    tabletOpen = true
    SetNuiFocus(true, true)
    
    SendNUIMessage({
        action = 'openTablet',  -- ALTEREI: de 'showTablet' para 'openTablet'
        data = {
            playerName = Player.charinfo.firstname .. ' ' .. Player.charinfo.lastname,
            playerJobGrade = Player.job.grade.name,
            playerGradeLevel = Player.job.grade.level
        }
    })
    
    print('[GOV-TABLET] Tablet aberto para: ' .. Player.charinfo.firstname .. ' (' .. Player.job.grade.name .. ')')
end, false)

-- ====================
-- CALLBACKS QUE O JAVASCRIPT USA
-- ====================

-- 1. Fechar tablet (JÁ TEM)
RegisterNUICallback('closeTablet', function(data, cb)
    tabletOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

-- 2. DASHBOARD
RegisterNUICallback('getDashboardData', function(data, cb)
    print('[GOV-NUI] Dashboard solicitado')
    QBCore.Functions.TriggerCallback('government:server:getDashboardData', function(dashboardData)
        cb(dashboardData or {})
    end)
end)

-- 3. TESOURARIA
RegisterNUICallback('getTreasuryData', function(data, cb)
    print('[GOV-NUI] Tesouraria solicitada')
    QBCore.Functions.TriggerCallback('government:server:getTreasuryData', function(treasuryData)
        cb(treasuryData or {})
    end)
end)

-- 4. TRANSFERÊNCIA (JÁ TEM, MAS VAMOS MANTER)
RegisterNUICallback('transferFunds', function(data, cb)
    local destino = data.destination
    local valor = data.amount
    local motivo = data.reason
    
    print('[GOV-NUI] Transferência solicitada: ' .. destino .. ' - R$' .. valor)
    
    -- Validação básica no cliente
    if not destino or not valor or valor <= 0 then
        QBCore.Functions.Notify("Preencha todos os campos corretamente.", "error")
        cb({ success = false })
        return
    end
    
    -- Envia para o servidor processar
    TriggerServerEvent('government:server:transferFunds', destino, valor, motivo)
    
    -- Confirma recebimento para a interface
    cb({ success = true })
end)

-- 5. LEGISLAÇÃO
RegisterNUICallback('processLaw', function(data, cb)
    print('[GOV-NUI] Processar lei: ' .. (data.lawId or 'N/A'))
    TriggerServerEvent('government:server:processLaw', data.lawId, data.decision, data.justification)
    cb({ success = true })
end)

-- 6. MEMBROS
RegisterNUICallback('appointMember', function(data, cb)
    print('[GOV-NUI] Nomear membro: ' .. (data.citizenid or 'N/A'))
    TriggerServerEvent('government:server:appointMember', data.citizenid, data.cargo)
    cb({ success = true })
end)

-- 7. EMENDAS
RegisterNUICallback('processAmendment', function(data, cb)
    print('[GOV-NUI] Processar emenda: ' .. (data.amendmentId or 'N/A'))
    TriggerServerEvent('government:server:processAmendment', data.amendmentId, data.decision, data.justification)
    cb({ success = true })
end)

-- 8. DEMANDAS
RegisterNUICallback('closeRequest', function(data, cb)
    print('[GOV-NUI] Fechar demanda: ' .. (data.requestId or 'N/A'))
    TriggerServerEvent('government:server:closeRequest', data.requestId, data.response)
    cb({ success = true })
end)

-- 9. TESTE (OPCIONAL)
RegisterNUICallback('requestData', function(data, cb)
    if data.type == 'test' then
        cb({ success = true, message = 'Sistema funcionando!' })
    else
        cb({})
    end
end)

-- ====================
-- CONTROLE DO ESC
-- ====================
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        
        if tabletOpen then
            -- Fechar com ESC
            if IsControlJustReleased(0, 322) then  -- ESC
                tabletOpen = false
                SetNuiFocus(false, false)
                SendNUIMessage({ action = 'closeTablet' })
            end
            
            -- Bloquear outras ações
            DisableControlAction(0, 1, true)   -- Mouse
            DisableControlAction(0, 2, true)   -- Mouse
            DisableControlAction(0, 24, true)  -- Attack
        end
    end
end)

-- ====================
-- DEBUG
-- ====================
RegisterCommand('govdebug', function()
    print('=== DEBUG GOV TABLET ===')
    print('Tablet aberto: ' .. tostring(tabletOpen))
    print('NUI focus: ' .. tostring(IsNuiFocused()))
    
    local Player = QBCore.Functions.GetPlayerData()
    if Player then
        print('Jogador: ' .. Player.charinfo.firstname)
        print('Emprego: ' .. Player.job.name)
        print('Grade: ' .. Player.job.grade.level)
    end
end, false)



-- client/tablet.lua - VERSÃO CORRIGIDA
local QBCore = exports['qb-core']:GetCoreObject()
local tabletOpen = false

-- Abrir tablet
RegisterCommand('govtablet', function()
    local PlayerData = QBCore.Functions.GetPlayerData()
    
    if PlayerData.job.name ~= "governo" then
        QBCore.Functions.Notify("Acesso restrito ao governo.", "error", 5000)
        return
    end
    
    tabletOpen = true
    SetNuiFocus(true, true)
    
    -- CORREÇÃO: Enviar dados corretamente para o NUI
    SendNUIMessage({
        action = 'openTablet',
        data = {
            -- CORREÇÃO AQUI: Enviar nome COMPLETO
            playerName = PlayerData.charinfo.firstname .. ' ' .. PlayerData.charinfo.lastname,
            -- CORREÇÃO AQUI: Enviar cargo CORRETO
            playerJobGrade = PlayerData.job.grade.name
        }
    })
    
    print('[GOV-TABLET] Tablet aberto para: ' .. PlayerData.charinfo.firstname)
end, false)

-- Callbacks para dados reais
RegisterNUICallback('getDashboardData', function(data, cb)
    QBCore.Functions.TriggerCallback('government:server:getDashboardData', function(dashboardData)
        cb(dashboardData or {})
    end)
end)

RegisterNUICallback('getTreasuryData', function(data, cb)
    QBCore.Functions.TriggerCallback('government:server:getTreasuryData', function(treasuryData)
        cb(treasuryData or {})
    end)
end)

RegisterNUICallback('getMembersData', function(data, cb)
    QBCore.Functions.TriggerCallback('government:server:getMembersData', function(membersData)
        cb(membersData or {})
    end)
end)

RegisterNUICallback('transferFunds', function(data, cb)
    TriggerServerEvent('government:server:transferFunds', data.destination, data.amount, data.reason)
    cb({ success = true })
end)

-- Fechar tablet
RegisterNUICallback('closeTablet', function(data, cb)
    tabletOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

-- Controle do ESC
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if tabletOpen and IsControlJustReleased(0, 322) then
            tabletOpen = false
            SetNuiFocus(false, false)
            SendNUIMessage({ action = 'closeTablet' })
        end
    end
end)