-- Pimp Management System - Discipline Synchronization
-- Created by NinjaTech AI

-- Synchronize discipline animations to all players
RegisterNetEvent('pimp:syncDisciplineAnimationToAll')
AddEventHandler('pimp:syncDisciplineAnimationToAll', function(girlId, disciplineType, playerNetId)
    local source = source
    
    -- Validate input
    if not girlId or not disciplineType or not playerNetId then
        return
    end
    
    -- Get player identifier
    local identifier = GetPlayerIdentifierFromId(source)
    if not identifier then
        return
    end
    
    -- Find girl in player data
    local girl = nil
    if PlayerData and PlayerData[identifier] and PlayerData[identifier].girls then
        for _, g in ipairs(PlayerData[identifier].girls) do
            if g.id == girlId then
                girl = g
                break
            end
        end
    end
    
    -- Validate girl exists
    if not girl then
        return
    end
    
    -- Broadcast animation to all nearby players
    TriggerClientEvent('pimp:syncDisciplineAnimation', -1, girlId, disciplineType, playerNetId)
    
    -- Log discipline action
    print(string.format("^2Player %s disciplined girl %s (%s) with %s^7", 
        GetPlayerName(source), girl.name, girlId, disciplineType))
end)

-- Export functions
exports('SyncDisciplineAnimation', function(source, girlId, disciplineType, playerNetId)
    TriggerClientEvent('pimp:syncDisciplineAnimation', -1, girlId, disciplineType, playerNetId)
end)