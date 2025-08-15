-- Pimp Management System - Girl Happiness System
-- Created by NinjaTech AI

-- Local variables
local GirlHappiness = {}

-- Initialize girl happiness system
function InitializeGirlHappinessSystem()
    -- Start happiness decay timer
    Citizen.CreateThread(function()
        while true do
            -- Process happiness decay every hour
            ProcessHappinessDecay()
            Citizen.Wait(60 * 60 * 1000) -- 1 hour
        end
    end)
end

-- Process happiness decay for all girls
function ProcessHappinessDecay()
    -- Get all girls
    MySQL.query('SELECT id, owner, name, happiness, status, last_work_time FROM pimp_girls', {}, function(result)
        if result and #result > 0 then
            for _, girl in ipairs(result) do
                -- Skip girls who are currently working
                if girl.status ~= 'working' then
                    -- Calculate idle time in hours
                    local lastWorkTime = girl.last_work_time or os.date("%Y-%m-%d %H:%M:%S")
                    local idleTime = os.difftime(os.time(), os.time(os.date("!*t", lastWorkTime))) / 3600
                    
                    -- Calculate happiness decay
                    local decayRate = Config.HappinessSystem.decayRate or 1 -- Default 1 point per hour
                    local decay = CalculateHappinessDecay(girl, idleTime)
                    
                    -- Apply happiness decay
                    if decay < 0 then
                        -- Get player perks
                        local perkEffect = 0
                        if girl.owner then
                            perkEffect = GetPerkEffectValue(girl.owner, "happiness_decay_reduction") or 0
                        end
                        
                        -- Apply perk effect
                        decay = decay * (1 - perkEffect)
                        
                        -- Update happiness
                        local newHappiness = math.max(0, girl.happiness + decay)
                        
                        -- Update database
                        MySQL.update('UPDATE pimp_girls SET happiness = ? WHERE id = ?', {newHappiness, girl.id})
                        
                        -- Check if happiness reached 0
                        if newHappiness == 0 then
                            -- Process girl leaving
                            ProcessGirlLeaving(girl.id, girl.owner, girl.name)
                        elseif newHappiness <= 20 and girl.happiness > 20 then
                            -- Notify owner that girl is very unhappy
                            local source = GetPlayerSource(girl.owner)
                            if source then
                                TriggerClientEvent('pimp:notification', source, "Girl Unhappy", girl.name .. " is very unhappy and might leave soon if her happiness doesn't improve!", "error")
                            end
                        end
                    end
                end
            end
        end
    end)
end

-- Process girl leaving
function ProcessGirlLeaving(girlId, owner, girlName)
    -- Log the event
    MySQL.insert('INSERT INTO pimp_girl_events (girl_id, event_name, description, happiness_change, loyalty_change) VALUES (?, ?, ?, ?, ?)',
        {girlId, "left", girlName .. " left due to extreme unhappiness", 0, 0})
    
    -- Delete girl from database
    MySQL.update('DELETE FROM pimp_girls WHERE id = ?', {girlId})
    
    -- Notify owner
    local source = GetPlayerSource(owner)
    if source then
        TriggerClientEvent('pimp:notification', source, "Girl Left", girlName .. " has left you due to extreme unhappiness!", "error")
        TriggerClientEvent('pimp:girlLeft', source, girlId, girlName, "unhappiness")
    end
end

-- Add happiness to girl
RegisterNetEvent('pimp:addGirlHappiness')
AddEventHandler('pimp:addGirlHappiness', function(girlId, amount)
    local source = source
    local identifier = GetPlayerIdentifierFromId(source)
    
    -- Validate input
    if not girlId or not amount or amount <= 0 then
        return
    end
    
    -- Check if girl exists and belongs to player
    MySQL.query('SELECT id, name, happiness, owner FROM pimp_girls WHERE id = ?', {girlId}, function(result)
        if result and #result > 0 then
            local girl = result[1]
            
            -- Check ownership
            if girl.owner ~= identifier then
                return
            end
            
            -- Calculate new happiness
            local newHappiness = math.min(100, girl.happiness + amount)
            
            -- Update database
            MySQL.update('UPDATE pimp_girls SET happiness = ? WHERE id = ?', {newHappiness, girlId})
            
            -- Log the event
            MySQL.insert('INSERT INTO pimp_girl_events (girl_id, event_name, description, happiness_change, loyalty_change) VALUES (?, ?, ?, ?, ?)',
                {girlId, "happiness_increase", "Happiness increased by " .. amount, amount, 0})
            
            -- Notify player
            TriggerClientEvent('pimp:notification', source, "Happiness Increased", girl.name .. "'s happiness increased by " .. amount .. " points", "success")
            
            -- Update client
            TriggerClientEvent('pimp:updateGirlData', source, girlId, {happiness = newHappiness})
        end
    end)
end)

-- Remove happiness from girl
RegisterNetEvent('pimp:removeGirlHappiness')
AddEventHandler('pimp:removeGirlHappiness', function(girlId, amount)
    local source = source
    local identifier = GetPlayerIdentifierFromId(source)
    
    -- Validate input
    if not girlId or not amount or amount <= 0 then
        return
    end
    
    -- Check if girl exists and belongs to player
    MySQL.query('SELECT id, name, happiness, owner FROM pimp_girls WHERE id = ?', {girlId}, function(result)
        if result and #result > 0 then
            local girl = result[1]
            
            -- Check ownership
            if girl.owner ~= identifier then
                return
            end
            
            -- Calculate new happiness
            local newHappiness = math.max(0, girl.happiness - amount)
            
            -- Update database
            MySQL.update('UPDATE pimp_girls SET happiness = ? WHERE id = ?', {newHappiness, girlId})
            
            -- Log the event
            MySQL.insert('INSERT INTO pimp_girl_events (girl_id, event_name, description, happiness_change, loyalty_change) VALUES (?, ?, ?, ?, ?)',
                {girlId, "happiness_decrease", "Happiness decreased by " .. amount, -amount, 0})
            
            -- Notify player
            TriggerClientEvent('pimp:notification', source, "Happiness Decreased", girl.name .. "'s happiness decreased by " .. amount .. " points", "warning")
            
            -- Update client
            TriggerClientEvent('pimp:updateGirlData', source, girlId, {happiness = newHappiness})
            
            -- Check if happiness reached 0
            if newHappiness == 0 then
                -- Process girl leaving
                ProcessGirlLeaving(girlId, identifier, girl.name)
            end
        end
    end)
end)

-- Start girl activity
RegisterNetEvent('pimp:startGirlActivity')
AddEventHandler('pimp:startGirlActivity', function(girlId, activityName)
    local source = source
    local identifier = GetPlayerIdentifierFromId(source)
    
    -- Validate input
    if not girlId or not activityName then
        return
    end
    
    -- Check if activity exists
    if not Config.HappinessSystem.activities or not Config.HappinessSystem.activities[activityName] then
        TriggerClientEvent('pimp:notification', source, "Invalid Activity", "This activity doesn't exist", "error")
        return
    end
    
    local activity = Config.HappinessSystem.activities[activityName]
    
    -- Check if girl exists and belongs to player
    MySQL.query('SELECT id, name, happiness, owner FROM pimp_girls WHERE id = ?', {girlId}, function(result)
        if result and #result > 0 then
            local girl = result[1]
            
            -- Check ownership
            if girl.owner ~= identifier then
                return
            end
            
            -- Check if activity is on cooldown
            local cooldownKey = "activity_" .. girlId .. "_" .. activityName
            if IsOnCooldown(identifier, cooldownKey) then
                local remainingTime = GetCooldownRemaining(identifier, cooldownKey)
                TriggerClientEvent('pimp:notification', source, "Activity on Cooldown", "This activity is on cooldown for " .. FormatTime(remainingTime), "error")
                return
            end
            
            -- Check if player can afford activity
            local playerMoney = GetPlayerMoney(identifier)
            if playerMoney < activity.cost then
                TriggerClientEvent('pimp:notification', source, "Cannot Afford", "You don't have enough money for this activity", "error")
                return
            end
            
            -- Deduct money
            if not RemovePlayerMoney(identifier, activity.cost) then
                TriggerClientEvent('pimp:notification', source, "Transaction Failed", "Failed to deduct money", "error")
                return
            end
            
            -- Calculate end time
            local endTime = os.time() + (activity.duration * 60)
            
            -- Insert activity into database
            MySQL.insert('INSERT INTO pimp_girl_activities (girl_id, activity_name, end_time, happiness_gain, cost) VALUES (?, ?, ?, ?, ?)',
                {girlId, activityName, os.date("%Y-%m-%d %H:%M:%S", endTime), activity.happinessGain, activity.cost})
            
            -- Set cooldown
            SetCooldown(identifier, cooldownKey, activity.cooldown * 60)
            
            -- Notify player
            TriggerClientEvent('pimp:notification', source, "Activity Started", girl.name .. " has started " .. activityName .. " activity", "success")
            
            -- Schedule activity completion
            Citizen.SetTimeout(activity.duration * 60 * 1000, function()
                CompleteGirlActivity(girlId, activityName, activity.happinessGain, identifier)
            end)
        end
    end)
end)

-- Complete girl activity
function CompleteGirlActivity(girlId, activityName, happinessGain, identifier)
    -- Check if girl still exists
    MySQL.query('SELECT id, name, happiness, owner FROM pimp_girls WHERE id = ?', {girlId}, function(result)
        if result and #result > 0 then
            local girl = result[1]
            
            -- Calculate new happiness
            local newHappiness = math.min(100, girl.happiness + happinessGain)
            
            -- Update database
            MySQL.update('UPDATE pimp_girls SET happiness = ? WHERE id = ?', {newHappiness, girlId})
            
            -- Log the event
            MySQL.insert('INSERT INTO pimp_girl_events (girl_id, event_name, description, happiness_change, loyalty_change) VALUES (?, ?, ?, ?, ?)',
                {girlId, "activity_completed", "Completed " .. activityName .. " activity", happinessGain, 0})
            
            -- Notify player
            local source = GetPlayerSource(identifier)
            if source then
                TriggerClientEvent('pimp:notification', source, "Activity Completed", girl.name .. " has completed " .. activityName .. " activity and gained " .. happinessGain .. " happiness", "success")
                
                -- Update client
                TriggerClientEvent('pimp:updateGirlData', source, girlId, {happiness = newHappiness})
            end
        end
    end)
end

-- Get girl happiness methods
function GetGirlHappinessMethods()
    local methods = {}
    
    -- Add activities from config
    if Config.HappinessSystem and Config.HappinessSystem.activities then
        for name, activity in pairs(Config.HappinessSystem.activities) do
            table.insert(methods, {
                name = name,
                displayName = activity.displayName or name:gsub("^%l", string.upper):gsub("_", " "),
                description = activity.description or "No description",
                happinessGain = activity.happinessGain,
                cost = activity.cost,
                duration = activity.duration,
                cooldown = activity.cooldown
            })
        end
    end
    
    return methods
end

-- Get girl happiness methods for client
RegisterNetEvent('pimp:requestHappinessMethods')
AddEventHandler('pimp:requestHappinessMethods', function()
    local source = source
    local methods = GetGirlHappinessMethods()
    TriggerClientEvent('pimp:receiveHappinessMethods', source, methods)
end)

-- Initialize happiness system on resource start
Citizen.CreateThread(function()
    Citizen.Wait(1000) -- Wait for database to be ready
    InitializeGirlHappinessSystem()
end)

-- Export functions
exports('ProcessHappinessDecay', ProcessHappinessDecay)
exports('ProcessGirlLeaving', ProcessGirlLeaving)
exports('GetGirlHappinessMethods', GetGirlHappinessMethods)