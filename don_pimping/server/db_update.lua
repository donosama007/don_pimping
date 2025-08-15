-- Database Update Script for Pimp Management System
-- This file ensures all required database columns exist

Citizen.CreateThread(function()
    Citizen.Wait(3000) -- Wait for database to be ready
    
    print("^3[DB UPDATE] Starting database structure verification...^7")
    
    -- Check and add missing columns to pimp_girls table
    local columnsToCheck = {
        {name = 'has_attitude', type = 'BOOLEAN NOT NULL DEFAULT 0'},
        {name = 'work_location', type = 'VARCHAR(100) DEFAULT NULL'},
        {name = 'height', type = 'INT DEFAULT 170'},
        {name = 'weight', type = 'INT DEFAULT 60'},
        {name = 'happiness', type = 'INT NOT NULL DEFAULT 50'},
        {name = 'fear', type = 'INT NOT NULL DEFAULT 0'},
        {name = 'reputation', type = 'INT NOT NULL DEFAULT 50'},
        {name = 'base_price', type = 'INT NOT NULL DEFAULT 100'},
        {name = 'price_tier', type = 'VARCHAR(20) NOT NULL DEFAULT "standard"'},
        {name = 'total_earnings', type = 'INT NOT NULL DEFAULT 0'},
        {name = 'pending_earnings', type = 'INT NOT NULL DEFAULT 0'},
        {name = 'clients_served', type = 'INT NOT NULL DEFAULT 0'},
        {name = 'last_work_time', type = 'DATETIME DEFAULT NULL'}
    }
    
    for _, column in ipairs(columnsToCheck) do
        MySQL.query("SHOW COLUMNS FROM pimp_girls LIKE ?", {column.name}, function(result)
            if not result or #result == 0 then
                local query = string.format("ALTER TABLE pimp_girls ADD COLUMN %s %s", column.name, column.type)
                MySQL.query(query, {}, function(success)
                    if success then
                        print("^2[DB UPDATE] Added column: " .. column.name .. "^7")
                    else
                        print("^1[DB UPDATE] Failed to add column: " .. column.name .. "^7")
                    end
                end)
            else
                print("^2[DB UPDATE] Column exists: " .. column.name .. "^7")
            end
        end)
        
        -- Small delay between queries
        Citizen.Wait(100)
    end
    
    -- Check and create indexes for better performance
    Citizen.Wait(1000)
    
    local indexesToCheck = {
        {table = 'pimp_girls', name = 'idx_owner', columns = '(owner)'},
        {table = 'pimp_girls', name = 'idx_status', columns = '(status)'},
        {table = 'pimp_earnings', name = 'idx_owner', columns = '(owner)'},
        {table = 'pimp_earnings', name = 'idx_girl_id', columns = '(girl_id)'},
        {table = 'pimp_earnings', name = 'idx_date', columns = '(date)'},
        {table = 'pimp_transactions', name = 'idx_owner', columns = '(owner)'},
        {table = 'pimp_transactions', name = 'idx_date', columns = '(date)'},
        {table = 'pimp_cooldowns', name = 'idx_owner_key', columns = '(owner, `key`)'},
        {table = 'pimp_cooldowns', name = 'idx_end_time', columns = '(end_time)'}
    }
    
    for _, index in ipairs(indexesToCheck) do
        MySQL.query("SHOW INDEX FROM " .. index.table .. " WHERE Key_name = ?", {index.name}, function(result)
            if not result or #result == 0 then
                local query = string.format("CREATE INDEX %s ON %s %s", index.name, index.table, index.columns)
                MySQL.query(query, {}, function(success)
                    if success then
                        print("^2[DB UPDATE] Added index: " .. index.name .. " to " .. index.table .. "^7")
                    else
                        print("^1[DB UPDATE] Failed to add index: " .. index.name .. " to " .. index.table .. "^7")
                    end
                end)
            else
                print("^2[DB UPDATE] Index exists: " .. index.name .. " on " .. index.table .. "^7")
            end
        end)
        
        -- Small delay between queries
        Citizen.Wait(100)
    end
    
    -- Create additional tables if they don't exist
    Citizen.Wait(1000)
    
    local additionalTables = {
        pimp_discipline_log = [[
            CREATE TABLE IF NOT EXISTS `pimp_discipline_log` (
                `id` INT NOT NULL AUTO_INCREMENT,
                `owner` VARCHAR(50) NOT NULL,
                `girl_id` INT NOT NULL,
                `discipline_type` VARCHAR(50) NOT NULL,
                `loyalty_change` INT NOT NULL,
                `fear_change` INT NOT NULL,
                `attitude_improved` BOOLEAN NOT NULL DEFAULT 0,
                `date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                PRIMARY KEY (`id`),
                INDEX `idx_owner` (`owner`),
                INDEX `idx_girl_id` (`girl_id`)
            )
        ]],
        
        pimp_girl_activities = [[
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
        ]],
        
        pimp_girl_events = [[
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
        ]],
        
        pimp_shop_history = [[
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
        ]]
    }
    
    for tableName, createQuery in pairs(additionalTables) do
        MySQL.query(createQuery, {}, function(success)
            if success then
                print("^2[DB UPDATE] Table verified/created: " .. tableName .. "^7")
            else
                print("^1[DB UPDATE] Failed to create table: " .. tableName .. "^7")
            end
        end)
        
        -- Small delay between queries
        Citizen.Wait(200)
    end
    
    print("^2[DB UPDATE] Database structure verification completed^7")
end)