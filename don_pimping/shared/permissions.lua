-- Pimp Management System - Permission System
-- Created by Donald Draper
-- Optimized by NinjaTech AI

-- This file handles all permission checks and access control

-- Local variables
local PermissionSystem = {}

-- Check if player has access to a specific feature
function HasAccess(player, accessType)
    -- Default to no access
    local hasAccess = false
    local accessLevel = 0
    
    -- Check if permission system is enabled
    if not Config.PermissionSystem or not Config.PermissionSystem.enabled then
        return true, 3 -- If permission system is disabled, everyone has full access
    end
    
    -- Get player job
    local playerJob = GetPlayerJob(player)
    
    -- Check if player has a whitelisted job
    if Config.PermissionSystem.whitelist and Config.PermissionSystem.whitelist.enabled then
        if playerJob and Config.PermissionSystem.whitelist.allowedJobs[playerJob.name] then
            -- Check job grade if required
            if Config.PermissionSystem.whitelist.requiredJobGrades[playerJob.name] then
                if playerJob.grade >= Config.PermissionSystem.whitelist.requiredJobGrades[playerJob.name] then
                    hasAccess = true
                end
            else
                hasAccess = true
            end
        end
    else
        -- If whitelist is disabled, everyone has access
        hasAccess = true
    end
    
    -- Check item requirements if enabled
    if hasAccess and Config.PermissionSystem.itemRequirements and Config.PermissionSystem.itemRequirements.enabled then
        -- This check is done server-side
        -- Client-side will assume access is granted if job check passed
        if IsDuplicityVersion() then
            for item, required in pairs(Config.PermissionSystem.itemRequirements.requiredItems) do
                if required and not HasItem(player, item) then
                    hasAccess = false
                    break
                end
            end
        end
    end
    
    -- Get access level for the specific feature
    if hasAccess and playerJob and Config.PermissionSystem.accessLevels and Config.PermissionSystem.accessLevels[accessType] then
        accessLevel = Config.PermissionSystem.accessLevels[accessType][playerJob.name] or 0
    end
    
    return hasAccess, accessLevel
end

-- Check if player has a specific item (server-side only)
function HasItem(player, item)
    if not IsDuplicityVersion() then
        return true -- Client-side always returns true, actual check is done server-side
    end
    
    -- Implementation depends on the framework
    -- This is a placeholder, actual implementation is in the server-side code
    return true
end

-- Get player job (implementation depends on the framework)
function GetPlayerJob(player)
    -- This is a placeholder, actual implementation is in the client/server-side code
    return {
        name = "unemployed",
        grade = 0
    }
end

-- Check if player has permission to access the menu
function HasMenuAccess(player)
    return HasAccess(player, "MenuAccess")
end

-- Check if player has permission to manage girls
function HasGirlManagementAccess(player)
    return HasAccess(player, "GirlManagement")
end

-- Check if player has permission to purchase girls
function HasGirlPurchaseAccess(player)
    return HasAccess(player, "GirlPurchase")
end

-- Check if player has permission to control territory
function HasTerritoryControlAccess(player)
    return HasAccess(player, "TerritoryControl")
end

-- Add functions to PermissionSystem
PermissionSystem.HasAccess = HasAccess
PermissionSystem.HasItem = HasItem
PermissionSystem.GetPlayerJob = GetPlayerJob
PermissionSystem.HasMenuAccess = HasMenuAccess
PermissionSystem.HasGirlManagementAccess = HasGirlManagementAccess
PermissionSystem.HasGirlPurchaseAccess = HasGirlPurchaseAccess
PermissionSystem.HasTerritoryControlAccess = HasTerritoryControlAccess

-- Make functions available globally
_G.HasAccess = HasAccess
_G.HasMenuAccess = HasMenuAccess
_G.HasGirlManagementAccess = HasGirlManagementAccess
_G.HasGirlPurchaseAccess = HasGirlPurchaseAccess
_G.HasTerritoryControlAccess = HasTerritoryControlAccess

-- Export permission functions
if IsDuplicityVersion() then
    -- Server-side exports
    exports('HasAccess', HasAccess)
    exports('HasMenuAccess', HasMenuAccess)
    exports('HasGirlManagementAccess', HasGirlManagementAccess)
    exports('HasGirlPurchaseAccess', HasGirlPurchaseAccess)
    exports('HasTerritoryControlAccess', HasTerritoryControlAccess)
else
    -- Client-side exports
    exports('HasMenuAccess', HasMenuAccess)
    exports('HasGirlManagementAccess', HasGirlManagementAccess)
    exports('HasGirlPurchaseAccess', HasGirlPurchaseAccess)
    exports('HasTerritoryControlAccess', HasTerritoryControlAccess)
end

-- Return the permission system
return PermissionSystem