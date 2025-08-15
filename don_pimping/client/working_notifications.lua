-- Pimp Management System - Working Notifications
-- Created by NinjaTech AI

-- Silence F8 console unless debugging is explicitly enabled in Config
local print = function(...)
    if Config and Config.Debug then
        _G.print(...)
    end
end

-- Start periodic working notifications
function StartWorkingNotifications(girl, location)
    -- Create a new thread for periodic notifications
    Citizen.CreateThread(function()
        -- Initial delay
        Citizen.Wait(60000) -- 1 minute delay before first notification
        
        -- Check if girl is still working
        local isWorking = false
        
        -- Get updated player data from exports or wait for it to be available
        local playerData = nil
        local attempts = 0
        while not playerData and attempts < 10 do
            if exports['don_pimping'] then
                playerData = exports['don_pimping']:GetPlayerData()
            end
            if not playerData and _G.PlayerData then
                playerData = _G.PlayerData
            end
            if not playerData then
                Citizen.Wait(1000)
                attempts = attempts + 1
            else
                break
            end
        end
        
        if not playerData or not playerData.girls then
            print("^3[WARNING] PlayerData not available for working notifications^7")
            return
        end
        
        for _, g in ipairs(playerData.girls) do
            if g.id == girl.id and g.status == 'working' then
                isWorking = true
                girl = g -- Update girl data
                break
            end
        end
        
        if not isWorking then return end
        
        -- First notification
        local clientType = GetRandomFromTable({"regular", "wealthy", "tourist", "local"})
        ShowNotification(girl.name .. " found a " .. clientType .. " client at " .. location.name, "info")
        
        -- Wait for next notification
        Citizen.Wait(120000) -- 2 minutes delay
        
        -- Check if girl is still working
        isWorking = false
        -- Refresh player data
        if exports['don_pimping'] then
            playerData = exports['don_pimping']:GetPlayerData()
        elseif _G.PlayerData then
            playerData = _G.PlayerData
        end
        
        if playerData and playerData.girls then
            for _, g in ipairs(playerData.girls) do
                if g.id == girl.id and g.status == 'working' then
                    isWorking = true
                    girl = g -- Update girl data
                    break
                end
            end
        end
        
        if not isWorking then return end
        
        -- Calculate estimated earnings
        local baseEarnings = 0
        if Config.GirlSystem and Config.GirlSystem.girlTypes then
            for typeName, typeConfig in pairs(Config.GirlSystem.girlTypes) do
                if typeName == girl.type then
                    baseEarnings = typeConfig.basePrice
                    break
                end
            end
        else
            baseEarnings = 100 -- Fallback value
        end
        
        -- Adjust based on location
        local locationMultiplier = location.priceMultiplier or 1.0
        local estimatedEarnings = math.floor(baseEarnings * locationMultiplier)
        
        -- Second notification
        ShowNotification(girl.name .. " has earned approximately " .. Config.DefaultCurrency .. FormatNumber(estimatedEarnings) .. " so far", "success")
        
        -- Wait for final notification
        Citizen.Wait(120000) -- 2 more minutes delay
        
        -- Check if girl is still working
        isWorking = false
        -- Refresh player data again
        if exports['don_pimping'] then
            playerData = exports['don_pimping']:GetPlayerData()
        elseif _G.PlayerData then
            playerData = _G.PlayerData
        end
        
        if playerData and playerData.girls then
            for _, g in ipairs(playerData.girls) do
                if g.id == girl.id and g.status == 'working' then
                    isWorking = true
                    girl = g -- Update girl data
                    break
                end
            end
        end
        
        if not isWorking then return end
        
        -- Final notification
        ShowNotification(girl.name .. " is performing well at " .. location.name .. ". Check earnings later.", "info")
    end)
end

-- Enhanced notification for when girl completes work
RegisterNetEvent('pimp:girlCompletedWork')
AddEventHandler('pimp:girlCompletedWork', function(girlId, earnings, clientsServed, locationName)
    -- Find girl data
    local girl = nil
    local playerData = nil
    
    -- Get player data safely
    if exports['don_pimping'] then
        playerData = exports['don_pimping']:GetPlayerData()
    elseif _G.PlayerData then
        playerData = _G.PlayerData
    end
    
    if playerData and playerData.girls then
        for _, g in ipairs(playerData.girls) do
            if g.id == girlId then
                girl = g
                break
            end
        end
    end
    
    if not girl then 
        print("^3[WARNING] Could not find girl data for completion notification^7")
        return 
    end
    
    -- Format earnings
    local formattedEarnings = FormatNumber(earnings)
    
    -- Show detailed completion notification
    ShowNotification(girl.name .. " has finished working at " .. locationName .. ".\nEarned: " .. Config.DefaultCurrency .. formattedEarnings .. "\nClients served: " .. clientsServed, "success")
end)

-- Function to get random element from table
function GetRandomFromTable(tbl)
    if type(tbl) ~= "table" or #tbl == 0 then return nil end
    return tbl[math.random(1, #tbl)]
end