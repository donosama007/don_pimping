-- Pimp Management System - Client Negotiation System
-- Created by NinjaTech AI

-- Silence F8 console unless debugging is explicitly enabled in Config
local print = function(...)
    if Config and Config.Debug then
        _G.print(...)
    end
end

-- Local variables
local currentNegotiation = {
    active = false,
    girlId = nil,
    girlPed = nil,
    clientPed = nil,
    basePrice = 0,
    location = nil,
    successChance = 0
}

-- Function to start negotiation with client
function StartClientNegotiation(girlId, girlPed, clientPed, location)
    -- Check if negotiation is already active
    if currentNegotiation.active then
        return false
    end
    
    -- Find girl data
    local girl = nil
    for _, g in ipairs(PlayerData.girls) do
        if g.id == girlId then
            girl = g
            break
        end
    end
    
    -- Check if girl exists
    if not girl then
        return false
    end
    
    -- Calculate base price based on girl attributes and location
    local basePrice = CalculateBasePrice(girl, location)
    
    -- Calculate success chance based on girl attributes
    local successChance = CalculateNegotiationSuccessChance(girl)
    
    -- Set current negotiation data
    currentNegotiation = {
        active = true,
        girlId = girlId,
        girlPed = girlPed,
        clientPed = clientPed,
        basePrice = basePrice,
        location = location,
        successChance = successChance
    }
    
    -- Show negotiation menu
    ShowNegotiationMenu(girl, basePrice, successChance)
    
    return true
end

-- Calculate base price for negotiation
function CalculateBasePrice(girl, location)
    -- Base price from girl type
    local basePrice = 0
    
    -- Get girl type config
    for typeName, typeConfig in pairs(Config.GirlSystem.girlTypes) do
        if typeName == girl.type then
            basePrice = typeConfig.basePrice
            break
        end
    end
    
    -- Adjust based on girl attributes
    local appearanceBonus = (girl.attributes.appearance - 5) * 20 -- -100 to +100
    local performanceBonus = (girl.attributes.performance - 5) * 30 -- -150 to +150
    
    -- Adjust based on location
    local locationMultiplier = location.priceMultiplier or 1.0
    
    -- Calculate final base price
    local finalPrice = math.floor((basePrice + appearanceBonus + performanceBonus) * locationMultiplier)
    
    -- Ensure minimum price
    return math.max(50, finalPrice)
end

-- Calculate negotiation success chance
function CalculateNegotiationSuccessChance(girl)
    -- Base chance
    local baseChance = 50
    
    -- Adjust based on girl attributes
    local appearanceBonus = (girl.attributes.appearance - 5) * 3 -- -15% to +15%
    local performanceBonus = (girl.attributes.performance - 5) * 2 -- -10% to +10%
    local discretionBonus = (girl.attributes.discretion - 5) * 5 -- -25% to +25%
    
    -- Apply perk bonus if available
    local negotiationBonus = 0
    if PlayerData.perks and PlayerData.perks.business then
        if PlayerData.perks.business.negotiation_skill_1 then
            negotiationBonus = negotiationBonus + 10
        end
        if PlayerData.perks.business.negotiation_skill_2 then
            negotiationBonus = negotiationBonus + 10
        end
    end
    
    -- Calculate final chance
    local finalChance = baseChance + appearanceBonus + performanceBonus + discretionBonus + negotiationBonus
    
    -- Clamp between 10% and 90%
    return math.max(10, math.min(90, finalChance))
end

-- Show negotiation menu
function ShowNegotiationMenu(girl, basePrice, successChance)
    -- Format price
    local formattedPrice = FormatNumber(basePrice)
    
    -- Create options
    local options = {
        {
            title = 'Agree to Price',
            description = 'Accept the offered price of ' .. Config.DefaultCurrency .. formattedPrice,
            icon = 'check-circle',
            onSelect = function()
                AcceptClientOffer(basePrice)
            end
        },
        {
            title = 'Negotiate',
            description = 'Try to negotiate a better price (Success Chance: ' .. successChance .. '%)',
            icon = 'comments-dollar',
            onSelect = function()
                ShowNegotiationOptions(girl, basePrice, successChance)
            end
        },
        {
            title = 'Reject Client',
            description = 'Turn down this client and wait for another',
            icon = 'times-circle',
            onSelect = function()
                RejectClient()
            end
        }
    }
    
    -- Show menu
    lib.registerContext({
        id = 'pimp_negotiation_menu',
        title = 'Client Negotiation - ' .. girl.name,
        options = options
    })
    
    lib.showContext('pimp_negotiation_menu')
end

-- Show negotiation options
function ShowNegotiationOptions(girl, basePrice, successChance)
    -- Calculate higher and lower prices
    local higherPrice = math.floor(basePrice * 1.25)
    local lowerPrice = math.floor(basePrice * 1.1)
    
    -- Format prices
    local formattedHigher = FormatNumber(higherPrice)
    local formattedLower = FormatNumber(lowerPrice)
    
    -- Calculate success chances
    local higherChance = math.floor(successChance * 0.7) -- 70% of base chance
    local lowerChance = math.floor(successChance * 1.3) -- 130% of base chance
    
    -- Clamp chances
    higherChance = math.max(5, math.min(85, higherChance))
    lowerChance = math.max(15, math.min(95, lowerChance))
    
    -- Create options
    local options = {
        {
            title = 'Ask for ' .. Config.DefaultCurrency .. formattedHigher,
            description = 'Try to get a higher price (Success Chance: ' .. higherChance .. '%)',
            icon = 'arrow-up',
            onSelect = function()
                AttemptNegotiation(higherPrice, higherChance)
            end
        },
        {
            title = 'Ask for ' .. Config.DefaultCurrency .. formattedLower,
            description = 'Try to get a slightly better price (Success Chance: ' .. lowerChance .. '%)',
            icon = 'arrow-up-right',
            onSelect = function()
                AttemptNegotiation(lowerPrice, lowerChance)
            end
        },
        {
            title = 'Go Back',
            description = 'Return to previous options',
            icon = 'arrow-left',
            onSelect = function()
                ShowNegotiationMenu(girl, basePrice, successChance)
            end
        }
    }
    
    -- Show menu
    lib.registerContext({
        id = 'pimp_negotiation_options',
        title = 'Negotiation Options - ' .. girl.name,
        menu = 'pimp_negotiation_menu',
        options = options
    })
    
    lib.showContext('pimp_negotiation_options')
end

-- Attempt negotiation
function AttemptNegotiation(requestedPrice, successChance)
    -- Check if negotiation is active
    if not currentNegotiation.active then
        return
    end
    
    -- Roll for success
    local roll = math.random(1, 100)
    local success = roll <= successChance
    
    -- Get girl data
    local girl = nil
    for _, g in ipairs(PlayerData.girls) do
        if g.id == currentNegotiation.girlId then
            girl = g
            break
        end
    end
    
    if not girl then
        ResetNegotiation()
        return
    end
    
    -- Handle result
    if success then
        -- Client accepts negotiation
        ShowNotification('The client accepted your price of ' .. Config.DefaultCurrency .. FormatNumber(requestedPrice), 'success')
        
        -- Play success animation
        if currentNegotiation.clientPed and DoesEntityExist(currentNegotiation.clientPed) then
            LoadAnimDict('mp_common')
            TaskPlayAnim(currentNegotiation.clientPed, 'mp_common', 'givetake1_a', 8.0, -8.0, 2000, 0, 0, false, false, false)
        end
        
        -- Accept the negotiated price
        AcceptClientOffer(requestedPrice)
    else
        -- Client rejects negotiation
        ShowNotification('The client rejected your price and walked away', 'error')
        
        -- Play rejection animation
        if currentNegotiation.clientPed and DoesEntityExist(currentNegotiation.clientPed) then
            LoadAnimDict('gestures@m@standing@casual')
            TaskPlayAnim(currentNegotiation.clientPed, 'gestures@m@standing@casual', 'gesture_no_way', 8.0, -8.0, 2000, 0, 0, false, false, false)
            
            -- Wait for animation to finish
            Citizen.Wait(2000)
            
            -- Make client walk away
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local clientCoords = GetEntityCoords(currentNegotiation.clientPed)
            local direction = clientCoords - playerCoords
            direction = direction / #direction
            local targetCoords = clientCoords + direction * 50.0
            
            TaskGoStraightToCoord(currentNegotiation.clientPed, targetCoords.x, targetCoords.y, targetCoords.z, 1.0, -1, 0.0, 0.0)
            
            -- Delete client after a delay
            Citizen.SetTimeout(10000, function()
                if currentNegotiation.clientPed and DoesEntityExist(currentNegotiation.clientPed) then
                    DeleteEntity(currentNegotiation.clientPed)
                end
            end)
        end
        
        -- Reset negotiation
        ResetNegotiation()
    end
end

-- Accept client offer
function AcceptClientOffer(finalPrice)
    -- Check if negotiation is active
    if not currentNegotiation.active then
        return
    end
    
    -- Get girl data
    local girl = nil
    for _, g in ipairs(PlayerData.girls) do
        if g.id == currentNegotiation.girlId then
            girl = g
            break
        end
    end
    
    if not girl then
        ResetNegotiation()
        return
    end
    
    -- Show notification
    ShowNotification(girl.name .. ' is now serving the client for ' .. Config.DefaultCurrency .. FormatNumber(finalPrice), 'success')
    
    -- Trigger server event
    TriggerServerEvent('pimp:girlServedClient', currentNegotiation.girlId, currentNegotiation.location.name, finalPrice)
    
    -- Reset negotiation
    ResetNegotiation()
end

-- Reject client
function RejectClient()
    -- Check if negotiation is active
    if not currentNegotiation.active then
        return
    end
    
    -- Get girl data
    local girl = nil
    for _, g in ipairs(PlayerData.girls) do
        if g.id == currentNegotiation.girlId then
            girl = g
            break
        end
    end
    
    if not girl then
        ResetNegotiation()
        return
    end
    
    -- Show notification
    ShowNotification('You rejected the client. ' .. girl.name .. ' will wait for another client.', 'info')
    
    -- Make client walk away
    if currentNegotiation.clientPed and DoesEntityExist(currentNegotiation.clientPed) then
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local clientCoords = GetEntityCoords(currentNegotiation.clientPed)
        local direction = clientCoords - playerCoords
        direction = direction / #direction
        local targetCoords = clientCoords + direction * 50.0
        
        TaskGoStraightToCoord(currentNegotiation.clientPed, targetCoords.x, targetCoords.y, targetCoords.z, 1.0, -1, 0.0, 0.0)
        
        -- Delete client after a delay
        Citizen.SetTimeout(10000, function()
            if currentNegotiation.clientPed and DoesEntityExist(currentNegotiation.clientPed) then
                DeleteEntity(currentNegotiation.clientPed)
            end
        end)
    end
    
    -- Reset negotiation
    ResetNegotiation()
end

-- Reset negotiation
function ResetNegotiation()
    currentNegotiation = {
        active = false,
        girlId = nil,
        girlPed = nil,
        clientPed = nil,
        basePrice = 0,
        location = nil,
        successChance = 0
    }
end

-- Load animation dictionary
function LoadAnimDict(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Citizen.Wait(10)
    end
end

-- Export functions
exports('StartClientNegotiation', StartClientNegotiation)
exports('ShowNegotiationMenu', ShowNegotiationMenu)
exports('AttemptNegotiation', AttemptNegotiation)