-- Pimp Management System - Girl Happiness System
-- Created by Donald Draper
-- Optimized by NinjaTech AI

-- This file handles the happiness system for girls

-- Local variables
local HappinessSystem = {}

-- Calculate happiness change based on work conditions
function CalculateHappinessChange(girl, workDuration, location)
    if not Config.HappinessSystem or not Config.HappinessSystem.enabled then
        return 0
    end
    
    -- Base happiness decay from working
    local baseDecay = Config.HappinessSystem.workDecayRate * (workDuration / 60)
    
    -- Location risk modifier
    local riskModifier = 1.0
    if location and location.riskLevel then
        if location.riskLevel == "low" then
            riskModifier = 0.8 -- Less decay in low-risk areas
        elseif location.riskLevel == "high" then
            riskModifier = 1.5 -- More decay in high-risk areas
        end
    end
    
    -- Loyalty modifier
    local loyaltyModifier = 1.0
    if girl and girl.attributes and girl.attributes.loyalty then
        loyaltyModifier = 1.0 - (girl.attributes.loyalty / 200) -- 0.5 to 1.0 based on loyalty
    end
    
    -- Calculate final happiness change (negative value)
    local happinessChange = -1 * baseDecay * riskModifier * loyaltyModifier
    
    -- Round to nearest whole number
    return math.floor(happinessChange)
end

-- Calculate happiness decay over time
function CalculateHappinessDecay(girl, idleTime)
    if not Config.HappinessSystem or not Config.HappinessSystem.enabled then
        return 0
    end
    
    -- Base happiness decay from being idle
    local baseDecay = Config.HappinessSystem.decayRate * (idleTime / 60)
    
    -- Loyalty modifier
    local loyaltyModifier = 1.0
    if girl and girl.attributes and girl.attributes.loyalty then
        loyaltyModifier = 1.0 - (girl.attributes.loyalty / 200) -- 0.5 to 1.0 based on loyalty
    end
    
    -- Calculate final happiness decay (negative value)
    local happinessDecay = -1 * baseDecay * loyaltyModifier
    
    -- Round to nearest whole number
    return math.floor(happinessDecay)
end

-- Get happiness level category
function GetHappinessCategory(happiness)
    if happiness >= 81 then
        return "veryHigh"
    elseif happiness >= 61 then
        return "high"
    elseif happiness >= 41 then
        return "normal"
    elseif happiness >= 21 then
        return "low"
    else
        return "veryLow"
    end
end

-- Get happiness effects on earnings
function GetHappinessEarningsMultiplier(happiness)
    if not Config.HappinessSystem or not Config.HappinessSystem.enabled then
        return 1.0
    end
    
    local category = GetHappinessCategory(happiness)
    return Config.HappinessSystem.effects.earnings[category] or 1.0
end

-- Get happiness effects on loyalty
function GetHappinessLoyaltyChange(happiness)
    if not Config.HappinessSystem or not Config.HappinessSystem.enabled then
        return 0
    end
    
    local category = GetHappinessCategory(happiness)
    return Config.HappinessSystem.effects.loyalty[category] or 0
end

-- Get happiness color based on level
function GetHappinessColor(happiness)
    if happiness >= 81 then
        return "green"
    elseif happiness >= 61 then
        return "lightgreen"
    elseif happiness >= 41 then
        return "yellow"
    elseif happiness >= 21 then
        return "orange"
    else
        return "red"
    end
end

-- Get happiness icon based on level
function GetHappinessIcon(happiness)
    if happiness >= 81 then
        return "face-laugh-beam"
    elseif happiness >= 61 then
        return "face-smile"
    elseif happiness >= 41 then
        return "face-meh"
    elseif happiness >= 21 then
        return "face-frown"
    else
        return "face-angry"
    end
end

-- Get happiness description based on level
function GetHappinessDescription(happiness)
    if happiness >= 81 then
        return "Ecstatic"
    elseif happiness >= 61 then
        return "Happy"
    elseif happiness >= 41 then
        return "Content"
    elseif happiness >= 21 then
        return "Unhappy"
    else
        return "Miserable"
    end
end

-- Calculate activity effects on happiness
function CalculateActivityHappiness(activityName)
    if not Config.HappinessSystem or not Config.HappinessSystem.enabled or not Config.HappinessSystem.activities then
        return 0, 0, 0
    end
    
    local activity = Config.HappinessSystem.activities[activityName]
    if not activity then
        return 0, 0, 0
    end
    
    return activity.happinessGain, activity.cost, activity.duration
end

-- Check if an activity is on cooldown
function IsActivityOnCooldown(girl, activityName, cooldowns)
    if not Config.HappinessSystem or not Config.HappinessSystem.enabled or not Config.HappinessSystem.activities then
        return false
    end
    
    local activity = Config.HappinessSystem.activities[activityName]
    if not activity then
        return false
    end
    
    local cooldownKey = "activity_" .. girl.id .. "_" .. activityName
    return IsOnCooldown(cooldowns, cooldownKey)
end

-- Get activity cooldown time
function GetActivityCooldown(activityName)
    if not Config.HappinessSystem or not Config.HappinessSystem.enabled or not Config.HappinessSystem.activities then
        return 0
    end
    
    local activity = Config.HappinessSystem.activities[activityName]
    if not activity then
        return 0
    end
    
    return activity.cooldown
end

-- Add happiness to girl
function AddHappiness(girlId, amount)
    -- This is a placeholder, actual implementation is in the server-side code
    if IsDuplicityVersion() then
        -- Server-side implementation
        -- Will be implemented in server/girl_happiness.lua
    else
        -- Client-side just triggers server event
        TriggerServerEvent('pimp:addGirlHappiness', girlId, amount)
    end
end

-- Remove happiness from girl
function RemoveHappiness(girlId, amount)
    -- This is a placeholder, actual implementation is in the server-side code
    if IsDuplicityVersion() then
        -- Server-side implementation
        -- Will be implemented in server/girl_happiness.lua
    else
        -- Client-side just triggers server event
        TriggerServerEvent('pimp:removeGirlHappiness', girlId, amount)
    end
end

-- Start girl activity
function StartGirlActivity(girlId, activityName)
    -- This is a placeholder, actual implementation is in the server-side code
    if IsDuplicityVersion() then
        -- Server-side implementation
        -- Will be implemented in server/girl_happiness.lua
    else
        -- Client-side just triggers server event
        TriggerServerEvent('pimp:startGirlActivity', girlId, activityName)
    end
end

-- Add functions to HappinessSystem
HappinessSystem.CalculateHappinessChange = CalculateHappinessChange
HappinessSystem.CalculateHappinessDecay = CalculateHappinessDecay
HappinessSystem.GetHappinessCategory = GetHappinessCategory
HappinessSystem.GetHappinessEarningsMultiplier = GetHappinessEarningsMultiplier
HappinessSystem.GetHappinessLoyaltyChange = GetHappinessLoyaltyChange
HappinessSystem.GetHappinessColor = GetHappinessColor
HappinessSystem.GetHappinessIcon = GetHappinessIcon
HappinessSystem.GetHappinessDescription = GetHappinessDescription
HappinessSystem.CalculateActivityHappiness = CalculateActivityHappiness
HappinessSystem.IsActivityOnCooldown = IsActivityOnCooldown
HappinessSystem.GetActivityCooldown = GetActivityCooldown
HappinessSystem.AddHappiness = AddHappiness
HappinessSystem.RemoveHappiness = RemoveHappiness
HappinessSystem.StartGirlActivity = StartGirlActivity

-- Make functions available globally
_G.CalculateHappinessChange = CalculateHappinessChange
_G.CalculateHappinessDecay = CalculateHappinessDecay
_G.GetHappinessCategory = GetHappinessCategory
_G.GetHappinessEarningsMultiplier = GetHappinessEarningsMultiplier
_G.GetHappinessLoyaltyChange = GetHappinessLoyaltyChange
_G.GetHappinessColor = GetHappinessColor
_G.GetHappinessIcon = GetHappinessIcon
_G.GetHappinessDescription = GetHappinessDescription
_G.CalculateActivityHappiness = CalculateActivityHappiness
_G.IsActivityOnCooldown = IsActivityOnCooldown
_G.GetActivityCooldown = GetActivityCooldown

-- Export happiness functions
if IsDuplicityVersion() then
    -- Server-side exports
    exports('CalculateHappinessChange', CalculateHappinessChange)
    exports('CalculateHappinessDecay', CalculateHappinessDecay)
    exports('GetHappinessEarningsMultiplier', GetHappinessEarningsMultiplier)
    exports('GetHappinessLoyaltyChange', GetHappinessLoyaltyChange)
    exports('AddHappiness', AddHappiness)
    exports('RemoveHappiness', RemoveHappiness)
else
    -- Client-side exports
    exports('GetHappinessColor', GetHappinessColor)
    exports('GetHappinessIcon', GetHappinessIcon)
    exports('GetHappinessDescription', GetHappinessDescription)
    exports('CalculateActivityHappiness', CalculateActivityHappiness)
    exports('IsActivityOnCooldown', IsActivityOnCooldown)
end

-- Return the happiness system
return HappinessSystem