-- Pimp Management System - Girl Management
-- Created by Donald Draper
-- Optimized by NinjaTech AI

-- Local variables
local GirlNames = Config.GirlSystem.names
local GirlNationalities = Config.GirlSystem.nationalities
local GirlTypes = Config.GirlSystem.girlTypes

-- Generate random girl
function GenerateRandomGirl(girlType)
    -- Default to random type if not specified
    if not girlType or not GirlTypes[girlType] then
        local types = {}
        for type, _ in pairs(GirlTypes) do
            table.insert(types, type)
        end
        girlType = GetRandomFromTable(types)
    end
    
    -- Get type configuration
    local typeConfig = GirlTypes[girlType]
    
    -- Generate random attributes
    local appearance = math.random(typeConfig.attributes.appearance.min, typeConfig.attributes.appearance.max)
    local performance = math.random(typeConfig.attributes.performance.min, typeConfig.attributes.performance.max)
    local loyalty = math.random(typeConfig.attributes.loyalty.min, typeConfig.attributes.loyalty.max)
    local discretion = math.random(typeConfig.attributes.discretion.min, typeConfig.attributes.discretion.max)
    
    -- Generate random name
    local name = GetRandomFromTable(GirlNames)
    
    -- Generate random age (21-35)
    local age = math.random(21, 35)
    
    -- Generate random nationality
    local nationality = GetRandomFromTable(GirlNationalities)
    
    -- Calculate base price
    local basePrice = typeConfig.basePrice + math.random(-500, 500)
    
    -- Create girl object
    local girl = {
        name = name,
        type = girlType,
        age = age,
        nationality = nationality,
        attributes = {
            appearance = appearance,
            performance = performance,
            loyalty = loyalty,
            discretion = discretion,
            fear = 0
        },
        happiness = 50,
        reputation = 50,
        basePrice = basePrice,
        priceTier = "standard",
        totalEarnings = 0,
        pendingEarnings = 0,
        clientsServed = 0,
        status = "idle"
    }
    
    return girl
end

-- Purchase girl
RegisterNetEvent('pimp:purchaseGirl')
AddEventHandler('pimp:purchaseGirl', function(girlType, price)
    local source = source
    local identifier = GetPlayerIdentifierFromId(source)
    
    -- Validate input
    if not girlType or not price then
        TriggerClientEvent('pimp:notification', source, 'Invalid input', 'error')
        return
    end
    
    -- Check if girl type exists
    if not GirlTypes[girlType] then
        TriggerClientEvent('pimp:notification', source, 'Invalid girl type', 'error')
        return
    end
    
    -- Get player data
    local playerData = GetPlayerDataSafe(identifier)
    if not playerData then
        TriggerClientEvent('pimp:notification', source, 'Player data not found', 'error')
        return
    end
    
    -- Check if player has reached the maximum number of girls
    local maxGirls = GetMaxGirls(playerData.reputation)
    if #playerData.girls >= maxGirls then
        TriggerClientEvent('pimp:notification', source, 'You have reached the maximum number of girls (' .. maxGirls .. ')', 'error')
        return
    end
    
    -- Check if player has enough money
    if GetPlayerMoney(identifier) < price then
        TriggerClientEvent('pimp:notification', source, 'You don\'t have enough money', 'error')
        return
    end
    
    -- Generate random girl
    local girl = GenerateRandomGirl(girlType)
    
    -- Remove money from player
    if not RemovePlayerMoney(identifier, price) then
        TriggerClientEvent('pimp:notification', source, 'Failed to remove money', 'error')
        return
    end
    
    -- Add girl to database
    MySQL.insert('INSERT INTO pimp_girls (owner, name, type, age, nationality, appearance, performance, loyalty, discretion, fear, happiness, reputation, base_price, price_tier) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', 
        {identifier, girl.name, girl.type, girl.age, girl.nationality, girl.attributes.appearance, girl.attributes.performance, girl.attributes.loyalty, girl.attributes.discretion, girl.attributes.fear, girl.happiness, girl.reputation, girl.basePrice, girl.priceTier}, 
        function(girlId)
            if girlId > 0 then
                -- Set girl ID
                girl.id = girlId
                
                -- Add girl to player data
                table.insert(playerData.girls, girl)
                
                -- Add to shop history
                MySQL.insert('INSERT INTO pimp_shop_history (owner, girl_name, girl_type, price) VALUES (?, ?, ?, ?)', 
                    {identifier, girl.name, girl.type, price})
                
                -- Add transaction to database
                MySQL.insert('INSERT INTO pimp_transactions (owner, type, amount, details) VALUES (?, ?, ?, ?)', 
                    {identifier, 'expense', price, 'Purchased girl: ' .. girl.name})
                
                -- Update player data
                UpdatePlayerData(identifier)
                
                -- Send notification
                TriggerClientEvent('pimp:notification', source, 'You purchased ' .. girl.name .. ' for $' .. price, 'success')
            else
                -- Failed to add girl to database
                TriggerClientEvent('pimp:notification', source, 'Failed to purchase girl', 'error')
                
                -- Refund money
                AddPlayerMoney(identifier, price)
            end
        end
    )
end)

-- Set girl to work
RegisterNetEvent('pimp:setGirlToWork')
AddEventHandler('pimp:setGirlToWork', function(girlId, locationName)
    local source = source
    local identifier = GetPlayerIdentifierFromId(source)
    
    -- Validate input
    if not girlId or not locationName then
        TriggerClientEvent('pimp:notification', source, 'Invalid input', 'error')
        return
    end
    
    -- Get player data
    local playerData = GetPlayerDataSafe(identifier)
    if not playerData then
        TriggerClientEvent('pimp:notification', source, 'Player data not found', 'error')
        return
    end
    
    -- Find girl
    local girlIndex = nil
    local girl = nil
    for i, g in ipairs(playerData.girls) do
        if g.id == girlId then
            girlIndex = i
            girl = g
            break
        end
    end
    
    if not girl then
        TriggerClientEvent('pimp:notification', source, 'Girl not found', 'error')
        return
    end
    
    -- Check if girl is already working
    if girl.status == 'working' then
        TriggerClientEvent('pimp:notification', source, girl.name .. ' is already working', 'error')
        return
    end
    
    -- Check if girl is on cooldown
    if playerData.cooldowns and playerData.cooldowns['work_' .. girlId] then
        local cooldownTime = GetCooldownTimeRemaining(playerData.cooldowns['work_' .. girlId])
        TriggerClientEvent('pimp:notification', source, girl.name .. ' needs to rest for ' .. cooldownTime, 'error')
        return
    end
    
    -- Find location
    local location = nil
    for _, loc in ipairs(Config.WorkLocations) do
        if loc.name == locationName then
            location = loc
            break
        end
    end
    
    if not location then
        TriggerClientEvent('pimp:notification', source, 'Location not found', 'error')
        return
    end
    
    -- Set girl to work
    girl.status = 'working'
    girl.workLocation = locationName
    
    -- Update database
    MySQL.update('UPDATE pimp_girls SET status = ?, last_work_time = CURRENT_TIMESTAMP WHERE id = ?', 
        {'working', girlId})
    
    -- Add cooldown for work duration
    local workDuration = Config.GirlSystem.workDuration * 60 * 1000 -- Convert minutes to milliseconds
    AddCooldown(identifier, 'work_duration_' .. girlId, workDuration)
    
    -- Start earnings thread
    StartGirlEarningsThread(identifier, girlId, locationName)
    
    -- Update player data
    UpdatePlayerData(identifier)
    
    -- Send notification
    TriggerClientEvent('pimp:notification', source, girl.name .. ' is now working at ' .. locationName, 'success')
end)

-- Start girl earnings thread
function StartGirlEarningsThread(identifier, girlId, locationName)
    Citizen.CreateThread(function()
        -- Get player data
        local playerData = GetPlayerDataSafe(identifier)
        if not playerData then
            return
        end
        
        -- Find girl
        local girl = nil
        for _, g in ipairs(playerData.girls) do
            if g.id == girlId then
                girl = g
                break
            end
        end
        
        if not girl then
            return
        end
        
        -- Find location
        local location = nil
        for _, loc in ipairs(Config.WorkLocations) do
            if loc.name == locationName then
                location = loc
                break
            end
        end
        
        if not location then
            return
        end
        
        -- Calculate work duration
        local workDuration = Config.GirlSystem.workDuration * 60 -- Convert minutes to seconds
        local earnInterval = 300 -- 5 minutes in seconds
        local totalEarnings = 0
        local clientsServed = 0
        
        -- Work loop
        local startTime = os.time()
        local endTime = startTime + workDuration
        local nextEarnTime = startTime + earnInterval
        
        while os.time() < endTime do
            -- Wait for next earn interval
            Citizen.Wait(1000) -- Check every second
            
            -- Check if it's time to earn
            if os.time() >= nextEarnTime then
                -- Calculate earnings
                local baseEarnings = CalculateGirlEarnings(girl, location)
                
                -- Add earnings
                AddGirlEarnings(identifier, girlId, baseEarnings, locationName)
                
                -- Update totals
                totalEarnings = totalEarnings + baseEarnings
                clientsServed = clientsServed + 1
                
                -- Set next earn time
                nextEarnTime = nextEarnTime + earnInterval
            end
        end
        
        -- Work completed
        CompleteGirlWork(identifier, girlId, totalEarnings, clientsServed)
    end)
end

-- Calculate girl earnings
function CalculateGirlEarnings(girl, location)
    -- Base earnings
    local baseEarnings = 0
    
    -- Get girl type base earnings
    if GirlTypes[girl.type] then
        baseEarnings = GirlTypes[girl.type].baseEarnings
    else
        baseEarnings = 100 -- Default base earnings
    end
    
    -- Apply attribute modifiers
    local appearanceModifier = girl.attributes.appearance / 50 -- 0.2 to 2.0
    local performanceModifier = girl.attributes.performance / 50 -- 0.2 to 2.0
    
    -- Apply location modifier
    local locationModifier = location.earningsMultiplier
    
    -- Apply happiness modifier
    local happinessModifier = 1.0
    if Config.HappinessSystem and Config.HappinessSystem.enabled then
        happinessModifier = GetHappinessEarningsMultiplier(girl.happiness or 50)
    end
    
    -- Calculate final earnings
    local finalEarnings = baseEarnings * appearanceModifier * performanceModifier * locationModifier * happinessModifier
    
    -- Round to nearest whole number
    return math.floor(finalEarnings + 0.5)
end

-- Add girl earnings
function AddGirlEarnings(identifier, girlId, amount, locationName)
    -- Get player data
    local playerData = GetPlayerDataSafe(identifier)
    if not playerData then
        return
    end
    
    -- Find girl
    local girl = nil
    for _, g in ipairs(playerData.girls) do
        if g.id == girlId then
            girl = g
            break
        end
    end
    
    if not girl then
        return
    end
    
    -- Add earnings to girl
    girl.pendingEarnings = (girl.pendingEarnings or 0) + amount
    
    -- Update database
    MySQL.update('UPDATE pimp_girls SET pending_earnings = pending_earnings + ? WHERE id = ?', 
        {amount, girlId})
    
    -- Add to earnings history
    MySQL.insert('INSERT INTO pimp_earnings (owner, girl_id, girl_name, amount, location) VALUES (?, ?, ?, ?, ?)', 
        {identifier, girlId, girl.name, amount, locationName})
    
    -- Update player data
    UpdatePlayerData(identifier)
    
    -- Send notification to player
    local source = GetPlayerIdFromIdentifier(identifier)
    if source then
        TriggerClientEvent('pimp:girlServedClientResult', source, girlId, amount)
    end
end

-- Complete girl work
function CompleteGirlWork(identifier, girlId, totalEarnings, clientsServed)
    -- Get player data
    local playerData = GetPlayerDataSafe(identifier)
    if not playerData then
        return
    end
    
    -- Find girl
    local girl = nil
    for _, g in ipairs(playerData.girls) do
        if g.id == girlId then
            girl = g
            break
        end
    end
    
    if not girl then
        return
    end
    
    -- Update girl status
    girl.status = 'idle'
    girl.workLocation = nil
    girl.totalEarnings = (girl.totalEarnings or 0) + totalEarnings
    girl.clientsServed = (girl.clientsServed or 0) + clientsServed
    
    -- Calculate happiness change
    local happinessChange = 0
    if Config.HappinessSystem and Config.HappinessSystem.enabled then
        happinessChange = CalculateHappinessChange(girl, Config.GirlSystem.workDuration * 60, nil)
        girl.happiness = math.max(0, math.min(100, (girl.happiness or 50) + happinessChange))
    end
    
    -- Update database
    MySQL.update('UPDATE pimp_girls SET status = ?, total_earnings = total_earnings + ?, clients_served = clients_served + ?, happiness = ? WHERE id = ?', 
        {'idle', totalEarnings, clientsServed, girl.happiness, girlId})
    
    -- Update player earnings
    playerData.earnings.total = (playerData.earnings.total or 0) + totalEarnings
    playerData.earnings.daily = (playerData.earnings.daily or 0) + totalEarnings
    playerData.earnings.weekly = (playerData.earnings.weekly or 0) + totalEarnings
    
    -- Update player database
    MySQL.update('UPDATE pimp_players SET total_earnings = total_earnings + ? WHERE identifier = ?', 
        {totalEarnings, identifier})
    
    -- Add cooldown for rest period
    local restDuration = Config.GirlSystem.workCooldown * 60 * 1000 -- Convert minutes to milliseconds
    AddCooldown(identifier, 'work_' .. girlId, restDuration)
    
    -- Update player data
    UpdatePlayerData(identifier)
    
    -- Send notification to player
    local source = GetPlayerIdFromIdentifier(identifier)
    if source then
        -- Send basic notification
        TriggerClientEvent('pimp:notification', source, girl.name .. ' has finished working and earned $' .. totalEarnings, 'success')
        
        -- Send detailed completion notification with location info
        TriggerClientEvent('pimp:girlCompletedWork', source, girlId, totalEarnings, clientsServed, girl.workLocation or "Unknown Location")
        
        -- Send happiness notification if changed
        if happinessChange and happinessChange < 0 then
            TriggerClientEvent('pimp:notification', source, girl.name .. '\'s happiness decreased by ' .. math.abs(happinessChange) .. ' points due to working', 'info')
        end
    end
end

-- Girl served client
RegisterNetEvent('pimp:girlServedClient')
AddEventHandler('pimp:girlServedClient', function(girlId, locationName, negotiatedPrice)
    local source = source
    local identifier = GetPlayerIdentifierFromId(source)
    
    -- Validate input
    if not girlId or not locationName then
        return
    end
    
    -- Get player data
    local playerData = GetPlayerDataSafe(identifier)
    if not playerData then
        return
    end
    
    -- Find girl
    local girl = nil
    for _, g in ipairs(playerData.girls) do
        if g.id == girlId then
            girl = g
            break
        end
    end
    
    if not girl then
        return
    end
    
    -- Find location
    local location = nil
    for _, loc in ipairs(Config.WorkLocations) do
        if loc.name == locationName then
            location = loc
            break
        end
    end
    
    if not location then
        return
    end
    
    -- Calculate earnings (use negotiated price if provided)
    local earnings = negotiatedPrice
    if not earnings or earnings <= 0 then
        earnings = CalculateGirlEarnings(girl, location)
    end
    
    -- Add earnings
    AddGirlEarnings(identifier, girlId, earnings, locationName)
    
    -- Update clients served
    MySQL.update('UPDATE pimp_girls SET clients_served = clients_served + 1 WHERE id = ?', 
        {girlId})
    
    -- Add reputation
    if Config.ReputationSystem and Config.ReputationSystem.enabled then
        local repGain = CalculateReputationGain(girl, nil, location)
        AddReputation(identifier, repGain)
    end
end)

-- Set girl status
RegisterNetEvent('pimp:setGirlStatus')
AddEventHandler('pimp:setGirlStatus', function(girlId, status)
    local source = source
    local identifier = GetPlayerIdentifierFromId(source)
    
    -- Validate input
    if not girlId or not status then
        TriggerClientEvent('pimp:notification', source, 'Invalid input', 'error')
        return
    end
    
    -- Get player data
    local playerData = GetPlayerDataSafe(identifier)
    if not playerData then
        TriggerClientEvent('pimp:notification', source, 'Player data not found', 'error')
        return
    end
    
    -- Find girl
    local girl = nil
    for _, g in ipairs(playerData.girls) do
        if g.id == girlId then
            girl = g
            break
        end
    end
    
    if not girl then
        TriggerClientEvent('pimp:notification', source, 'Girl not found', 'error')
        return
    end
    
    -- Set girl status
    girl.status = status
    
    -- Update database
    MySQL.update('UPDATE pimp_girls SET status = ? WHERE id = ?', 
        {status, girlId})
    
    -- Update player data
    UpdatePlayerData(identifier)
end)

-- Start girl activity
RegisterNetEvent('pimp:startGirlActivity')
AddEventHandler('pimp:startGirlActivity', function(girlId, activityName)
    local source = source
    local identifier = GetPlayerIdentifierFromId(source)
    
    -- Validate input
    if not girlId or not activityName then
        TriggerClientEvent('pimp:notification', source, 'Invalid input', 'error')
        return
    end
    
    -- Get player data
    local playerData = GetPlayerDataSafe(identifier)
    if not playerData then
        TriggerClientEvent('pimp:notification', source, 'Player data not found', 'error')
        return
    end
    
    -- Find girl
    local girl = nil
    for _, g in ipairs(playerData.girls) do
        if g.id == girlId then
            girl = g
            break
        end
    end
    
    if not girl then
        TriggerClientEvent('pimp:notification', source, 'Girl not found', 'error')
        return
    end
    
    -- Check if activity exists
    if not Config.HappinessSystem or not Config.HappinessSystem.activities or not Config.HappinessSystem.activities[activityName] then
        TriggerClientEvent('pimp:notification', source, 'Activity not found', 'error')
        return
    end
    
    local activity = Config.HappinessSystem.activities[activityName]
    
    -- Check if activity is on cooldown
    local cooldownKey = "activity_" .. girlId .. "_" .. activityName
    if playerData.cooldowns and playerData.cooldowns[cooldownKey] then
        local cooldownTime = GetCooldownTimeRemaining(playerData.cooldowns[cooldownKey])
        TriggerClientEvent('pimp:notification', source, 'This activity is on cooldown for ' .. cooldownTime, 'error')
        return
    end
    
    -- Check if player has enough money
    if GetPlayerMoney(identifier) < activity.cost then
        TriggerClientEvent('pimp:notification', source, 'You don\'t have enough money', 'error')
        return
    end
    
    -- Remove money from player
    if not RemovePlayerMoney(identifier, activity.cost) then
        TriggerClientEvent('pimp:notification', source, 'Failed to remove money', 'error')
        return
    end
    
    -- Add happiness to girl
    local newHappiness = math.min(100, (girl.happiness or 50) + activity.happinessGain)
    girl.happiness = newHappiness
    
    -- Update database
    MySQL.update('UPDATE pimp_girls SET happiness = ? WHERE id = ?', 
        {newHappiness, girlId})
    
    -- Add activity to database
    local endTime = os.time() + activity.duration * 60 -- Convert minutes to seconds
    MySQL.insert('INSERT INTO pimp_girl_activities (girl_id, activity_name, start_time, end_time, happiness_gain, cost) VALUES (?, ?, CURRENT_TIMESTAMP, FROM_UNIXTIME(?), ?, ?)', 
        {girlId, activityName, endTime, activity.happinessGain, activity.cost})
    
    -- Add cooldown
    local cooldownDuration = activity.cooldown * 60 * 1000 -- Convert minutes to milliseconds
    AddCooldown(identifier, cooldownKey, cooldownDuration)
    
    -- Add transaction to database
    MySQL.insert('INSERT INTO pimp_transactions (owner, type, amount, details) VALUES (?, ?, ?, ?)', 
        {identifier, 'expense', activity.cost, 'Activity: ' .. activityName .. ' for ' .. girl.name})
    
    -- Update player data
    UpdatePlayerData(identifier)
    
    -- Send notification
    TriggerClientEvent('pimp:notification', source, girl.name .. ' is now enjoying a ' .. activityName .. ' (+' .. activity.happinessGain .. ' happiness)', 'success')
end)

-- Upgrade girl attribute
RegisterNetEvent('pimp:upgradeGirlAttribute')
AddEventHandler('pimp:upgradeGirlAttribute', function(girlId, attribute, cost)
    local source = source
    local identifier = GetPlayerIdentifierFromId(source)
    
    -- Validate input
    if not girlId or not attribute or not cost then
        TriggerClientEvent('pimp:notification', source, 'Invalid input', 'error')
        return
    end
    
    -- Get player data
    local playerData = GetPlayerDataSafe(identifier)
    if not playerData then
        TriggerClientEvent('pimp:notification', source, 'Player data not found', 'error')
        return
    end
    
    -- Find girl
    local girl = nil
    for _, g in ipairs(playerData.girls) do
        if g.id == girlId then
            girl = g
            break
        end
    end
    
    if not girl then
        TriggerClientEvent('pimp:notification', source, 'Girl not found', 'error')
        return
    end
    
    -- Check if attribute exists
    if not girl.attributes[attribute] then
        TriggerClientEvent('pimp:notification', source, 'Attribute not found', 'error')
        return
    end
    
    -- Check if attribute is at max level
    local maxValue = Config.GirlSystem.attributes.maxValue or 100
    if girl.attributes[attribute] >= maxValue then
        TriggerClientEvent('pimp:notification', source, 'Attribute is already at maximum level', 'error')
        return
    end
    
    -- Check if player has enough money
    if GetPlayerMoney(identifier) < cost then
        TriggerClientEvent('pimp:notification', source, 'You don\'t have enough money', 'error')
        return
    end
    
    -- Remove money from player
    if not RemovePlayerMoney(identifier, cost) then
        TriggerClientEvent('pimp:notification', source, 'Failed to remove money', 'error')
        return
    end
    
    -- Upgrade attribute
    local increment = Config.GirlSystem.attributes.levelUpIncrement or 5
    local newValue = math.min(maxValue, girl.attributes[attribute] + increment)
    girl.attributes[attribute] = newValue
    
    -- Update database
    local columnName = attribute
    MySQL.update('UPDATE pimp_girls SET ' .. columnName .. ' = ? WHERE id = ?', 
        {newValue, girlId})
    
    -- Add transaction to database
    MySQL.insert('INSERT INTO pimp_transactions (owner, type, amount, details) VALUES (?, ?, ?, ?)', 
        {identifier, 'expense', cost, 'Upgraded ' .. attribute .. ' for ' .. girl.name})
    
    -- Update player data
    UpdatePlayerData(identifier)
    
    -- Send notification
    TriggerClientEvent('pimp:notification', source, girl.name .. '\'s ' .. attribute .. ' increased to ' .. newValue, 'success')
end)

-- Add happiness to girl
function AddHappiness(girlId, amount)
    -- Get girl from database
    MySQL.query('SELECT * FROM pimp_girls WHERE id = ?', {girlId}, function(result)
        if result and result[1] then
            local girl = result[1]
            local newHappiness = math.min(100, math.max(0, (girl.happiness or 50) + amount))
            
            -- Update database
            MySQL.update('UPDATE pimp_girls SET happiness = ? WHERE id = ?', 
                {newHappiness, girlId})
            
            -- Update player data if online
            local owner = girl.owner
            if PlayerData[owner] then
                for i, g in ipairs(PlayerData[owner].girls) do
                    if g.id == girlId then
                        PlayerData[owner].girls[i].happiness = newHappiness
                        break
                    end
                end
                
                UpdatePlayerData(owner)
            end
        end
    end)
end

-- Remove happiness from girl
function RemoveHappiness(girlId, amount)
    AddHappiness(girlId, -amount)
end

-- Helper function to get a girl by ID from player data
function GetGirlById(identifier, girlId)
    if not identifier or not PlayerData or not PlayerData[identifier] then
        return nil, nil
    end
    
    for i, girl in ipairs(PlayerData[identifier].girls or {}) do
        if girl.id == girlId then
            return girl, i
        end
    end
    
    return nil, nil
end
-- Discipline girl
RegisterNetEvent('pimp:disciplineGirl')
AddEventHandler('pimp:disciplineGirl', function(girlId, disciplineType)
    local source = source
    local identifier = GetPlayerIdentifierFromId(source)
    
    if not identifier or not PlayerData or not PlayerData[identifier] then
        TriggerClientEvent('pimp:notification', source, 'Error loading player data', 'error')
        return
    end
    
    -- Find girl in player data
    local girl, girlIndex = GetGirlById(identifier, girlId)
    
    if not girl then
        TriggerClientEvent('pimp:notification', source, 'Girl not found', 'error')
        return
    end
    
    -- Get discipline config
    if not Config.NPCInteraction.Discipline or not Config.NPCInteraction.Discipline.types[disciplineType] then
        TriggerClientEvent('pimp:notification', source, 'Invalid discipline type', 'error')
        return
    end
    
    local disciplineConfig = Config.NPCInteraction.Discipline.types[disciplineType]
    
    -- Calculate attribute changes based on discipline type
    local loyaltyChange = disciplineConfig.loyaltyChange or 0
    local fearChange = disciplineConfig.fearChange or 0
    
    -- Calculate new values
    local newLoyalty = math.max(0, math.min(100, girl.attributes.loyalty + loyaltyChange))
    local newFear = math.max(0, math.min(100, girl.attributes.fear + fearChange))
    
    -- Check for attitude improvement
    local attitudeImproved = false
    if girl.hasAttitude and Config.NPCInteraction.Discipline.attitudeCorrection and Config.NPCInteraction.Discipline.attitudeCorrection[disciplineType] then
        local correctionChance = Config.NPCInteraction.Discipline.attitudeCorrection[disciplineType]
        if math.random() < correctionChance then
            attitudeImproved = true
            PlayerData[identifier].girls[girlIndex].hasAttitude = false
        end
    end
    
    -- Update girl attributes
    PlayerData[identifier].girls[girlIndex].attributes.loyalty = newLoyalty
    PlayerData[identifier].girls[girlIndex].attributes.fear = newFear
    
    -- Update database
    MySQL.update('UPDATE pimp_girls SET loyalty = ?, fear = ?, has_attitude = ? WHERE id = ?', 
        {newLoyalty, newFear, attitudeImproved and 0 or (girl.hasAttitude and 1 or 0), girlId})
    
    -- Log discipline action
    MySQL.insert('INSERT INTO pimp_discipline_log (owner, girl_id, discipline_type, loyalty_change, fear_change, attitude_improved) VALUES (?, ?, ?, ?, ?, ?)',
        {identifier, girlId, disciplineType, loyaltyChange, fearChange, attitudeImproved and 1 or 0})
    
    -- Update player data
    UpdatePlayerData(identifier)
    
    -- Send result to client
    TriggerClientEvent('pimp:disciplineResult', source, girlId, girl.name, disciplineType, loyaltyChange, fearChange, attitudeImproved)
    
    -- Send detailed notification about attribute changes
    local message = 'You disciplined ' .. girl.name
    
    -- Add attribute change details
    if loyaltyChange ~= 0 then
        message = message .. '\nLoyalty: ' .. (loyaltyChange > 0 and '+' or '') .. loyaltyChange .. ' (' .. newLoyalty .. '/100)'
    end
    
    if fearChange ~= 0 then
        message = message .. '\nFear: ' .. (fearChange > 0 and '+' or '') .. fearChange .. ' (' .. newFear .. '/100)'
    end
    
    if attitudeImproved then
        message = message .. '\nAttitude improved!'
    end
    
    -- Send notification with appropriate type based on discipline
    local notificationType = 'info'
    if disciplineType == 'slap' then
        notificationType = 'warning'
    elseif disciplineType == 'threaten' then
        notificationType = 'error'
    end
    
    TriggerClientEvent('pimp:notification', source, message, notificationType)
end)

-- Export functions
-- Assign girl to territory
RegisterNetEvent('pimp:assignGirlToTerritory')
AddEventHandler('pimp:assignGirlToTerritory', function(girlId, territoryName)
    local source = source
    local identifier = GetPlayerIdentifierFromId(source)
    
    if not identifier then return end
    
    -- Check if territory exists
    if not Territories[territoryName] then
        TriggerClientEvent('pimp:notification', source, "Territory Assignment", "This territory doesn't exist", "error")
        return
    end
    
    -- Check if player owns the territory
    if not PlayerTerritories[identifier] or not PlayerTerritories[identifier][territoryName] then
        TriggerClientEvent('pimp:notification', source, "Territory Assignment", "You don't own this territory", "error")
        return
    end
    
    -- Check if territory is contested
    if PlayerTerritories[identifier][territoryName].contested then
        TriggerClientEvent('pimp:notification', source, "Territory Assignment", "This territory is contested and cannot be used", "error")
        return
    end
    
    -- Get the girl
    local girl = nil
    if PlayerData[identifier] and PlayerData[identifier].girls then
        for _, g in ipairs(PlayerData[identifier].girls) do
            if g.id == girlId then
                girl = g
                break
            end
        end
    end
    
    if not girl then
        TriggerClientEvent('pimp:notification', source, "Territory Assignment", "Girl not found", "error")
        return
    end
    
    -- Check if girl is available
    if girl.status ~= 'idle' and girl.status ~= nil then
        TriggerClientEvent('pimp:notification', source, "Territory Assignment", girl.name .. " is not available (Status: " .. girl.status .. ")", "error")
        return
    end
    
    -- Check how many girls are already working in this territory
    local girlsInTerritory = 0
    MySQL.query('SELECT COUNT(*) as count FROM pimp_girls WHERE owner = ? AND workLocation = ?', 
        {identifier, territoryName}, function(result)
        if result and result[1] then
            girlsInTerritory = result[1].count
            
            -- Check if territory is at max capacity
            local maxGirls = Config.TerritorySystem.maxGirlsPerTerritory or 3
            if girlsInTerritory >= maxGirls then
                TriggerClientEvent('pimp:notification', source, "Territory Assignment", "This territory already has the maximum number of girls (" .. maxGirls .. ")", "error")
                return
            end
            
            -- Update girl status
            MySQL.update('UPDATE pimp_girls SET status = ?, work_location = ? WHERE id = ?', 
                {'working', territoryName, girlId}, function()
                -- Update local data
                for i, g in ipairs(PlayerData[identifier].girls) do
                    if g.id == girlId then
                        PlayerData[identifier].girls[i].status = 'working'
                        PlayerData[identifier].girls[i].workLocation = territoryName
                        break
                    end
                end
                
                -- Notify player
                TriggerClientEvent('pimp:notification', source, "Territory Assignment", girl.name .. " is now working in " .. territoryName, "success")
                
                -- Update client
                UpdatePlayerData(identifier)
                
                -- Spawn girl in territory for all nearby players
                local territory = Territories[territoryName]
                if territory then
                    -- Calculate spawn position (slightly offset from territory center)
                    local spawnX = territory.x + (math.random(-10, 10) / 10) * Config.TerritorySystem.workingGirlSpawnDistance
                    local spawnY = territory.y + (math.random(-10, 10) / 10) * Config.TerritorySystem.workingGirlSpawnDistance
                    local spawnZ = territory.z
                    
                    -- Broadcast to all players
                    TriggerClientEvent('pimp:spawnWorkingGirl', -1, girlId, girl.name, territoryName, spawnX, spawnY, spawnZ)
                    
                    -- Log
                    print("^2[Territory] Girl " .. girl.name .. " assigned to work in " .. territoryName .. "^7")
                end
            end)
        end
    end)
end)

-- Recall girl from territory
RegisterNetEvent('pimp:recallGirlFromTerritory')
AddEventHandler('pimp:recallGirlFromTerritory', function(girlId, territoryName)
    local source = source
    local identifier = GetPlayerIdentifierFromId(source)
    
    if not identifier then return end
    
    -- Get the girl
    local girl = nil
    if PlayerData[identifier] and PlayerData[identifier].girls then
        for _, g in ipairs(PlayerData[identifier].girls) do
            if g.id == girlId then
                girl = g
                break
            end
        end
    end
    
    if not girl then
        TriggerClientEvent('pimp:notification', source, "Girl Recall", "Girl not found", "error")
        return
    end
    
    -- Check if girl is working in this territory
    if girl.status ~= 'working' or girl.workLocation ~= territoryName then
        TriggerClientEvent('pimp:notification', source, "Girl Recall", girl.name .. " is not working in this territory", "error")
        return
    end
    
    -- Update girl status
    MySQL.update('UPDATE pimp_girls SET status = ?, work_location = NULL WHERE id = ?', 
        {'idle', girlId}, function()
        -- Update local data
        for i, g in ipairs(PlayerData[identifier].girls) do
            if g.id == girlId then
                PlayerData[identifier].girls[i].status = 'idle'
                PlayerData[identifier].girls[i].workLocation = nil
                break
            end
        end
        
        -- Notify player
        TriggerClientEvent('pimp:notification', source, "Girl Recall", girl.name .. " has been recalled from " .. territoryName, "success")
        
        -- Update client
        UpdatePlayerData(identifier)
        
        -- Remove girl from territory for all players
        TriggerClientEvent('pimp:removeWorkingGirl', -1, girlId, territoryName)
        
        -- Log
        print("^2[Territory] Girl " .. girl.name .. " recalled from " .. territoryName .. "^7")
    end)
end)

exports('GenerateRandomGirl', GenerateRandomGirl)
exports('CalculateGirlEarnings', CalculateGirlEarnings)
exports('AddGirlEarnings', AddGirlEarnings)
exports('AddHappiness', AddHappiness)
exports('RemoveHappiness', RemoveHappiness)-- Enhanced Girl Discipline System for Pimp Management System (Server)
-- To be merged into server/girl_management.lua

-- Discipline girl
RegisterNetEvent('pimp:disciplineGirl')
AddEventHandler('pimp:disciplineGirl', function(girlId, disciplineType)
    local source = source
    local identifier = GetPlayerIdentifierFromId(source)
    
    if not identifier or not PlayerData or not PlayerData[identifier] then
        TriggerClientEvent('pimp:notification', source, 'Error loading player data', 'error')
        return
    end
    
    -- Find girl in player data
    local girl, girlIndex = GetGirlById(identifier, girlId)
    
    if not girl then
        TriggerClientEvent('pimp:notification', source, 'Girl not found', 'error')
        return
    end
    
    -- Get discipline config
    if not Config.NPCInteraction.Discipline or not Config.NPCInteraction.Discipline.types[disciplineType] then
        TriggerClientEvent('pimp:notification', source, 'Invalid discipline type', 'error')
        return
    end
    
    local disciplineConfig = Config.NPCInteraction.Discipline.types[disciplineType]
    
    -- Calculate attribute changes based on discipline type
    local loyaltyChange = disciplineConfig.loyaltyChange or 0
    local fearChange = disciplineConfig.fearChange or 0
    
    -- Calculate new values
    local newLoyalty = math.max(0, math.min(100, girl.attributes.loyalty + loyaltyChange))
    local newFear = math.max(0, math.min(100, girl.attributes.fear + fearChange))
    
    -- Update girl attributes
    PlayerData[identifier].girls[girlIndex].attributes.loyalty = newLoyalty
    PlayerData[identifier].girls[girlIndex].attributes.fear = newFear
    
    -- Update database
    MySQL.update('UPDATE pimp_girls SET loyalty = ?, fear = ? WHERE id = ?', {newLoyalty, newFear, girlId})
    
    -- Update player data
    UpdatePlayerData(identifier)
    
    -- Send detailed notification about attribute changes
    local message = 'You disciplined ' .. girl.name
    
    -- Add attribute change details
    if loyaltyChange ~= 0 then
        message = message .. '\nLoyalty: ' .. (loyaltyChange > 0 and '+' or '') .. loyaltyChange .. ' (' .. newLoyalty .. '/100)'
    end
    
    if fearChange ~= 0 then
        message = message .. '\nFear: ' .. (fearChange > 0 and '+' or '') .. fearChange .. ' (' .. newFear .. '/100)'
    end
    
    -- Send notification with appropriate type based on discipline
    local notificationType = 'info'
    if disciplineType == 'slap' then
        notificationType = 'warning'
    elseif disciplineType == 'threaten' then
        notificationType = 'error'
    end
    
    TriggerClientEvent('pimp:notification', source, message, notificationType)
end)

-- Set girl attitude
RegisterNetEvent('pimp:setGirlAttitude')
AddEventHandler('pimp:setGirlAttitude', function(girlId, hasAttitude)
    local source = source
    local identifier = GetPlayerIdentifierFromId(source)
    
    -- Check if player data exists
    if not identifier or not PlayerData or not PlayerData[identifier] then
        TriggerClientEvent('pimp:notification', source, 'Error loading player data', 'error')
        return
    end
    
    -- Find girl
    local girl, girlIndex = GetGirlById(identifier, girlId)
    
    if not girl then
        TriggerClientEvent('pimp:notification', source, 'Girl not found', 'error')
        return
    end
    
    -- Set attitude
    PlayerData[identifier].girls[girlIndex].hasAttitude = hasAttitude
    
    -- Update database
    MySQL.update('UPDATE pimp_girls SET has_attitude = ? WHERE id = ?', {hasAttitude and 1 or 0, girlId}, function(affectedRows)
        if affectedRows == 0 then
            print("^1Error: Failed to update girl attitude in database^7")
        else
            print("^2Girl attitude updated successfully^7")
        end
    end)
    
    -- Update client
    UpdatePlayerData(identifier)
    
    -- Send notification
    if hasAttitude then
        TriggerClientEvent('pimp:notification', source, girl.name .. ' has developed an attitude problem', 'warning')
    else
        TriggerClientEvent('pimp:notification', source, girl.name .. ' is now behaving properly', 'success')
    end
end)

-- Check for attitude development periodically
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(60000) -- Check every minute
        
        -- Loop through all players
        for identifier, playerData in pairs(PlayerData or {}) do
            -- Loop through all girls
            for i, girl in ipairs(playerData.girls or {}) do
                -- Skip girls that already have attitude
                if not girl.hasAttitude then
                    -- Calculate attitude chance based on loyalty and fear
                    local loyalty = girl.attributes and girl.attributes.loyalty or 50
                    local fear = girl.attributes and girl.attributes.fear or 0
                    
                    -- Girls with low loyalty and low fear are more likely to develop attitude
                    local attitudeChance = (100 - loyalty) * (100 - fear) / 100000 -- 0.01% to 1% chance per minute
                    
                    if math.random() < attitudeChance then
                        -- Develop attitude
                        PlayerData[identifier].girls[i].hasAttitude = true
                        
                        -- Update database
                        MySQL.update('UPDATE pimp_girls SET has_attitude = 1 WHERE id = ?', {girl.id})
                        
                        -- Notify player if online
                        local source = GetPlayerIdFromIdentifier(identifier)
                        if source then
                            TriggerClientEvent('pimp:notification', source, girl.name .. ' has developed an attitude problem', 'warning')
                            UpdatePlayerData(identifier)
                        end
                    end
                end
            end
        end
    end
end)

-- Add has_attitude column to pimp_girls table if it doesn't exist
Citizen.CreateThread(function()
    MySQL.query("SHOW COLUMNS FROM pimp_girls LIKE 'has_attitude'", {}, function(result)
        if not result or #result == 0 then
            print("^3Adding has_attitude column to pimp_girls table^7")
            MySQL.query("ALTER TABLE pimp_girls ADD COLUMN has_attitude BOOLEAN NOT NULL DEFAULT 0", {}, function(result)
                if result then
                    print("^2has_attitude column added successfully^7")
                else
                    print("^1Failed to add has_attitude column^7")
                end
            end)
        else
            print("^2has_attitude column already exists^7")
        end
    end)
end)