-- Pimp Management System - Utility Functions
-- Created by Donald Draper
-- Optimized by NinjaTech AI

-- Silence F8 console unless debugging is explicitly enabled in Config
local print = function(...)
    if Config and Config.Debug then
        _G.print(...)
    end
end

-- Format number with commas
function FormatNumber(number)
    local i, j, minus, int, fraction = tostring(number):find('([-]?)(%d+)([.]?%d*)')
    int = int:reverse():gsub("(%d%d%d)", "%1,")
    return minus .. int:reverse():gsub("^,", "") .. fraction
end

-- Check if a cooldown is active
function IsOnCooldown(cooldowns, key)
    if not cooldowns or not cooldowns[key] then
        return false
    end
    
    return cooldowns[key] > GetGameTimer()
end

-- Get cooldown time remaining in formatted string
function GetCooldownTimeRemaining(endTime)
    if not endTime then return "0s" end
    
    local remaining = endTime - GetGameTimer()
    if remaining <= 0 then return "0s" end
    
    local seconds = math.floor(remaining / 1000)
    local minutes = math.floor(seconds / 60)
    local hours = math.floor(minutes / 60)
    
    if hours > 0 then
        return string.format("%dh %dm", hours, minutes % 60)
    elseif minutes > 0 then
        return string.format("%dm %ds", minutes, seconds % 60)
    else
        return string.format("%ds", seconds)
    end
end

function ShowProgressBar(id, text, duration, icon)
    if lib and lib.progressBar then
        lib.progressBar({
            duration = duration,
            label = text,
            useWhileDead = false,
            canCancel = false,
            disable = {
                car = true,
                move = true,
                combat = true,
                mouse = false
            },
            anim = {
                dict = 'missheist_agency2aig_13',
                clip = 'wait_loop_lamar'
            },
            prop = {},
        })
    else
        -- Fallback if ox_lib is not available
        Citizen.Wait(duration)
    end
end

-- Discipline a girl with enhanced effects
function DisciplineGirl(girlId, girlName, disciplineType)
    local disciplineConfig = Config.NPCInteraction.Discipline.types[disciplineType]
    if not disciplineConfig then
        ShowNotification("Invalid discipline type", "error")
        return
    end
    
    -- Trigger server event (always do this)
    TriggerServerEvent('pimp:disciplineGirl', girlId, disciplineType)
    
    -- Set cooldown with notification
    local cooldownKey = 'discipline_' .. girlId .. '_' .. disciplineType
    DisciplineCooldowns[cooldownKey] = GetGameTimer() + (disciplineConfig.cooldown or 60000)
    
    -- Show progress bar
    local actionText = "Disciplining"
    if disciplineType == "verbal" then
        actionText = "Warning"
    elseif disciplineType == "threaten" then
        actionText = "Threatening"
    elseif disciplineType == "slap" then
        actionText = "Slapping"
    elseif disciplineType == "push" then
        actionText = "Pushing"
    elseif disciplineType == "grab" then
        actionText = "Grabbing"
    end
    
    -- Request GirlPeds data if needed
    if not GirlPeds or next(GirlPeds) == nil then
        print("^3GirlPeds is empty, requesting data^7")
        TriggerEvent('pimp:requestGirlPeds')
        Citizen.Wait(100) -- Give it a moment to receive data
    end
    
    -- Skip physical interaction if GirlPeds is nil or empty
    if not GirlPeds or next(GirlPeds) == nil then
        print("^1GirlPeds is nil or empty, skipping physical interaction^7")
        ShowProgressBar('discipline', actionText .. ' ' .. girlName .. '...', 3000, 'hand')
        Citizen.Wait(3000)
        ShowNotification('You disciplined ' .. girlName .. ' with ' .. disciplineConfig.name, 'warning')
        return
    end
    
    -- Get girl ped
    local girlPed = GirlPeds[girlId]
    if not girlPed or not DoesEntityExist(girlPed) then
        print("^1Girl ped not found or doesn't exist for ID " .. girlId .. ", skipping physical interaction^7")
        ShowProgressBar('discipline', actionText .. ' ' .. girlName .. '...', 3000, 'hand')
        Citizen.Wait(3000)
        ShowNotification('You disciplined ' .. girlName .. ' with ' .. disciplineConfig.name, 'warning')
        return
    end

    -- Rest of the function remains the same...
    -- Check distance to girl
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local girlCoords = GetEntityCoords(girlPed)
    local distance = #(playerCoords - girlCoords)
    
    -- For slapping, we'll allow a greater distance since we'll walk to the girl
    local maxDistance = 2.0
    if disciplineType == 'slap' then
        maxDistance = 10.0
    end
    
    if distance > maxDistance then
        ShowNotification("You need to be closer to " .. girlName .. " to discipline her", "error")
        return
    end
    
    -- Show progress bar only for non-physical disciplines or if girl is too far
    if disciplineType ~= 'slap' and disciplineType ~= 'push' and disciplineType ~= 'grab' then
        ShowProgressBar('discipline', actionText .. ' ' .. girlName .. '...', 3000, 'hand')
        Citizen.Wait(3000)
    end
    
    -- Show cooldown notification
    local cooldownMinutes = math.ceil((disciplineConfig.cooldown or 60000) / 60000)
    ShowNotification('You can discipline ' .. girlName .. ' with ' .. disciplineConfig.name .. ' again in ' .. cooldownMinutes .. ' minute(s)', 'info')
    
    -- Trigger synchronized animation for all players if close enough
    if distance <= maxDistance then
        -- Trigger synchronized animation for all players
        TriggerServerEvent('pimp:syncDisciplineAnimationToAll', girlId, disciplineType, PedToNet(playerPed))
    end
    
    -- Physical discipline interaction
    if disciplineType == 'slap' then
        PerformSlapAnimation(playerPed, girlPed)
    elseif disciplineType == 'verbal' then
        PerformVerbalAnimation(playerPed, girlPed, girlId)
    elseif disciplineType == 'push' then
        PerformPushAnimation(playerPed, girlPed)
    elseif disciplineType == 'grab' then
        PerformGrabAnimation(playerPed, girlPed)
    elseif disciplineType == 'threaten' then
        PerformThreatenAnimation(playerPed, girlPed)
    end
    
    -- Show immediate feedback after animation completes
    Citizen.SetTimeout(3500, function()
        ShowNotification('You disciplined ' .. girlName .. ' with ' .. disciplineConfig.name, 'warning')
    end)
end


-- Show notification
function ShowNotification(message, notificationType)
    notificationType = notificationType or "info"
    
    if lib and lib.notify then
        lib.notify({
            title = 'Pimp Management',
            description = message,
            type = notificationType,
            position = Config.Notifications and Config.Notifications.position or 'top-right',
            duration = Config.Notifications and Config.Notifications.duration or 5000,
            icon = Config.Notifications and Config.Notifications.defaultIcon or 'info-circle'
        })
    else
        -- Fallback to native notification
        SetNotificationTextEntry('STRING')
        AddTextComponentString(message)
        DrawNotification(false, false)
    end
end
