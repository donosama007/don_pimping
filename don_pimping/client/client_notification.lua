-- Pimp Management System - Client Notification System
-- Created by NinjaTech AI

-- Silence F8 console unless debugging is explicitly enabled in Config
local print = function(...)
    if Config and Config.Debug then
        _G.print(...)
    end
end

-- Local variables
local activeNotifications = {}

-- Show girl found client notification
RegisterNetEvent('pimp:girlFoundClient')
AddEventHandler('pimp:girlFoundClient', function(girlId, girlName, basePrice, minPrice, maxPrice, clientType, territoryName)
    -- Default client type if not provided
    clientType = clientType or "standard"
    territoryName = territoryName or "Unknown Location"
    
    -- Determine client type icon and color
    local icon = 'user'
    local iconColor = '#1E88E5'
    
    if clientType == "premium" then
        icon = 'user-tie'
        iconColor = '#FFD700' -- Gold
    elseif clientType == "vip" then
        icon = 'crown'
        iconColor = '#9C27B0' -- Purple
    end
    
    -- Show notification with client type
    lib.notify({
        id = 'client_found_' .. girlId,
        title = clientType:gsub("^%l", string.upper) .. ' Client Found',
        description = girlName .. ' found a ' .. clientType .. ' client offering $' .. basePrice .. ' in ' .. territoryName,
        type = 'info',
        position = 'top-right',
        icon = icon,
        iconColor = iconColor,
        duration = 7000
    })
    
    -- Play notification sound based on client type
    if clientType == "vip" then
        PlaySoundFrontend(-1, "CHALLENGE_UNLOCKED", "HUD_AWARDS", true)
    elseif clientType == "premium" then
        PlaySoundFrontend(-1, "PROPERTY_PURCHASE", "HUD_AWARDS", true)
    else
        PlaySoundFrontend(-1, "Text_Arrive_Tone", "Phone_SoundSet_Default", true)
    end
    
    -- Start negotiation
    TriggerEvent('pimp:startNegotiation', girlId, girlName, basePrice, minPrice, maxPrice, clientType, territoryName)
end)

-- Handle client negotiation
RegisterNetEvent('pimp:startNegotiation')
AddEventHandler('pimp:startNegotiation', function(girlId, girlName, basePrice, minPrice, maxPrice, clientType, territoryName)
    -- Default client type if not provided
    clientType = clientType or "standard"
    territoryName = territoryName or "Unknown Location"
    
    -- Find girl data
    local girl = nil
    for _, g in ipairs(PlayerData.girls) do
        if g.id == girlId then
            girl = g
            break
        end
    end
    
    if not girl then return end
    
    -- Calculate negotiation success chance
    local successChance = CalculateNegotiationSuccessChance(girl)
    
    -- Show negotiation menu
    ShowClientNegotiationMenu(girlId, girlName, basePrice, minPrice, maxPrice, successChance, clientType, territoryName)
end)

-- Show client negotiation menu
function ShowClientNegotiationMenu(girlId, girlName, basePrice, minPrice, maxPrice, successChance, clientType, territoryName)
    -- Calculate negotiation options
    local higherPrice = math.floor(basePrice * 1.25) -- 25% higher
    higherPrice = math.min(higherPrice, maxPrice) -- Cap at max price
    
    local evenHigherPrice = math.floor(basePrice * 1.5) -- 50% higher
    evenHigherPrice = math.min(evenHigherPrice, maxPrice) -- Cap at max price
    
    -- Calculate success chances
    local higherChance = math.floor(successChance * 0.7) -- 70% of base chance
    local evenHigherChance = math.floor(successChance * 0.4) -- 40% of base chance
    
    -- Create menu options
    local options = {
        {
            title = 'Client Negotiation',
            description = 'A ' .. clientType .. ' client wants to hire ' .. girlName .. ' in ' .. territoryName,
            icon = 'comments-dollar',
            disabled = true,
            metadata = {
                {label = 'Offered Price', value = '$' .. basePrice},
                {label = 'Client Type', value = clientType:gsub("^%l", string.upper)},
                {label = 'Location', value = territoryName}
            }
        },
        {
            title = 'Agree to Price',
            description = 'Accept the offered price of $' .. basePrice,
            icon = 'check',
            onSelect = function()
                TriggerServerEvent('pimp:negotiationResponse', girlId, basePrice, 'accept', territoryName)
            end
        },
        {
            title = 'Negotiate',
            description = 'Try to negotiate a different price',
            icon = 'comments-dollar',
            menu = 'pimp_negotiate_options'
        },
        {
            title = 'Reject Client',
            description = 'Reject this client and wait for another',
            icon = 'times',
            onSelect = function()
                TriggerServerEvent('pimp:negotiationResponse', girlId, 0, 'reject', territoryName)
            end
        }
    }
    
    -- Create negotiation options submenu
    local negotiateOptions = {
        {
            title = 'Ask for Higher Price',
            description = 'Try to get $' .. higherPrice .. ' (25% more)',
            icon = 'arrow-up',
            onSelect = function()
                TriggerServerEvent('pimp:negotiationResponse', girlId, higherPrice, 'higher', territoryName)
            end,
            metadata = {
                {label = 'Original Price', value = '$' .. basePrice},
                {label = 'Requested Price', value = '$' .. higherPrice},
                {label = 'Increase', value = '25%'},
                {label = 'Success Chance', value = higherChance .. '%'}
            }
        },
        {
            title = 'Demand Much Higher Price',
            description = 'Try to get $' .. evenHigherPrice .. ' (50% more)',
            icon = 'arrow-circle-up',
            onSelect = function()
                TriggerServerEvent('pimp:negotiationResponse', girlId, evenHigherPrice, 'much_higher', territoryName)
            end,
            metadata = {
                {label = 'Original Price', value = '$' .. basePrice},
                {label = 'Requested Price', value = '$' .. evenHigherPrice},
                {label = 'Increase', value = '50%'},
                {label = 'Success Chance', value = evenHigherChance .. '%'}
            }
        },
        {
            title = 'Back',
            icon = 'arrow-left',
            menu = 'pimp_negotiation_menu'
        }
    }
    
    -- Register menus
    lib.registerContext({
        id = 'pimp_negotiation_menu',
        title = 'Client Negotiation',
        options = options
    })
    
    lib.registerContext({
        id = 'pimp_negotiate_options',
        title = 'Negotiation Options',
        menu = 'pimp_negotiation_menu',
        options = negotiateOptions
    })
    
    -- Show main negotiation menu
    lib.showContext('pimp_negotiation_menu')
end

-- Handle negotiation result
RegisterNetEvent('pimp:negotiationResult')
AddEventHandler('pimp:negotiationResult', function(girlId, girlName, finalPrice, result, clientType)
    clientType = clientType or "standard"
    
    local resultText = ''
    local resultType = 'info'
    local icon = 'comments-dollar'
    
    if result == 'success' then
        resultText = girlName .. ' will serve the ' .. clientType .. ' client for $' .. finalPrice
        resultType = 'success'
        icon = 'check-circle'
    elseif result == 'failed' then
        resultText = 'The ' .. clientType .. ' client rejected your price and left'
        resultType = 'error'
        icon = 'times-circle'
    elseif result == 'rejected' then
        resultText = 'You rejected the ' .. clientType .. ' client'
        resultType = 'info'
        icon = 'ban'
    end
    
    -- Show notification
    lib.notify({
        title = 'Negotiation Result',
        description = resultText,
        type = resultType,
        icon = icon,
        position = 'top-right',
        duration = 5000
    })
    
    -- Play appropriate sound
    if result == 'success' then
        PlaySoundFrontend(-1, "PICK_UP", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
    elseif result == 'failed' then
        PlaySoundFrontend(-1, "ERROR", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
    else
        PlaySoundFrontend(-1, "CANCEL", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
    end
end)