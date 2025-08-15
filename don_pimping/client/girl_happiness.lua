-- Pimp Management System - Girl Happiness System (Client)
-- Created by NinjaTech AI

-- Silence F8 console unless debugging is explicitly enabled in Config
local print = function(...)
    if Config and Config.Debug then
        _G.print(...)
    end
end

-- Local variables
local HappinessMethods = {}

-- Request happiness methods from server
function RequestHappinessMethods()
    TriggerServerEvent('pimp:requestHappinessMethods')
end

-- Receive happiness methods from server
RegisterNetEvent('pimp:receiveHappinessMethods')
AddEventHandler('pimp:receiveHappinessMethods', function(methods)
    HappinessMethods = methods
end)

-- Open happiness menu for a girl
function OpenGirlHappinessMenu(girlId)
    -- Find girl data
    local girl = nil
    for _, g in ipairs(PlayerData.girls) do
        if g.id == girlId then
            girl = g
            break
        end
    end
    
    if not girl then
        return
    end
    
    -- Request happiness methods if not loaded
    if #HappinessMethods == 0 then
        RequestHappinessMethods()
        Citizen.Wait(500) -- Wait for server response
    end
    
    -- Create options
    local options = {
        {
            title = girl.name .. "'s Happiness",
            description = "Current happiness: " .. girl.happiness .. "%",
            icon = GetHappinessIcon(girl.happiness),
            disabled = true,
            metadata = {
                {label = 'Happiness', value = girl.happiness .. '%'},
                {label = 'Status', value = GetHappinessDescription(girl.happiness)},
                {label = 'Effect on Earnings', value = math.floor(GetHappinessEarningsMultiplier(girl.happiness) * 100) .. '%'}
            }
        }
    }
    
    -- Add happiness methods
    if #HappinessMethods > 0 then
        for _, method in ipairs(HappinessMethods) do
            -- Check if method is on cooldown
            local isOnCooldown = false
            local cooldownKey = "activity_" .. girlId .. "_" .. method.name
            
            if ActiveCooldowns[cooldownKey] then
                local currentTime = GetGameTimer() / 1000
                if currentTime < ActiveCooldowns[cooldownKey] then
                    isOnCooldown = true
                end
            end
            
            table.insert(options, {
                title = method.displayName,
                description = method.description .. " (+" .. method.happinessGain .. " happiness)",
                icon = isOnCooldown and 'clock' or 'smile',
                disabled = isOnCooldown,
                onSelect = function()
                    -- Show confirmation dialog
                    local confirmOptions = {
                        title = 'Confirm ' .. method.displayName,
                        description = 'Spend $' .. FormatNumber(method.cost) .. ' for ' .. method.displayName .. '?\n\nThis will increase ' .. girl.name .. "'s happiness by " .. method.happinessGain .. " points.",
                        buttons = {
                            {
                                text = 'Yes',
                                callback = function()
                                    TriggerServerEvent('pimp:startGirlActivity', girlId, method.name)
                                end
                            },
                            {
                                text = 'No',
                                callback = function()
                                    -- Do nothing, just close the dialog
                                end
                            }
                        }
                    }
                    
                    lib.alertDialog(confirmOptions)
                end,
                metadata = {
                    {label = 'Happiness Gain', value = '+' .. method.happinessGain},
                    {label = 'Cost', value = '$' .. FormatNumber(method.cost)},
                    {label = 'Duration', value = method.duration .. ' minutes'},
                    {label = 'Cooldown', value = method.cooldown .. ' minutes'},
                    {label = 'Status', value = isOnCooldown and 'On Cooldown' or 'Available'}
                }
            })
        end
    else
        table.insert(options, {
            title = 'No Happiness Methods Available',
            description = 'No methods available to improve happiness',
            icon = 'info-circle',
            disabled = true
        })
    end
    
    -- Add back button
    table.insert(options, {
        title = 'Back',
        icon = 'arrow-left',
        menu = 'pimp_girl_menu_' .. girlId
    })
    
    -- Show menu
    lib.registerContext({
        id = 'pimp_girl_happiness_menu_' .. girlId,
        title = 'Happiness Management',
        menu = 'pimp_girl_menu_' .. girlId,
        options = options
    })
    
    lib.showContext('pimp_girl_happiness_menu_' .. girlId)
end

-- Get happiness icon based on level
function GetHappinessIcon(happiness)
    if happiness >= 81 then
        return 'grin-beam'
    elseif happiness >= 61 then
        return 'smile'
    elseif happiness >= 41 then
        return 'meh'
    elseif happiness >= 21 then
        return 'frown'
    else
        return 'angry'
    end
end

-- Get happiness description based on level
function GetHappinessDescription(happiness)
    if happiness >= 81 then
        return 'Ecstatic'
    elseif happiness >= 61 then
        return 'Happy'
    elseif happiness >= 41 then
        return 'Content'
    elseif happiness >= 21 then
        return 'Unhappy'
    else
        return 'Miserable'
    end
end

-- Get happiness earnings multiplier
function GetHappinessEarningsMultiplier(happiness)
    if happiness >= 81 then
        return 1.2 -- 120% earnings
    elseif happiness >= 61 then
        return 1.1 -- 110% earnings
    elseif happiness >= 41 then
        return 1.0 -- 100% earnings
    elseif happiness >= 21 then
        return 0.8 -- 80% earnings
    else
        return 0.6 -- 60% earnings
    end
end

-- Girl left event
RegisterNetEvent('pimp:girlLeft')
AddEventHandler('pimp:girlLeft', function(girlId, girlName, reason)
    -- Show notification
    local reasonText = ""
    if reason == "unhappiness" then
        reasonText = "extreme unhappiness"
    else
        reasonText = reason or "unknown reasons"
    end
    
    lib.notify({
        title = 'Girl Left',
        description = girlName .. ' has left you due to ' .. reasonText,
        type = 'error',
        position = 'top-right',
        icon = 'frown',
        duration = 10000
    })
    
    -- Play sound
    PlaySoundFrontend(-1, "DELETE", "HUD_DEATHMATCH_SOUNDSET", true)
    
    -- Remove girl from local data
    for i, girl in ipairs(PlayerData.girls) do
        if girl.id == girlId then
            table.remove(PlayerData.girls, i)
            break
        end
    end
end)

-- Initialize
Citizen.CreateThread(function()
    Citizen.Wait(2000) -- Wait for resource to fully start
    RequestHappinessMethods()
end)

-- Export functions
exports('OpenGirlHappinessMenu', OpenGirlHappinessMenu)
exports('GetHappinessIcon', GetHappinessIcon)
exports('GetHappinessDescription', GetHappinessDescription)
exports('GetHappinessEarningsMultiplier', GetHappinessEarningsMultiplier)