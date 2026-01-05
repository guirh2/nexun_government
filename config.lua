Config = {}

-- [[ 1. GESTÃO GOVERNAMENTAL E HIERARQUIA ]] --
-- Define quem pode ver o quê no tablet baseado na grade do cargo
Config.GovManagement = {
    JobName = "government", -- Nome do Job no seu database/shared
    
    Grades = {
        [0] = { 
            cargo = "Estagiário", 
            access = {"logs"}, 
            dept = "geral" 
        },
        [1] = { 
            cargo = "Assessor de Imprensa", 
            access = {"logs"}, 
            dept = "comunicacao" 
        },
        [2] = { 
            cargo = "Secretário de Saúde", 
            access = {"saude", "logs"}, 
            dept = "saude",
            canTransfer = true -- Envia verba para Hospitais
        },
        [3] = { 
            cargo = "Secretário de Segurança", 
            access = {"seguranca", "logs"}, 
            dept = "seguranca",
            canTransfer = true -- Envia verba para Batalhões
        },
        [4] = { 
            cargo = "Secretário da Fazenda", 
            access = {"fazenda", "logs"}, 
            dept = "fazenda",
            canTax = true -- Altera impostos
        },
        [5] = { 
            cargo = "Vice-Governador", 
            access = {"governo", "fazenda", "seguranca", "saude", "logs"}, 
            dept = "estado",
            canTax = true,
            canTransfer = true,
            isMaster = true -- Acesso total ao sistema
        },
        [6] = { 
            cargo = "Governador", 
            access = {"governo", "fazenda", "seguranca", "saude", "logs"}, 
            dept = "estado",
            canTax = true,
            canTransfer = true,
            isMaster = true 
        }
    }
}

-- [[ 2. ECONOMIA, TAXAS E IMPOSTOS ]] --
Config.Finance = {
    TaxInterval = 60, -- Ciclo de cobrança em minutos
    
    -- Configurações de Arrecadação
    Taxes = {
        ['inss'] = { label = "INSS (Renda sobre Banco)", default = 8, min = 0, max = 15 },
        ['ipva'] = { label = "IPVA (Por Veículo)", default = 5, min = 0, max = 20 },
        ['empresas'] = { label = "Alvará de Funcionamento", default = 500, type = "fixed" },
        ['porte_arma'] = { label = "Manutenção de Porte de Arma", default = 1000, type = "fixed" },
        ['licenca_motorista'] = { label = "Taxa de Licença de Condução", default = 150, type = "fixed" }
    }
}

-- [[ 3. DEPARTAMENTO DE SEGURANÇA (POLÍCIAS) ]] --
Config.SecurityDept = {
    -- Unidades que gerem verba própria (Manutenção e Pequenos Reparos)
    Units = {
        ['pm_19bpm'] = { label = "19º Batalhão (PM)", job = "police", grade_gestor = 4 },
        ['pc_deic'] = { label = "DEIC (Civil)", job = "police", grade_gestor = 4 },
        ['prf_base'] = { label = "Base PRF", job = "police", grade_gestor = 3 }
    },

    -- Catálogo da Secretaria (Compras em Lote)
    Catalog = {
        { model = "police", label = "Viatura Patrulha", price = 55000, type = "vehicle" },
        { model = "police2", label = "Viatura Tática", price = 85000, type = "vehicle" },
        { model = "weapon_carbine_rifle", label = "Lote Fuzis (x5)", price = 30000, type = "weapon" },
        { model = "weapon_smg", label = "Lote SMG (x10)", price = 25000, type = "weapon" }
    },

    -- Conforme requisitado: Manutenção de viaturas deve ser requisitada pelo batalhão
    RepairCostMultiplier = 1.5, 
}

-- [[ 4. DEPARTAMENTO DE SAÚDE (HOSPITAIS) ]] --
Config.HealthDept = {
    Units = {
        ['pillbox'] = { label = "Hospital Central Pillbox", job = "ambulance", grade_gestor = 3 },
        ['viceroy'] = { label = "Hospital Viceroy", job = "ambulance", grade_gestor = 3 }
    },

    Catalog = {
        { model = "ambulance", label = "Ambulância UTI", price = 45000, type = "vehicle" },
        { model = "medkit", label = "Insumos Médicos (x50)", price = 8000, type = "item" }
    }
}

-- [[ 5. LOGÍSTICA E HUBS ]] --
-- Locais onde os Secretários retiram as compras feitas pelo tablet
Config.LogisticsHubs = {
    [1] = { label = "Porto de Los Santos", coords = vector3(827.81, -2994.49, 5.9), type = "maritime" },
    [2] = { label = "Aeroporto Internacional", coords = vector3(-1042.84, -2745.71, 13.9), type = "air" },
    [3] = { label = "Depósito Ferroviário", coords = vector3(467.53, -1894.21, 26.0), type = "land" },
    [4] = { label = "Base Militar Zancudo", coords = vector3(-2343.83, 3266.08, 32.8), type = "military" }
}

-- [[ 6. WEBHOOKS DE AUDITORIA ]] --
Config.Webhooks = {
    ['fazenda'] = "https://discord.com/api/webhooks/1456705807398731848/y0HCiVpYlV5Nt-UWv9a3X4OTHV4XGXLT70bY4yRanKf8CzuZ9288l3BnfX4F7eqAXc9L",
    ['seguranca'] = "https://discord.com/api/webhooks/1456705807398731848/y0HCiVpYlV5Nt-UWv9a3X4OTHV4XGXLT70bY4yRanKf8CzuZ9288l3BnfX4F7eqAXc9L",
    ['saude'] = "https://discord.com/api/webhooks/1456705807398731848/y0HCiVpYlV5Nt-UWv9a3X4OTHV4XGXLT70bY4yRanKf8CzuZ9288l3BnfX4F7eqAXc9L",
    ['auditoria'] = "https://discord.com/api/webhooks/1456705807398731848/y0HCiVpYlV5Nt-UWv9a3X4OTHV4XGXLT70bY4yRanKf8CzuZ9288l3BnfX4F7eqAXc9L" 
}

-- [[ 7. TRADUÇÕES E MENSAGENS ]] --
Config.Locales = {
    ['no_access'] = "Acesso negado: Este dispositivo é criptografado para a alta cúpula do governo.",
    ['repair_requested'] = "Manutenção efetuada! O batalhão utilizou verba própria para o reparo.",
    ['transfer_received'] = "Verba Estadual recebida: R$ %s foram adicionados ao cofre da unidade.",
    ['tax_changed'] = "A alíquota de %s foi reajustada para %s%%.",
}