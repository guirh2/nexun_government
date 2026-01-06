-- client/tablet.lua
-- Controle do tablet (versão simplificada)

local QBCore = exports['qb-core']:GetCoreObject()

-- Função para abrir tablet (comando básico)
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
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'showTablet',
        test = true,
        playerGrade = Player.job.grade.level
    })
    
    print('[GOV-TABLET] Tablet aberto para grade: ' .. Player.job.grade.level)
end, false)

-- Fechar tablet
RegisterNUICallback('closeTablet', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

-- Receber dados do servidor
RegisterNUICallback('requestData', function(data, cb)
    if data.type == 'test' then
        cb({ success = true, message = 'Sistema funcionando!' })
    else
        cb({})
    end
end)