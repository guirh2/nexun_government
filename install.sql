-- ============================================
-- INSTALL.SQL - SISTEMA DE GOVERNO DO ESTADO DE SP
-- Versão: 2.0.0 (QB-Core)
-- Data: $(current_date)
-- ============================================

-- --------------------------------------------------------
-- REMOVER TABELAS ANTIGAS DE GOVERNO (SE EXISTIREM)
-- --------------------------------------------------------

DROP TABLE IF EXISTS `government_treasury`;
DROP TABLE IF EXISTS `government_taxes`;
DROP TABLE IF EXISTS `government_logs`;
DROP TABLE IF EXISTS `government_units`;
DROP TABLE IF EXISTS `government_deliveries`;
DROP TABLE IF EXISTS `government_armory`;

-- --------------------------------------------------------
-- TABELA PRINCIPAL DO ESTADO (TESOURO)
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS `government_state` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `account_balance` DECIMAL(15,2) NOT NULL DEFAULT 0.00 COMMENT 'Saldo total do Tesouro',
    `total_collected` DECIMAL(15,2) NOT NULL DEFAULT 0.00 COMMENT 'Total histórico arrecadado',
    
    -- IMPOSTOS PRINCIPAIS
    `tax_iptu` FLOAT NOT NULL DEFAULT 1.0 COMMENT 'IPTU (%) - Config.IPTU.taxaPadrao',
    `tax_ipva` FLOAT NOT NULL DEFAULT 4.0 COMMENT 'IPVA (%) - Config.IPVA.taxaPadrao',
    `tax_inss` FLOAT NOT NULL DEFAULT 8.0 COMMENT 'INSS (%) - Config.INSS.taxaEmpregado',
    `tax_fuel` FLOAT NOT NULL DEFAULT 25.0 COMMENT 'Combustível (%) - Config.Combustivel.taxaPadrao',
    `tax_business` FLOAT NOT NULL DEFAULT 15.0 COMMENT 'Empresas (%) - Config.Empresas.taxaPadrao',
    `tax_iss` FLOAT NOT NULL DEFAULT 5.0 COMMENT 'ISS (%) - Config.ISS.taxaPadrao',
    `tax_iof` FLOAT NOT NULL DEFAULT 0.38 COMMENT 'IOF (%) - Config.IOF.taxaPadrao',
    `tax_icms` FLOAT NOT NULL DEFAULT 18.0 COMMENT 'ICMS (%) - Config.ICMS.taxaPadrao',
    
    -- ORÇAMENTOS POR SECRETARIA (%)
    `budget_health_perc` INT(3) NOT NULL DEFAULT 20 COMMENT '% para Saúde',
    `budget_security_perc` INT(3) NOT NULL DEFAULT 20 COMMENT '% para Segurança',
    `budget_finance_perc` INT(3) NOT NULL DEFAULT 60 COMMENT '% para Fazenda',
    
    -- SALDOS DAS SECRETARIAS
    `health_balance` DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    `security_balance` DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    `finance_balance` DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    
    -- CONTROLE
    `last_tax_collection` DATE DEFAULT NULL COMMENT 'Última coleta de impostos',
    `next_tax_collection` DATE DEFAULT NULL COMMENT 'Próxima coleta',
    `last_salary_payment` DATE DEFAULT NULL COMMENT 'Último pagamento de salários',
    
    -- METADADOS
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------
-- TABELA DE SECRETARIAS E SECRETÁRIOS
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS `government_secretaries` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `department` ENUM('health', 'security', 'finance') NOT NULL,
    `department_label` VARCHAR(50) NOT NULL,
    `secretary_citizenid` VARCHAR(11) DEFAULT NULL,
    `secretary_name` VARCHAR(100) DEFAULT NULL,
    `secretary_grade` INT(2) DEFAULT NULL COMMENT 'Grade do cargo (2,3,4)',
    `appointed_by` VARCHAR(100) DEFAULT NULL COMMENT 'Quem nomeou',
    `appointed_at` TIMESTAMP NULL DEFAULT NULL,
    `removed_at` TIMESTAMP NULL DEFAULT NULL,
    `removed_by` VARCHAR(100) DEFAULT NULL,
    `removal_reason` TEXT DEFAULT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `metadata` JSON DEFAULT NULL,
    
    PRIMARY KEY (`id`),
    UNIQUE KEY `department_active` (`department`, `is_active`),
    KEY `secretary_citizenid` (`secretary_citizenid`),
    KEY `department` (`department`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------
-- TABELA DE IMPOSTOS POR JOGADOR (DÍVIDAS)
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS `government_player_taxes` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(11) NOT NULL,
    `player_name` VARCHAR(100) NOT NULL,
    
    -- TIPO DE IMPOSTO
    `tax_type` ENUM('IPTU', 'IPVA', 'INSS', 'ISS', 'IOF', 'ICMS', 'LICENCA', 'MULTA') NOT NULL,
    `tax_subtype` VARCHAR(50) DEFAULT NULL COMMENT 'Ex: gasolina, etanol, porte_arma',
    `description` VARCHAR(255) NOT NULL,
    
    -- VALORES
    `original_amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `current_amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `amount_paid` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `tax_rate` FLOAT DEFAULT NULL COMMENT 'Taxa aplicada (%)',
    
    -- REFERÊNCIA
    `reference_id` VARCHAR(100) DEFAULT NULL COMMENT 'plate, house_name, business_id',
    `reference_data` JSON DEFAULT NULL,
    
    -- DATAS
    `issue_date` DATE NOT NULL,
    `due_date` DATE NOT NULL,
    `paid_date` DATE DEFAULT NULL,
    
    -- STATUS
    `status` ENUM('pending', 'paid', 'overdue', 'exempt', 'cancelled') NOT NULL DEFAULT 'pending',
    `payment_method` VARCHAR(50) DEFAULT NULL COMMENT 'bank, cash, transfer',
    
    -- METADADOS
    `created_by` VARCHAR(100) DEFAULT 'SISTEMA',
    `paid_to` VARCHAR(100) DEFAULT NULL COMMENT 'Quem recebeu o pagamento',
    `notes` TEXT DEFAULT NULL,
    `metadata` JSON DEFAULT NULL,
    
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (`id`),
    KEY `idx_citizenid_status` (`citizenid`, `status`),
    KEY `idx_tax_type` (`tax_type`),
    KEY `idx_due_date` (`due_date`),
    KEY `idx_status_due` (`status`, `due_date`),
    KEY `idx_reference` (`reference_id`(50))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------
-- TABELA DE TRANSAÇÕES FINANCEIRAS
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS `government_transactions` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `transaction_id` VARCHAR(50) NOT NULL COMMENT 'ID único da transação',
    
    -- TIPO
    `transaction_type` ENUM(
        'tax_payment',      -- Pagamento de imposto
        'salary_payment',   -- Pagamento de salário
        'purchase',         -- Compra de itens/veículos
        'transfer',         -- Transferência entre contas
        'deposit',          -- Depósito no tesouro
        'withdraw',         -- Saque do tesouro
        'fine',             -- Multa aplicada
        'license_fee',      -- Taxa de licença
        'maintenance',      -- Manutenção
        'other'             -- Outros
    ) NOT NULL,
    
    -- CONTAS
    `from_account` ENUM('state', 'health', 'security', 'finance', 'player', 'other') NOT NULL,
    `to_account` ENUM('state', 'health', 'security', 'finance', 'player', 'other') NOT NULL,
    
    -- VALORES
    `amount` DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    `previous_balance` DECIMAL(15,2) DEFAULT NULL,
    `new_balance` DECIMAL(15,2) DEFAULT NULL,
    
    -- ENVOLVIDOS
    `citizenid_from` VARCHAR(11) DEFAULT NULL,
    `citizenid_to` VARCHAR(11) DEFAULT NULL,
    `player_name_from` VARCHAR(100) DEFAULT NULL,
    `player_name_to` VARCHAR(100) DEFAULT NULL,
    
    -- DESCRIÇÃO
    `description` VARCHAR(255) NOT NULL,
    `details` TEXT DEFAULT NULL,
    
    -- AUTORIZAÇÃO
    `authorized_by` VARCHAR(100) DEFAULT NULL,
    `authorized_by_cid` VARCHAR(11) DEFAULT NULL,
    
    -- METADADOS
    `metadata` JSON DEFAULT NULL,
    `receipt_url` VARCHAR(500) DEFAULT NULL COMMENT 'URL do comprovante',
    
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (`id`),
    UNIQUE KEY `transaction_id` (`transaction_id`),
    KEY `idx_type_date` (`transaction_type`, `created_at`),
    KEY `idx_accounts` (`from_account`, `to_account`),
    KEY `idx_citizenid_from` (`citizenid_from`),
    KEY `idx_citizenid_to` (`citizenid_to`),
    KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------
-- TABELA DE MANIFESTOS DE CARGA
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS `government_manifests` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `manifest_number` VARCHAR(20) NOT NULL COMMENT 'MF-2024-001',
    
    -- TIPO
    `manifest_type` ENUM('health', 'security') NOT NULL,
    `department` ENUM('health', 'security') NOT NULL,
    
    -- ORIGEM E DESTINO
    `origin` VARCHAR(100) NOT NULL COMMENT 'Porto, Aeroporto, Depósito',
    `destination` VARCHAR(100) NOT NULL COMMENT 'Hospital, Delegacia, Base',
    `destination_unit` VARCHAR(50) DEFAULT NULL COMMENT 'Código da unidade',
    
    -- CONTEÚDO
    `items_data` JSON NOT NULL COMMENT '[{"item": "medkit", "quantity": 50, "unit_price": 100}]',
    `total_items` INT(11) NOT NULL DEFAULT 0,
    `total_value` DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    
    -- RESPONSÁVEIS
    `created_by` VARCHAR(100) NOT NULL,
    `created_by_cid` VARCHAR(11) NOT NULL,
    `assigned_to` VARCHAR(11) DEFAULT NULL COMMENT 'CID do entregador',
    `assigned_name` VARCHAR(100) DEFAULT NULL,
    
    -- STATUS
    `status` ENUM(
        'pending',      -- Aguardando aprovação
        'approved',     -- Aprovado
        'preparing',    -- Em preparação
        'ready',        -- Pronto para retirada
        'in_transit',   -- Em transporte
        'delivered',    -- Entregue
        'cancelled',    -- Cancelado
        'stolen',       -- Roubado
        'lost'          -- Perdido
    ) NOT NULL DEFAULT 'pending',
    
    -- DATAS
    `approved_at` TIMESTAMP NULL DEFAULT NULL,
    `approved_by` VARCHAR(100) DEFAULT NULL,
    `dispatched_at` TIMESTAMP NULL DEFAULT NULL,
    `delivered_at` TIMESTAMP NULL DEFAULT NULL,
    `delivered_by` VARCHAR(100) DEFAULT NULL,
    
    -- TRANSPORTE
    `vehicle_plate` VARCHAR(10) DEFAULT NULL,
    `driver_name` VARCHAR(100) DEFAULT NULL,
    `route_details` TEXT DEFAULT NULL,
    
    -- METADADOS
    `notes` TEXT DEFAULT NULL,
    `signature_data` JSON DEFAULT NULL COMMENT 'Assinaturas digitais',
    `metadata` JSON DEFAULT NULL,
    
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (`id`),
    UNIQUE KEY `manifest_number` (`manifest_number`),
    KEY `idx_type_status` (`manifest_type`, `status`),
    KEY `idx_created_by` (`created_by_cid`),
    KEY `idx_assigned_to` (`assigned_to`),
    KEY `idx_dates` (`created_at`, `dispatched_at`, `delivered_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------
-- TABELA DE FROTA GOVERNAMENTAL
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS `government_vehicles` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `vehicle_plate` VARCHAR(10) NOT NULL,
    
    -- INFORMAÇÕES DO VEÍCULO
    `vehicle_model` VARCHAR(50) NOT NULL,
    `vehicle_label` VARCHAR(100) NOT NULL,
    `vehicle_class` ENUM('car', 'motorcycle', 'truck', 'helicopter', 'boat', 'other') NOT NULL DEFAULT 'car',
    
    -- ALOCAÇÃO
    `department` ENUM('health', 'security', 'finance', 'governor') NOT NULL,
    `unit_assigned` VARCHAR(100) DEFAULT NULL COMMENT 'Hospital Central, 1º DP, etc',
    `unit_code` VARCHAR(50) DEFAULT NULL,
    
    -- STATUS
    `status` ENUM(
        'active',       -- Em uso
        'available',    -- Disponível
        'maintenance',  -- Em manutenção
        'damaged',      -- Danificado
        'destroyed',    -- Destruído
        'stolen',       -- Roubado
        'decommissioned'-- Baixado
    ) NOT NULL DEFAULT 'available',
    
    -- CONDIÇÃO
    `fuel_level` INT(3) DEFAULT 100,
    `engine_health` INT(3) DEFAULT 100,
    `body_health` INT(3) DEFAULT 100,
    `mileage` INT(11) DEFAULT 0 COMMENT 'Quilometragem',
    
    -- MANUTENÇÃO
    `last_maintenance` DATE DEFAULT NULL,
    `next_maintenance` DATE DEFAULT NULL,
    `maintenance_history` JSON DEFAULT NULL,
    
    -- COMPRA
    `purchase_date` DATE NOT NULL,
    `purchase_price` DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    `supplier` VARCHAR(100) DEFAULT NULL,
    `invoice_number` VARCHAR(50) DEFAULT NULL,
    
    -- USUÁRIO ATUAL
    `current_driver` VARCHAR(11) DEFAULT NULL,
    `current_driver_name` VARCHAR(100) DEFAULT NULL,
    `checked_out_at` TIMESTAMP NULL DEFAULT NULL,
    
    -- METADADOS
    `notes` TEXT DEFAULT NULL,
    `metadata` JSON DEFAULT NULL,
    
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (`id`),
    UNIQUE KEY `vehicle_plate` (`vehicle_plate`),
    KEY `idx_department_status` (`department`, `status`),
    KEY `idx_unit_assigned` (`unit_assigned`),
    KEY `idx_current_driver` (`current_driver`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------
-- TABELA DE SOLICITAÇÕES DE MANUTENÇÃO
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS `government_maintenance` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `request_number` VARCHAR(20) NOT NULL COMMENT 'MT-2024-001',
    
    -- VEÍCULO
    `vehicle_plate` VARCHAR(10) NOT NULL,
    `vehicle_model` VARCHAR(50) NOT NULL,
    
    -- SOLICITANTE
    `requested_by` VARCHAR(100) NOT NULL,
    `requested_by_cid` VARCHAR(11) NOT NULL,
    `unit_origin` VARCHAR(100) NOT NULL,
    
    -- PROBLEMA
    `issue_type` ENUM(
        'engine', 'transmission', 'brakes', 'electrical',
        'bodywork', 'tires', 'suspension', 'other'
    ) NOT NULL DEFAULT 'other',
    
    `issue_description` TEXT NOT NULL,
    `damage_level` ENUM('low', 'medium', 'high', 'total') NOT NULL DEFAULT 'medium',
    
    -- ORÇAMENTO
    `estimated_cost` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `approved_cost` DECIMAL(10,2) DEFAULT NULL,
    `final_cost` DECIMAL(10,2) DEFAULT NULL,
    
    -- APROVAÇÃO
    `status` ENUM('pending', 'approved', 'rejected', 'in_progress', 'completed') NOT NULL DEFAULT 'pending',
    
    `approved_by` VARCHAR(100) DEFAULT NULL,
    `approved_by_cid` VARCHAR(11) DEFAULT NULL,
    `approved_at` TIMESTAMP NULL DEFAULT NULL,
    
    -- EXECUÇÃO
    `mechanic_assigned` VARCHAR(100) DEFAULT NULL,
    `started_at` TIMESTAMP NULL DEFAULT NULL,
    `completed_at` TIMESTAMP NULL DEFAULT NULL,
    `completion_notes` TEXT DEFAULT NULL,
    
    -- METADADOS
    `photos` JSON DEFAULT NULL COMMENT 'Fotos do problema',
    `notes` TEXT DEFAULT NULL,
    
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (`id`),
    UNIQUE KEY `request_number` (`request_number`),
    KEY `idx_vehicle_plate` (`vehicle_plate`),
    KEY `idx_status` (`status`),
    KEY `idx_requested_by` (`requested_by_cid`),
    KEY `idx_approved_by` (`approved_by_cid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------
-- TABELA DE ESTOQUES (SAÚDE E SEGURANÇA)
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS `government_stocks` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    
    -- LOCALIZAÇÃO
    `department` ENUM('health', 'security') NOT NULL,
    `unit_name` VARCHAR(100) NOT NULL COMMENT 'Hospital Central, 1º DP',
    `unit_code` VARCHAR(50) NOT NULL,
    `location` VARCHAR(100) DEFAULT NULL COMMENT 'Almoxarifado, Arsenal, Farmácia',
    
    -- ITEM
    `item_name` VARCHAR(100) NOT NULL,
    `item_label` VARCHAR(100) NOT NULL,
    `item_category` VARCHAR(50) DEFAULT NULL,
    `unit_type` VARCHAR(20) DEFAULT 'unit' COMMENT 'unit, box, pack, etc',
    
    -- ESTOQUE
    `current_quantity` INT(11) NOT NULL DEFAULT 0,
    `minimum_quantity` INT(11) NOT NULL DEFAULT 10,
    `maximum_quantity` INT(11) NOT NULL DEFAULT 100,
    `reorder_point` INT(11) NOT NULL DEFAULT 20,
    
    -- VALORES
    `unit_cost` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `total_value` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    
    -- CONTROLE
    `last_received` DATE DEFAULT NULL,
    `last_used` DATE DEFAULT NULL,
    `last_audit` DATE DEFAULT NULL,
    
    -- METADADOS
    `supplier` VARCHAR(100) DEFAULT NULL,
    `notes` TEXT DEFAULT NULL,
    
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_stock` (`department`, `unit_code`, `item_name`),
    KEY `idx_department_unit` (`department`, `unit_code`),
    KEY `idx_item_category` (`item_category`),
    KEY `idx_low_stock` (`current_quantity`, `minimum_quantity`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------
-- TABELA DE LICENÇAS E PERMISSÕES
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS `government_licenses` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `license_number` VARCHAR(50) NOT NULL,
    
    -- TIPO
    `license_type` ENUM(
        'porte_arma',
        'alvara_funcionamento', 
        'habilitacao_profissional',
        'licenca_ambiental',
        'habite_se',
        'venda_alcool',
        'taxi_uber',
        'pesca',
        'cacador'
    ) NOT NULL,
    
    -- DETENTOR
    `citizenid` VARCHAR(11) NOT NULL,
    `player_name` VARCHAR(100) NOT NULL,
    `business_name` VARCHAR(100) DEFAULT NULL COMMENT 'Para alvarás',
    
    -- VALIDADE
    `issue_date` DATE NOT NULL,
    `expiry_date` DATE NOT NULL,
    `renewed_date` DATE DEFAULT NULL,
    
    -- STATUS
    `status` ENUM('active', 'expired', 'revoked', 'suspended', 'pending') NOT NULL DEFAULT 'active',
    
    -- TAXAS
    `license_fee` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `fee_paid` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `renewal_fee` DECIMAL(10,2) DEFAULT NULL,
    
    -- EMISSÃO
    `issued_by` VARCHAR(100) DEFAULT NULL,
    `issued_by_cid` VARCHAR(11) DEFAULT NULL,
    
    -- REVOGAÇÃO (se aplicável)
    `revoked_by` VARCHAR(100) DEFAULT NULL,
    `revoked_at` DATE DEFAULT NULL,
    `revoke_reason` TEXT DEFAULT NULL,
    
    -- METADADOS
    `conditions` JSON DEFAULT NULL COMMENT 'Condições especiais',
    `notes` TEXT DEFAULT NULL,
    
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (`id`),
    UNIQUE KEY `license_number` (`license_number`),
    KEY `idx_citizenid_type` (`citizenid`, `license_type`),
    KEY `idx_status_expiry` (`status`, `expiry_date`),
    KEY `idx_license_type` (`license_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------
-- TABELA DE LOGS DO SISTEMA (DISCORD + INTERNO)
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS `government_logs` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    
    -- TIPO DE LOG
    `log_type` ENUM(
        'impostos', 'financeiro', 'operacoes', 'saude', 
        'seguranca', 'admin', 'alertas', 'relatorios', 'sistema'
    ) NOT NULL,
    
    `log_category` VARCHAR(50) NOT NULL,
    `title` VARCHAR(255) NOT NULL,
    `description` TEXT NOT NULL,
    
    -- ENVOLVIDOS
    `citizenid_involved` VARCHAR(11) DEFAULT NULL,
    `player_name` VARCHAR(100) DEFAULT NULL,
    `department` VARCHAR(50) DEFAULT NULL,
    
    -- VALORES
    `amount` DECIMAL(15,2) DEFAULT NULL,
    `tax_type` VARCHAR(50) DEFAULT NULL,
    `tax_rate` FLOAT DEFAULT NULL,
    
    -- DISCORD
    `discord_webhook` VARCHAR(50) DEFAULT NULL COMMENT 'Qual webhook foi usado',
    `discord_sent` TINYINT(1) NOT NULL DEFAULT 0,
    `discord_message_id` VARCHAR(100) DEFAULT NULL,
    `discord_error` TEXT DEFAULT NULL,
    
    -- METADADOS
    `ip_address` VARCHAR(45) DEFAULT NULL,
    `user_agent` TEXT DEFAULT NULL,
    `metadata` JSON DEFAULT NULL,
    
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (`id`),
    KEY `idx_log_type` (`log_type`),
    KEY `idx_created_at` (`created_at`),
    KEY `idx_citizenid` (`citizenid_involved`),
    KEY `idx_discord_sent` (`discord_sent`),
    KEY `idx_type_date` (`log_type`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------
-- TABELA DE CONFIGURAÇÕES
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS `government_settings` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `setting_key` VARCHAR(100) NOT NULL,
    `setting_value` TEXT NOT NULL,
    `setting_type` ENUM('string', 'number', 'boolean', 'json', 'array') NOT NULL DEFAULT 'string',
    `category` VARCHAR(50) NOT NULL,
    `description` VARCHAR(255) DEFAULT NULL,
    `updated_by` VARCHAR(100) DEFAULT NULL,
    `updated_by_cid` VARCHAR(11) DEFAULT NULL,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (`id`),
    UNIQUE KEY `setting_key` (`setting_key`),
    KEY `category` (`category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ============================================
-- INSERIR DADOS INICIAIS
-- ============================================

-- Estado inicial com R$ 10 milhões
INSERT INTO `government_state` (
    `account_balance`,
    `total_collected`,
    `tax_iptu`,
    `tax_ipva`,
    `tax_inss`,
    `tax_fuel`,
    `tax_business`,
    `tax_iss`,
    `tax_iof`,
    `tax_icms`,
    `health_balance`,
    `security_balance`,
    `finance_balance`
) VALUES (
    10000000.00, -- R$ 10 milhões
    0.00,
    1.0,    -- IPTU
    4.0,    -- IPVA
    8.0,    -- INSS
    25.0,   -- Combustível
    15.0,   -- Empresas
    5.0,    -- ISS
    0.38,   -- IOF
    18.0,   -- ICMS
    2000000.00, -- Saúde: R$ 2 milhões
    2000000.00, -- Segurança: R$ 2 milhões
    6000000.00  -- Fazenda: R$ 6 milhões
);

-- Configurações padrão
INSERT INTO `government_settings` (`setting_key`, `setting_value`, `setting_type`, `category`, `description`) VALUES
('system_name', 'Sistema de Governo do Estado de SP', 'string', 'system', 'Nome do sistema'),
('system_version', '2.0.0', 'string', 'system', 'Versão do sistema'),
('currency', 'R$', 'string', 'system', 'Símbolo da moeda'),
('state_name', 'Estado de São Paulo', 'string', 'system', 'Nome do estado'),
('state_initials', 'SP', 'string', 'system', 'Sigla do estado'),
('capital', 'São Paulo', 'string', 'system', 'Capital do estado'),
('tax_collection_day', '5', 'number', 'taxes', 'Dia da coleta de impostos'),
('salary_payment_day', '25', 'number', 'economy', 'Dia do pagamento de salários'),
('enable_auto_taxes', 'true', 'boolean', 'taxes', 'Coleta automática de impostos'),
('enable_discord_logs', 'true', 'boolean', 'system', 'Ativar logs no Discord'),
('max_tax_rate', '25.0', 'number', 'taxes', 'Taxa máxima permitida'),
('min_tax_rate', '0.1', 'number', 'taxes', 'Taxa mínima permitida'),
('default_license_duration', '365', 'number', 'licenses', 'Duração padrão de licenças (dias)'),
('manifest_prefix_health', 'MF-SAUDE', 'string', 'operations', 'Prefixo manifestos saúde'),
('manifest_prefix_security', 'MF-SEG', 'string', 'operations', 'Prefixo manifestos segurança'),
('maintenance_prefix', 'MT', 'string', 'operations', 'Prefixo solicitações manutenção');

-- ============================================
-- PROCEDURES E TRIGGERS
-- ============================================

DELIMITER //

-- Atualizar saldo automático quando houver transação
CREATE TRIGGER IF NOT EXISTS update_state_balance
AFTER INSERT ON `government_transactions`
FOR EACH ROW
BEGIN
    DECLARE state_balance DECIMAL(15,2);
    
    -- Atualizar saldo do estado se a transação envolver conta 'state'
    IF NEW.to_account = 'state' THEN
        UPDATE `government_state` 
        SET `account_balance` = `account_balance` + NEW.amount,
            `updated_at` = NOW()
        WHERE `id` = 1;
    END IF;
    
    IF NEW.from_account = 'state' THEN
        UPDATE `government_state` 
        SET `account_balance` = `account_balance` - NEW.amount,
            `updated_at` = NOW()
        WHERE `id` = 1;
    END IF;
END//

-- Gerar próximo número de manifesto
CREATE FUNCTION IF NOT EXISTS generate_manifest_number(department VARCHAR(20))
RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
    DECLARE prefix VARCHAR(10);
    DECLARE year_part VARCHAR(4);
    DECLARE last_number INT;
    DECLARE new_number VARCHAR(20);
    
    SET year_part = YEAR(CURDATE());
    
    IF department = 'health' THEN
        SET prefix = 'MF-SAUDE';
    ELSE
        SET prefix = 'MF-SEG';
    END IF;
    
    -- Buscar último número
    SELECT COALESCE(MAX(CAST(SUBSTRING_INDEX(manifest_number, '-', -1) AS UNSIGNED)), 0)
    INTO last_number
    FROM `government_manifests`
    WHERE manifest_number LIKE CONCAT(prefix, '-', year_part, '-%');
    
    SET new_number = CONCAT(prefix, '-', year_part, '-', LPAD(last_number + 1, 3, '0'));
    
    RETURN new_number;
END//

DELIMITER ;

-- ============================================
-- VIEWS PARA RELATÓRIOS
-- ============================================

CREATE OR REPLACE VIEW `government_daily_report` AS
SELECT 
    DATE(t.created_at) as report_date,
    COUNT(*) as total_transactions,
    COUNT(DISTINCT t.citizenid_from) as unique_players,
    SUM(CASE WHEN t.amount > 0 AND t.to_account = 'state' THEN t.amount ELSE 0 END) as total_income,
    SUM(CASE WHEN t.amount > 0 AND t.from_account = 'state' THEN t.amount ELSE 0 END) as total_expenses,
    (SUM(CASE WHEN t.amount > 0 AND t.to_account = 'state' THEN t.amount ELSE 0 END) - 
     SUM(CASE WHEN t.amount > 0 AND t.from_account = 'state' THEN t.amount ELSE 0 END)) as net_balance
FROM `government_transactions` t
WHERE DATE(t.created_at) = CURDATE()
GROUP BY DATE(t.created_at);

CREATE OR REPLACE VIEW `government_tax_summary` AS
SELECT 
    tax_type,
    COUNT(*) as total_debts,
    SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) as pending_debts,
    SUM(CASE WHEN status = 'overdue' THEN 1 ELSE 0 END) as overdue_debts,
    SUM(CASE WHEN status = 'paid' THEN 1 ELSE 0 END) as paid_debts,
    SUM(original_amount) as total_value,
    SUM(amount_paid) as total_paid,
    AVG(tax_rate) as avg_tax_rate
FROM `government_player_taxes`
GROUP BY tax_type;

-- ============================================
-- MENSAGEM FINAL
-- ============================================
SELECT '============================================' as '';
SELECT 'SISTEMA DE GOVERNO DO ESTADO DE SP' as '';
SELECT 'INSTALAÇÃO CONCLUÍDA COM SUCESSO!' as '';
SELECT '============================================' as '';
SELECT CONCAT('Tabelas criadas: ', 
    (SELECT COUNT(*) FROM information_schema.tables 
     WHERE table_schema = DATABASE() 
     AND table_name LIKE 'government_%')) as '';
SELECT '============================================' as '';
SELECT 'TABELAS INSTALADAS:' as '';
SELECT '1. government_state' as '';
SELECT '2. government_secretaries' as '';
SELECT '3. government_player_taxes' as '';
SELECT '4. government_transactions' as '';
SELECT '5. government_manifests' as '';
SELECT '6. government_vehicles' as '';
SELECT '7. government_maintenance' as '';
SELECT '8. government_stocks' as '';
SELECT '9. government_licenses' as '';
SELECT '10. government_logs' as '';
SELECT '11. government_settings' as '';
SELECT '============================================' as '';
SELECT 'Saldo inicial: R$ 10.000.000,00' as '';
SELECT 'Secretarias provisionadas com orçamento' as '';
SELECT 'Sistema pronto para uso!' as '';