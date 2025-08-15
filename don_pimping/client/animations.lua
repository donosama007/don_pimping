-- Pimp Management System - Animation Functions
-- Created by NinjaTech AI

-- Silence F8 console unless debugging is explicitly enabled in Config
local print = function(...)
    if Config and Config.Debug then
        _G.print(...)
    end
end

-- Load animation dictionary
function LoadAnimDict(dict)
    RequestAnimDict(dict)
    local timeout = 0
    while not HasAnimDictLoaded(dict) and timeout < 100 do
        Citizen.Wait(10)
        timeout = timeout + 1
    end
end

-- Perform slap animation
function PerformSlapAnimation(playerPed, girlPed)
    -- Check if entities exist
    if not DoesEntityExist(playerPed) or not DoesEntityExist(girlPed) then
        print("^1Error: Player or girl ped doesn't exist^7")
        return
    end

    -- Get positions
    local playerCoords = GetEntityCoords(playerPed)
    local girlCoords = GetEntityCoords(girlPed)
    
    -- Calculate direction vector
    local direction = girlCoords - playerCoords
    direction = direction / #direction
    
    -- Make girl face player
    TaskTurnPedToFaceEntity(girlPed, playerPed, 1000)
    Citizen.Wait(1000) -- Wait for girl to turn
    
    -- Position player in front of girl for slap
    local slapDistance = 0.9 -- Close enough to slap
    local targetPos = girlCoords - (direction * slapDistance)
    
    -- Set player position and heading
    local heading = GetHeadingFromVector_2d(direction.x, direction.y)
    TaskGoStraightToCoord(playerPed, targetPos.x, targetPos.y, targetPos.z, 1.0, 1000, heading, 0.1)
    Citizen.Wait(1000) -- Wait for player to move to position
    
    -- Load slap animation dictionaries
    LoadAnimDict("melee@unarmed@streamed_variations")
    LoadAnimDict("melee@unarmed@streamed_core")
    
    -- Play slap animation for player
    TaskPlayAnim(playerPed, "melee@unarmed@streamed_variations", "plyr_takedown_front_slap", 8.0, -8.0, 1500, 0, 0, false, false, false)
    
    -- Wait for slap to connect
    Citizen.Wait(500)
    
    -- Play reaction animation for girl
    LoadAnimDict("melee@unarmed@streamed_variations")
    TaskPlayAnim(girlPed, "melee@unarmed@streamed_variations", "victim_takedown_front_slap", 8.0, -8.0, 3000, 0, 0, false, false, false)
    
    -- Add sound effect
    PlaySoundFrontend(-1, "SLAP", "PLAYER_SWITCH_CUSTOM_SOUNDSET", true)
    
    -- Wait for animation to finish
    Citizen.Wait(1500)
    
    -- Clear tasks
    ClearPedTasks(playerPed)
end

-- Enhanced slap animation with proper sequence
function PerformEnhancedSlapAnimation(playerPed, girlPed)
    -- Check if entities exist
    if not DoesEntityExist(playerPed) or not DoesEntityExist(girlPed) then
        print("^1Error: Player or girl ped doesn't exist^7")
        return
    end

    -- Get positions
    local playerCoords = GetEntityCoords(playerPed)
    local girlCoords = GetEntityCoords(girlPed)
    
    -- Calculate direction vector
    local direction = girlCoords - playerCoords
    direction = direction / #direction
    
    -- PHASE 1: Position both entities face-to-face
    -- Make girl face player
    TaskTurnPedToFaceEntity(girlPed, playerPed, 1000)
    Citizen.Wait(1000) -- Wait for girl to turn
    
    -- Position player in front of girl for slap
    local slapDistance = 0.9 -- Close enough to slap
    local targetPos = girlCoords - (direction * slapDistance)
    
    -- Set player position and heading
    local heading = GetHeadingFromVector_2d(direction.x, direction.y)
    TaskGoStraightToCoord(playerPed, targetPos.x, targetPos.y, targetPos.z, 1.0, 1000, heading, 0.1)
    Citizen.Wait(1000) -- Wait for player to move to position
    
    -- PHASE 2: Player performs slapping animation (2 seconds)
    LoadAnimDict("melee@unarmed@streamed_variations")
    TaskPlayAnim(playerPed, "melee@unarmed@streamed_variations", "plyr_takedown_front_slap", 8.0, -8.0, 2000, 0, 0, false, false, false)
    
    -- Wait for slap to connect
    Citizen.Wait(500)
    
    -- PHASE 3: Girl falls backward/sideways animation (1 second)
    LoadAnimDict("melee@unarmed@streamed_variations")
    TaskPlayAnim(girlPed, "melee@unarmed@streamed_variations", "victim_takedown_front_slap", 8.0, -8.0, 1000, 0, 0, false, false, false)
    
    -- Add sound effect
    PlaySoundFrontend(-1, "SLAP", "PLAYER_SWITCH_CUSTOM_SOUNDSET", true)
    
    -- Add screen shake effect
    ShakeGameplayCam("SMALL_EXPLOSION_SHAKE", 0.3)
    
    -- PHASE 4: Girl stays on ground briefly (2 seconds)
    Citizen.Wait(1000)
    
    -- PHASE 5: Girl gets up with dizzy/stunned animation (3 seconds)
    LoadAnimDict("get_up@directional@movement@from_knees@standard")
    TaskPlayAnim(girlPed, "get_up@directional@movement@from_knees@standard", "getup_r_0", 8.0, -8.0, 3000, 0, 0, false, false, false)
    
    -- Wait for animation to finish
    Citizen.Wait(3000)
    
    -- Return to normal idle state
    ClearPedTasks(girlPed)
    ClearPedTasks(playerPed)
end

-- Synchronize slap animation
RegisterNetEvent('pimp:syncDisciplineAnimation')
AddEventHandler('pimp:syncDisciplineAnimation', function(girlId, disciplineType, playerNetId)
    -- Only process if we're not the player who initiated the discipline
    if NetworkGetNetworkIdFromEntity(PlayerPedId()) ~= playerNetId then
        -- Find the girl ped
        local girlPed = nil
        
        -- Check if girl is in working girls
        if workingGirlPeds and workingGirlPeds[girlId] then
            girlPed = workingGirlPeds[girlId]
        end
        
        -- Check if girl is in GirlPeds
        if not girlPed and GirlPeds and GirlPeds[girlId] then
            girlPed = GirlPeds[girlId]
        end
        
        -- If we found the girl ped, play the appropriate animation
        if girlPed and DoesEntityExist(girlPed) and disciplineType == "slap" then
            -- Get player ped from net id
            local playerPed = NetworkGetEntityFromNetworkId(playerNetId)
            
            if DoesEntityExist(playerPed) then
                -- Play synchronized animation
                PerformEnhancedSlapAnimation(playerPed, girlPed)
            end
        end
    end
end)

-- Perform verbal animation
function PerformVerbalAnimation(playerPed, girlPed, girlId)
    -- Check if entities exist
    if not DoesEntityExist(playerPed) or not DoesEntityExist(girlPed) then
        return
    end
    
    -- Load animation dictionaries
    LoadAnimDict("misscarsteal4@actor")
    LoadAnimDict("missfbi3_party_d")
    
    -- Make girl face player
    TaskTurnPedToFaceEntity(girlPed, playerPed, 1000)
    Citizen.Wait(1000) -- Wait for girl to turn
    
    -- Play animation for player
    TaskPlayAnim(playerPed, "misscarsteal4@actor", "actor_berating_loop", 8.0, -8.0, 3000, 0, 0, false, false, false)
    
    -- Play reaction animation for girl
    TaskPlayAnim(girlPed, "missfbi3_party_d", "stand_talk_loop_b_female", 8.0, -8.0, 3000, 0, 0, false, false, false)
    
    -- Wait for animation to finish
    Citizen.Wait(3000)
    
    -- Clear tasks
    ClearPedTasks(playerPed)
    ClearPedTasks(girlPed)
end

-- Perform push animation
function PerformPushAnimation(playerPed, girlPed)
    -- Check if entities exist
    if not DoesEntityExist(playerPed) or not DoesEntityExist(girlPed) then
        return
    end
    
    -- Load animation dictionaries
    LoadAnimDict("melee@unarmed@streamed_variations")
    
    -- Make girl face player
    TaskTurnPedToFaceEntity(girlPed, playerPed, 1000)
    Citizen.Wait(1000) -- Wait for girl to turn
    
    -- Play animation for player
    TaskPlayAnim(playerPed, "melee@unarmed@streamed_variations", "plyr_takedown_front_backhand", 8.0, -8.0, 1500, 0, 0, false, false, false)
    
    -- Wait for push to connect
    Citizen.Wait(500)
    
    -- Play reaction animation for girl
    TaskPlayAnim(girlPed, "melee@unarmed@streamed_variations", "victim_takedown_front_cross_r", 8.0, -8.0, 3000, 0, 0, false, false, false)
    
    -- Wait for animation to finish
    Citizen.Wait(1500)
    
    -- Clear tasks
    ClearPedTasks(playerPed)
end

-- Perform grab animation
function PerformGrabAnimation(playerPed, girlPed)
    -- Check if entities exist
    if not DoesEntityExist(playerPed) or not DoesEntityExist(girlPed) then
        return
    end
    
    -- Load animation dictionaries
    LoadAnimDict("missmic4")
    LoadAnimDict("missfbi3_party_d")
    
    -- Make girl face player
    TaskTurnPedToFaceEntity(girlPed, playerPed, 1000)
    Citizen.Wait(1000) -- Wait for girl to turn
    
    -- Play animation for player
    TaskPlayAnim(playerPed, "missmic4", "bar_handover_bottle_player", 8.0, -8.0, 2000, 0, 0, false, false, false)
    
    -- Play reaction animation for girl
    TaskPlayAnim(girlPed, "missfbi3_party_d", "stand_talk_loop_a_female", 8.0, -8.0, 2000, 0, 0, false, false, false)
    
    -- Wait for animation to finish
    Citizen.Wait(2000)
    
    -- Clear tasks
    ClearPedTasks(playerPed)
    ClearPedTasks(girlPed)
end

-- Perform threaten animation
function PerformThreatenAnimation(playerPed, girlPed)
    -- Check if entities exist
    if not DoesEntityExist(playerPed) or not DoesEntityExist(girlPed) then
        return
    end
    
    -- Load animation dictionaries
    LoadAnimDict("mp_player_int_upperfinger")
    LoadAnimDict("missfbi3_party_d")
    
    -- Make girl face player
    TaskTurnPedToFaceEntity(girlPed, playerPed, 1000)
    Citizen.Wait(1000) -- Wait for girl to turn
    
    -- Play animation for player
    TaskPlayAnim(playerPed, "mp_player_int_upperfinger", "mp_player_int_finger_01_enter", 8.0, -8.0, 3000, 0, 0, false, false, false)
    
    -- Play reaction animation for girl
    TaskPlayAnim(girlPed, "missfbi3_party_d", "stand_talk_loop_a_female", 8.0, -8.0, 3000, 0, 0, false, false, false)
    
    -- Wait for animation to finish
    Citizen.Wait(3000)
    
    -- Clear tasks
    ClearPedTasks(playerPed)
    ClearPedTasks(girlPed)
end