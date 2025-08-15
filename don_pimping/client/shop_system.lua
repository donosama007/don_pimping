-- Pimp Management System - Shop System (COMPLETE FIXED VERSION)
-- Created by NinjaTech AI

-- Local variables
-- Silence F8 console unless debugging is explicitly enabled in Config
local print = function(...)
    if Config and Config.Debug then
        _G.print(...)
    end
end

local shopBlips = {}
local isNearShop = false
local currentShopLocation = nil

-- Debug function
local function DebugPrint(message)
    if Config and Config.Debug then
        print("^3[Shop Debug] " .. message .. "^7")
    end
end

-- Safe notification function
local function SafeNotify(message, type)
    DebugPrint("Notification: " .. message)
    
    -- Try ox_lib first
    if GetResourceState('ox_lib') == 'started' and lib and lib.notify then
        lib.notify({
            title = 'Girl Hiring',
            description = message,
            type = type or 'info'
        })
        return
    end
    
    -- Try qb-core notifications
    if GetResourceState('qb-core') == 'started' and QBCore and QBCore.Functions and QBCore.Functions.Notify then
        QBCore.Functions.Notify(message, type or 'primary')
        return
    end
    
    -- Try ESX notifications
    if GetResourceState('es_extended') == 'started' and ESX and ESX.ShowNotification then
        ESX.ShowNotification(message)
        return
    end
    
    -- Fallback to GTA notification
    SetNotificationTextEntry('STRING')
    AddTextComponentString(message)
    DrawNotification(false, false)
end

-- Initialize shop system
Citizen.CreateThread(function()
    -- Wait for everything to load
    Citizen.Wait(5000)
    
    DebugPrint("Initializing shop system...")
    
    -- Wait for the player to spawn
    while not NetworkIsPlayerActive(PlayerId()) do
        Citizen.Wait(100)
    end
    
    DebugPrint("Player active, creating blips...")
    
    -- Create blips for hiring locations
    CreateShopBlips()
    
    -- Start shop location check
    StartShopLocationCheck()
    
    DebugPrint("Shop system initialized")
end)

-- Create blips for hiring locations
function CreateShopBlips()
    DebugPrint("Creating shop blips...")
    
    -- Check if config exists
    if not Config or not Config.HiringLocations then
        DebugPrint("ERROR: Config.HiringLocations not found!")
        return
    end
    
    -- Remove existing blips
    for _, blip in pairs(shopBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    
    -- Clear blips table
    shopBlips = {}
    
    -- Create blips for each hiring location
    for i, location in pairs(Config.HiringLocations) do
        DebugPrint("Creating blip for: " .. (location.name or "Unknown"))
        
        -- Create blip
        local blip = AddBlipForCoord(location.coords.x, location.coords.y, location.coords.z)
        
        -- Set blip properties
        SetBlipSprite(blip, location.blip.sprite or 121)
        SetBlipColour(blip, location.blip.color or 48)
        SetBlipScale(blip, location.blip.scale or 0.8)
        SetBlipAsShortRange(blip, true)
        
        -- Set blip name
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(location.blip.label or "Girl Hiring")
        EndTextCommandSetBlipName(blip)
        
        -- Add blip to table
        table.insert(shopBlips, blip)
        
        DebugPrint("Created blip " .. i .. " successfully")
    end
    
    DebugPrint("Created " .. #shopBlips .. " shop blips")
end

-- Start shop location check
function StartShopLocationCheck()
    DebugPrint("Starting shop location check thread...")
    
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(1000)
            
            -- Get player position
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            
            -- Check if player is near any hiring location
            local nearShop = false
            local nearestShop = nil
            local nearestDistance = 999999.0
            
            if Config and Config.HiringLocations then
                for _, location in pairs(Config.HiringLocations) do
                    local distance = #(playerCoords - location.coords)
                    
                    if distance < 50.0 and distance < nearestDistance then
                        nearShop = true
                        nearestShop = location
                        nearestDistance = distance
                    end
                end
            end
            
            -- Update shop status
            if nearShop ~= isNearShop then
                isNearShop = nearShop
                currentShopLocation = nearestShop
                
                if isNearShop then
                    DebugPrint("Player near shop: " .. (nearestShop.name or "Unknown"))
                    -- Create shop NPC
                    CreateShopNPC()
                else
                    DebugPrint("Player left shop area")
                    -- Remove shop NPC
                    RemoveShopNPC()
                end
            end
        end
    end)
end

-- Create shop NPC
function CreateShopNPC()
    DebugPrint("Creating shop NPC...")
    
    Citizen.CreateThread(function()
        -- Check if we have a shop location
        if not currentShopLocation then
            DebugPrint("ERROR: No current shop location")
            return
        end
        
        -- Don't create if already exists
        if currentShopLocation.ped and DoesEntityExist(currentShopLocation.ped) then
            DebugPrint("NPC already exists")
            return
        end
        
        -- Create NPC
        local modelHash = GetHashKey("s_f_y_shop_mid")
        
        -- Request model
        RequestModel(modelHash)
        local timeout = 0
        while not HasModelLoaded(modelHash) and timeout < 100 do
            Citizen.Wait(100)
            timeout = timeout + 1
        end
        
        if not HasModelLoaded(modelHash) then
            DebugPrint("ERROR: Failed to load NPC model")
            return
        end
        
        -- Create ped
        local shopPed = CreatePed(4, modelHash, 
            currentShopLocation.coords.x, 
            currentShopLocation.coords.y, 
            currentShopLocation.coords.z - 1.0, 
            0.0, false, true)
        
        if not DoesEntityExist(shopPed) then
            DebugPrint("ERROR: Failed to create NPC")
            return
        end
        
        -- Set ped properties
        SetEntityHeading(shopPed, 0.0)
        FreezeEntityPosition(shopPed, true)
        SetEntityInvincible(shopPed, true)
        SetBlockingOfNonTemporaryEvents(shopPed, true)
        
        -- Store ped
        currentShopLocation.ped = shopPed
        
        DebugPrint("NPC created successfully with ID: " .. shopPed)
        
        -- Setup targeting
        SetupShopTargeting(shopPed)
        
        SetModelAsNoLongerNeeded(modelHash)
    end)
end

-- Remove shop NPC
function RemoveShopNPC()
    -- Check if we have a shop location with a ped
    if currentShopLocation and currentShopLocation.ped then
        DebugPrint("Removing shop NPC: " .. currentShopLocation.ped)
        
        -- Remove targeting first
        if exports['ox_target'] then
            exports['ox_target']:removeLocalEntity(currentShopLocation.ped)
        elseif exports['qb-target'] then
            exports['qb-target']:RemoveTargetEntity(currentShopLocation.ped)
        elseif exports['qtarget'] then
            exports['qtarget']:RemoveTargetEntity(currentShopLocation.ped)
        end
        
        -- Delete ped
        DeleteEntity(currentShopLocation.ped)
        currentShopLocation.ped = nil
    end
end

-- Setup shop targeting
function SetupShopTargeting(ped)
    DebugPrint("Setting up targeting for NPC: " .. ped)
    
    -- Check which targeting system is available
    if GetResourceState('ox_target') == 'started' and exports['ox_target'] then
        DebugPrint("Using ox_target")
        exports['ox_target']:addLocalEntity(ped, {
            {
                name = 'pimp:openShop',
                icon = 'fas fa-female',
                label = 'Browse Girls',
                canInteract = function(entity, distance, coords, name, bone)
                    return distance < 3.0
                end,
                onSelect = function(data)
                    DebugPrint("ox_target triggered")
                    OpenShopMenu()
                end
            }
        })
    elseif GetResourceState('qb-target') == 'started' and exports['qb-target'] then
        DebugPrint("Using qb-target")
        exports['qb-target']:AddTargetEntity(ped, {
            options = {
                {
                    type = "client",
                    icon = "fas fa-female",
                    label = "Browse Girls",
                    action = function()
                        DebugPrint("qb-target triggered")
                        OpenShopMenu()
                    end,
                    canInteract = function(entity, distance, data)
                        return distance < 3.0
                    end
                }
            },
            distance = 3.0
        })
    elseif GetResourceState('qtarget') == 'started' and exports['qtarget'] then
        DebugPrint("Using qtarget")
        exports['qtarget']:AddTargetEntity(ped, {
            options = {
                {
                    icon = "fas fa-female",
                    label = "Browse Girls",
                    action = function()
                        DebugPrint("qtarget triggered")
                        OpenShopMenu()
                    end
                }
            },
            distance = 3.0
        })
    else
        DebugPrint("No targeting system found, using fallback")
        -- Fallback: Create text UI prompt
        Citizen.CreateThread(function()
            while DoesEntityExist(ped) and currentShopLocation and currentShopLocation.ped == ped do
                Citizen.Wait(0)
                local playerPed = PlayerPedId()
                local playerCoords = GetEntityCoords(playerPed)
                local pedCoords = GetEntityCoords(ped)
                local distance = #(playerCoords - pedCoords)
                
                if distance < 3.0 then
                    -- Show text prompt
                    SetTextComponentFormat("STRING")
                    AddTextComponentString("Press ~INPUT_CONTEXT~ to browse girls")
                    DisplayHelpTextFromStringLabel(0, 0, 1, -1)
                    
                    -- Check for input
                    if IsControlJustPressed(0, 51) then -- E key
                        DebugPrint("Fallback input triggered")
                        OpenShopMenu()
                    end
                end
            end
        end)
    end
end

-- Open shop menu
function OpenShopMenu()
    DebugPrint("Opening shop menu...")
    
    -- Check if we have a shop location
    if not currentShopLocation then
        DebugPrint("ERROR: No shop location found")
        SafeNotify("No shop location found", "error")
        return
    end
    
    DebugPrint("Current shop: " .. (currentShopLocation.name or "Unknown"))
    
    -- Get available girl types
    local girlTypes = currentShopLocation.girlTypes
    if not girlTypes then
        DebugPrint("ERROR: No girl types for this location")
        SafeNotify("No girls available at this location", "error")
        return
    end
    
    DebugPrint("Girl types: " .. table.concat(girlTypes, ", "))
    
    -- Check config
    if not Config then
        DebugPrint("ERROR: Config is nil")
        SafeNotify("Configuration error - contact administrator", "error")
        return
    end
    
    if not Config.GirlSystem then
        DebugPrint("ERROR: Config.GirlSystem is nil")
        SafeNotify("Girl system configuration missing", "error")
        return
    end
    
    if not Config.GirlSystem.girlTypes then
        DebugPrint("ERROR: Config.GirlSystem.girlTypes is nil")
        SafeNotify("Girl types configuration missing", "error")
        return
    end
    
    DebugPrint("Config validation passed")
    
    -- Try ox_lib menu first
    if GetResourceState('ox_lib') == 'started' and lib and lib.registerContext then
        DebugPrint("Using ox_lib menu")
        CreateOxLibMenu(girlTypes)
        return
    end
    
    -- Try qb-menu
    if GetResourceState('qb-menu') == 'started' and exports['qb-menu'] then
        DebugPrint("Using qb-menu")
        CreateQBMenu(girlTypes)
        return
    end
    
    -- Fallback to simple input
    DebugPrint("Using fallback menu")
    CreateFallbackMenu(girlTypes)
end

-- Create ox_lib menu
function CreateOxLibMenu(girlTypes)
    local options = {}
    
    -- Add girl types to options
    for _, girlType in ipairs(girlTypes) do
        local girlTypeData = Config.GirlSystem.girlTypes[girlType]
        
        if girlTypeData then
            local price = girlTypeData.basePrice
            
            table.insert(options, {
                title = girlType,
                description = 'Price: $' .. price,
                icon = 'female',
                metadata = {
                    {label = 'Price', value = '$' .. price},
                    {label = 'Type', value = girlType},
                    {label = 'Base Earnings', value = '$' .. girlTypeData.baseEarnings .. '/hr'}
                },
                onSelect = function()
                    DebugPrint("Selected: " .. girlType)
                    PurchaseGirl(girlType, price)
                end
            })
        else
            DebugPrint("WARNING: Girl type data not found for: " .. girlType)
        end
    end
    
    if #options == 0 then
        SafeNotify("No valid girls available", "error")
        return
    end
    
    lib.registerContext({
        id = 'pimp_shop_menu',
        title = currentShopLocation.name .. ' - Girl Hiring',
        options = options
    })
    
    lib.showContext('pimp_shop_menu')
end

-- Create QB menu
function CreateQBMenu(girlTypes)
    local menuItems = {}
    
    for _, girlType in ipairs(girlTypes) do
        local girlTypeData = Config.GirlSystem.girlTypes[girlType]
        
        if girlTypeData then
            local price = girlTypeData.basePrice
            
            menuItems[#menuItems + 1] = {
                header = girlType,
                txt = 'Price: $' .. price .. ' | Earnings: $' .. girlTypeData.baseEarnings .. '/hr',
                params = {
                    event = 'pimp:purchaseGirl',
                    args = {
                        girlType = girlType,
                        price = price
                    }
                }
            }
        end
    end
    
    menuItems[#menuItems + 1] = {
        header = "Close",
        txt = "",
        params = {
            event = "qb-menu:closeMenu"
        }
    }
    
    exports['qb-menu']:openMenu(menuItems)
end

-- Create fallback menu
function CreateFallbackMenu(girlTypes)
    SafeNotify("Available girls: " .. table.concat(girlTypes, ", "), "info")
    SafeNotify("Use /buygirl [type] command to purchase", "info")
end

-- Purchase girl
function PurchaseGirl(girlType, price)
    DebugPrint("Purchasing girl: " .. girlType .. " for $" .. price)
    
    local girlTypeData = Config.GirlSystem.girlTypes[girlType]
    
    if not girlTypeData then
        DebugPrint("ERROR: Invalid girl type: " .. girlType)
        SafeNotify("Invalid girl type", "error")
        return
    end
    
    -- Simple purchase without money check for testing
    DebugPrint("Creating girl data...")
    
    -- Generate girl data
    local girlData = {
        type = girlType,
        name = GenerateGirlName(),
        happiness = 100,
        health = 100,
        working = false,
        earnings = 0,
        location = nil
    }
    
    -- Generate attributes
    girlData.attributes = {}
    for attribute, range in pairs(girlTypeData.attributes) do
        girlData.attributes[attribute] = math.random(range.min, range.max)
    end
    
    DebugPrint("Girl data created: " .. girlData.name)
    
    -- Trigger server event
    TriggerServerEvent('pimp:addGirl', girlData)
    
    SafeNotify("Hired " .. girlData.name .. " for $" .. price, "success")
end

-- Generate girl name
function GenerateGirlName()
    local names = {"Amber", "Bella", "Candy", "Diamond", "Emerald", "Faith", "Ginger", "Honey", "Ivy", "Jasmine", "Kiki", "Lily", "Misty", "Nikki", "Orchid", "Peach", "Queen", "Ruby", "Sapphire", "Tiffany", "Velvet", "Willow", "Xena", "Yasmine", "Zoe"}
    return names[math.random(1, #names)] .. " Star"
end

-- Register events
RegisterNetEvent('pimp:purchaseGirl')
AddEventHandler('pimp:purchaseGirl', function(data)
    PurchaseGirl(data.girlType, data.price)
end)

-- Commands for testing
RegisterCommand('testshop', function()
    DebugPrint("Test shop command triggered")
    if currentShopLocation then
        OpenShopMenu()
    else
        SafeNotify("You're not near a shop", "error")
    end
end, false)

RegisterCommand('buygirl', function(source, args)
    if not args[1] then
        SafeNotify("Usage: /buygirl [type]", "error")
        return
    end
    
    local girlType = args[1]
    if Config and Config.GirlSystem and Config.GirlSystem.girlTypes and Config.GirlSystem.girlTypes[girlType] then
        local price = Config.GirlSystem.girlTypes[girlType].basePrice
        PurchaseGirl(girlType, price)
    else
        SafeNotify("Invalid girl type: " .. girlType, "error")
    end
end, false)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then
        return
    end
    
    DebugPrint("Cleaning up shop system...")
    
    -- Remove blips
    for _, blip in pairs(shopBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    
    -- Remove NPC
    RemoveShopNPC()
end)