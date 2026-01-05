local scriptName = GetCurrentResourceName()
local expectedName = "nexun_government"
local expectedAuthor = "Nexun Dev"
local author = GetResourceMetadata(scriptName, 'author', 0)

CreateThread(function()
    local authenticated = true

    -- Validação do Nome da Pasta
    if scriptName ~= expectedName then
        print("^1[ERRO DE AUTENTICAÇÃO] O nome da pasta foi alterado para: " .. scriptName .. "^7")
        authenticated = false
    end

    -- Validação do Autor
    if author ~= expectedAuthor then
        print("^1[ERRO DE INTEGRIDADE] O autor no fxmanifest.lua foi alterado!^7")
        authenticated = false
    end

    if not authenticated then
        print("^1O script " .. expectedName .. " será desativado por segurança. Entre em contato com Nexun Dev.^7")
        StopResource(scriptName)
        return
    end

    print("^2[NEXUN DEV] Sistema de Governo v2.0.0 autenticado com sucesso.^7")
end)