local QBCore = exports['qb-core']:GetCoreObject()
Utils = {}

-- Notificações customizadas estilo iOS
Utils.Notify = function(text, type)
    QBCore.Functions.Notify(text, type)
end

-- Efeitos sonoros de interface iOS
Utils.PlaySound = function(soundType)
    if soundType == "click" then
        PlaySoundFrontend(-1, "TAP", "DLC_HEIST_BIOLAB_PREP_TRACKING_SOUNDS", 1)
    elseif soundType == "open" then
        PlaySoundFrontend(-1, "Menu_Accept", "Phone_SoundSet_Default", 1)
    elseif soundType == "close" then
        PlaySoundFrontend(-1, "Menu_Back", "Phone_SoundSet_Default", 1)
    end
end

-- Helper para carregar modelos/animações
Utils.LoadAnimDict = function(dict)
    while (not HasAnimDictLoaded(dict)) do
        RequestAnimDict(dict)
        Wait(5)
    end
end