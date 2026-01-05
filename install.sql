-- 1. Tabela de Tesouro Estadual (Dados Macro)
CREATE TABLE IF NOT EXISTS `government_treasury` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `balance` DECIMAL(15, 2) DEFAULT 0.00,             -- Reserva do Tesouro
    `budget_saude_balance` DECIMAL(15, 2) DEFAULT 0.00,  -- Saldo da Secretaria de Saúde
    `budget_seguranca_balance` DECIMAL(15, 2) DEFAULT 0.00, -- Saldo da Sec. Segurança
    `budget_saude_perc` INT(3) DEFAULT 20,             -- Porcentagem definida pelo Gov
    `budget_seguranca_perc` INT(3) DEFAULT 20,         -- Porcentagem definida pelo Gov
    `total_collected` DECIMAL(15, 2) DEFAULT 0.00,     -- Histórico total arrecadado
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Inserir o estado inicial do Governo
INSERT INTO `government_treasury` (`id`, `balance`) VALUES (1, 0.00) 
ON DUPLICATE KEY UPDATE id=id;

-- 2. Tabela de Impostos (Configuráveis via Tablet)
CREATE TABLE IF NOT EXISTS `government_taxes` (
    `tax_name` VARCHAR(50) NOT NULL,
    `label` VARCHAR(50) NOT NULL,
    `tax_value` DECIMAL(5, 2) DEFAULT 0.00,
    `updated_by` VARCHAR(100) DEFAULT 'Sistema',
    PRIMARY KEY (`tax_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `government_taxes` (`tax_name`, `label`, `tax_value`) VALUES
('ipva', 'IPVA (Veículos)', 5.00),
('iptu', 'IPTU (Propriedades)', 2.50),
('inss', 'INSS (Renda)', 8.00),
('alimentos', 'Taxa de Alimentos', 3.00),
('combustivel', 'Taxa de Combustível', 12.00), -- Removido o ; daqui
('empresas', 'Taxa de Funcionamento (Empresas)', 15.00), 
('porte_arma', 'Renovação de Licença de Armas', 500.00),  
('licenca_motorista', 'Taxa de Licença de Condução', 150.00),
('licenca_pesca', 'Licença de Pesca Profissional', 100.00); -- O ; vai apenas no final de tudo

-- 3. Tabela de Unidades (Batalhões e Hospitais)
-- Aqui fica a verba que o Secretário envia para a gestão local
CREATE TABLE IF NOT EXISTS `government_units` (
    `unit_id` VARCHAR(50) NOT NULL,           -- Ex: 'pm_19bpm', 'pillbox'
    `label` VARCHAR(100) NOT NULL,
    `budget_balance` DECIMAL(15, 2) DEFAULT 0.00,
    `last_transfer` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`unit_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `government_units` (`unit_id`, `label`, `budget_balance`) VALUES
('pm_19bpm', '19º Batalhão de Polícia Militar', 0.00),
('pc_deic', 'DEIC - Polícia Civil', 0.00),
('pillbox', 'Hospital Central Pillbox', 0.00);

-- 4. Tabela de Logística (Cargas nos Hubs)
CREATE TABLE IF NOT EXISTS `government_deliveries` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `hub_origin` VARCHAR(50) NOT NULL,        -- Porto, Aeroporto, etc
    `destiny_unit` VARCHAR(50) NOT NULL,      -- Batalhão de destino
    `items_data` LONGTEXT NOT NULL,           -- JSON com modelos e seriais
    `status` ENUM('waiting', 'shipping', 'delivered', 'stolen') DEFAULT 'waiting',
    `type` ENUM('seguranca', 'saude') NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 5. Tabela de Arsenal Governamental (Rastreio de Seriais)
CREATE TABLE IF NOT EXISTS `government_armory` (
    `serial_number` VARCHAR(50) NOT NULL,     -- SEC-SEG-XXXX
    `item_name` VARCHAR(50) NOT NULL,
    `unit_owner` VARCHAR(50) NOT NULL,        -- Batalhão atual
    `officer_cid` VARCHAR(50) DEFAULT NULL,   -- Policial que está portando
    `status` ENUM('available', 'in_use', 'lost', 'stolen') DEFAULT 'available',
    PRIMARY KEY (`serial_number`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 6. Tabela de Logs de Auditoria (Extrato do Estado)
CREATE TABLE IF NOT EXISTS `government_logs` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `dept` ENUM('governadoria', 'fazenda', 'seguranca', 'saude', 'sistema') NOT NULL,
    `author_name` VARCHAR(100) DEFAULT 'Sistema',
    `author_cid` VARCHAR(50) DEFAULT NULL,
    `action` VARCHAR(100) NOT NULL,            -- Ex: 'Compra de Viatura', 'Ajuste de Imposto'
    `details` TEXT NOT NULL,                  -- Detalhes da transação
    `amount` DECIMAL(15, 2) DEFAULT 0.00,     -- Valor envolvido (se houver)
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Exemplo de índice para buscas rápidas no Tablet
CREATE INDEX idx_dept_logs ON government_logs(dept);