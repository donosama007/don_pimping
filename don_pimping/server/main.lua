-- Pimp Management System - Enhanced Server Main
-- Created by Donald Draper
-- Optimized by NinjaTech AI
-- Enhanced with Money System and Shop Integration

-- Database tables (existing structure)
local dbTables = {
    players = "CREATE TABLE IF NOT EXISTS `pimp_players` (" ..
              "`identifier` VARCHAR(50) NOT NULL," ..
              "`name` VARCHAR(50) NOT NULL," ..
              "`level` INT NOT NULL DEFAULT 1," ..
              "`reputation` INT NOT NULL DEFAULT 0," ..
              "`total_earnings` INT NOT NULL DEFAULT 0," ..
              "`last_active` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP," ..
              "PRIMARY KEY (`identifier`)" ..
              ");",
    
    girls = "CREATE TABLE IF NOT EXISTS `pimp_girls` (" ..
            "`id` INT NOT NULL AUTO_INCREMENT," ..
            "`owner` VARCHAR(50) NOT NULL," ..
            "`name` VARCHAR(50) NOT NULL," ..
            "`type` VARCHAR(50) NOT NULL," ..
            "`age` INT NOT NULL," ..
            "`nationality` VARCHAR(50) NOT NULL," ..
            "`hire_date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP," ..
            "`appearance` INT NOT NULL," ..
            "`performance` INT NOT NULL," ..
            "`loyalty` INT NOT NULL," ..
            "`discretion` INT NOT NULL," ..
            "`fear` INT NOT NULL DEFAULT 0," ..
            "`happiness` INT NOT NULL DEFAULT 50," ..
            "`reputation` INT NOT NULL DEFAULT 50," ..
            "`base_price` INT NOT NULL DEFAULT 100," ..
            "`price_tier` VARCHAR(20) NOT NULL DEFAULT 'standard'," ..
            "`total_earnings` INT NOT NULL DEFAULT 0," ..
            "`pending_earnings` INT NOT NULL DEFAULT 0," ..
            "`clients_served` INT NOT NULL DEFAULT 0," ..
            "`status` VARCHAR(50) NOT NULL DEFAULT 'idle'," ..
            "`last_work_time` DATETIME DEFAULT NULL," ..
            "`has_attitude` BOOLEAN NOT NULL DEFAULT 0," ..
            "`work_location` VARCHAR(100) DEFAULT NULL," ..
            "`height` INT DEFAULT 170," ..
            "`weight` INT DEFAULT 60," ..
            "PRIMARY KEY (`id`)" ..
            ");",
    
    transactions = "CREATE TABLE IF NOT EXISTS `pimp_transactions` (" ..
                  "`id` INT NOT NULL AUTO_INCREMENT," ..
                  "`owner` VARCHAR(50) NOT NULL," ..
                  "`type` VARCHAR(50) NOT NULL," ..
                  "`amount` INT NOT NULL," ..
                  "`girl_id` INT DEFAULT NULL," ..
                  "`girl_name` VARCHAR(50) DEFAULT NULL," ..
                  "`description` TEXT NULL," ..
                  "`date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP," ..
                  "PRIMARY KEY (`id`)," ..
                  "INDEX `idx_owner` (`owner`)," ..
                  "INDEX `idx_date` (`date`)" ..
                  ");",
    
    earnings = "CREATE TABLE IF NOT EXISTS `pimp_earnings` (" ..
               "`id` INT NOT NULL AUTO_INCREMENT," ..
               "`owner` VARCHAR(50) NOT NULL," ..
               "`girl_id` INT NOT NULL," ..
               "`girl_name` VARCHAR(50) NOT NULL," ..
               "`amount` INT NOT NULL," ..
               "`location` VARCHAR(50) NOT NULL," ..
               "`date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP," ..
               "PRIMARY KEY (`id`)" ..
               ");",
    
    cooldowns = "CREATE TABLE IF NOT EXISTS `pimp_cooldowns` (" ..
                "`id` INT NOT NULL AUTO_INCREMENT," ..
                "`owner` VARCHAR(50) NOT NULL," ..
                "`key` VARCHAR(50) NOT NULL," ..
                "`end_time` BIGINT NOT NULL," ..
                "PRIMARY KEY (`id`)" ..
                ");"
}

-- Global variables
PlayerData = {}
local DisciplineCooldowns = {}

-- Framework detection
local ESX, QBCore = nil, nil

-- Initialize frameworks
Citizen.CreateThread(function()
    if GetResourceState('es_extended') ~= 'missing' then
        if exports['es_extended'] and exports['es_extended'].getSharedObject then
            ESX = exports['es_extended']:getSharedObject()
            if ESX then
                print("^2ESX Framework detected via export^7")
            end
        else
            TriggerEvent('esx:getSharedObject', function(obj) 
                ESX = obj 
                print("^2ESX Framework detected via event^7")
            end)
        end
    else
        print("^3ESX Framework not found^7")
    end
end)

Citizen.CreateThread(function()
    if GetResourceState('qb-core') ~= 'missing' then
        QBCore = exports['qb-core']:GetCoreObject()
        if QBCore then
            print("^2QBCore Framework detected^7")
        end
    else
        print("^3QBCore Framework not found^7")
    end
end)

-- Initialize the script
Citizen.CreateThread(function()
    Citizen.Wait(2000)
    
    if ESX then
        print("^2Using ESX Framework for money handling^7")
    elseif QBCore then
        print("^2Using QBCore Framework for money handling^7")
    else
        print("^3No framework detected. Using standalone mode^7")
    end
    
    -- Create database tables
    for _, query in pairs(dbTables) do
        MySQL.query(query, {}, function(result)
            if result then
                print("^2Database table created/verified successfully^7")
            else
                print("^1Error creating database table^7")
            end
        end)
        Citizen.Wait(100)
    end
    
    Citizen.Wait(1000)
    CheckDatabaseStructure()
    
    print("^2Enhanced Pimp Management System initialized^7")
end)

-- Enhanced database structure check
function CheckDatabaseStructure()
    -- Check for has_attitude column
    MySQL.query("SHOW COLUMNS FROM pimp_girls LIKE 'has_attitude'", {}, function(result)
        if not result or #result == 0 then
            MySQL.query("ALTER TABLE pimp_girls ADD COLUMN has_attitude BOOLEAN NOT NULL DEFAULT 0", {})
            print("^2Added has_attitude column to pimp_girls table^7")
        end
    end)
    
    -- Check for work_location column
    MySQL.query("SHOW COLUMNS FROM pimp_girls LIKE 'work_location'", {}, function(result)
        if not result or #result == 0 then
            MySQL.query("ALTER TABLE pimp_girls ADD COLUMN work_location VARCHAR(100) DEFAULT NULL", {})
            print("^2Added work_location column to pimp_girls table^7")
        end
    end)
    
    -- Check for height column
    MySQL.query("SHOW COLUMNS FROM pimp_girls LIKE 'height'", {}, function(result)
        if not result or #result == 0 then
            MySQL.query("ALTER TABLE pimp_girls ADD COLUMN height INT DEFAULT 170", {})
            print("^2Added height column to pimp_girls table^7")
        end
    end)
    
    -- Check for weight column
    MySQL.query("SHOW COLUMNS FROM pimp_girls LIKE 'weight'", {}, function(result)
        if not result or #result == 0 then
            MySQL.query("ALTER TABLE pimp_girls ADD COLUMN weight INT DEFAULT 60", {})
            print("^2Added weight column to pimp_girls table^7")
        end
    end)
    
    -- Other existing checks...
    MySQL.query("SHOW COLUMNS FROM pimp_girls LIKE 'happiness'", {}, function(result)
        if not result or #result == 0 then
            MySQL.query("ALTER TABLE pimp_girls ADD COLUMN happiness INT NOT NULL DEFAULT 50", {})
            print("^2Added happiness column to pimp_girls table^7")
        end
    end)
    
    MySQL.query("SHOW COLUMNS FROM pimp_girls LIKE 'fear'", {}, function(result)
        if not result or #result == 0 then
            MySQL.query("ALTER TABLE pimp_girls ADD COLUMN fear INT NOT NULL DEFAULT 0", {})
            print("^2Added fear column to pimp_girls table^7")
        end
    end)
end

-- Enhanced money functions with bank integration
function AddPlayerMoney(identifier, amount, method)
    local source = GetPlayerIdFromIdentifier(identifier)
    if not source then 
        print("^3[MONEY] Player source not found for identifier " .. identifier .. "^7")
        return false 
    end
    
    method = method or 'cash' -- Default to cash, can be 'bank'
    
    if ESX then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then
            if method == 'bank' then
                xPlayer.addAccountMoney('bank', amount)
                print("^2[MONEY] Added $" .. amount .. " to " .. identifier .. "'s bank account via ESX^7")
            else
                xPlayer.addMoney(amount)
                print("^2[MONEY] Added $" .. amount .. " to " .. identifier .. " via ESX^7")
            end
            return true
        end
    end
    
    if QBCore then
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then
            if method == 'bank' then
                Player.Functions.AddMoney('bank', amount)
                print("^2[MONEY] Added $" .. amount .. " to " .. identifier .. "'s bank account via QBCore^7")
            else
                Player.Functions.AddMoney('cash', amount)
                print("^2[MONEY] Added $" .. amount .. " to " .. identifier .. " via QBCore^7")
            end
            return true
        end
    end
    
    print("^2[MONEY] Fallback mode: Simulating money addition^7")
    return true
end

function RemovePlayerMoney(identifier, amount, method)
    local source = GetPlayerIdFromIdentifier(identifier)
    if not source then 
        print("^3[MONEY] Player source not found for identifier " .. identifier .. "^7")
        return false 
    end
    
    method = method or 'cash'
    
    if ESX then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then
            local currentMoney = method == 'bank' and xPlayer.getAccount('bank').money or xPlayer.getMoney()
            if currentMoney >= amount then
                if method == 'bank' then
                    xPlayer.removeAccountMoney('bank', amount)
                else
                    xPlayer.removeMoney(amount)
                end
                print("^2[MONEY] Removed $" .. amount .. " from " .. identifier .. " via ESX^7")
                return true
            else
                print("^1[MONEY] ESX: Player doesn't have enough money^7")
                return false
            end
        end
    end
    
    if QBCore then
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then
            local currentMoney = Player.PlayerData.money[method] or 0
            if currentMoney >= amount then
                Player.Functions.RemoveMoney(method, amount)
                print("^2[MONEY] Removed $" .. amount .. " from " .. identifier .. " via QBCore^7")
                return true
            else
                print("^1[MONEY] QBCore: Player doesn't have enough money^7")
                return false
            end
        end
    end
    
    print("^2[MONEY] Fallback mode: Allowing transaction^7")
    return true
end

function GetPlayerMoney(identifier, method)
    local source = GetPlayerIdFromIdentifier(identifier)
    if not source then 
        return 10000 -- Fallback
    end
    
    method = method or 'cash'
    
    if ESX then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then
            return method == 'bank' and xPlayer.getAccount('bank').money or xPlayer.getMoney()
        end
    end
    
    if QBCore then
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then
            return Player.PlayerData.money[method] or 0
        end
    end
    
    return 10000 -- Fallback
end

-- Enhanced girl addition with proper database integration
RegisterNetEvent('pimp:addGirl')
AddEventHandler('pimp:addGirl', function(girlData)
    local source = source
    local identifier = GetPlayerIdentifierFromId(source)
    
    print("^3[PIMP SYSTEM] Player " .. source .. " (" .. identifier .. ") adding girl: " .. (girlData.name or "Unknown") .. "^7")
    
    if not identifier then
        print("^1[PIMP SYSTEM] Error: Could not get player identifier^7")
        TriggerClientEvent('pimp:notification', source, 'Error getting player data', 'error')
        return
    end
    
    -- Initialize player data if needed
    local playerData = GetPlayerDataSafe(identifier)
    if not playerData then
        print("^1[PIMP SYSTEM] Error: Could not get player data for " .. identifier .. "^7")
        TriggerClientEvent('pimp:notification', source, 'Error loading player data', 'error')
        return
    end
    
    -- Validate girl data
    if not girlData or not girlData.name or not girlData.type then
        print("^1[PIMP SYSTEM] Error: Invalid girl data^7")
        TriggerClientEvent('pimp:notification', source, 'Invalid girl data', 'error')
        return
    end
    
    -- Ensure all required fields exist
    girlData.id = girlData.id or math.random(1000000, 9999999)
    girlData.age = girlData.age or math.random(18, 35)
    girlData.nationality = girlData.nationality or (Config.GirlSystem.nationalities and Config.GirlSystem.nationalities[1] or "American")
    girlData.status = 'idle'
    girlData.workLocation = nil
    girlData.earnings = 0
    girlData.earningsToday = 0
    girlData.earningsWeek = 0
    girlData.earningsMonth = 0
    girlData.earningsTotal = 0
    girlData.clientsToday = 0
    girlData.clientsWeek = 0
    girlData.clientsMonth = 0
    girlData.clientsTotal = 0
    girlData.totalEarnings = 0
    girlData.pendingEarnings = 0
    girlData.clientsServed = 0
    girlData.loyalty = girlData.attributes and girlData.attributes.loyalty or 50
    girlData.energy = 100
    girlData.reputation = 50
    girlData.happiness = girlData.happiness or 100
    girlData.health = girlData.health or 100
    girlData.hiredDate = os.time()
    girlData.lastWorked = 0
    girlData.hasAttitude = false
    girlData.height = girlData.height or math.random(160, 180)
    girlData.weight = girlData.weight or math.random(50, 70)
    
    -- Ensure attributes exist with all required fields
    if not girlData.attributes then
        girlData.attributes = {
            appearance = math.random(50, 90),
            performance = math.random(50, 90),
            loyalty = math.random(50, 90),
            discretion = math.random(50, 90),
            fear = 0
        }
    else
        -- Ensure all attribute fields exist
        girlData.attributes.fear = girlData.attributes.fear or 0
    end
    
    -- Calculate base price based on type
    local girlTypeConfig = Config.GirlSystem.girlTypes[girlData.type]
    if girlTypeConfig then
        girlData.basePrice = girlTypeConfig.basePrice or 1000
    else
        girlData.basePrice = 1000
    end
    
    girlData.priceTier = "standard"
    
    print("^3[PIMP SYSTEM] Inserting girl into database...^7")
    
    -- Insert girl into database
    MySQL.insert([[
        INSERT INTO pimp_girls (
            owner, name, type, age, nationality, 
            appearance, performance, loyalty, discretion, fear,
            happiness, reputation, base_price, price_tier,
            total_earnings, pending_earnings, clients_served, status,
            height, weight
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        identifier, girlData.name, girlData.type, girlData.age, girlData.nationality,
        girlData.attributes.appearance, girlData.attributes.performance, 
        girlData.attributes.loyalty, girlData.attributes.discretion, girlData.attributes.fear,
        girlData.happiness, girlData.reputation, girlData.basePrice, girlData.priceTier,
        girlData.totalEarnings, girlData.pendingEarnings, girlData.clientsServed, girlData.status,
        girlData.height, girlData.weight
    }, function(insertId)
        if insertId and insertId > 0 then
            print("^2[PIMP SYSTEM] Girl inserted successfully with ID: " .. insertId .. "^7")
            
            -- Set the database ID
            girlData.id = insertId
            
            -- Add to player data
            if not playerData.girls then
                playerData.girls = {}
            end
            table.insert(playerData.girls, girlData)
            
            print("^2[PIMP SYSTEM] Added girl to player data - Total girls: " .. #playerData.girls .. "^7")
            
            -- Update global PlayerData
            if not PlayerData then PlayerData = {} end
            PlayerData[identifier] = playerData
            
            -- Send success notification
            TriggerClientEvent('pimp:girlAddedSuccess', source, girlData)
            
            -- Update client with full player data
            TriggerClientEvent('pimp:updatePlayerData', source, {
                reputation = playerData.reputation or 0,
                earnings = playerData.earnings or {},
                girls = playerData.girls,
                girlsCount = #playerData.girls,
                girlsWorking = 0,
                girlsIdle = #playerData.girls
            })
            
            -- Update active girls for compatibility
            TriggerClientEvent('pimp:updateActiveGirls', source, playerData.girls)
            
            -- Set player data for compatibility
            TriggerClientEvent('pimp:setPlayerData', source, playerData)
            
            print("^2[PIMP SYSTEM] Successfully processed girl addition for player " .. source .. "^7")
        else
            print("^1[PIMP SYSTEM] Error: Failed to insert girl into database^7")
            TriggerClientEvent('pimp:notification', source, 'Failed to add girl to database', 'error')
        end
    end)
end)

-- Enhanced player loaded event to ensure proper data loading
RegisterNetEvent('pimp:playerLoaded')
AddEventHandler('pimp:playerLoaded', function()
    local source = source
    local identifier = GetPlayerIdentifierFromId(source)
    
    print("^2[PIMP SYSTEM] Player " .. source .. " (" .. identifier .. ") loaded, initializing data...^7")
    
    if not identifier then
        print("^1[PIMP SYSTEM] Error: Could not get identifier for player " .. source .. "^7")
        return
    end
    
    -- Load or create player data
    LoadPlayerData(identifier)
    
    -- Wait a moment for data to load, then send to client
    Citizen.SetTimeout(2000, function()
        local playerData = GetPlayerDataSafe(identifier)
        if playerData then
            print("^2[PIMP SYSTEM] Sending initial data to player " .. source .. " - Girls: " .. #(playerData.girls or {}) .. "^7")
            
            -- Send comprehensive data update
            TriggerClientEvent('pimp:updatePlayerData', source, {
                reputation = playerData.reputation or 0,
                earnings = playerData.earnings or {},
                girls = playerData.girls or {},
                girlsCount = #(playerData.girls or {}),
                girlsWorking = 0,
                girlsIdle = #(playerData.girls or {})
            })
            
            TriggerClientEvent('pimp:updateActiveGirls', source, playerData.girls or {})
            TriggerClientEvent('pimp:setPlayerData', source, playerData)
        else
            print("^1[PIMP SYSTEM] Warning: Could not load player data for " .. source .. "^7")
        end
    end)
end)

-- Enhanced get player girls event
RegisterNetEvent('pimp:getPlayerGirls')
AddEventHandler('pimp:getPlayerGirls', function()
    local source = source
    local identifier = GetPlayerIdentifierFromId(source)
    
    print("^3[PIMP SYSTEM] Player " .. source .. " requested girls data^7")
    
    if not identifier then
        print("^1[PIMP SYSTEM] Error: Could not get identifier^7")
        return
    end
    
    -- Load fresh data from database
    MySQL.query('SELECT * FROM pimp_girls WHERE owner = ?', {identifier}, function(result)
        local girls = {}
        
        if result and #result > 0 then
            for _, girlRow in ipairs(result) do
                local girl = {
                    id = girlRow.id,
                    name = girlRow.name,
                    type = girlRow.type,
                    age = girlRow.age,
                    nationality = girlRow.nationality,
                    hireDate = girlRow.hire_date,
                    attributes = {
                        appearance = girlRow.appearance,
                        performance = girlRow.performance,
                        loyalty = girlRow.loyalty,
                        discretion = girlRow.discretion,
                        fear = girlRow.fear or 0
                    },
                    happiness = girlRow.happiness or 50,
                    reputation = girlRow.reputation or 50,
                    basePrice = girlRow.base_price,
                    priceTier = girlRow.price_tier,
                    totalEarnings = girlRow.total_earnings,
                    pendingEarnings = girlRow.pending_earnings,
                    clientsServed = girlRow.clients_served,
                    status = girlRow.status,
                    lastWorkTime = girlRow.last_work_time,
                    hasAttitude = girlRow.has_attitude == 1,
                    workLocation = girlRow.work_location,
                    -- Additional fields for compatibility
                    earnings = girlRow.total_earnings,
                    earningsToday = 0,
                    earningsWeek = 0,
                    earningsMonth = 0,
                    earningsTotal = girlRow.total_earnings,
                    clientsToday = 0,
                    clientsWeek = 0,
                    clientsMonth = 0,
                    clientsTotal = girlRow.clients_served,
                    loyalty = girlRow.loyalty,
                    energy = 100,
                    health = 100,
                    attractiveness = girlRow.appearance,
                    experience = girlRow.performance,
                    skill = girlRow.performance,
                    height = girlRow.height or 170,
                    weight = girlRow.weight or 60
                }
                
                table.insert(girls, girl)
            end
        end
        
        print("^2[PIMP SYSTEM] Loaded " .. #girls .. " girls for player " .. source .. "^7")
        
        -- Update player data
        local playerData = GetPlayerDataSafe(identifier) or {}
        playerData.girls = girls
        
        -- Update global PlayerData
        if not PlayerData then PlayerData = {} end
        PlayerData[identifier] = playerData
        
        -- Send data to client
        TriggerClientEvent('pimp:updatePlayerData', source, {
            reputation = playerData.reputation or 0,
            earnings = playerData.earnings or {},
            girls = girls,
            girlsCount = #girls,
            girlsWorking = 0,
            girlsIdle = #girls
        })
        
        TriggerClientEvent('pimp:updateActiveGirls', source, girls)
        TriggerClientEvent('pimp:setPlayerData', source, playerData)
    end)
end)

-- Helper functions
function GetPlayerIdFromIdentifier(identifier)
    for _, playerId in ipairs(GetPlayers()) do
        local playerIdentifier = GetPlayerIdentifier(playerId, 0)
        if playerIdentifier == identifier then
            return tonumber(playerId)
        end
    end
    return nil
end

function GetPlayerIdentifierFromId(playerId)
    return GetPlayerIdentifier(playerId, 0)
end

function GetPlayerDataSafe(identifier)
    if not identifier then
        return nil
    end
    
    if not PlayerData then
        PlayerData = {}
    end
    
    if not PlayerData[identifier] then
        local source = GetPlayerIdFromIdentifier(identifier)
        if source then
            PlayerData[identifier] = {
                identifier = identifier,
                name = GetPlayerName(source),
                level = 1,
                reputation = 0,
                girls = {},
                earnings = {
                    total = 0,
                    daily = 0,
                    weekly = 0
                }
            }
        else
            return nil
        end
    end
    
    return PlayerData[identifier]
end

function LoadPlayerData(identifier)
    local source = GetPlayerIdFromIdentifier(identifier)
    if not source then return end
    
    if not PlayerData then
        PlayerData = {}
    end
    
    PlayerData[identifier] = {
        identifier = identifier,
        name = GetPlayerName(source),
        level = 1,
        reputation = 0,
        girls = {},
        earnings = {
            total = 0,
            daily = 0,
            weekly = 0
        }
    }
    
    -- Load from database
    MySQL.query('SELECT * FROM pimp_players WHERE identifier = ?', {identifier}, function(result)
        if result and result[1] then
            PlayerData[identifier].level = result[1].level
            PlayerData[identifier].reputation = result[1].reputation
            PlayerData[identifier].earnings.total = result[1].total_earnings
            
            MySQL.update('UPDATE pimp_players SET last_active = CURRENT_TIMESTAMP, name = ? WHERE identifier = ?', 
                {GetPlayerName(source), identifier})
        else
            MySQL.insert('INSERT INTO pimp_players (identifier, name, level, reputation) VALUES (?, ?, ?, ?)', 
                {identifier, GetPlayerName(source), 1, 0})
        end
        
        LoadPlayerGirls(identifier)
    end)
end

-- Update player data in database and memory
function UpdatePlayerData(identifier)
    if not identifier or not PlayerData or not PlayerData[identifier] then
        print("^1Error: Cannot update player data for " .. tostring(identifier) .. " - data not found^7")
        return
    end
    
    local playerData = PlayerData[identifier]
    
    -- Update database
    MySQL.update('UPDATE pimp_players SET level = ?, reputation = ?, total_earnings = ? WHERE identifier = ?', 
        {playerData.level, playerData.reputation, playerData.earnings.total, identifier},
        function(affectedRows)
            if affectedRows == 0 then
                print("^3Warning: No rows updated for player " .. identifier .. "^7")
                -- Insert if not exists
                MySQL.insert('INSERT INTO pimp_players (identifier, name, level, reputation, total_earnings) VALUES (?, ?, ?, ?, ?)', 
                    {identifier, playerData.name, playerData.level, playerData.reputation, playerData.earnings.total})
            end
        end
    )
    
    -- Sync to client
    local source = GetPlayerIdFromIdentifier(identifier)
    if source then
        TriggerClientEvent('pimp:syncPlayerData', source, playerData)
    end
end

function LoadPlayerGirls(identifier)
    if not identifier or not PlayerData or not PlayerData[identifier] then
        print("Error: Cannot load girls for identifier " .. tostring(identifier))
        return
    end
    
    MySQL.query('SELECT * FROM pimp_girls WHERE owner = ?', {identifier}, function(result)
        if result then
            PlayerData[identifier].girls = {}
            
            for _, girl in ipairs(result) do
                table.insert(PlayerData[identifier].girls, {
                    id = girl.id,
                    name = girl.name,
                    type = girl.type,
                    age = girl.age,
                    nationality = girl.nationality,
                    hireDate = girl.hire_date,
                    attributes = {
                        appearance = girl.appearance,
                        performance = girl.performance,
                        loyalty = girl.loyalty,
                        discretion = girl.discretion,
                        fear = girl.fear or 0
                    },
                    happiness = girl.happiness or 50,
                    reputation = girl.reputation or 50,
                    basePrice = girl.base_price,
                    priceTier = girl.price_tier,
                    totalEarnings = girl.total_earnings,
                    pendingEarnings = girl.pending_earnings,
                    clientsServed = girl.clients_served,
                    status = girl.status,
                    lastWorkTime = girl.last_work_time,
                    hasAttitude = girl.has_attitude == 1,
                    workLocation = girl.work_location
                })
            end
        end
        
        local source = GetPlayerIdFromIdentifier(identifier)
        if source then
            TriggerClientEvent('pimp:receivePlayerData', source, PlayerData[identifier])
        end
    end)
end

-- Debug commands
RegisterCommand('servergirlscheck', function(source, args)
    if source == 0 then return end -- Server console only
    
    local identifier = GetPlayerIdentifierFromId(source)
    print("^3=== SERVER GIRLS CHECK ===^7")
    print("^3Player: " .. source .. " (" .. identifier .. ")^7")
    
    -- Check database
    MySQL.query('SELECT COUNT(*) as count FROM pimp_girls WHERE owner = ?', {identifier}, function(result)
        if result and result[1] then
            print("^3Database girls count: " .. result[1].count .. "^7")
        end
    end)
    
    -- Check PlayerData
    if PlayerData and PlayerData[identifier] and PlayerData[identifier].girls then
        print("^3PlayerData girls count: " .. #PlayerData[identifier].girls .. "^7")
        for i, girl in ipairs(PlayerData[identifier].girls) do
            print("^3  " .. i .. ". " .. girl.name .. " (" .. girl.type .. ") - ID: " .. girl.id .. "^7")
        end
    else
        print("^1PlayerData has no girls for this player^7")
    end
    print("^3========================^7")
end, true)

RegisterCommand('reloadplayerdata', function(source, args)
    if source == 0 then return end -- Server console only
    
    local identifier = GetPlayerIdentifierFromId(source)
    print("^3Reloading player data for " .. identifier .. "^7")
    
    LoadPlayerData(identifier)
    
    Citizen.SetTimeout(1000, function()
        TriggerEvent('pimp:getPlayerGirls')
    end)
end, true)

-- Player connection events
RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
    local identifier = xPlayer.getIdentifier()
    LoadPlayerData(identifier)
end)

RegisterNetEvent('QBCore:Server:PlayerLoaded')
AddEventHandler('QBCore:Server:PlayerLoaded', function(Player)
    local identifier = Player.PlayerData.citizenid
    LoadPlayerData(identifier)
end)

AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local source = source
    local identifier = GetPlayerIdentifier(source, 0)
    
    Citizen.Wait(1000)
    
    if identifier and (not PlayerData or not PlayerData[identifier]) then
        LoadPlayerData(identifier)
    end
end)

-- Export functions
exports('AddPlayerMoney', AddPlayerMoney)
exports('RemovePlayerMoney', RemovePlayerMoney)
exports('GetPlayerMoney', GetPlayerMoney)
exports('GetPlayerDataSafe', GetPlayerDataSafe)
exports('LoadPlayerData', LoadPlayerData)