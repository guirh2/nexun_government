-- config.lua - Governo do Estado de São Paulo
Config = {}

-- ====================
-- CONFIGURAÇÃO PRINCIPAL
-- ====================

Config.Framework = "qb-core"
Config.UseDiscordWebhook = true
Config.ModoTeste = false

-- ====================
-- GOVERNO DO ESTADO DE SÃO PAULO
-- ====================

Config.Estado = {
    nome = "Estado de São Paulo",
    sigla = "SP",
    capital = "São Paulo",
    moeda = "R$"
}

-- EMPREGO GOVERNO (NOME CORRETO: "governo")
Config.JobName = "governo"
Config.JobLabel = "Governo do Estado de SP"

-- ====================
-- GRADES DO GOVERNO
-- ====================

Config.Grades = {
    ['0'] = { name = 'Estagiário', payment = 1500, isboss = false },
    ['1'] = { name = 'Assessor', payment = 3500, isboss = false },
    ['2'] = { name = 'Sec. Saúde', payment = 15000, isboss = true },
    ['3'] = { name = 'Sec. Segurança', payment = 15000, isboss = true },
    ['4'] = { name = 'Sec. Fazenda', payment = 18000, isboss = true },
    ['5'] = { name = 'Vice-Governador', payment = 25000, isboss = true },
    ['6'] = { name = 'Governador', payment = 35000, isboss = true }
}

-- ====================
-- SISTEMA DE IMPOSTOS
-- ====================

-- 1. IPTU - Imposto sobre Propriedade
Config.IPTU = {
    taxaPadrao = 1.0, -- 1% ao ano
    min = 0.1,
    max = 3.0,
    isencaoPrimeiraCasa = true,
    valorIsencao = 100000
}

-- 2. IPVA - Imposto sobre Veículos
Config.IPVA = {
    taxaPadrao = 4.0, -- 4% ao ano
    min = 1.0,
    max = 8.0,
    
    categorias = {
        motos = 2.0,
        carros_populares = 3.0,
        suv_caminhonetes = 4.0,
        carros_luxo = 6.0,
        caminhoes = 3.5,
        onibus = 2.5
    },
    
    veiculosIsentos = {
        -- Veículos de trabalho
        "burrito", "burrito2", "burrito3", "burrito4",
        "boxville", "boxville2", "boxville3", "boxville4",
        "mule", "mule2", "mule3", "mule4", "mule5",
        "pounder", "pounder2",
        "flatbed", "hauler", "phantom", "phantom3",
        "tiptruck", "tiptruck2",
        "trash", "trash2",
        "utillitruck", "utillitruck2", "utillitruck3",
        
        -- Veículos agrícolas/construção
        "tractor", "tractor2", "tractor3",
        "bulldozer", "cutter", "dump", "mixer", "mixer2",
        
        -- Veículos de serviço público
        "bus", "airbus", "coach",
        "taxi",
        "tourbus",
        
        -- Veículos oficiais
        "ambulance",
        "firetruk",
        "police", "police2", "police3", "police4",
        "policet", "policeb",
        "pranger", "riot", "riot2",
        "sheriff", "sheriff2",
        
        -- Veículos governamentais
        "fbi", "fbi2",
        "polmav",
        "barracks", "barracks2", "barracks3"
    }
}

-- 3. INSS - Previdência Social (APENAS EMPREGADO)
Config.INSS = {
    taxaEmpregado = 8.0, -- 8% do salário do empregado
    min = 5.0,
    max = 12.0,
    empregadorTaxa = 0.0 -- SEM TAXA PARA EMPREGADOR
}

-- 4. IMPOSTO SOBRE COMBUSTÍVEL
Config.Combustivel = {
    taxaPadrao = 25.0, -- 25%
    min = 15.0,
    max = 35.0,
    
    tipos = {
        gasolina = 25.0,
        etanol = 20.0,
        diesel = 18.0,
        gnv = 15.0
    }
}

-- 5. IMPOSTO SOBRE EMPRESAS (SIMPLIFICADO)
Config.Empresas = {
    taxaPadrao = 15.0, -- 15% sobre o lucro
    min = 5.0,
    max = 25.0,
    
    setores = {
        comercio = 10.0,
        industria = 12.0,
        servicos = 15.0,
        agropecuaria = 8.0,
        tecnologia = 7.0,
        construcao = 18.0,
        transporte = 13.0,
        alimentacao = 11.0
    },
    
    isencaoMicroempresa = true,
    limiteMicroempresa = 81000
}

-- 6. LICENÇAS (Taxas Fixas)
Config.Licencas = {
    taxas = {
        porte_arma = 5000,
        alvara_funcionamento = 10000,
        habilitacao_profissional = 2000,
        licenca_ambiental = 15000,
        habite_se = 5000,
        venda_alcool = 8000,
        taxi_uber = 3000,
        pesca = 500,
        cacador = 1200
    }
}

-- 7. ISS - Imposto sobre Serviços
Config.ISS = {
    taxaPadrao = 5.0, -- 5%
    min = 2.0,
    max = 10.0,
    
    servicos = {
        mecanica = 4.0,
        advogado = 6.0,
        medico = 2.5,
        engenheiro = 5.0,
        taxi = 3.0,
        entregador = 3.5,
        programador = 3.0,
        professor = 2.0
    }
}

-- 8. IOF - Imposto sobre Operações Financeiras
Config.IOF = {
    taxaPadrao = 0.38, -- 0,38%
    min = 0.1,
    max = 1.5,
    valorMinimo = 10000, -- R$ 10.000
    isentoGoverno = true
}

-- 9. ICMS - Imposto sobre Mercadorias
Config.ICMS = {
    taxaPadrao = 18.0, -- 18%
    min = 7.0,
    max = 35.0,
    
    produtos = {
        alimentos_basicos = 0.0,
        medicamentos = 12.0,
        livros = 0.0,
        gasolina = 25.0,
        eletronicos = 18.0,
        veiculos = 18.0,
        bebidas = 25.0,
        luxo = 35.0
    }
}

-- ====================
-- POLÍCIAS BRASILEIRAS
-- ====================

Config.Policias = {
    PM = {
        nome = "Polícia Militar",
        sigla = "PM",
        cor = "#1E3A8A"
    },
    
    PC = {
        nome = "Polícia Civil",
        sigla = "PC", 
        cor = "#DC2626"
    },
    
    PF = {
        nome = "Polícia Federal",
        sigla = "PF",
        cor = "#1E3A8A"
    },
    
    PRF = {
        nome = "Polícia Rodoviária Federal",
        sigla = "PRF",
        cor = "#FFD700"
    },
    
    GM = {
        nome = "Guarda Municipal",
        sigla = "GM",
        cor = "#059669"
    }
}

-- ====================
-- INTEGRAÇÃO COM SCRIPTS
-- ====================

Config.Integrations = {
    qb_houses = true,      -- Para IPTU
    qb_vehicleshop = true, -- Para IPVA
    qb_fuel = true,        -- Para imposto combustível
    qb_phone = true,       -- Para notificações
    qb_banking = true,     -- Para IOF
    qb_shops = true,       -- Para ICMS
    qb_ambulancejob = true,-- Para sistema saúde
    qb_policejob = true    -- Para sistema segurança
}

-- ====================
-- WEBHOOK DISCORD
-- ====================

Config.Webhooks = {
    -- ATIVAR/DESATIVAR WEBHOOKS
    enabled = true,
    
    -- LOGS DE IMPOSTOS
    impostos = {
        url = "https://discord.com/api/webhooks/1456705807398731848/y0HCiVpYlV5Nt-UWv9a3X4OTHV4XGXLT70bY4yRanKf8CzuZ9288l3BnfX4F7eqAXc9L",
        enabled = true,
        events = {
            alteracao_taxa = true,     -- Quando Secretário altera taxa
            cobranca_realizada = true, -- Quando imposto é cobrado
            divida_registrada = true,  -- Quando jogador fica devendo
            pagamento_divida = true,   -- Quando dívida é paga
            isencao_concedida = true   -- Quando isenção é dada
        },
        color = 0xFF5733, -- Cor laranja
        emoji = "💰"
    },
    
    -- LOGS FINANCEIROS
    financeiro = {
        url = "https://discord.com/api/webhooks/1456705807398731848/y0HCiVpYlV5Nt-UWv9a3X4OTHV4XGXLT70bY4yRanKf8CzuZ9288l3BnfX4F7eqAXc9L",
        enabled = true,
        events = {
            salario_pago = true,        -- Pagamento de salários
            transferencia = true,       -- Transferência entre contas
            compra_governo = true,      -- Compra de itens/veículos
            orcamento_ajustado = true,  -- Ajuste de orçamento
            tesouro_atualizado = true   -- Mudança no tesouro
        },
        color = 0x2ECC71, -- Cor verde
        emoji = "💳"
    },
    
    -- LOGS DE OPERAÇÕES
    operacoes = {
        url = "https://discord.com/api/webhooks/1456705807398731848/y0HCiVpYlV5Nt-UWv9a3X4OTHV4XGXLT70bY4yRanKf8CzuZ9288l3BnfX4F7eqAXc9L",
        enabled = true,
        events = {
            manifesto_gerado = true,    -- Novo manifesto de carga
            entrega_iniciada = true,    -- Entrega começou
            entrega_concluida = true,   -- Entrega finalizada
            entrega_falhou = true,      -- Entrega falhou/roubada
            solicitacao_feita = true    -- Solicitação de insumos
        },
        color = 0x3498DB, -- Cor azul
        emoji = "🚚"
    },
    
    -- LOGS DE SAÚDE
    saude = {
        url = "https://discord.com/api/webhooks/1456705807398731848/y0HCiVpYlV5Nt-UWv9a3X4OTHV4XGXLT70bY4yRanKf8CzuZ9288l3BnfX4F7eqAXc9L",
        enabled = true,
        events = {
            compra_medicamentos = true, -- Compra de insumos
            ambulancia_comprada = true, -- Nova ambulância
            estoque_baixo = true,       -- Alerta estoque baixo
            hospital_atendimento = true, -- Relatório hospital
            orcamento_solicitado = true -- Solicitação de verba
        },
        color = 0xE91E63, -- Cor rosa
        emoji = "🏥"
    },
    
    -- LOGS DE SEGURANÇA
    seguranca = {
        url = "https://discord.com/api/webhooks/1456705807398731848/y0HCiVpYlV5Nt-UWv9a3X4OTHV4XGXLT70bY4yRanKf8CzuZ9288l3BnfX4F7eqAXc9L",
        enabled = true,
        events = {
            compra_armas = true,        -- Compra de armamento
            viatura_comprada = true,    -- Nova viatura
            reparo_aprovado = true,     -- Reparo de viatura aprovado
            efetivo_online = true,      -- Relatório de policiais online
            ocorrencia_grave = true     -- Ocorrência importante
        },
        color = 0xC0392B, -- Cor vermelho escuro
        emoji = "👮"
    },
    
    -- LOGS ADMINISTRATIVOS
    admin = {
        url = "https://discord.com/api/webhooks/1456705807398731848/y0HCiVpYlV5Nt-UWv9a3X4OTHV4XGXLT70bY4yRanKf8CzuZ9288l3BnfX4F7eqAXc9L",
        enabled = true,
        events = {
            nomeacao_cargo = true,      -- Nomeação para cargo
            demissao_cargo = true,      -- Demissão de cargo
            acesso_negado = true,       -- Tentativa de acesso negado
            comando_admin = true,       -- Comando admin executado
            sistema_erro = true         -- Erro no sistema
        },
        color = 0x9B59B6, -- Cor roxo
        emoji = "⚙️"
    },
    
    -- LOGS DE ALERTAS/EMERGÊNCIAS
    alertas = {
        url = "https://discord.com/api/webhooks/1456705807398731848/y0HCiVpYlV5Nt-UWv9a3X4OTHV4XGXLT70bY4yRanKf8CzuZ9288l3BnfX4F7eqAXc9L",
        enabled = true,
        events = {
            emergencia_saude = true,    -- Emergência médica
            emergencia_seguranca = true,-- Emergência policial
            tesouro_baixo = true,       -- Tesouro abaixo de X%
            protesto_ruas = true,       -- Protestos na cidade
            sistema_critico = true      -- Sistema em estado crítico
        },
        color = 0xF1C40F, -- Cor amarelo
        emoji = "🚨"
    },
    
    -- RELATÓRIOS AUTOMÁTICOS
    relatorios = {
        url = "https://discord.com/api/webhooks/1456705807398731848/y0HCiVpYlV5Nt-UWv9a3X4OTHV4XGXLT70bY4yRanKf8CzuZ9288l3BnfX4F7eqAXc9L",
        enabled = true,
        events = {
            diario = true,              -- Relatório diário 00:00
            semanal = true,             -- Relatório semanal domingo
            mensal = true,              -- Relatório mensal dia 1
            impostos_detalhado = true   -- Relatório detalhado impostos
        },
        color = 0x1ABC9C, -- Cor verde água
        emoji = "📊"
    },
    
    -- LOGS DE SISTEMA (Técnico)
    sistema = {
        url = "https://discord.com/api/webhooks/1456705807398731848/y0HCiVpYlV5Nt-UWv9a3X4OTHV4XGXLT70bY4yRanKf8CzuZ9288l3BnfX4F7eqAXc9L",
        enabled = true,
        events = {
            script_iniciado = true,     -- Script iniciado
            script_reiniciado = true,   -- Script reiniciado
            database_backup = true,     -- Backup realizado
            erro_lua = true,            -- Erro Lua detectado
            performance = true          -- Log de performance
        },
        color = 0x95A5A6, -- Cor cinza
        emoji = "🖥️"
    }
}

-- ====================
-- CONFIGURAÇÃO DOS WEBHOOKS
-- ====================

Config.WebhookSettings = {
    -- FORMATO DAS MENSAGENS
    format = {
        useEmbeds = true,               -- Usar embed do Discord
        includeTimestamp = true,        -- Incluir timestamp
        includeServerName = true,       -- Incluir nome do servidor
        includePlayerInfo = true,       -- Incluir info do jogador
        truncateLongMessages = true,    -- Cortar mensagens longas
        maxLength = 2000                -- Tamanho máximo mensagem
    },
    
    -- FILTROS
    filters = {
        minGradeForLog = 2,             -- Grade mínima para aparecer no log
        logAllAdmins = true,            -- Logar todas ações de admin
        ignoreTestPlayers = true,       -- Ignorar jogadores em modo teste
        logOnlyOnline = true            -- Logar apenas jogadores online
    },
    
    -- TEMPO ENTRE WEBHOOKS
    cooldowns = {
        sameEvent = 5,                  -- Segundos entre mesmo evento
        samePlayer = 2,                 -- Segundos entre mesmo jogador
        global = 1                      -- Segundos entre qualquer webhook
    },
    
    -- MENSAGENS PERSONALIZADAS
    messages = {
        prefix = "[GOV-SP]",            -- Prefixo nas mensagens
        footer = "Sistema de Governo do Estado de SP",
        dateFormat = "DD/MM/YYYY HH:mm:ss",
        timezone = "America/Sao_Paulo"
    }
}

-- ====================
-- EVENTOS ESPECÍFICOS PARA CADA IMPOSTO
-- ====================

Config.ImpostoWebhooks = {
    IPTU = {
        webhook = "impostos",
        events = {
            calculado = true,
            cobrado = true,
            isento = true,
            divida = true
        }
    },
    
    IPVA = {
        webhook = "impostos",
        events = {
            calculado = true,
            cobrado = true,
            isento_veiculo_trabalho = true,
            divida = true
        }
    },
    
    INSS = {
        webhook = "financeiro",
        events = {
            desconto_salario = true,
            contribuicao_mensal = true
        }
    },
    
    Combustivel = {
        webhook = "impostos",
        events = {
            taxa_aplicada = true,
            abastecimento_taxado = true
        }
    },
    
    Empresas = {
        webhook = "financeiro",
        events = {
            lucro_calculado = true,
            imposto_pago = true,
            microempresa_isenta = true
        }
    },
    
    Licencas = {
        webhook = "financeiro",
        events = {
            taxa_paga = true,
            licenca_emitida = true,
            renovacao = true
        }
    },
    
    ISS = {
        webhook = "impostos",
        events = {
            servico_taxado = true,
            nota_emitida = true
        }
    },
    
    IOF = {
        webhook = "financeiro",
        events = {
            transacao_taxada = true,
            transferencia_taxada = true
        }
    },
    
    ICMS = {
        webhook = "impostos",
        events = {
            compra_taxada = true,
            nota_fiscal = true,
            produto_isento = true
        }
    }
}

return Config