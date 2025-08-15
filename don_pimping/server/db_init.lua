-- Pimp Management System - Database Initialization
-- Created by Donald Draper
-- Optimized by NinjaTech AI

-- This file handles database initialization and structure verification

-- Initialize database
Citizen.CreateThread(function()
    -- Wait for MySQL to be ready
    Citizen.Wait(1000)
    
    -- Create tables if they don't exist
    InitializeTables()
    
    -- Verify and update table structure
    VerifyTableStructure()
    
    -- Insert default data
    InsertDefaultData()
    
    print("^2Database initialization completed^7")
end)

-- Initialize tables
function InitializeTables()
    -- Players table
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `pimp_players` (
            `identifier` VARCHAR(50) NOT NULL,
            `name` VARCHAR(50) NOT NULL,
            `level` INT NOT NULL DEFAULT 1,
            `reputation` INT NOT NULL DEFAULT 0,
            `total_earnings` INT NOT NULL DEFAULT 0,
            `last_active` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`identifier`),
            INDEX `idx_reputation` (`reputation`)
        )
    ]], {})
    
    -- Girls table
    MySQL.query([[
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
        )
    ]], {})
    
    -- Earnings table
    MySQL.query([[
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
        )
    ]], {})
    
    -- Items table
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `pimp_items` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `owner` VARCHAR(50) NOT NULL,
            `name` VARCHAR(50) NOT NULL,
            `count` INT NOT NULL DEFAULT 1,
            PRIMARY KEY (`id`),
            INDEX `idx_owner` (`owner`),
            INDEX `idx_name` (`name`)
        )
    ]], {})
    
    -- Cooldowns table
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `pimp_cooldowns` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `owner` VARCHAR(50) NOT NULL,
            `key` VARCHAR(50) NOT NULL,
            `end_time` BIGINT NOT NULL,
            PRIMARY KEY (`id`),
            INDEX `idx_owner_key` (`owner`, `key`),
            INDEX `idx_end_time` (`end_time`)
        )
    ]], {})
    
    -- Territory table
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `pimp_territory` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `owner` VARCHAR(50) NOT NULL,
            `location` VARCHAR(50) NOT NULL,
            `control` FLOAT NOT NULL DEFAULT 0,
            `last_updated` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `unique_owner_location` (`owner`, `location`),
            INDEX `idx_location` (`location`)
        )
    ]], {})
    
    -- Girl reputation history table
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `pimp_girl_reputation_history` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `girl_id` INT NOT NULL,
            `event_name` VARCHAR(50) NOT NULL,
            `description` VARCHAR(100) NOT NULL,
            `reputation_change` INT NOT NULL,
            `date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            INDEX `idx_girl_id` (`girl_id`)
        )
    ]], {})
    
    -- Service prices table
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `pimp_service_prices` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `service_type` VARCHAR(50) NOT NULL,
            `base_price` INT NOT NULL,
            `min_price` INT NOT NULL,
            `max_price` INT NOT NULL,
            PRIMARY KEY (`id`),
            UNIQUE KEY `unique_service` (`service_type`)
        )
    ]], {})
    
    -- Location pricing table
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `pimp_location_pricing` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `zone_name` VARCHAR(50) NOT NULL,
            `price_multiplier` FLOAT NOT NULL DEFAULT 1.0,
            `zone_tier` VARCHAR(20) NOT NULL DEFAULT 'standard',
            `description` VARCHAR(100),
            PRIMARY KEY (`id`),
            UNIQUE KEY `unique_zone` (`zone_name`)
        )
    ]], {})
    
    -- Price history table
    MySQL.query([[
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
        )
    ]], {})
    
    -- Girl events table
    MySQL.query([[
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
        )
    ]], {})
    
    -- Shop history table
    MySQL.query([[
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
        )
    ]], {})
    
    -- Transactions table
    MySQL.query([[
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
        )
    ]], {})
    
    -- Girl activities table
    MySQL.query([[
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
        )
    ]], {})
end

-- Verify and update table structure
function VerifyTableStructure()
    -- Check if happiness column exists in pimp_girls
    MySQL.query("SHOW COLUMNS FROM pimp_girls LIKE 'happiness'", {}, function(result)
        if not result or #result == 0 then
            -- Add happiness column
            MySQL.query("ALTER TABLE pimp_girls ADD COLUMN happiness INT NOT NULL DEFAULT 50", {})
            print("^2Added happiness column to pimp_girls table^7")
        end
    end)
    
    -- Check if reputation column exists in pimp_girls
    MySQL.query("SHOW COLUMNS FROM pimp_girls LIKE 'reputation'", {}, function(result)
        if not result or #result == 0 then
            -- Add reputation column
            MySQL.query("ALTER TABLE pimp_girls ADD COLUMN reputation INT NOT NULL DEFAULT 50", {})
            print("^2Added reputation column to pimp_girls table^7")
        end
    end)
    
    -- Check if last_work_time column exists in pimp_girls
    MySQL.query("SHOW COLUMNS FROM pimp_girls LIKE 'last_work_time'", {}, function(result)
        if not result or #result == 0 then
            -- Add last_work_time column
            MySQL.query("ALTER TABLE pimp_girls ADD COLUMN last_work_time DATETIME DEFAULT NULL", {})
            print("^2Added last_work_time column to pimp_girls table^7")
        end
    end)
    
    -- Check if price_tier column exists in pimp_girls
    MySQL.query("SHOW COLUMNS FROM pimp_girls LIKE 'price_tier'", {}, function(result)
        if not result or #result == 0 then
            -- Add price_tier column
            MySQL.query("ALTER TABLE pimp_girls ADD COLUMN price_tier VARCHAR(20) NOT NULL DEFAULT 'standard'", {})
            print("^2Added price_tier column to pimp_girls table^7")
        end
    end)
    
    -- Check if base_price column exists in pimp_girls
    MySQL.query("SHOW COLUMNS FROM pimp_girls LIKE 'base_price'", {}, function(result)
        if not result or #result == 0 then
            -- Add base_price column
            MySQL.query("ALTER TABLE pimp_girls ADD COLUMN base_price INT NOT NULL DEFAULT 100", {})
            print("^2Added base_price column to pimp_girls table^7")
        end
    end)
    
    -- Check if fear column exists in pimp_girls
    MySQL.query("SHOW COLUMNS FROM pimp_girls LIKE 'fear'", {}, function(result)
        if not result or #result == 0 then
            -- Add fear column
            MySQL.query("ALTER TABLE pimp_girls ADD COLUMN fear INT NOT NULL DEFAULT 0", {})
            print("^2Added fear column to pimp_girls table^7")
        end
    end)
    
    -- Add indexes for better performance
    MySQL.query("SHOW INDEX FROM pimp_girls WHERE Key_name = 'idx_owner'", {}, function(result)
        if not result or #result == 0 then
            -- Add index
            MySQL.query("CREATE INDEX idx_owner ON pimp_girls (owner)", {})
            print("^2Added owner index to pimp_girls table^7")
        end
    end)
    
    MySQL.query("SHOW INDEX FROM pimp_girls WHERE Key_name = 'idx_status'", {}, function(result)
        if not result or #result == 0 then
            -- Add index
            MySQL.query("CREATE INDEX idx_status ON pimp_girls (status)", {})
            print("^2Added status index to pimp_girls table^7")
        end
    end)
    
    MySQL.query("SHOW INDEX FROM pimp_earnings WHERE Key_name = 'idx_owner'", {}, function(result)
        if not result or #result == 0 then
            -- Add index
            MySQL.query("CREATE INDEX idx_owner ON pimp_earnings (owner)", {})
            print("^2Added owner index to pimp_earnings table^7")
        end
    end)
    
    MySQL.query("SHOW INDEX FROM pimp_earnings WHERE Key_name = 'idx_girl_id'", {}, function(result)
        if not result or #result == 0 then
            -- Add index
            MySQL.query("CREATE INDEX idx_girl_id ON pimp_earnings (girl_id)", {})
            print("^2Added girl_id index to pimp_earnings table^7")
        end
    end)
    
    MySQL.query("SHOW INDEX FROM pimp_earnings WHERE Key_name = 'idx_date'", {}, function(result)
        if not result or #result == 0 then
            -- Add index
            MySQL.query("CREATE INDEX idx_date ON pimp_earnings (date)", {})
            print("^2Added date index to pimp_earnings table^7")
        end
    end)
    
    MySQL.query("SHOW INDEX FROM pimp_cooldowns WHERE Key_name = 'idx_owner_key'", {}, function(result)
        if not result or #result == 0 then
            -- Add index
            MySQL.query("CREATE INDEX idx_owner_key ON pimp_cooldowns (owner, `key`)", {})
            print("^2Added owner_key index to pimp_cooldowns table^7")
        end
    end)
    
    MySQL.query("SHOW INDEX FROM pimp_cooldowns WHERE Key_name = 'idx_end_time'", {}, function(result)
        if not result or #result == 0 then
            -- Add index
            MySQL.query("CREATE INDEX idx_end_time ON pimp_cooldowns (end_time)", {})
            print("^2Added end_time index to pimp_cooldowns table^7")
        end
    end)
end

-- Insert default data
function InsertDefaultData()
    -- Insert default service prices
    MySQL.query([[
        INSERT INTO pimp_service_prices (service_type, base_price, min_price, max_price)
        VALUES 
            ('standard', 100, 70, 150),
            ('premium', 200, 140, 300),
            ('special', 300, 210, 450),
            ('exclusive', 500, 350, 750)
        ON DUPLICATE KEY UPDATE
            base_price = VALUES(base_price),
            min_price = VALUES(min_price),
            max_price = VALUES(max_price)
    ]], {})
    
    -- Insert default location pricing
    MySQL.query([[
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
            description = VALUES(description)
    ]], {})
end

-- Export functions
exports('InitializeTables', InitializeTables)
exports('VerifyTableStructure', VerifyTableStructure)
exports('InsertDefaultData', InsertDefaultData)