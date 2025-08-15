-- Pimp Management System - NPC Interaction System
-- Created by NinjaTech AI

-- Local variables
-- Silence F8 console unless debugging is explicitly enabled in Config
local print = function(...)
    if Config and Config.Debug then
        _G.print(...)
    end
end

local isNearbyNPC = false
local nearbyPeds = {}
local currentInteractionPed = nil
local currentInteractionGirl = nil
local interactionInProgress = false
local interactionBlips = {}
local pimpingMode = false

-- Start pimping mode
RegisterNetEvent('pimp:startPimping')
AddEventHandler('pimp:startPimping', function()
    -- Check if already in pimping mode
    if pimpingMode then
        ShowNotification('You are already in pimping mode', 'info')
        return
    end
    
    -- Start pimping mode
    pimpingMode = true
    isNearbyNPC = true
    ShowNotification('Pimping mode activated. You can now interact with nearby NPCs', 'success')
    
    -- Start nearby NPC detection
    StartNearbyNPCDetection()
end)

-- Stop pimping mode
RegisterNetEvent('pimp:stopPimping')
AddEventHandler('pimp:stopPimping', function()
    -- Check if in pimping mode
    if not pimpingMode then
        ShowNotification('You are not in pimping mode', 'info')
        return
    end
    
    -- Stop pimping mode
    pimpingMode = false
    isNearbyNPC = false
    ShowNotification('Pimping mode deactivated', 'info')
    
    -- Clear nearby peds
    nearbyPeds = {}
    
    -- Remove all blips
    for _, blip in pairs(interactionBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    interactionBlips = {}
end)

-- Register commands
RegisterCommand('startpimping', function()
    TriggerEvent('pimp:startPimping')
end, false)

RegisterCommand('stoppimping', function()
    TriggerEvent('pimp:stopPimping')
end, false)

-- Start nearby NPC detection
function StartNearbyNPCDetection()
    Citizen.CreateThread(function()
        while isNearbyNPC do
            Citizen.Wait(1000) -- Check every second
            
            -- Get player position
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            
            -- Clear old nearby peds
            nearbyPeds = {}
            
            -- Remove all blips
            for _, blip in pairs(interactionBlips) do
                if DoesBlipExist(blip) then
                    RemoveBlip(blip)
                end
            end
            interactionBlips = {}
            
            -- Find nearby peds
            local peds = GetGamePool('CPed')
            for _, ped in ipairs(peds) do
                -- Skip if ped is player or not human
                if ped ~= playerPed and not IsPedAPlayer(ped) and IsPedHuman(ped) and not IsPedDeadOrDying(ped, true) then
                    -- Skip if ped is one of our girls
                    local isOurGirl = false
                    if GirlPeds then
                        for _, girlPed in pairs(GirlPeds) do
                            if ped == girlPed then
                                isOurGirl = true
                                break
                            end
                        end
                    end
                    
                    if not isOurGirl then
                        -- Get ped position
                        local pedCoords = GetEntityCoords(ped)
                        local distance = #(playerCoords - pedCoords)
                        
                        -- Check if ped is within range
                        if distance <= 20.0 then
                            -- Add to nearby peds
                            table.insert(nearbyPeds, {
                                ped = ped,
                                coords = pedCoords,
                                distance = distance,
                                model = GetEntityModel(ped)
                            })
                            
                            -- Create blip for ped
                            local blip = AddBlipForEntity(ped)
                            SetBlipSprite(blip, 280)
                            SetBlipColour(blip, 1)
                            SetBlipScale(blip, 0.8)
                            SetBlipAsShortRange(blip, true)
                            BeginTextCommandSetBlipName("STRING")
                            AddTextComponentString("Potential Client")
                            EndTextCommandSetBlipName(blip)
                            
                            -- Add to blips table
                            table.insert(interactionBlips, blip)
                        end
                    end
                end
            end
        end
    end)
    
    -- Setup third-eye targeting for nearby peds
    Citizen.CreateThread(function()
        while isNearbyNPC do
            Citizen.Wait(1000) -- Check every second
            
            -- Setup targeting for each nearby ped
            for _, pedData in ipairs(nearbyPeds) do
                -- Skip if already setup
                if not pedData.targetSetup then
                    -- Setup third-eye targeting
                    SetupPedTargeting(pedData.ped)
                    pedData.targetSetup = true
                end
            end
        end
    end)
    
    -- Interaction key handling
    Citizen.CreateThread(function()
        while isNearbyNPC do
            Citizen.Wait(0)
            
            -- Check for nearby peds
            if #nearbyPeds > 0 and not interactionInProgress then
                -- Get player position
                local playerPed = PlayerPedId()
                local playerCoords = GetEntityCoords(playerPed)
                
                -- Find closest ped
                local closestPed = nil
                local closestDistance = Config.NPCInteraction.interactionDistance + 1.0
                
                for _, pedData in ipairs(nearbyPeds) do
                    if DoesEntityExist(pedData.ped) then
                        local pedCoords = GetEntityCoords(pedData.ped)
                        local distance = #(playerCoords - pedCoords)
                        
                        if distance < closestDistance then
                            closestPed = pedData.ped
                            closestDistance = distance
                        end
                    end
                end
                
                -- If close to a ped, show interaction prompt
                if closestPed and closestDistance <= Config.NPCInteraction.interactionDistance then
                    -- Show help text
                    BeginTextCommandDisplayHelp("STRING")
                    AddTextComponentSubstringPlayerName("Press ~INPUT_CONTEXT~ to offer services")
                    EndTextCommandDisplayHelp(0, false, true, -1)
                    
                    -- Check for input
                    if IsControlJustReleased(0, 38) then -- E key
                        -- Start interaction
                        StartNPCInteraction(closestPed)
                    end
                end
            end
        end
    end)
end

-- Setup third-eye targeting for a ped
function SetupPedTargeting(ped)
    -- Check which targeting system is available
    if exports['ox_target'] then
        -- ox_target
        exports['ox_target']:addLocalEntity(ped, {
            {
                name = 'pimp:offerServices',
                icon = 'fas fa-user-tie',
                label = 'Offer Services',
                canInteract = function(entity, distance, coords, name, bone)
                    return not interactionInProgress and distance < Config.NPCInteraction.interactionDistance
                end,
                onSelect = function(data)
                    StartNPCInteraction(ped)
                end
            }
        })
    elseif exports['qb-target'] then
        -- qb-target
        exports['qb-target']:AddTargetEntity(ped, {
            options = {
                {
                    type = "client",
                    icon = "fas fa-user-tie",
                    label = "Offer Services",
                    action = function()
                        StartNPCInteraction(ped)
                    end,
                    canInteract = function(entity, distance, data)
                        return not interactionInProgress and distance < Config.NPCInteraction.interactionDistance
                    end
                }
            },
            distance = Config.NPCInteraction.interactionDistance
        })
    elseif exports['qtarget'] then
        -- qtarget
        exports['qtarget']:AddTargetEntity(ped, {
            options = {
                {
                    icon = "fas fa-user-tie",
                    label = "Offer Services",
                    action = function()
                        StartNPCInteraction(ped)
                    end
                }
            },
            distance = Config.NPCInteraction.interactionDistance
        })
    end
    -- Note: Default interaction is handled by the key press thread
end

-- Start NPC interaction
function StartNPCInteraction(ped)
    -- Check if already in an interaction
    if interactionInProgress then
        return
    end
    
    -- Set interaction in progress
    interactionInProgress = true
    currentInteractionPed = ped
    
    -- Get NPC type
    local npcModel = GetEntityModel(ped)
    local npcType = nil
    
    for _, type in ipairs(Config.NPCInteraction.npcTypes) do
        if GetHashKey(type.model) == npcModel then
            npcType = type
            break
        end
    end
    
    -- If NPC type not found, use default
    if not npcType then
        npcType = {
            name = "Stranger",
            priceMultiplier = 1.0,
            preferredService = "Standard Service"
        }
    end
    
    -- Open girl selection menu
    OpenGirlSelectionMenu(npcType)
end

-- Open girl selection menu
function OpenGirlSelectionMenu(npcType)
    -- Check if player has any girls
    if not PlayerData or not PlayerData.girls or #PlayerData.girls == 0 then
        ShowNotification('You don\'t have any girls to offer', 'error')
        interactionInProgress = false
        return
    end
    
    -- Create options for each available girl
    local options = {}
    
    for i, girl in ipairs(PlayerData.girls) do
        -- Skip if girl is working or has attitude
        if girl.status ~= 'working' and not girl.hasAttitude then
            -- Get happiness info
            local happinessIcon = GetHappinessIcon(girl.happiness or 50)
            local happinessColor = GetHappinessColor(girl.happiness or 50)
            local happinessDesc = GetHappinessDescription(girl.happiness or 50)
            
            table.insert(options, {
                title = girl.name .. ' - ' .. girl.type,
                description = 'Appearance: ' .. girl.attributes.appearance .. ' | Performance: ' .. girl.attributes.performance,
                icon = 'female',
                metadata = {
                    {label = 'Appearance', value = girl.attributes.appearance},
                    {label = 'Performance', value = girl.attributes.performance},
                    {label = 'Happiness', value = happinessDesc, icon = happinessIcon, iconColor = happinessColor}
                },
                onSelect = function()
                    OpenServiceSelectionMenu(npcType, girl, i)
                end
            })
        end
    end
    
    -- Add cancel option
    table.insert(options, {
        title = 'Cancel',
        icon = 'times',
        onSelect = function()
            interactionInProgress = false
        end
    })
    
    -- Show menu
    ShowContextMenu('pimp_girl_selection_menu', 'Select a Girl to Offer', nil, options)
end

-- Open service selection menu
function OpenServiceSelectionMenu(npcType, girl, girlIndex)
    -- Create options for each service
    local options = {}
    
    for _, service in ipairs(Config.NPCInteraction.services) do
        -- Calculate price based on girl's attributes and NPC type
        local basePrice = service.basePrice
        local performanceMultiplier = girl.attributes.performance / 50 -- 0.5 to 2.0
        local appearanceMultiplier = girl.attributes.appearance / 50 -- 0.5 to 2.0
        local npcMultiplier = npcType.priceMultiplier
        
        local price = math.floor(basePrice * performanceMultiplier * appearanceMultiplier * npcMultiplier)
        
        -- Highlight preferred service
        local isPreferred = service.name == npcType.preferredService
        
        table.insert(options, {
            title = service.name,
            description = 'Duration: ' .. math.floor(service.duration / 60) .. ' min | Price: $' .. price,
            icon = isPreferred and 'star' or 'clock',
            metadata = {
                {label = 'Duration', value = math.floor(service.duration / 60) .. ' minutes'},
                {label = 'Base Price', value = '$' .. service.basePrice},
                {label = 'Final Price', value = '$' .. price},
                {label = 'Preferred by Client', value = isPreferred and 'Yes' or 'No'}
            },
            onSelect = function()
                NegotiatePrice(npcType, girl, girlIndex, service, price)
            end
        })
    end
    
    -- Add cancel option
    table.insert(options, {
        title = 'Cancel',
        icon = 'times',
        onSelect = function()
            interactionInProgress = false
        end
    })
    
    -- Show menu
    ShowContextMenu('pimp_service_selection_menu', 'Select a Service to Offer', 'pimp_girl_selection_menu', options)
end

-- Negotiate price
function NegotiatePrice(npcType, girl, girlIndex, service, suggestedPrice)
    -- Calculate NPC's willingness to pay
    local willingness = math.random(80, 120) / 100 -- 0.8 to 1.2
    local npcMaxPrice = math.floor(suggestedPrice * willingness)
    
    -- Calculate minimum acceptable price
    local minPrice = math.floor(suggestedPrice * 0.7)
    
    -- Create input dialog
    local input = ShowInputDialog('Negotiate Price', {
        {
            type = 'number',
            label = 'Your Price',
            description = 'Suggested: $' .. suggestedPrice .. ' | Minimum: $' .. minPrice,
            default = suggestedPrice,
            min = minPrice,
            max = suggestedPrice * 1.5
        }
    })
    
    -- Check if input was canceled
    if not input then
        interactionInProgress = false
        return
    end
    
    -- Get negotiated price
    local negotiatedPrice = input[1]
    
    -- Check if NPC accepts the price
    local acceptChance = 1.0 - ((negotiatedPrice - suggestedPrice) / suggestedPrice)
    if negotiatedPrice <= npcMaxPrice or math.random() < acceptChance then
        -- NPC accepts
        ShowNotification(npcType.name .. ' accepted your price of $' .. negotiatedPrice, 'success')
        
        -- Start service
        StartService(npcType, girl, girlIndex, service, negotiatedPrice)
    else
        -- NPC rejects
        ShowNotification(npcType.name .. ' rejected your price', 'error')
        
        -- Counter offer
        local counterOffer = math.floor(npcMaxPrice * 0.9)
        
        -- Create alert dialog
        local alert = ShowAlertDialog(
            'Counter Offer',
            npcType.name .. ' offers $' .. counterOffer .. ' instead',
            true,
            true
        )
        
        if alert == 'confirm' then
            -- Accept counter offer
            ShowNotification('You accepted the counter offer of $' .. counterOffer, 'success')
            
            -- Start service
            StartService(npcType, girl, girlIndex, service, counterOffer)
        else
            -- Reject counter offer
            ShowNotification('You rejected the counter offer', 'info')
            interactionInProgress = false
        end
    end
end

-- Start service
function StartService(npcType, girl, girlIndex, service, price)
    -- Set current interaction girl
    currentInteractionGirl = girl
    
    -- Show progress bar
    ShowProgressBar('service_preparation', 'Preparing ' .. girl.name .. ' for service...', 3000, 'handshake')
    
    -- Wait for progress bar
    Citizen.Wait(3000)
    
    -- Check if girl is spawned
    local girlPed = nil
    if GirlPeds and GirlPeds[girl.id] and DoesEntityExist(GirlPeds[girl.id]) then
        girlPed = GirlPeds[girl.id]
    else
        -- Spawn girl temporarily
        local models = Config.GirlModels
        local model = GetRandomFromTable(models)
        
        -- Request model
        RequestModel(GetHashKey(model))
        while not HasModelLoaded(GetHashKey(model)) do
            Citizen.Wait(1)
        end
        
        -- Create ped
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local playerHeading = GetEntityHeading(playerPed)
        
        -- Position to the side of player
        local x = playerCoords.x + math.sin(math.rad(playerHeading + 90)) * 1.0
        local y = playerCoords.y + math.cos(math.rad(playerHeading + 90)) * 1.0
        local z = playerCoords.z
        
        girlPed = CreatePed(4, GetHashKey(model), x, y, z, playerHeading, true, false)
        
        -- Set ped properties
        SetEntityAsMissionEntity(girlPed, true, true)
        SetBlockingOfNonTemporaryEvents(girlPed, true)
        SetPedCanBeTargetted(girlPed, false)
        SetPedKeepTask(girlPed, true)
    end
    
    -- Make girl and NPC walk away together
    if DoesEntityExist(girlPed) and DoesEntityExist(currentInteractionPed) then
        -- Get a random location nearby
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local playerHeading = GetEntityHeading(playerPed)
        
        -- Position some distance away
        local distance = 50.0
        local angle = math.random() * 360
        local x = playerCoords.x + math.sin(math.rad(angle)) * distance
        local y = playerCoords.y + math.cos(math.rad(angle)) * distance
        local z = playerCoords.z
        
        -- Make NPC follow girl
        TaskFollowToOffsetOfEntity(currentInteractionPed, girlPed, 0.0, -1.0, 0.0, 1.0, -1, 5.0, true)
        
        -- Make girl walk to location
        TaskGoStraightToCoord(girlPed, x, y, z, 1.0, 20000, playerHeading, 0.1)
    end
    
    -- Show notification
    ShowNotification(girl.name .. ' is now with the client. Service will take ' .. math.floor(service.duration / 60) .. ' minutes', 'info')
    
    -- Set girl status to working
    TriggerServerEvent('pimp:setGirlStatus', girl.id, 'working')
    
    -- Add cooldown
    local cooldownDuration = service.duration * 1000 -- Convert seconds to milliseconds
    TriggerServerEvent('pimp:addCooldown', girl.id, 'work', cooldownDuration)
    
    -- Complete service after duration
    Citizen.SetTimeout(service.duration * 1000, function()
        CompleteService(npcType, girl, girlIndex, service, price)
    end)
end

-- Complete service
function CompleteService(npcType, girl, girlIndex, service, price)
    -- Add money to player
    TriggerServerEvent('pimp:addMoney', price)
    
    -- Add earnings to girl
    TriggerServerEvent('pimp:addGirlEarnings', girl.id, price)
    
    -- Set girl status to idle
    TriggerServerEvent('pimp:setGirlStatus', girl.id, 'idle')
    
    -- Show notification
    ShowNotification(girl.name .. ' has completed the service and earned you $' .. price, 'success')
    
    -- Delete temporary girl ped if we created one
    if not GirlPeds or not GirlPeds[girl.id] then
        if DoesEntityExist(girlPed) then
            DeleteEntity(girlPed)
        end
    end
    
    -- Reset interaction
    interactionInProgress = false
    currentInteractionPed = nil
    currentInteractionGirl = nil
end

-- Export functions
exports('StartPimping', function()
    TriggerEvent('pimp:startPimping')
end)

exports('StopPimping', function()
    TriggerEvent('pimp:stopPimping')
end)

exports('IsInPimpingMode', function()
    return pimpingMode
end)