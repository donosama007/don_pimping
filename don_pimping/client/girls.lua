-- Pimp Management System - Enhanced Girl Management
-- Created by Donald Draper
-- Optimized by NinjaTech AI
-- Enhanced with Discipline System, Location Tracking, and Following

-- Local variables
-- Silence F8 console unless debugging is explicitly enabled in Config
local print = function(...)
    if Config and Config.Debug then
        _G.print(...)
    end
end

local ActiveGirls = {}
-- Use the shared GirlPeds variable from shared_variables.lua
-- local GirlPeds = {} -- Commented out to use the shared variable
local GirlBlips = {}
local FollowingGirl = nil
local FollowingGirlPed = nil

-- Enhanced variables for new features
local followingGirls = {}
local isFollowing = false
local followingPeds = {}
local followingBlips = {}
local disciplineCooldowns = {}
local girlLocations = {}

-- Debug function
local function DebugPrint(message)
    if Config and Config.Debug then
        print("^3[Girls Debug] " .. message .. "^7")
    end
end

-- Initialize girl management system
Citizen.CreateThread(function()
    Citizen.Wait(2000)
    InitializeGirlManagement()
end)

-- Initialize girl management
function InitializeGirlManagement()
    ClearGirlEntities()
    
    -- Start girl management thread
    Citizen.CreateThread(function()
        while true do
            local updateInterval = 2000
            if Config and Config.Performance then
                updateInterval = Config.Performance.girlUpdateInterval or 2000
            end
            Citizen.Wait(updateInterval)
            UpdateGirlEntities()
        end
    end)
end

-- Add this to girls.lua
RegisterNetEvent('pimp:getGirlPeds')
AddEventHandler('pimp:getGirlPeds', function()
    -- Send GirlPeds to requesting script
    TriggerEvent('pimp:setGirlPeds', GirlPeds)
    DebugPrint("Sent GirlPeds to requesting script")
    
    -- Print debug info about GirlPeds
    if GirlPeds then
        local count = 0
        for id, ped in pairs(GirlPeds) do
            count = count + 1
            if DoesEntityExist(ped) then
                DebugPrint("GirlPed " .. id .. " exists")
            else
                DebugPrint("GirlPed " .. id .. " does not exist")
            end
        end
        DebugPrint("Total GirlPeds: " .. count)
    else
        DebugPrint("GirlPeds is nil")
    end
end)

-- Add this to expose GirlPeds to other resources
exports('GetGirlPeds', function()
    return GirlPeds
end)

-- Update shared variables whenever GirlPeds changes
function UpdateSharedGirlPeds()
    TriggerEvent('pimp:setSharedVariables', {
        GirlPeds = GirlPeds
    })
    DebugPrint("Updated shared GirlPeds variable")
end
    
    -- Start location tracking thread
    if Config and Config.EnhancedFeatures and Config.EnhancedFeatures.locationTracking and Config.EnhancedFeatures.locationTracking.enabled then
        Citizen.CreateThread(function()
            while true do
                local updateInterval = 5000
                if Config.EnhancedFeatures and Config.EnhancedFeatures.locationTracking then
                    updateInterval = Config.EnhancedFeatures.locationTracking.updateInterval or 5000
                end
                Citizen.Wait(updateInterval)
                UpdateGirlLocationTracking()
            end
        end)
    end

-- Enhanced update girl entities
function UpdateGirlEntities()
    if not PlayerData or not PlayerData.girls then return end
    
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local maxRenderDistance = Config.Performance and Config.Performance.maxRenderDistance or 100.0
    
    ActiveGirls = {}
    for _, girl in ipairs(PlayerData.girls) do
        -- Check if girl is following
        local isFollowing = IsGirlFollowing(girl.id)
        
        if girl.status == 'working' and girl.workLocation and not isFollowing then
            -- Find work location
            local workLocation = nil
            for _, location in ipairs(Config.WorkLocations) do
                if girl.workLocation == location.name then
                    workLocation = location
                    break
                end
            end
            
            if workLocation then
                local distance = #(playerCoords - workLocation.coords)
                
                -- Check if girl should be spawned
                if not GirlPeds[girl.id] and distance < maxRenderDistance then
                    SpawnGirlPed(girl, workLocation)
                elseif GirlPeds[girl.id] and distance > (maxRenderDistance + 50.0) then
                    DeleteGirlPed(girl.id)
                end
                
                -- Update active girls
                ActiveGirls[girl.id] = {
                    girl = girl,
                    location = workLocation,
                    distance = distance
                }
                
                -- Update location tracking
                girlLocations[girl.id] = {
                    coords = workLocation.coords,
                    location = workLocation,
                    lastUpdate = GetGameTimer()
                }
            end
        else
            -- Only delete girl ped if not working AND not following
            if GirlPeds[girl.id] and not isFollowing then
                DeleteGirlPed(girl.id)
            end
        end
    end
    
    -- Update shared GirlPeds variable
    UpdateSharedGirlPeds()
end

-- Enhanced spawn girl ped with better positioning
function SpawnGirlPed(girl, location)
    local model = GetRandomFromTable(Config.GirlModels)
    
    RequestModel(GetHashKey(model))
    while not HasModelLoaded(GetHashKey(model)) do
        Citizen.Wait(1)
    end
    
    -- Better positioning algorithm
    local radius = math.min(15.0, location.radius * 0.15)
    local attempts = 0
    local validPosition = false
    local x, y, z
    
    while not validPosition and attempts < 10 do
        local angle = math.random() * 2 * math.pi
        x = location.coords.x + radius * math.cos(angle)
        y = location.coords.y + radius * math.sin(angle)
        z = location.coords.z
        
        -- Check for ground and clear area
        local ground, groundZ = GetGroundZFor_3dCoord(x, y, z + 5.0, false)
        if ground then
            z = groundZ
            -- Check if position is clear
            if not IsPositionOccupied(x, y, z, 2.0, false, true, true, false, false, 0, false) then
                validPosition = true
            end
        end
        attempts = attempts + 1
    end
    
    if not validPosition then
        -- Fallback to location center
        x, y, z = location.coords.x, location.coords.y, location.coords.z
    end
    
    -- Create ped with enhanced properties
    local ped = CreatePed(4, GetHashKey(model), x, y, z, math.random(0, 359) * 1.0, false, true)
    
    -- Enhanced ped properties
    SetEntityAsMissionEntity(ped, true, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedCanBeTargetted(ped, false)
    SetPedCanRagdoll(ped, false)
    SetPedKeepTask(ped, true)
    SetEntityInvincible(ped, true)
    SetPedFleeAttributes(ped, 0, false)
    SetPedCombatAttributes(ped, 17, true)
    
    -- Set appearance based on girl type and attributes
    ApplyGirlAppearance(ped, girl)
    
    -- Enhanced scenario selection based on location and girl type
    local scenarios = GetAppropriateScenarios(girl, location)
    TaskStartScenarioInPlace(ped, GetRandomFromTable(scenarios), 0, true)
    
    -- Create enhanced blip
    local blip = CreateEnhancedGirlBlip(ped, girl)
    
    -- Store ped and blip
    GirlPeds[girl.id] = ped
    GirlBlips[girl.id] = blip
    
    -- Update shared GirlPeds variable
    UpdateSharedGirlPeds()
    DebugPrint("Added girl ped " .. girl.id .. " to GirlPeds")
    
    -- Start enhanced behavior thread
    StartEnhancedGirlBehavior(girl.id, ped, location)
end

-- Apply girl appearance based on type and attributes
function ApplyGirlAppearance(ped, girl)
    -- Set default components
    SetPedDefaultComponentVariation(ped)
    
    -- Customize based on girl type
    if girl.type == "High-Class" or girl.type == "VIP" then
        -- High-class styling
        SetPedComponentVariation(ped, 2, math.random(0, 3), 0, 0) -- Hair
        SetPedComponentVariation(ped, 3, 0, 0, 0) -- Torso
        SetPedComponentVariation(ped, 4, math.random(0, 2), 0, 0) -- Legs
        SetPedComponentVariation(ped, 6, math.random(0, 3), 0, 0) -- Feet
        
        -- Add accessories for high-class girls
        if math.random() > 0.5 then
            SetPedPropIndex(ped, 1, math.random(0, 2), 0, true) -- Glasses
        end
    elseif girl.type == "Escort" then
        -- Escort styling
        SetPedComponentVariation(ped, 2, math.random(0, 5), 0, 0) -- Hair
        SetPedComponentVariation(ped, 3, math.random(0, 2), 0, 0) -- Torso
        SetPedComponentVariation(ped, 4, math.random(0, 3), 0, 0) -- Legs
        SetPedComponentVariation(ped, 6, math.random(0, 4), 0, 0) -- Feet
    else
        -- Streetwalker styling (more varied/casual)
        SetPedComponentVariation(ped, 2, math.random(0, 7), 0, 0) -- Hair
        SetPedComponentVariation(ped, 3, math.random(0, 3), 0, 0) -- Torso
        SetPedComponentVariation(ped, 4, math.random(0, 5), 0, 0) -- Legs
        SetPedComponentVariation(ped, 6, math.random(0, 6), 0, 0) -- Feet
    end
end

-- Get appropriate scenarios based on girl and location
function GetAppropriateScenarios(girl, location)
    local scenarios = {}
    
    -- Base scenarios
    table.insert(scenarios, "WORLD_HUMAN_STAND_IMPATIENT")
    table.insert(scenarios, "WORLD_HUMAN_STAND_MOBILE")
    
    -- Girl type specific scenarios
    if girl.type == "High-Class" or girl.type == "VIP" then
        table.insert(scenarios, "WORLD_HUMAN_SMOKING")
        table.insert(scenarios, "WORLD_HUMAN_STAND_MOBILE_CLUBHOUSE")
        table.insert(scenarios, "WORLD_HUMAN_PROSTITUTE_HIGH_CLASS")
    elseif girl.type == "Escort" then
        table.insert(scenarios, "WORLD_HUMAN_SMOKING")
        table.insert(scenarios, "WORLD_HUMAN_STAND_MOBILE")
        table.insert(scenarios, "WORLD_HUMAN_PROSTITUTE_HIGH_CLASS")
    else
        table.insert(scenarios, "WORLD_HUMAN_PROSTITUTE_LOW_CLASS")
        table.insert(scenarios, "WORLD_HUMAN_SMOKING")
        table.insert(scenarios, "WORLD_HUMAN_DRUG_DEALER")
    end
    
    -- Location specific scenarios
    if location.name == "Vespucci Beach" then
        table.insert(scenarios, "WORLD_HUMAN_SUNBATHE")
        table.insert(scenarios, "WORLD_HUMAN_STAND_FISHING")
    elseif location.name == "Vinewood Boulevard" or location.name == "Downtown Vinewood" then
        table.insert(scenarios, "WORLD_HUMAN_PAPARAZZI")
        table.insert(scenarios, "WORLD_HUMAN_TOURIST_MOBILE")
    end
    
    return scenarios
end

-- Create enhanced girl blip
function CreateEnhancedGirlBlip(ped, girl)
    local blip = AddBlipForEntity(ped)
    SetBlipSprite(blip, 280)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.7)
    
    -- Color based on girl type
    if girl.type == "VIP" then
        SetBlipColour(blip, 5) -- Purple for VIP
    elseif girl.type == "High-Class" then
        SetBlipColour(blip, 2) -- Green for High-Class
    elseif girl.type == "Escort" then
        SetBlipColour(blip, 3) -- Blue for Escort
    else
        SetBlipColour(blip, 48) -- Pink for Streetwalker
    end
    
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(girl.name .. " - " .. girl.type)
    EndTextCommandSetBlipName(blip)
    
    return blip
end

-- Enhanced girl behavior with improved AI
function StartEnhancedGirlBehavior(girlId, ped, location)
    Citizen.CreateThread(function()
        -- Get girl data
        local girl = nil
        for _, g in ipairs(PlayerData.girls) do
            if g.id == girlId then
                girl = g
                break
            end
        end
        
        if not girl then return end
        
        -- Enhanced behavior variables
        local lastClientTime = 0
        local lastMoveTime = 0
        local lastScenarioChange = 0
        local clientPed = nil
        local currentMood = "normal"
        local interactionState = "idle"
        
        -- Behavior loop
        while DoesEntityExist(ped) and GirlPeds[girlId] == ped do
            Citizen.Wait(1000)
            
            -- Check if girl is still working
            local stillWorking = false
            for _, g in ipairs(PlayerData.girls) do
                if g.id == girlId and g.status == 'working' then
                    stillWorking = true
                    girl = g
                    break
                end
            end
            
            if not stillWorking and girlId ~= FollowingGirl then
                DeleteGirlPed(girlId)
                break
            end
            
            -- Enhanced movement pattern
            if GetGameTimer() - lastMoveTime > 45000 then -- Every 45 seconds
                lastMoveTime = GetGameTimer()
                
                if math.random() > 0.3 then -- 70% chance to move
                    MoveGirlToNewPosition(ped, location, girl)
                end
            end
            
            -- Dynamic scenario changes
            if GetGameTimer() - lastScenarioChange > 60000 then -- Every minute
                lastScenarioChange = GetGameTimer()
                
                if math.random() > 0.4 then -- 60% chance to change scenario
                    local scenarios = GetAppropriateScenarios(girl, location)
                    ClearPedTasks(ped)
                    TaskStartScenarioInPlace(ped, GetRandomFromTable(scenarios), 0, true)
                end
            end
            
            -- Enhanced client interaction
            if GetGameTimer() - lastClientTime > 90000 then -- Every 90 seconds
                lastClientTime = GetGameTimer()
                
                local clientChance = CalculateEnhancedClientChance(girl, location)
                
                if math.random() <= clientChance then
                    clientPed = SpawnEnhancedClientPed(girlId, ped, location, girl)
                    if clientPed then
                        interactionState = "client_found"
                    end
                end
            end
            
            -- Handle client interaction
            if clientPed and DoesEntityExist(clientPed) then
                HandleEnhancedClientInteraction(girlId, ped, clientPed, location, girl)
                clientPed = nil
                interactionState = "idle"
            end
        end
    end)
end

-- Move girl to new position within location
function MoveGirlToNewPosition(ped, location, girl)
    ClearPedTasks(ped)
    
    local radius = math.min(20.0, location.radius * 0.2)
    local angle = math.random() * 2 * math.pi
    local x = location.coords.x + radius * math.cos(angle)
    local y = location.coords.y + radius * math.sin(angle)
    local z = location.coords.z
    
    local ground, groundZ = GetGroundZFor_3dCoord(x, y, z + 5.0, false)
    if ground then
        z = groundZ
    end
    
    -- Use appropriate movement style based on girl type
    local moveStyle = girl.type == "High-Class" or girl.type == "VIP" and 1.0 or 1.2
    TaskGoToCoordAnyMeans(ped, x, y, z, moveStyle, 0, false, 0, 0)
    
    Citizen.SetTimeout(15000, function()
        if DoesEntityExist(ped) then
            local scenarios = GetAppropriateScenarios(girl, location)
            TaskStartScenarioInPlace(ped, GetRandomFromTable(scenarios), 0, true)
        end
    end)
end

-- Calculate enhanced client chance
function CalculateEnhancedClientChance(girl, location)
    local baseChance = 0.08 -- 8% base chance
    
    -- Girl attribute bonuses
    local appearanceBonus = (girl.attributes.appearance / 100) * 0.05
    local performanceBonus = (girl.attributes.performance / 100) * 0.03
    local reputationBonus = ((girl.reputation or 50) / 100) * 0.02
    
    -- Location factors
    local locationBonus = location.clientDensity * 0.04
    
    -- Time of day factor
    local hour = GetClockHours()
    local timeMultiplier = 1.0
    if hour >= 20 or hour <= 4 then
        timeMultiplier = 1.5 -- Night time bonus
    elseif hour >= 17 and hour <= 19 then
        timeMultiplier = 1.3 -- Evening bonus
    elseif hour >= 6 and hour <= 11 then
        timeMultiplier = 0.7 -- Morning penalty
    end
    
    -- Happiness factor
    local happinessMultiplier = 1.0
    if girl.happiness then
        if girl.happiness >= 80 then
            happinessMultiplier = 1.3
        elseif girl.happiness >= 60 then
            happinessMultiplier = 1.1
        elseif girl.happiness <= 30 then
            happinessMultiplier = 0.6
        elseif girl.happiness <= 50 then
            happinessMultiplier = 0.8
        end
    end
    
    local finalChance = (baseChance + appearanceBonus + performanceBonus + reputationBonus + locationBonus) * timeMultiplier * happinessMultiplier
    
    return math.min(finalChance, 0.25) -- Cap at 25%
end

-- Spawn enhanced client ped with better AI
function SpawnEnhancedClientPed(girlId, girlPed, location, girl)
    -- Select appropriate client model based on location and time
    local clientModels = Config.ClientModels
    local hour = GetClockHours()
    
    -- Filter models based on location prestige
    if location.name == "Casino District" or location.name == "Downtown Vinewood" then
        -- Wealthy area - prefer business models
        clientModels = {
            "a_m_m_business_01", "a_m_m_bevhills_01", "a_m_m_bevhills_02",
            "a_m_y_business_01", "a_m_y_business_02", "a_m_y_business_03",
            "a_m_y_vinewood_01", "a_m_y_vinewood_02"
        }
    elseif location.name == "South Los Santos" then
        -- Lower income area
        clientModels = {
            "a_m_m_skidrow_01", "a_m_m_tramp_01", "a_m_m_hillbilly_01",
            "a_m_y_genstreet_01", "a_m_y_genstreet_02"
        }
    end
    
    local model = GetRandomFromTable(clientModels)
    
    RequestModel(GetHashKey(model))
    while not HasModelLoaded(GetHashKey(model)) do
        Citizen.Wait(10)
    end
    
    -- Smart spawning - approach from street/parking areas when possible
    local girlCoords = GetEntityCoords(girlPed)
    local spawnRadius = math.random(30, 60)
    local attempts = 0
    local validSpawn = false
    local x, y, z
    
    while not validSpawn and attempts < 8 do
        local angle = math.random() * 2 * math.pi
        x = girlCoords.x + spawnRadius * math.cos(angle)
        y = girlCoords.y + spawnRadius * math.sin(angle)
        z = girlCoords.z
        
        local ground, groundZ = GetGroundZFor_3dCoord(x, y, z + 10.0, false)
        if ground then
            z = groundZ
            -- Check if spawn point is on a road or sidewalk
            if GetVehicleNodePosition(x, y, z) or IsPointOnRoad(x, y, z, 0) then
                validSpawn = true
            end
        end
        attempts = attempts + 1
    end
    
    if not validSpawn then
        -- Fallback spawn
        local angle = math.random() * 2 * math.pi
        x = girlCoords.x + 40 * math.cos(angle)
        y = girlCoords.y + 40 * math.sin(angle)
        z = girlCoords.z
        
        local ground, groundZ = GetGroundZFor_3dCoord(x, y, z + 5.0, false)
        if ground then
            z = groundZ
        end
    end
    
    -- Create ped
    local ped = CreatePed(4, GetHashKey(model), x, y, z, math.random(0, 359) * 1.0, false, true)
    
    -- Enhanced ped properties
    SetEntityAsMissionEntity(ped, true, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedCanBeTargetted(ped, false)
    SetPedCanRagdoll(ped, false)
    SetPedKeepTask(ped, true)
    
    -- Make ped walk to girl with appropriate behavior
    TaskGoToEntity(ped, girlPed, -1, 2.0, 1.2, 0, 0)
    
    -- Show enhanced notification
    if girl then
        local clientType = DetermineClientType(model, location, hour)
        ShowNotification(girl.name .. " has attracted a " .. clientType .. " client", "info")
    end
    
    return ped
end

-- Determine client type based on model and context
function DetermineClientType(model, location, hour)
    local businessModels = {
        "a_m_m_business_01", "a_m_m_bevhills_01", "a_m_m_bevhills_02",
        "a_m_y_business_01", "a_m_y_business_02", "a_m_y_business_03"
    }
    
    local wealthyModels = {
        "a_m_y_vinewood_01", "a_m_y_vinewood_02", "a_m_y_vinewood_03",
        "a_m_y_clubcust_01", "a_m_y_clubcust_02"
    }
    
    if TableContains(businessModels, model) then
        return "businessman"
    elseif TableContains(wealthyModels, model) then
        return "wealthy"
    elseif hour >= 20 or hour <= 4 then
        return "night"
    else
        return "regular"
    end
end

-- Handle enhanced client interaction
function HandleEnhancedClientInteraction(girlId, girlPed, clientPed, location, girl)
    -- Find girl data
    local girl = nil
    for _, g in ipairs(PlayerData.girls) do
        if g.id == girlId then
            girl = g
            break
        end
    end
    
    if not girl then return end
    
    -- Calculate interaction details
    local basePrice = CalculateBasePrice(girl, location)
    local minPrice = math.floor(basePrice * 0.7)
    local maxPrice = math.floor(basePrice * 1.5)
    local clientType = DetermineClientType(GetEntityModel(clientPed), location, GetClockHours())
    
    -- Check if negotiation system is available
    if StartClientNegotiation then
        local negotiationStarted = StartClientNegotiation(girlId, girlPed, clientPed, location)
        if negotiationStarted then
            return
        end
    end
    
    -- Enhanced client notification system
    TriggerEvent('pimp:girlFoundClient', girlId, girl.name, basePrice, minPrice, maxPrice, clientType, location.name)
end

-- Calculate base price for client interaction
function CalculateBasePrice(girl, location)
    local basePrice = 100
    
    -- Get girl type base price
    if Config.GirlSystem.girlTypes[girl.type] then
        basePrice = Config.GirlSystem.girlTypes[girl.type].baseEarnings or 100
    end
    
    -- Apply attribute modifiers
    local appearanceBonus = (girl.attributes.appearance - 50) * 2
    local performanceBonus = (girl.attributes.performance - 50) * 3
    local discretionBonus = (girl.attributes.discretion - 50) * 1
    
    -- Apply location modifier
    local locationMultiplier = location.priceMultiplier or location.earningsMultiplier or 1.0
    
    -- Apply happiness modifier
    local happinessMultiplier = 1.0
    if girl.happiness then
        if girl.happiness >= 80 then
            happinessMultiplier = 1.3
        elseif girl.happiness >= 60 then
            happinessMultiplier = 1.1
        elseif girl.happiness <= 30 then
            happinessMultiplier = 0.7
        elseif girl.happiness <= 50 then
            happinessMultiplier = 0.85
        end
    end
    
    -- Calculate final price
    local finalPrice = (basePrice + appearanceBonus + performanceBonus + discretionBonus) * locationMultiplier * happinessMultiplier
    
    return math.max(50, math.floor(finalPrice))
end

-- Enhanced Following System
function MakeGirlFollow(girl)
    if not Config.NPCInteraction.Following or not Config.NPCInteraction.Following.enabled then
        ShowNotification("Following system is disabled", "error")
        return
    end
    
    -- Check if girl is already following
    for i, followingGirl in ipairs(followingGirls) do
        if followingGirl.id == girl.id then
            ShowNotification(girl.name .. " is already following you", "info")
            return
        end
    end
    
    -- Check maximum followers
    if #followingGirls >= (Config.NPCInteraction.Following.maxFollowers or 3) then
        ShowNotification("You can't have more than " .. (Config.NPCInteraction.Following.maxFollowers or 3) .. " girls following you", "error")
        return
    end
    
    -- Store original status to restore later if needed
    local originalStatus = girl.status
    local originalWorkLocation = girl.workLocation
    
    -- Check if girl is spawned
    if not GirlPeds or not GirlPeds[girl.id] or not DoesEntityExist(GirlPeds[girl.id]) then
        -- Spawn the girl
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local playerHeading = GetEntityHeading(playerPed)
        
        -- Calculate spawn position
        local spawnDistance = 2.0 + (#followingGirls * 0.5) -- Stagger based on number of followers
        local x = playerCoords.x + math.sin(math.rad(playerHeading + 90)) * spawnDistance
        local y = playerCoords.y + math.cos(math.rad(playerHeading + 90)) * spawnDistance
        local z = playerCoords.z
        
        local ground, groundZ = GetGroundZFor_3dCoord(x, y, z + 10.0, 0)
        if ground then
            z = groundZ
        end
        
        -- Get appropriate model
        local model = GetRandomFromTable(Config.GirlModels)
        
        RequestModel(GetHashKey(model))
        local timeout = 0
        while not HasModelLoaded(GetHashKey(model)) and timeout < 50 do
            Citizen.Wait(100)
            timeout = timeout + 1
        end
        
        if not HasModelLoaded(GetHashKey(model)) then
            ShowNotification("Failed to load girl model", "error")
            return
        end
        
        -- Create ped
        local ped = CreatePed(4, GetHashKey(model), x, y, z, playerHeading - 180.0, true, false)
        
        -- Enhanced ped properties
        SetEntityAsMissionEntity(ped, true, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        SetPedCanBeTargetted(ped, false)
        SetPedKeepTask(ped, true)
        SetPedFleeAttributes(ped, 0, false)
        SetPedCombatAttributes(ped, 17, true)
        SetEntityInvincible(ped, true)
        
        -- Apply appearance
        ApplyGirlAppearance(ped, girl)
        
        -- Store the ped
        GirlPeds[girl.id] = ped
        
        -- Make the girl face the player initially
        TaskTurnPedToFaceEntity(ped, playerPed, 2000)
    end
    
    local ped = GirlPeds[girl.id]
    
    -- If the girl was working, clear her task so she can follow
    if girl.status == 'working' then
        ClearPedTasks(ped)
    end
    
    -- Create enhanced blip
    local blip = AddBlipForEntity(ped)
    SetBlipSprite(blip, 280)
    SetBlipColour(blip, 48)
    SetBlipScale(blip, 0.7)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(girl.name .. " (Following)")
    EndTextCommandSetBlipName(blip)
    
    -- Add to following list
    table.insert(followingGirls, {
        id = girl.id,
        name = girl.name,
        type = girl.type,
        ped = ped,
        blip = blip,
        inVehicle = false,
        followDistance = 2.0 + (#followingGirls * 0.8), -- Dynamic follow distance
        originalStatus = originalStatus,
        originalWorkLocation = originalWorkLocation
    })
    
    -- Set as following girl for global reference
    FollowingGirl = girl.id
    FollowingGirlPed = ped
    
    -- Start following if not already
    if not isFollowing then
        isFollowing = true
        StartEnhancedFollowing()
    end
    
    -- Play acknowledgment animation
    LoadAnimDict("gestures@f@standing@casual")
    TaskPlayAnim(ped, "gestures@f@standing@casual", "gesture_hello", 8.0, -8.0, 2000, 0, 0, false, false, false)
    
    ShowNotification(girl.name .. " is now following you", "success")
    
    -- Store for cleanup
    followingPeds[girl.id] = ped
    followingBlips[girl.id] = blip
    
    -- Update shared GirlPeds variable
    UpdateSharedGirlPeds()
end

-- Enhanced stop girl from following
function StopGirlFromFollowing(girlId, sendHome)
    for i, girl in ipairs(followingGirls) do
        if girl.id == girlId then
            local ped = girl.ped
            
            -- Remove from following list
            table.remove(followingGirls, i)
            
            -- Clear global following references
            if FollowingGirl == girlId then
                FollowingGirl = nil
                FollowingGirlPed = nil
            end
            
            if sendHome and DoesEntityExist(ped) then
                -- Enhanced send home behavior
                ShowNotification(girl.name .. " is going home", "info")
                
                -- Play goodbye animation
                LoadAnimDict("gestures@f@standing@casual")
                TaskPlayAnim(ped, "gestures@f@standing@casual", "gesture_bye_soft", 8.0, -8.0, 3000, 0, 0, false, false, false)
                
                -- Remove blip immediately
                if girl.blip and DoesBlipExist(girl.blip) then
                    RemoveBlip(girl.blip)
                end
                
                -- Make girl walk away naturally
                local playerPed = PlayerPedId()
                local playerCoords = GetEntityCoords(playerPed)
                local pedCoords = GetEntityCoords(ped)
                local direction = pedCoords - playerCoords
                direction = direction / #direction
                local targetCoords = pedCoords + direction * 100.0
                
                -- Find nearest road for more natural exit
                local roadFound, roadCoords = GetNthClosestVehicleNode(targetCoords.x, targetCoords.y, targetCoords.z, 1, 1, 300.0, 300.0)
                if roadFound then
                    targetCoords = roadCoords
                end
                
                ClearPedTasks(ped)
                TaskGoStraightToCoord(ped, targetCoords.x, targetCoords.y, targetCoords.z, 1.0, -1, 0.0, 0.0)
                
                -- Delete ped after delay with fade effect
                Citizen.SetTimeout(8000, function()
                    if DoesEntityExist(ped) then
                        -- Fade out effect
                        for alpha = 255, 0, -15 do
                            SetEntityAlpha(ped, alpha, false)
                            Citizen.Wait(50)
                        end
                        DeleteEntity(ped)
                        GirlPeds[girlId] = nil
                        -- Update shared GirlPeds variable
                        UpdateSharedGirlPeds()
                    end
                end)
            else
                -- Standard stop following
                ShowNotification(girl.name .. " has stopped following you", "info")
                
                if DoesEntityExist(ped) then
                    ClearPedTasks(ped)
                    
                    -- Remove blip
                    if girl.blip and DoesBlipExist(girl.blip) then
                        RemoveBlip(girl.blip)
                    end
                    
                    -- Check if girl was working before following
                    if girl.originalStatus == 'working' and girl.originalWorkLocation then
                        -- Find work location
                        local workLocation = nil
                        for _, location in ipairs(Config.WorkLocations) do
                            if girl.originalWorkLocation == location.name then
                                workLocation = location
                                break
                            end
                        end
                        
                        if workLocation then
                            -- Return to work location
                            local scenarios = GetAppropriateScenarios({type = girl.type}, workLocation)
                            TaskStartScenarioInPlace(ped, GetRandomFromTable(scenarios), 0, true)
                        end
                    else
                        -- Delete ped if not working
                        DeleteEntity(ped)
                        GirlPeds[girlId] = nil
                    end
                end
            end
            
            -- Clear stored references
            followingPeds[girlId] = nil
            followingBlips[girlId] = nil
            
            -- Stop following thread if no more girls
            if #followingGirls == 0 then
                isFollowing = false
            end
            
            -- Update shared GirlPeds variable
            UpdateSharedGirlPeds()
            
            return
        end
    end
end

-- Enhanced following system with vehicle support
function StartEnhancedFollowing()
    Citizen.CreateThread(function()
        while isFollowing and #followingGirls > 0 do
            Citizen.Wait(Config.NPCInteraction.Following.updateInterval or 1000)
            
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local playerInVehicle = IsPedInAnyVehicle(playerPed, false)
            
            -- Handle vehicle entry/exit
            if Config.NPCInteraction.Following and Config.NPCInteraction.Following.vehicleSupport then
                HandleEnhancedVehicleEntry(playerPed, playerInVehicle)
            end
            
            -- Update following girls
            for i, girl in ipairs(followingGirls) do
                if DoesEntityExist(girl.ped) then
                    local pedCoords = GetEntityCoords(girl.ped)
                    local distance = #(playerCoords - pedCoords)
                    
                    -- If not in vehicle mode
                    if not girl.inVehicle and not playerInVehicle then
                        local maxDistance = Config.NPCInteraction.Following and Config.NPCInteraction.Following.maxDistance or 10.0
                        
                        if distance > maxDistance then
                            -- Teleport if too far (prevents getting stuck)
                            if distance > maxDistance * 2 then
                                local teleportCoords = GetOffsetFromEntityInWorldCoords(playerPed, 
                                    math.random(-3, 3), math.random(-5, -2), 0.0)
                                SetEntityCoords(girl.ped, teleportCoords.x, teleportCoords.y, teleportCoords.z, 
                                    true, false, false, false)
                                
                                -- Update GirlPeds reference after teleporting
                                GirlPeds[girl.id] = girl.ped
                            else
                                -- Task girl to follow with staggered positioning
                                ClearPedTasks(girl.ped)
                                local followDistance = girl.followDistance or 2.0
                                TaskFollowToOffsetOfEntity(girl.ped, playerPed, 
                                    math.sin(i * 0.5) * 1.5, -- X offset
                                    -followDistance - (i * 0.3), -- Y offset (behind player)
                                    0.0, -- Z offset
                                    1.5, -- Move speed
                                    -1, -- Timeout
                                    followDistance * 0.8, -- Stop distance
                                    true) -- Persistent following
                            end
                        end
                        
                        -- Periodically make sure the girl is still following correctly
                        if math.random() < 0.1 then -- 10% chance each update
                            local followDistance = girl.followDistance or 2.0
                            TaskFollowToOffsetOfEntity(girl.ped, playerPed, 
                                math.sin(i * 0.5) * 1.5, -- X offset
                                -followDistance - (i * 0.3), -- Y offset (behind player)
                                0.0, -- Z offset
                                1.5, -- Move speed
                                -1, -- Timeout
                                followDistance * 0.8, -- Stop distance
                                true) -- Persistent following
                        end
                    end
                    
                    -- Update vehicle status
                    if girl.inVehicle and not IsPedInAnyVehicle(girl.ped, false) then
                        girl.inVehicle = false
                    end
                    
                    -- Update GirlPeds reference to ensure it stays current
                    GirlPeds[girl.id] = girl.ped
                else
                    -- Remove from following list if ped doesn't exist anymore
                    table.remove(followingGirls, i)
                    
                    -- Stop following thread if no more girls
                    if #followingGirls == 0 then
                        isFollowing = false
                    end
                end
            end
            
            -- Update shared GirlPeds variable
            UpdateSharedGirlPeds()
        end
    end)
end

-- Enhanced vehicle entry handling
function HandleEnhancedVehicleEntry(playerPed, playerInVehicle)
    if playerInVehicle then
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        local maxSeats = GetVehicleMaxNumberOfPassengers(vehicle) + 1
        
        -- Find girls not in vehicle
        local girlsToEnter = {}
        for i, girl in ipairs(followingGirls) do
            if not girl.inVehicle and DoesEntityExist(girl.ped) then
                table.insert(girlsToEnter, girl)
            end
        end
        
        -- Sort by distance to vehicle
        table.sort(girlsToEnter, function(a, b)
            local distA = #(GetEntityCoords(a.ped) - GetEntityCoords(vehicle))
            local distB = #(GetEntityCoords(b.ped) - GetEntityCoords(vehicle))
            return distA < distB
        end)
        
        -- Find available seats (skip driver seat)
        local availableSeats = {}
        for i = 0, maxSeats - 1 do
            if i ~= -1 and IsVehicleSeatFree(vehicle, i) then -- Skip driver seat
                table.insert(availableSeats, i)
            end
        end
        
        -- Make girls enter vehicle
        for i, girl in ipairs(girlsToEnter) do
            if i <= #availableSeats then
                TaskEnterVehicle(girl.ped, vehicle, -1, availableSeats[i], 1.0, 1, 0)
                girl.inVehicle = true
                ShowNotification(girl.name .. " is getting in your vehicle", "info")
            else
                ShowNotification("No more seats available for " .. girl.name, "warning")
            end
        end
    else
        -- Player exited vehicle - make girls exit
        for i, girl in ipairs(followingGirls) do
            if girl.inVehicle and DoesEntityExist(girl.ped) then
                if IsPedInAnyVehicle(girl.ped, false) then
                    TaskLeaveVehicle(girl.ped, GetVehiclePedIsIn(girl.ped, false), 0)
                end
                girl.inVehicle = false
                ShowNotification(girl.name .. " is getting out of the vehicle", "info")
            end
        end
    end
end

-- Stop all girls from following
function StopAllGirlsFromFollowing()
    -- Make a copy of the followingGirls table since we'll be modifying it
    local girlsToStop = {}
    for i, girl in ipairs(followingGirls) do
        table.insert(girlsToStop, girl.id)
    end
    
    -- Stop each girl from following
    for _, girlId in ipairs(girlsToStop) do
        StopGirlFromFollowing(girlId, true)
    end
    
    -- Clear global following references
    FollowingGirl = nil
    FollowingGirlPed = nil
    
    -- Clear any remaining references
    followingGirls = {}
    followingPeds = {}
    followingBlips = {}
    isFollowing = false
    
    -- Update shared GirlPeds variable
    UpdateSharedGirlPeds()
    
    ShowNotification("All girls have stopped following you", "info")
end

-- Enhanced delete girl ped with cleanup
function DeleteGirlPed(girlId)
    -- Delete ped
    if GirlPeds[girlId] and DoesEntityExist(GirlPeds[girlId]) then
        DeleteEntity(GirlPeds[girlId])
    end
    
    -- Remove blip
    if GirlBlips[girlId] then
        RemoveBlip(GirlBlips[girlId])
    end
    
    -- Clear location tracking
    if girlLocations[girlId] then
        girlLocations[girlId] = nil
    end
    
    -- Clear references
    GirlPeds[girlId] = nil
    GirlBlips[girlId] = nil
    
    -- Update shared GirlPeds variable
    UpdateSharedGirlPeds()
    DebugPrint("Removed girl ped " .. girlId .. " from GirlPeds")
end

-- Clear all girl entities with enhanced cleanup
function ClearGirlEntities()
    -- Delete all peds
    for girlId, ped in pairs(GirlPeds) do
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
    end
    
    -- Remove all blips
    for girlId, blip in pairs(GirlBlips) do
        RemoveBlip(blip)
    end
    
    -- Clear following system
    for girlId, ped in pairs(followingPeds) do
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
    end
    
    for girlId, blip in pairs(followingBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    
    -- Clear all references
    GirlPeds = {}
    GirlBlips = {}
    ActiveGirls = {}
    followingGirls = {}
    followingPeds = {}
    followingBlips = {}
    girlLocations = {}
    FollowingGirl = nil
    FollowingGirlPed = nil
    isFollowing = false
end

-- Enhanced location tracking system
function UpdateGirlLocationTracking()
    if not Config.EnhancedFeatures.locationTracking.enabled then return end
    
    for girlId, locationData in pairs(girlLocations) do
        -- Update location data
        if locationData.location then
            locationData.coords = locationData.location.coords
            locationData.lastUpdate = GetGameTimer()
            
            -- Calculate distance from player
            local playerCoords = GetEntityCoords(PlayerPedId())
            locationData.distance = #(playerCoords - locationData.coords)
        end
    end
end

-- Get girl location data
function GetGirlLocation(girlId)
    return girlLocations[girlId]
end

-- Check if girl is following
function IsGirlFollowing(girlId)
    -- First, respect a global follow check (from client/main.lua) if present
    if type(_G.IsGirlFollowing) == 'function' then
        local res = _G.IsGirlFollowing(girlId)
        if res then return true end
    end

    -- Check if girlId matches the local FollowingGirl variable
    if FollowingGirl == girlId then
        return true
    end
    
    -- Also check the followingGirls table for backward compatibility
    for i, girl in ipairs(followingGirls) do
        if girl.id == girlId then
            return true
        end
    end
    
    return false
end

-- Load animation dictionary helper
function LoadAnimDict(dict)
    RequestAnimDict(dict)
    local timeout = 0
    while not HasAnimDictLoaded(dict) and timeout < 100 do
        Citizen.Wait(10)
        timeout = timeout + 1
    end
end

-- Helper function to check if table contains value
function TableContains(table, value)
    for _, v in pairs(table) do
        if v == value then
            return true
        end
    end
    return false
end

-- Enhanced girl served client event
RegisterNetEvent('pimp:girlServedClientResult')
AddEventHandler('pimp:girlServedClientResult', function(girlId, earnings)
    local girlName = "Your girl"
    
    if PlayerData and PlayerData.girls then
        for _, girl in ipairs(PlayerData.girls) do
            if girl.id == girlId then
                girlName = girl.name
                break
            end
        end
    end
    
    ShowNotification(girlName .. ' served a client and earned $' .. FormatNumber(earnings), 'success')
end)

-- Register follow command
RegisterCommand(Config.NPCInteraction.Following.commands.followMe or "followme", function(source, args)
    if not PlayerData or not PlayerData.girls or #PlayerData.girls == 0 then
        ShowNotification("You don't have any girls to follow you", "error")
        return
    end
    
    if #args == 0 then
        -- Show menu if no specific girl mentioned
        -- This would integrate with the main menu system
        TriggerEvent('pimp:openFollowMenu')
    else
        local girlName = table.concat(args, " ")
        local girlFound = false
        
        for i, girl in ipairs(PlayerData.girls) do
            if girl.name:lower() == girlName:lower() or tostring(girl.id) == girlName then
                MakeGirlFollow(girl)
                girlFound = true
                break
            end
        end
        
        if not girlFound then
            ShowNotification("Could not find a girl named " .. girlName, "error")
        end
    end
end, false)

-- Register stop follow command
RegisterCommand(Config.NPCInteraction.Following.commands.stopFollow or "stopfollow", function(source, args)
    if #followingGirls == 0 then
        ShowNotification("No girls are currently following you", "info")
        return
    end
    
    if #args == 0 then
        if #followingGirls == 1 then
            StopGirlFromFollowing(followingGirls[1].id, true)
        else
            ShowNotification("Specify which girl should stop following or use stopallfollow", "info")
        end
    else
        local girlName = table.concat(args, " ")
        local girlFound = false
        
        for i, girl in ipairs(followingGirls) do
            if girl.name:lower() == girlName:lower() or tostring(girl.id) == girlName then
                StopGirlFromFollowing(girl.id, true)
                girlFound = true
                break
            end
        end
        
        if not girlFound then
            ShowNotification("Could not find a following girl named " .. girlName, "error")
        end
    end
end, false)

-- Register stop all follow command
RegisterCommand(Config.NPCInteraction.Following.commands.stopAllFollow or "stopallfollow", function()
    if #followingGirls == 0 then
        ShowNotification("No girls are currently following you", "info")
        return
    end
    
    StopAllGirlsFromFollowing()
end, false)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then
        return
    end
    
    ClearGirlEntities()
end)

-- Export functions
exports('GetActiveGirls', function()
    return ActiveGirls
end)

exports('GetGirlPeds', function()
    return GirlPeds
end)

exports('MakeGirlFollow', MakeGirlFollow)
exports('StopGirlFromFollowing', StopGirlFromFollowing)
exports('StopAllGirlsFromFollowing', StopAllGirlsFromFollowing)
exports('IsGirlFollowing', IsGirlFollowing)
exports('GetGirlLocation', GetGirlLocation)

exports('GetFollowingGirls', function() 
    return followingGirls 
end)

-- Make functions globally accessible
_G.MakeGirlFollow = MakeGirlFollow
_G.StopGirlFromFollowing = StopGirlFromFollowing
_G.StopAllGirlsFromFollowing = StopAllGirlsFromFollowing
_G.GetFollowingGirls = function() return followingGirls end
_G.IsGirlFollowing = IsGirlFollowing