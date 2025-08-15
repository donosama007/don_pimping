-- Pimp Management System - SQL Setup
-- Created by Donald Draper
-- Optimized by NinjaTech AI

-- Players Table
CREATE TABLE IF NOT EXISTS `pimp_players` (
    `identifier` VARCHAR(50) NOT NULL,
    `name` VARCHAR(50) NOT NULL,
    `level` INT NOT NULL DEFAULT 1,
    `reputation` INT NOT NULL DEFAULT 0,
    `total_earnings` INT NOT NULL DEFAULT 0,
    `last_active` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`identifier`),
    INDEX `idx_reputation` (`reputation`)
);

-- Girls Table
CREATE TABLE IF NOT EXISTS `pimp_girls` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `owner` VARCHAR(50) NOT NULL,
    `name` VARCHAR(50) NOT NULL,
    `type` VARCHAR(50) NOT NULL,
    `age` INT NOT NULL,
    `nationality` VARCHAR(50) NOT NULL,
    `hire_date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `appearance` INT NOT NULL,
    `performance` INT NOT NULL,
    `loyalty` INT NOT NULL,
    `discretion` INT NOT NULL,
    `fear` INT NOT NULL DEFAULT 0,
    `happiness` INT NOT NULL DEFAULT 50,
    `reputation` INT NOT NULL DEFAULT 50,
    `base_price` INT NOT NULL DEFAULT 100,
    `price_tier` VARCHAR(20) NOT NULL DEFAULT 'standard',
    `total_earnings` INT NOT NULL DEFAULT 0,
    `pending_earnings` INT NOT NULL DEFAULT 0,
    `clients_served` INT NOT NULL DEFAULT 0,
    `status` VARCHAR(50) NOT NULL DEFAULT 'idle',
    `last_work_time` DATETIME DEFAULT NULL,
    PRIMARY KEY (`id`),
    INDEX `idx_owner` (`owner`),
    INDEX `idx_status` (`status`)
);

-- Earnings Table
CREATE TABLE IF NOT EXISTS `pimp_earnings` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `owner` VARCHAR(50) NOT NULL,
    `girl_id` INT NOT NULL,
    `girl_name` VARCHAR(50) NOT NULL,
    `amount` INT NOT NULL,
    `location` VARCHAR(50) NOT NULL,
    `date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_owner` (`owner`),
    INDEX `idx_girl_id` (`girl_id`),
    INDEX `idx_date` (`date`)
);

-- Items Table
CREATE TABLE IF NOT EXISTS `pimp_items` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `owner` VARCHAR(50) NOT NULL,
    `name` VARCHAR(50) NOT NULL,
    `count` INT NOT NULL DEFAULT 1,
    PRIMARY KEY (`id`),
    INDEX `idx_owner` (`owner`),
    INDEX `idx_name` (`name`)
);

-- Cooldowns Table
CREATE TABLE IF NOT EXISTS `pimp_cooldowns` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `owner` VARCHAR(50) NOT NULL,
    `key` VARCHAR(50) NOT NULL,
    `end_time` BIGINT NOT NULL,
    PRIMARY KEY (`id`),
    INDEX `idx_owner_key` (`owner`, `key`),
    INDEX `idx_end_time` (`end_time`)
);

-- Territory Table
CREATE TABLE IF NOT EXISTS `pimp_territory` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `owner` VARCHAR(50) NOT NULL,
    `location` VARCHAR(50) NOT NULL,
    `control` FLOAT NOT NULL DEFAULT 0,
    `last_updated` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_owner_location` (`owner`, `location`),
    INDEX `idx_location` (`location`)
);

-- Territory Definitions Table
CREATE TABLE IF NOT EXISTS `pimp_territory_definitions` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(50) NOT NULL,
    `label` VARCHAR(50) NOT NULL,
    `type` VARCHAR(20) NOT NULL DEFAULT 'standard',
    `x` FLOAT NOT NULL,
    `y` FLOAT NOT NULL,
    `z` FLOAT NOT NULL,
    `radius` FLOAT NOT NULL DEFAULT 50.0,
    `earnings_multiplier` FLOAT NOT NULL DEFAULT 1.0,
    `risk_level` VARCHAR(20) NOT NULL DEFAULT 'medium',
    `client_quality` VARCHAR(20) NOT NULL DEFAULT 'standard',
    `visibility` FLOAT NOT NULL DEFAULT 1.0,
    `security` FLOAT NOT NULL DEFAULT 1.0,
    `is_premium` TINYINT(1) NOT NULL DEFAULT 0,
    `is_vip` TINYINT(1) NOT NULL DEFAULT 0,
    `is_discovered` TINYINT(1) NOT NULL DEFAULT 1,
    `blip_sprite` INT NOT NULL DEFAULT 280,
    `blip_color` INT NOT NULL DEFAULT 1,
    `description` TEXT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_name` (`name`)
);

-- Territory Upgrades Table
CREATE TABLE IF NOT EXISTS `pimp_territory_upgrades` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `owner` VARCHAR(50) NOT NULL,
    `territory_name` VARCHAR(50) NOT NULL,
    `upgrade_type` VARCHAR(50) NOT NULL,
    `level` INT NOT NULL DEFAULT 1,
    `purchase_date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_owner_territory_upgrade` (`owner`, `territory_name`, `upgrade_type`),
    INDEX `idx_owner` (`owner`),
    INDEX `idx_territory` (`territory_name`)
);

-- Territory Discovered Table
CREATE TABLE IF NOT EXISTS `pimp_territory_discovered` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `owner` VARCHAR(50) NOT NULL,
    `territory_name` VARCHAR(50) NOT NULL,
    `discovery_date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_owner_territory` (`owner`, `territory_name`),
    INDEX `idx_owner` (`owner`)
);

-- Territory Earnings Table
CREATE TABLE IF NOT EXISTS `pimp_territory_earnings` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `owner` VARCHAR(50) NOT NULL,
    `territory_name` VARCHAR(50) NOT NULL,
    `amount` INT NOT NULL,
    `date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_owner` (`owner`),
    INDEX `idx_territory` (`territory_name`),
    INDEX `idx_date` (`date`)
);

-- Territory Events Table
CREATE TABLE IF NOT EXISTS `pimp_territory_events` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `territory_name` VARCHAR(50) NOT NULL,
    `event_type` VARCHAR(50) NOT NULL,
    `description` TEXT NOT NULL,
    `owner` VARCHAR(50) NULL,
    `target` VARCHAR(50) NULL,
    `date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_territory` (`territory_name`),
    INDEX `idx_date` (`date`)
);

-- Girl Reputation History Table
CREATE TABLE IF NOT EXISTS `pimp_girl_reputation_history` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `girl_id` INT NOT NULL,
    `event_name` VARCHAR(50) NOT NULL,
    `description` VARCHAR(100) NOT NULL,
    `reputation_change` INT NOT NULL,
    `date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_girl_id` (`girl_id`)
);

-- Service Prices Table
CREATE TABLE IF NOT EXISTS `pimp_service_prices` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `service_type` VARCHAR(50) NOT NULL,
    `base_price` INT NOT NULL,
    `min_price` INT NOT NULL,
    `max_price` INT NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_service` (`service_type`)
);

-- Location Pricing Table
CREATE TABLE IF NOT EXISTS `pimp_location_pricing` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `zone_name` VARCHAR(50) NOT NULL,
    `price_multiplier` FLOAT NOT NULL DEFAULT 1.0,
    `zone_tier` VARCHAR(20) NOT NULL DEFAULT 'standard',
    `description` VARCHAR(100),
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_zone` (`zone_name`)
);

-- Price History Table
CREATE TABLE IF NOT EXISTS `pimp_price_history` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `girl_id` INT NOT NULL,
    `service_type` VARCHAR(50) NOT NULL,
    `base_price` INT NOT NULL,
    `final_price` INT NOT NULL,
    `client_type` VARCHAR(20) NOT NULL,
    `location` VARCHAR(50) NOT NULL,
    `date_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_girl_id` (`girl_id`),
    INDEX `idx_date_time` (`date_time`)
);

-- Girl Events Table
CREATE TABLE IF NOT EXISTS `pimp_girl_events` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `girl_id` INT NOT NULL,
    `event_name` VARCHAR(50) NOT NULL,
    `description` VARCHAR(100) NOT NULL,
    `happiness_change` INT NOT NULL,
    `loyalty_change` INT NOT NULL,
    `date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_girl_id` (`girl_id`),
    INDEX `idx_date` (`date`)
);

-- Shop History Table
CREATE TABLE IF NOT EXISTS `pimp_shop_history` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `owner` VARCHAR(50) NOT NULL,
    `girl_name` VARCHAR(50) NOT NULL,
    `girl_type` VARCHAR(50) NOT NULL,
    `price` INT NOT NULL,
    `purchase_date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_owner` (`owner`),
    INDEX `idx_purchase_date` (`purchase_date`)
);

-- Transactions Table
CREATE TABLE IF NOT EXISTS `pimp_transactions` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `owner` VARCHAR(50) NOT NULL,
    `type` VARCHAR(50) NOT NULL,
    `amount` INT NOT NULL,
    `details` TEXT NULL,
    `date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_owner` (`owner`),
    INDEX `idx_type` (`type`),
    INDEX `idx_date` (`date`)
);

-- Player Perks Table
CREATE TABLE IF NOT EXISTS `pimp_player_perks` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `owner` VARCHAR(50) NOT NULL,
    `perk_id` VARCHAR(50) NOT NULL,
    `category` VARCHAR(50) NOT NULL,
    `purchase_date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `active` TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_owner_perk` (`owner`, `perk_id`),
    INDEX `idx_owner` (`owner`),
    INDEX `idx_perk_id` (`perk_id`)
);

-- Girl Activities Table
CREATE TABLE IF NOT EXISTS `pimp_girl_activities` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `girl_id` INT NOT NULL,
    `activity_name` VARCHAR(50) NOT NULL,
    `start_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `end_time` DATETIME NOT NULL,
    `happiness_gain` INT NOT NULL,
    `cost` INT NOT NULL,
    PRIMARY KEY (`id`),
    INDEX `idx_girl_id` (`girl_id`),
    INDEX `idx_end_time` (`end_time`)
);

-- Insert default service prices if they don't exist
INSERT INTO pimp_service_prices (service_type, base_price, min_price, max_price)
VALUES 
    ('standard', 100, 70, 150),
    ('premium', 200, 140, 300),
    ('special', 300, 210, 450),
    ('exclusive', 500, 350, 750)
ON DUPLICATE KEY UPDATE
    base_price = VALUES(base_price),
    min_price = VALUES(min_price),
    max_price = VALUES(max_price);

-- Insert default location pricing if they don't exist
INSERT INTO pimp_location_pricing (zone_name, price_multiplier, zone_tier, description)
VALUES
    ('Red Light District', 1.0, 'standard', 'Standard pricing area'),
    ('Vinewood Boulevard', 1.2, 'premium', 'Premium pricing area'),
    ('Vespucci Beach', 1.1, 'standard', 'Standard pricing area with slight premium'),
    ('South Los Santos', 0.8, 'low', 'Budget pricing area'),
    ('Downtown Vinewood', 1.3, 'premium', 'Premium pricing area')
ON DUPLICATE KEY UPDATE
    price_multiplier = VALUES(price_multiplier),
    zone_tier = VALUES(zone_tier),
    description = VALUES(description);
    
-- Insert default territory definitions
INSERT INTO pimp_territory_definitions (name, label, type, x, y, z, radius, earnings_multiplier, risk_level, client_quality, visibility, security, is_premium, is_vip, is_discovered, blip_sprite, blip_color, description)
VALUES
    -- Standard territories (discovered by default)
    ('strawberry', 'Strawberry', 'standard', 232.61, -1359.72, 28.65, 75.0, 0.8, 'medium', 'standard', 1.0, 0.7, 0, 0, 1, 280, 1, 'A standard territory in Strawberry with moderate risk and standard clients.'),
    ('vespucci_canals', 'Vespucci Canals', 'standard', -1161.78, -1403.69, 4.96, 80.0, 1.0, 'low', 'standard', 1.2, 0.9, 0, 0, 1, 280, 1, 'A low-risk territory in Vespucci Canals with good visibility.'),
    ('la_mesa', 'La Mesa', 'standard', 970.52, -1720.71, 31.12, 70.0, 0.9, 'high', 'standard', 0.8, 0.6, 0, 0, 1, 280, 1, 'A high-risk territory in La Mesa with lower security but decent earnings.'),
    
    -- Premium territories (some discovered, some not)
    ('vinewood_boulevard', 'Vinewood Boulevard', 'premium', 284.68, 80.95, 104.17, 90.0, 1.3, 'medium', 'premium', 1.5, 1.2, 1, 0, 1, 280, 3, 'A premium territory on Vinewood Boulevard with high-paying clients.'),
    ('del_perro', 'Del Perro Beach', 'premium', -1879.61, -647.65, 11.17, 85.0, 1.2, 'low', 'premium', 1.4, 1.1, 1, 0, 1, 280, 3, 'A premium low-risk territory at Del Perro Beach with excellent visibility.'),
    ('downtown_vinewood', 'Downtown Vinewood', 'premium', 638.81, 1.95, 82.79, 95.0, 1.4, 'medium', 'premium', 1.3, 1.0, 1, 0, 0, 280, 3, 'A hidden premium territory in Downtown Vinewood with high earnings potential.'),
    
    -- VIP territories (all hidden by default)
    ('rockford_hills', 'Rockford Hills', 'vip', -678.74, 73.33, 84.14, 100.0, 2.0, 'low', 'vip', 0.7, 1.8, 1, 1, 0, 280, 5, 'An exclusive VIP territory in Rockford Hills with extremely wealthy clients.'),
    ('pacific_bluffs', 'Pacific Bluffs', 'vip', -2311.98, 268.46, 169.6, 110.0, 1.8, 'medium', 'vip', 0.8, 1.5, 1, 1, 0, 280, 5, 'A secluded VIP territory in Pacific Bluffs with high-profile clients.'),
    ('richman', 'Richman', 'vip', -1549.42, 134.78, 56.78, 90.0, 2.2, 'low', 'vip', 0.6, 2.0, 1, 1, 0, 280, 5, 'The most exclusive territory in Richman with the highest-paying clients in the city.')
ON DUPLICATE KEY UPDATE
    label = VALUES(label),
    type = VALUES(type),
    x = VALUES(x),
    y = VALUES(y),
    z = VALUES(z),
    radius = VALUES(radius),
    earnings_multiplier = VALUES(earnings_multiplier),
    risk_level = VALUES(risk_level),
    client_quality = VALUES(client_quality),
    visibility = VALUES(visibility),
    security = VALUES(security),
    is_premium = VALUES(is_premium),
    is_vip = VALUES(is_vip),
    is_discovered = VALUES(is_discovered),
    blip_sprite = VALUES(blip_sprite),
    blip_color = VALUES(blip_color),
    description = VALUES(description);