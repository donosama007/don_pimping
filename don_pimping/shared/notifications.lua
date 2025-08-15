-- Pimp Management System - Notification System
-- Created by Donald Draper
-- Optimized by NinjaTech AI

-- This file handles all notifications in a consistent manner across the script

-- Local variables
local NotificationSystem = {}

-- Show notification function
function ShowNotification(message, type, title, duration, position, icon)
    -- Default values
    type = type or 'info'
    title = title or 'Pimp Management'
    duration = duration or Config.Notifications.duration
    position = position or Config.Notifications.position
    icon = icon or Config.Notifications.defaultIcon
    
    -- Check if we're on the client side
    if not IsDuplicityVersion() then
        -- Client-side notification
        if lib and lib.notify then
            -- Use ox_lib notification
            lib.notify({
                title = title,
                description = message,
                type = type,
                position = position,
                duration = duration,
                icon = icon
            })
        else
            -- Fallback to native notification
            BeginTextCommandThefeedPost('STRING')
            AddTextComponentSubstringPlayerName(message)
            EndTextCommandThefeedPostTicker(false, false)
        end
    else
        -- Server-side notification (will be sent to client)
        -- This is just a placeholder, actual implementation is in the server-side code
    end
end

-- Server-side notification function (sends to specific player)
function SendNotificationToPlayer(playerId, message, type, title, duration, position, icon)
    if IsDuplicityVersion() then
        TriggerClientEvent('pimp:notification', playerId, message, type, title, duration, position, icon)
    end
end

-- Server-side notification function (sends to all players)
function SendNotificationToAll(message, type, title, duration, position, icon)
    if IsDuplicityVersion() then
        TriggerClientEvent('pimp:notification', -1, message, type, title, duration, position, icon)
    end
end

-- Progress bar function
function ShowProgressBar(id, text, duration, icon)
    -- Check if we're on the client side
    if not IsDuplicityVersion() then
        -- Check if ox_lib is available
        if lib and lib.progressBar then
            -- Use ox_lib progress bar
            lib.progressBar({
                duration = duration,
                label = text,
                useWhileDead = false,
                canCancel = false,
                disable = {
                    car = true,
                    move = true,
                    combat = true
                },
                anim = {
                    dict = 'missheistdockssetup1clipboard@base',
                    clip = 'base'
                },
                prop = {
                    model = 'prop_notepad_01',
                    pos = {0.03, 0.03, 0.02},
                    rot = {0.0, 0.0, -1.5}
                }
            })
            return true
        else
            -- Fallback to simple wait
            Citizen.Wait(duration)
            return true
        end
    end
    return false
end

-- Alert dialog function
function ShowAlertDialog(header, content, centered, cancelable)
    -- Check if we're on the client side
    if not IsDuplicityVersion() then
        -- Check if ox_lib is available
        if lib and lib.alertDialog then
            -- Use ox_lib alert dialog
            local options = {
                header = header,
                content = content,
                centered = centered or true
            }
            
            if cancelable then
                options.cancel = true
            end
            
            return lib.alertDialog(options)
        else
            -- Fallback to simple notification
            ShowNotification(content, 'info', header)
            return 'confirm'
        end
    end
    return nil
end

-- Input dialog function
function ShowInputDialog(title, inputs)
    -- Check if we're on the client side
    if not IsDuplicityVersion() then
        -- Check if ox_lib is available
        if lib and lib.inputDialog then
            -- Use ox_lib input dialog
            return lib.inputDialog(title, inputs)
        else
            -- Fallback to simple notification
            ShowNotification('Input dialog not available', 'error')
            return nil
        end
    end
    return nil
end

-- Context menu function
function ShowContextMenu(id, title, menu, options)
    -- Check if we're on the client side
    if not IsDuplicityVersion() then
        -- Check if ox_lib is available
        if lib and lib.registerContext and lib.showContext then
            -- Use ox_lib context menu
            lib.registerContext({
                id = id,
                title = title,
                menu = menu,
                options = options
            })
            
            lib.showContext(id)
            return true
        else
            -- Fallback to simple notification
            ShowNotification('Context menu not available', 'error')
            return false
        end
    end
    return false
end

-- Register client event handler for notifications
if not IsDuplicityVersion() then
    RegisterNetEvent('pimp:notification')
    AddEventHandler('pimp:notification', function(message, type, title, duration, position, icon)
        ShowNotification(message, type, title, duration, position, icon)
    end)
end

-- Add functions to NotificationSystem
NotificationSystem.ShowNotification = ShowNotification
NotificationSystem.SendNotificationToPlayer = SendNotificationToPlayer
NotificationSystem.SendNotificationToAll = SendNotificationToAll
NotificationSystem.ShowProgressBar = ShowProgressBar
NotificationSystem.ShowAlertDialog = ShowAlertDialog
NotificationSystem.ShowInputDialog = ShowInputDialog
NotificationSystem.ShowContextMenu = ShowContextMenu

-- Make functions available globally
_G.ShowNotification = ShowNotification
_G.ShowProgressBar = ShowProgressBar
_G.ShowAlertDialog = ShowAlertDialog
_G.ShowInputDialog = ShowInputDialog
_G.ShowContextMenu = ShowContextMenu

-- Export notification functions
if IsDuplicityVersion() then
    -- Server-side exports
    exports('ShowNotification', ShowNotification)
    exports('SendNotificationToPlayer', SendNotificationToPlayer)
    exports('SendNotificationToAll', SendNotificationToAll)
else
    -- Client-side exports
    exports('ShowNotification', ShowNotification)
    exports('ShowProgressBar', ShowProgressBar)
    exports('ShowAlertDialog', ShowAlertDialog)
    exports('ShowInputDialog', ShowInputDialog)
    exports('ShowContextMenu', ShowContextMenu)
end

-- Return the notification system
return NotificationSystem