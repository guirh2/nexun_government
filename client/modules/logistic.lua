-- Função para abrir a visualização do Manifesto (Chamada pelo Item)
RegisterNetEvent('nexun_government:client:viewManifesto', function(metadata)
    if not metadata then return end

    -- Envia os dados para uma tela especial no Tablet
    SendNUIMessage({
        action = "openManifestoView",
        data = {
            id = metadata.purchaseId,
            buyer = metadata.buyerName,
            dept = metadata.department,
            content = metadata.itemLabel,
            hub = metadata.hubName,
            date = metadata.date
        }
    })
    
    -- Abre o tablet apenas na visualização do documento
    SetNuiFocus(true, true)
    OpenTabletAnimation() -- Aquela animação de segurar o tablet
end)

-- Export para o ox_inventory / qb-inventory
exports('openManifesto', function(data)
    -- O 'data' contém os metadados do item no inventário
    TriggerEvent('nexun_government:client:viewManifesto', data.metadata)
end)