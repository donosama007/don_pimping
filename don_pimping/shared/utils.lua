-- Pimp Management System - Shared Utilities
-- Created by Donald Draper
-- Optimized by NinjaTech AI

-- Shared utility functions that can be used by both client and server scripts

-- Format number with commas
function FormatNumber(number)
    if not number then return "0" end
    
    local i, j, minus, int, fraction = tostring(number):find('([-]?)(%d+)([.]?%d*)')
    int = int:reverse():gsub("(%d%d%d)", "%1,")
    return minus .. int:reverse():gsub("^,", "") .. fraction
end

-- Check if a table contains a value
function TableContains(table, value)
    for _, v in pairs(table) do
        if v == value then
            return true
        end
    end
    return false
end

-- Get table length (works with non-sequential tables)
function TableLength(table)
    local count = 0
    for _ in pairs(table) do
        count = count + 1
    end
    return count
end

-- Deep copy a table
function DeepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[DeepCopy(orig_key)] = DeepCopy(orig_value)
        end
        setmetatable(copy, DeepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

-- Round a number to the specified decimal places
function Round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

-- Calculate distance between two coordinates
function GetDistance(x1, y1, z1, x2, y2, z2)
    return math.sqrt((x2 - x1)^2 + (y2 - y1)^2 + (z2 - z1)^2)
end

-- Calculate distance between two vector3 coordinates
function GetVectorDistance(vec1, vec2)
    return GetDistance(vec1.x, vec1.y, vec1.z, vec2.x, vec2.y, vec2.z)
end

-- Get a random element from a table
function GetRandomFromTable(table)
    if #table == 0 then return nil end
    return table[math.random(1, #table)]
end

-- Check if a string starts with a specific substring
function StartsWith(str, start)
    return str:sub(1, #start) == start
end

-- Check if a string ends with a specific substring
function EndsWith(str, ending)
    return ending == "" or str:sub(-#ending) == ending
end

-- Split a string by a delimiter
function SplitString(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end

-- Convert a table to a string for debugging
function TableToString(tbl, indent)
    if not tbl then return "nil" end
    if type(tbl) ~= "table" then return tostring(tbl) end
    
    indent = indent or 0
    local indentStr = string.rep("  ", indent)
    local result = "{\n"
    
    for k, v in pairs(tbl) do
        result = result .. indentStr .. "  " .. tostring(k) .. " = "
        
        if type(v) == "table" then
            result = result .. TableToString(v, indent + 1)
        else
            result = result .. tostring(v)
        end
        
        result = result .. ",\n"
    end
    
    result = result .. indentStr .. "}"
    return result
end

-- Calculate cooldown time remaining in a human-readable format
function GetCooldownTimeRemaining(endTime)
    if not endTime then return "0m 0s" end
    
    local currentTime = GetGameTimer and GetGameTimer() or (os.time() * 1000)
    
    if endTime > currentTime then
        local remainingTime = endTime - currentTime
        local minutes = math.floor(remainingTime / 60000)
        local seconds = math.floor((remainingTime % 60000) / 1000)
        
        return minutes .. "m " .. seconds .. "s"
    end
    
    return "0m 0s"
end

-- Check if a cooldown is active
function IsOnCooldown(cooldowns, key)
    if not cooldowns or not cooldowns[key] then return false end
    
    local cooldown = cooldowns[key]
    local currentTime = GetGameTimer and GetGameTimer() or (os.time() * 1000)
    
    if type(cooldown) == "number" then
        return cooldown > currentTime
    elseif type(cooldown) == "table" and cooldown.endTime then
        return cooldown.endTime > currentTime
    end
    
    return false
end

-- Calculate price based on girl attributes and location
function CalculatePrice(girl, service, location, clientType)
    if not girl or not service or not Config.DynamicPricing then
        return service and service.basePrice or 100
    end
    
    -- Base price from service
    local basePrice = service.basePrice
    
    -- Apply girl attribute multipliers
    local appearanceMult = (girl.attributes.appearance / 50) * Config.DynamicPricing.baseMultipliers.appearance
    local performanceMult = (girl.attributes.performance / 50) * Config.DynamicPricing.baseMultipliers.performance
    local discretionMult = (girl.attributes.discretion / 50) * Config.DynamicPricing.baseMultipliers.discretion
    
    -- Apply client type multiplier
    local clientMult = 1.0
    if clientType and Config.DynamicPricing.clientTypes[clientType] then
        clientMult = Config.DynamicPricing.clientTypes[clientType].priceMultiplier
    end
    
    -- Apply location multiplier
    local locationMult = 1.0
    if location and location.earningsMultiplier then
        locationMult = location.earningsMultiplier
    end
    
    -- Apply time of day multiplier
    local hour = GetClockHours and GetClockHours() or 12
    local timeMult = 1.0
    
    if hour >= 6 and hour < 12 then
        timeMult = Config.DynamicPricing.timeOfDay.morning
    elseif hour >= 12 and hour < 18 then
        timeMult = Config.DynamicPricing.timeOfDay.afternoon
    elseif hour >= 18 and hour < 24 then
        timeMult = Config.DynamicPricing.timeOfDay.evening
    else
        timeMult = Config.DynamicPricing.timeOfDay.night
    end
    
    -- Calculate final price
    local finalPrice = basePrice * (1 + appearanceMult + performanceMult + discretionMult) * clientMult * locationMult * timeMult
    
    -- Round to nearest whole number
    return math.floor(finalPrice + 0.5)
end

-- Calculate reputation gain based on girl, service, and location
function CalculateReputationGain(girl, service, location)
    if not girl or not Config.ReputationSystem or not Config.ReputationSystem.earnings then
        return 10 -- Default reputation gain
    end
    
    -- Base reputation points
    local basePoints = Config.ReputationSystem.earnings.basePoints
    
    -- Girl quality bonus
    local girlAttributes = girl.attributes.appearance + girl.attributes.performance + girl.attributes.loyalty + girl.attributes.discretion
    local girlQualityBonus = girlAttributes * Config.ReputationSystem.earnings.girlQualityMultiplier
    
    -- Location multiplier
    local locationMult = 1.0
    if location and location.riskLevel then
        if location.riskLevel == "low" then
            locationMult = Config.ReputationSystem.earnings.locationMultiplier.lowRisk
        elseif location.riskLevel == "medium" then
            locationMult = Config.ReputationSystem.earnings.locationMultiplier.mediumRisk
        elseif location.riskLevel == "high" then
            locationMult = Config.ReputationSystem.earnings.locationMultiplier.highRisk
        end
    end
    
    -- Service bonus
    local serviceBonus = 1.0
    if service then
        serviceBonus = service.duration / 60 -- Longer services give more reputation
    end
    
    -- Calculate final reputation gain
    local repGain = (basePoints + girlQualityBonus) * locationMult * serviceBonus
    
    -- Round to nearest whole number
    return math.floor(repGain + 0.5)
end

-- Calculate happiness change based on work conditions
function CalculateHappinessChange(girl, workDuration, location)
    if not girl or not Config.HappinessSystem or not Config.HappinessSystem.enabled then
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
    local loyaltyModifier = 1.0 - (girl.attributes.loyalty / 200) -- 0.5 to 1.0 based on loyalty
    
    -- Calculate final happiness change (negative value)
    local happinessChange = -1 * baseDecay * riskModifier * loyaltyModifier
    
    -- Round to nearest whole number
    return math.floor(happinessChange)
end

-- Get girl level based on attributes
function GetGirlLevel(girl)
    if not girl or not girl.attributes then return 1 end
    
    local totalAttributes = girl.attributes.appearance + girl.attributes.performance + 
                           girl.attributes.loyalty + girl.attributes.discretion
    
    local avgAttribute = totalAttributes / 4
    
    if avgAttribute >= 90 then
        return 5
    elseif avgAttribute >= 75 then
        return 4
    elseif avgAttribute >= 60 then
        return 3
    elseif avgAttribute >= 45 then
        return 2
    else
        return 1
    end
end

-- Get player level based on reputation
function GetPlayerLevel(reputation)
    if not reputation or not Config.ReputationSystem or not Config.ReputationSystem.levels then
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
    if not reputation or not Config.ReputationSystem or not Config.ReputationSystem.levels then
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
    if not reputation or not Config.ReputationSystem or not Config.ReputationSystem.levels then
        return Config.GirlSystem.maxGirls
    end
    
    local maxGirls = Config.GirlSystem.maxGirls
    
    for _, levelData in ipairs(Config.ReputationSystem.levels) do
        if reputation >= levelData.threshold then
            maxGirls = levelData.maxGirls
        else
            break
        end
    end
    
    return maxGirls
end

-- Export shared functions
if IsDuplicityVersion() then
    -- Server-side exports
    exports('FormatNumber', FormatNumber)
    exports('CalculatePrice', CalculatePrice)
    exports('CalculateReputationGain', CalculateReputationGain)
    exports('CalculateHappinessChange', CalculateHappinessChange)
    exports('GetPlayerLevel', GetPlayerLevel)
    exports('GetPlayerLevelName', GetPlayerLevelName)
    exports('GetMaxGirls', GetMaxGirls)
else
    -- Client-side exports
    exports('FormatNumber', FormatNumber)
    exports('CalculatePrice', CalculatePrice)
    exports('GetCooldownTimeRemaining', GetCooldownTimeRemaining)
    exports('IsOnCooldown', IsOnCooldown)
    exports('GetPlayerLevel', GetPlayerLevel)
    exports('GetPlayerLevelName', GetPlayerLevelName)
    exports('GetMaxGirls', GetMaxGirls)
end

-- Make functions available globally
_G.FormatNumber = FormatNumber
_G.TableContains = TableContains
_G.TableLength = TableLength
_G.DeepCopy = DeepCopy
_G.Round = Round
_G.GetDistance = GetDistance
_G.GetVectorDistance = GetVectorDistance
_G.GetRandomFromTable = GetRandomFromTable
_G.StartsWith = StartsWith
_G.EndsWith = EndsWith
_G.SplitString = SplitString
_G.TableToString = TableToString
_G.GetCooldownTimeRemaining = GetCooldownTimeRemaining
_G.IsOnCooldown = IsOnCooldown
_G.CalculatePrice = CalculatePrice
_G.CalculateReputationGain = CalculateReputationGain
_G.CalculateHappinessChange = CalculateHappinessChange
_G.GetGirlLevel = GetGirlLevel
_G.GetPlayerLevel = GetPlayerLevel
_G.GetPlayerLevelName = GetPlayerLevelName
_G.GetMaxGirls = GetMaxGirls