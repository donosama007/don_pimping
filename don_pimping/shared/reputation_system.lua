-- Pimp Management System - Reputation System
-- Created by Donald Draper
-- Optimized by NinjaTech AI

-- This file handles the reputation system for players

-- Local variables
local ReputationSystem = {}

-- Calculate reputation gain from a client service
function CalculateReputationGain(girl, service, location)
    if not Config.ReputationSystem or not Config.ReputationSystem.enabled then
        return 0
    end
    
    -- Base reputation points
    local basePoints = Config.ReputationSystem.earnings.basePoints or 10
    
    -- Calculate girl quality bonus
    local girlQualityBonus = 0
    if girl and girl.attributes then
        local totalAttributes = girl.attributes.appearance + girl.attributes.performance + 
                               girl.attributes.loyalty + girl.attributes.discretion
        girlQualityBonus = totalAttributes * (Config.ReputationSystem.earnings.girlQualityMultiplier or 0.1)
    end
    
    -- Calculate location multiplier
    local locationMultiplier = 1.0
    if location and location.riskLevel and Config.ReputationSystem.earnings.locationMultiplier then
        if location.riskLevel == "low" then
            locationMultiplier = Config.ReputationSystem.earnings.locationMultiplier.lowRisk or 0.8
        elseif location.riskLevel == "medium" then
            locationMultiplier = Config.ReputationSystem.earnings.locationMultiplier.mediumRisk or 1.0
        elseif location.riskLevel == "high" then
            locationMultiplier = Config.ReputationSystem.earnings.locationMultiplier.highRisk or 1.5
        end
    end
    
    -- Calculate service multiplier
    local serviceMultiplier = 1.0
    if service and service.duration then
        -- Longer services give more reputation
        serviceMultiplier = service.duration / 60
    end
    
    -- Calculate final reputation gain
    local repGain = (basePoints + girlQualityBonus) * locationMultiplier * serviceMultiplier
    
    -- Round to nearest whole number
    return math.floor(repGain + 0.5)
end

-- Get player level based on reputation
function GetPlayerLevel(reputation)
    if not Config.ReputationSystem or not Config.ReputationSystem.enabled or not Config.ReputationSystem.levels then
        return 1
    end
    
    local level = 1
    
    for i, levelData in ipairs(Config.ReputationSystem.levels) do
        if reputation >= levelData.threshold then
            level = i
        else
            break
        end
    end
    
    return level
end

-- Get player level name based on reputation
function GetPlayerLevelName(reputation)
    if not Config.ReputationSystem or not Config.ReputationSystem.enabled or not Config.ReputationSystem.levels then
        return "Rookie Pimp"
    end
    
    local levelName = "Rookie Pimp"
    
    for _, levelData in ipairs(Config.ReputationSystem.levels) do
        if reputation >= levelData.threshold then
            levelName = levelData.name
        else
            break
        end
    end
    
    return levelName
end

-- Get maximum number of girls based on player level
function GetMaxGirls(reputation)
    if not Config.ReputationSystem or not Config.ReputationSystem.enabled or not Config.ReputationSystem.levels then
        return Config.GirlSystem.maxGirls or 10
    end
    
    local maxGirls = Config.GirlSystem.maxGirls or 10
    
    for _, levelData in ipairs(Config.ReputationSystem.levels) do
        if reputation >= levelData.threshold then
            maxGirls = levelData.maxGirls
        else
            break
        end
    end
    
    return maxGirls
end

-- Get reputation needed for next level
function GetReputationForNextLevel(currentReputation)
    if not Config.ReputationSystem or not Config.ReputationSystem.enabled or not Config.ReputationSystem.levels then
        return 1000
    end
    
    local nextLevelThreshold = nil
    
    for _, levelData in ipairs(Config.ReputationSystem.levels) do
        if levelData.threshold > currentReputation then
            nextLevelThreshold = levelData.threshold
            break
        end
    end
    
    -- If no next level found, return a high number
    if not nextLevelThreshold then
        return 999999
    end
    
    return nextLevelThreshold
end

-- Calculate reputation progress to next level (0.0 to 1.0)
function GetReputationProgress(currentReputation)
    if not Config.ReputationSystem or not Config.ReputationSystem.enabled or not Config.ReputationSystem.levels then
        return 0
    end
    
    local currentLevel = GetPlayerLevel(currentReputation)
    local currentLevelThreshold = 0
    local nextLevelThreshold = 1000
    
    -- Get current level threshold
    if currentLevel > 1 and currentLevel <= #Config.ReputationSystem.levels then
        currentLevelThreshold = Config.ReputationSystem.levels[currentLevel].threshold
    end
    
    -- Get next level threshold
    if currentLevel < #Config.ReputationSystem.levels then
        nextLevelThreshold = Config.ReputationSystem.levels[currentLevel + 1].threshold
    else
        -- If at max level, use a value 20% higher than current threshold
        nextLevelThreshold = currentLevelThreshold * 1.2
    end
    
    -- Calculate progress
    local levelDifference = nextLevelThreshold - currentLevelThreshold
    local playerProgress = currentReputation - currentLevelThreshold
    
    if levelDifference <= 0 then
        return 1.0
    end
    
    local progress = playerProgress / levelDifference
    
    -- Clamp between 0 and 1
    return math.max(0, math.min(1, progress))
end

-- Calculate daily reputation decay
function CalculateReputationDecay(lastActiveTime)
    if not Config.ReputationSystem or not Config.ReputationSystem.enabled or 
       not Config.ReputationSystem.decay or not Config.ReputationSystem.decay.enabled then
        return 0
    end
    
    -- Check if we're on the server side
    if not IsDuplicityVersion() then
        return 0 -- Decay is calculated server-side only
    end
    
    -- Get current time
    local currentTime = os.time()
    
    -- Calculate days since last active
    local daysSinceLastActive = (currentTime - lastActiveTime) / (60 * 60 * 24)
    
    -- Check if within grace period
    if daysSinceLastActive <= Config.ReputationSystem.decay.gracePeriod then
        return 0
    end
    
    -- Calculate days beyond grace period
    local decayDays = math.floor(daysSinceLastActive - Config.ReputationSystem.decay.gracePeriod)
    
    -- Calculate total decay
    local totalDecay = decayDays * Config.ReputationSystem.decay.dailyDecay
    
    return totalDecay
end

-- Add reputation to player
function AddReputation(playerId, amount)
    -- This is a placeholder, actual implementation is in the server-side code
    if IsDuplicityVersion() then
        -- Server-side implementation
        -- Will be implemented in server/reputation.lua
    else
        -- Client-side just triggers server event
        TriggerServerEvent('pimp:addReputation', amount)
    end
end

-- Remove reputation from player
function RemoveReputation(playerId, amount)
    -- This is a placeholder, actual implementation is in the server-side code
    if IsDuplicityVersion() then
        -- Server-side implementation
        -- Will be implemented in server/reputation.lua
    else
        -- Client-side just triggers server event
        TriggerServerEvent('pimp:removeReputation', amount)
    end
end

-- Get reputation leaderboard
function GetReputationLeaderboard()
    -- This is a placeholder, actual implementation is in the server-side code
    if IsDuplicityVersion() then
        -- Server-side implementation
        -- Will be implemented in server/reputation.lua
    else
        -- Client-side just triggers server event
        TriggerServerEvent('pimp:requestReputationLeaderboard')
    end
end

-- Add functions to ReputationSystem
ReputationSystem.CalculateReputationGain = CalculateReputationGain
ReputationSystem.GetPlayerLevel = GetPlayerLevel
ReputationSystem.GetPlayerLevelName = GetPlayerLevelName
ReputationSystem.GetMaxGirls = GetMaxGirls
ReputationSystem.GetReputationForNextLevel = GetReputationForNextLevel
ReputationSystem.GetReputationProgress = GetReputationProgress
ReputationSystem.CalculateReputationDecay = CalculateReputationDecay
ReputationSystem.AddReputation = AddReputation
ReputationSystem.RemoveReputation = RemoveReputation
ReputationSystem.GetReputationLeaderboard = GetReputationLeaderboard

-- Make functions available globally
_G.CalculateReputationGain = CalculateReputationGain
_G.GetPlayerLevel = GetPlayerLevel
_G.GetPlayerLevelName = GetPlayerLevelName
_G.GetMaxGirls = GetMaxGirls
_G.GetReputationForNextLevel = GetReputationForNextLevel
_G.GetReputationProgress = GetReputationProgress

-- Export reputation functions
if IsDuplicityVersion() then
    -- Server-side exports
    exports('CalculateReputationGain', CalculateReputationGain)
    exports('GetPlayerLevel', GetPlayerLevel)
    exports('GetPlayerLevelName', GetPlayerLevelName)
    exports('GetMaxGirls', GetMaxGirls)
    exports('CalculateReputationDecay', CalculateReputationDecay)
    exports('AddReputation', AddReputation)
    exports('RemoveReputation', RemoveReputation)
else
    -- Client-side exports
    exports('CalculateReputationGain', CalculateReputationGain)
    exports('GetPlayerLevel', GetPlayerLevel)
    exports('GetPlayerLevelName', GetPlayerLevelName)
    exports('GetMaxGirls', GetMaxGirls)
    exports('GetReputationForNextLevel', GetReputationForNextLevel)
    exports('GetReputationProgress', GetReputationProgress)
end

-- Return the reputation system
return ReputationSystem