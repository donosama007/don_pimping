-- Pimp Management System - Reputation Perks System
-- Created by Donald Draper
-- Enhanced by NinjaTech AI

-- Local variables
local PlayerPerks = {}

-- SOLUTION 1: Add GetPlayerData function if it doesn't exist elsewhere
-- Uncomment this if GetPlayerData is not defined in another file
--[[
function GetPlayerData(identifier)
    local playerData = nil
    
    MySQL.query('SELECT * FROM pimp_players WHERE identifier = ?', {identifier}, function(result)
        if result and #result > 0 then
            playerData = result[1]
        end
    end)
    
    -- Wait for the query to complete (you might need to adjust this based on your async setup)
    while playerData == nil do
        Wait(0)
    end
    
    return playerData
end
--]]

-- SOLUTION 2: Use export from another resource
-- If GetPlayerData is exported from another resource, uncomment this:
--[[
function GetPlayerData(identifier)
    return exports['your_resource_name']:GetPlayerData(identifier)
end
--]]

-- SOLUTION 3: Direct database query (recommended if GetPlayerData doesn't exist)
function GetPlayerDataAsync(identifier, callback)
    MySQL.query('SELECT * FROM pimp_players WHERE identifier = ?', {identifier}, function(result)
        if result and #result > 0 then
            callback(result[1])
        else
            callback(nil)
        end
    end)
end

-- Initialize player perks
function InitializePlayerPerks(identifier)
    if not PlayerPerks[identifier] then
        PlayerPerks[identifier] = {}
        
        -- Load perks from database
        MySQL.query('SELECT perk_id, category FROM pimp_player_perks WHERE owner = ? AND active = 1', {identifier}, function(result)
            if result and #result > 0 then
                for _, perk in ipairs(result) do
                    if not PlayerPerks[identifier][perk.category] then
                        PlayerPerks[identifier][perk.category] = {}
                    end
                    
                    PlayerPerks[identifier][perk.category][perk.perk_id] = true
                end
            end
        end)
    end
end

-- Get player perks
function GetPlayerPerks(identifier)
    if not PlayerPerks[identifier] then
        InitializePlayerPerks(identifier)
    end
    
    return PlayerPerks[identifier] or {}
end

-- Check if player has a specific perk
function HasPerk(identifier, perkId)
    if not PlayerPerks[identifier] then
        InitializePlayerPerks(identifier)
        return false
    end
    
    -- Check all categories for the perk
    for category, perks in pairs(PlayerPerks[identifier]) do
        if perks[perkId] then
            return true
        end
    end
    
    return false
end

-- Get perk effect value
function GetPerkEffectValue(identifier, effectType)
    if not PlayerPerks[identifier] then
        InitializePlayerPerks(identifier)
        return 0
    end
    
    local totalValue = 0
    
    -- Check all categories and perks for matching effect type
    for category, categoryPerks in pairs(Config.ReputationSystem.perks) do
        for _, perkConfig in ipairs(categoryPerks) do
            -- Check if player has this perk
            if HasPerk(identifier, perkConfig.id) then
                -- Check if effect type matches
                if perkConfig.effect and perkConfig.effect.type == effectType then
                    if type(perkConfig.effect.value) == "number" then
                        totalValue = totalValue + perkConfig.effect.value
                    elseif perkConfig.effect.value == true then
                        return true -- For boolean effects
                    end
                end
            end
        end
    end
    
    return totalValue
end

-- Purchase a perk (FIXED VERSION - Using async approach)
function PurchasePerk(identifier, perkId, category)
    -- Get player data using async approach
    GetPlayerDataAsync(identifier, function(playerData)
        if not playerData then
            local source = GetPlayerSource(identifier)
            if source then
                TriggerClientEvent('pimp:notification', source, "Error", "Player data not found", "error")
            end
            return
        end
        
        -- Find perk in config
        local perkConfig = nil
        for _, perk in ipairs(Config.ReputationSystem.perks[category] or {}) do
            if perk.id == perkId then
                perkConfig = perk
                break
            end
        end
        
        if not perkConfig then
            local source = GetPlayerSource(identifier)
            if source then
                TriggerClientEvent('pimp:notification', source, "Error", "Perk not found", "error")
            end
            return
        end
        
        -- Check if player already has this perk
        if HasPerk(identifier, perkId) then
            local source = GetPlayerSource(identifier)
            if source then
                TriggerClientEvent('pimp:notification', source, "Error", "You already have this perk", "error")
            end
            return
        end
        
        -- Check if player has required level
        if playerData.level < perkConfig.requiredLevel then
            local source = GetPlayerSource(identifier)
            if source then
                TriggerClientEvent('pimp:notification', source, "Error", "You need to be level " .. perkConfig.requiredLevel .. " to purchase this perk", "error")
            end
            return
        end
        
        -- Check if player has required prerequisite perk
        if perkConfig.requiredPerk and not HasPerk(identifier, perkConfig.requiredPerk) then
            local source = GetPlayerSource(identifier)
            if source then
                TriggerClientEvent('pimp:notification', source, "Error", "You need to purchase the prerequisite perk first", "error")
            end
            return
        end
        
        -- Check if player has enough reputation points
        if playerData.reputation < perkConfig.cost then
            local source = GetPlayerSource(identifier)
            if source then
                TriggerClientEvent('pimp:notification', source, "Error", "You don't have enough reputation points", "error")
            end
            return
        end
        
        -- Deduct reputation points
        MySQL.update('UPDATE pimp_players SET reputation = reputation - ? WHERE identifier = ?', 
            {perkConfig.cost, identifier}, function(affectedRows)
            if affectedRows > 0 then
                -- Add perk to database
                MySQL.insert('INSERT INTO pimp_player_perks (owner, perk_id, category) VALUES (?, ?, ?)',
                    {identifier, perkId, category}, function(insertId)
                    if insertId > 0 then
                        -- Update local cache
                        if not PlayerPerks[identifier] then
                            PlayerPerks[identifier] = {}
                        end
                        
                        if not PlayerPerks[identifier][category] then
                            PlayerPerks[identifier][category] = {}
                        end
                        
                        PlayerPerks[identifier][category][perkId] = true
                        
                        -- Update player data
                        playerData.reputation = playerData.reputation - perkConfig.cost
                        
                        -- Notify player
                        local source = GetPlayerSource(identifier)
                        if source then
                            TriggerClientEvent('pimp:notification', source, "Perk Purchased", "You've acquired the " .. perkConfig.name .. " perk!", "success")
                            TriggerClientEvent('pimp:updatePlayerData', source, playerData)
                            TriggerClientEvent('pimp:perkPurchased', source, perkId, category)
                        end
                    end
                end)
            end
        end)
    end)
end

-- Get available perks for player (FIXED VERSION - Using async approach)
function GetAvailablePerks(identifier, callback)
    GetPlayerDataAsync(identifier, function(playerData)
        if not playerData then
            callback({})
            return
        end
        
        local availablePerks = {}
        local playerPerks = GetPlayerPerks(identifier)
        
        -- Process each perk category
        for category, perks in pairs(Config.ReputationSystem.perks) do
            availablePerks[category] = {}
            
            for _, perk in ipairs(perks) do
                local perkData = {
                    id = perk.id,
                    name = perk.name,
                    description = perk.description,
                    icon = perk.icon,
                    cost = perk.cost,
                    requiredLevel = perk.requiredLevel,
                    effect = perk.effect,
                    owned = HasPerk(identifier, perk.id),
                    available = playerData.level >= perk.requiredLevel,
                    affordable = playerData.reputation >= perk.cost,
                    requiredPerk = perk.requiredPerk,
                    hasRequiredPerk = true -- Default to true, will set to false if needed
                }
                
                -- Check if player has required perk
                if perk.requiredPerk and not HasPerk(identifier, perk.requiredPerk) then
                    perkData.hasRequiredPerk = false
                    perkData.available = false
                end
                
                table.insert(availablePerks[category], perkData)
            end
        end
        
        callback(availablePerks)
    end)
end

-- Apply perk effects to a value
function ApplyPerkEffects(identifier, value, effectType)
    local effectValue = GetPerkEffectValue(identifier, effectType)
    
    -- Handle different effect types
    if effectType:find("multiplier") then
        -- Multiplicative effect (e.g., earnings_multiplier)
        return value * (1 + effectValue)
    elseif effectType:find("bonus") then
        -- Additive effect (e.g., negotiation_bonus)
        return value + effectValue
    elseif effectType:find("reduction") then
        -- Reduction effect (e.g., happiness_decay_reduction)
        return value * (1 - effectValue)
    elseif effectType:find("boost") then
        -- Boost effect (e.g., loyalty_gain_boost)
        return value * (1 + effectValue)
    else
        -- Default: return original value
        return value
    end
end

-- FIXED: Get player source from identifier
function GetPlayerSource(identifier)
    for _, playerId in ipairs(GetPlayers()) do
        if GetPlayerIdentifierFromId(playerId) == identifier then
            return playerId
        end
    end
    return nil
end

-- Register server events (FIXED - Using async approach)
RegisterNetEvent('pimp:requestAvailablePerks')
AddEventHandler('pimp:requestAvailablePerks', function()
    local source = source
    local identifier = GetPlayerIdentifierFromId(source)
    
    GetAvailablePerks(identifier, function(availablePerks)
        TriggerClientEvent('pimp:receiveAvailablePerks', source, availablePerks)
    end)
end)

RegisterNetEvent('pimp:purchasePerk')
AddEventHandler('pimp:purchasePerk', function(perkId, category)
    local source = source
    local identifier = GetPlayerIdentifierFromId(source)
    
    PurchasePerk(identifier, perkId, category)
end)

-- Export functions
exports('HasPerk', HasPerk)
exports('GetPerkEffectValue', GetPerkEffectValue)
exports('ApplyPerkEffects', ApplyPerkEffects)