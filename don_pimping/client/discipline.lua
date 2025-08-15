-- Pimp Management System - Discipline System
-- Created by NinjaTech AI

-- Local variables
-- Silence F8 console unless debugging is explicitly enabled in Config
local print = function(...)
    if Config and Config.Debug then
        _G.print(...)
    end
end

local DisciplineConfig = {
    verbal = {
        name = "Verbal Warning",
        description = "Give a verbal warning to the girl",
        effects = {
            loyalty = -5,
            happiness = -10,
            obedience = 5
        },
        cooldown = 60000, -- 1 minute
        animation = {
            dict = "mp_arresting",
            anim = "a_uncuff",
            duration = 2000
        },
        sound = "verbal_warning",
        notification = "You gave %s a verbal warning."
    },
    slap = {
        name = "Slap",
        description = "Slap the girl to discipline her",
        effects = {
            loyalty = -10,
            happiness = -15,
            obedience = 10,
            health = -5
        },
        cooldown = 300000, -- 5 minutes
        animation = {
            dict = "melee@unarmed@streamed_variations",
            anim = "plyr_takedown_front_slap",
            duration = 2500
        },
        sound = "slap",
        notification = "You slapped %s to discipline her."
    },
    threaten = {
        name = "Threaten",
        description = "Threaten the girl with consequences",
        effects = {
            loyalty = -15,
            happiness = -20,
            obedience = 15
        },
        cooldown = 600000, -- 10 minutes
        animation = {
            dict = "mp_player_int_upperfinger",
            anim = "mp_player_int_finger_01_enter",
            duration = 3000
        },
        sound = "threaten",
        notification = "You threatened %s with consequences."
    },
    punish = {
        name = "Punish",
        description = "Punish the girl by taking away privileges",
        effects = {
            loyalty = -20,
            happiness = -25,
            obedience = 20
        },
        cooldown = 1800000, -- 30 minutes
        animation = {
            dict = "mp_player_int_uppergrab_crotch",
            anim = "mp_player_int_grab_crotch",
            duration = 2500
        },
        sound = "punish",
        notification = "You punished %s by taking away privileges."
    },
    beat = {
        name = "Beat",
        description = "Beat the girl severely (may cause injuries)",
        effects = {
            loyalty = -30,
            happiness = -40,
            obedience = 30,
            health = -20
        },
        cooldown = 3600000, -- 60 minutes
        animation = {
            dict = "melee@unarmed@streamed_variations",
            anim = "plyr_takedown_rear_lefthook",
            duration = 3500
        },
        sound = "beat",
        notification = "You beat %s severely."
    }
}

-- Local variables
local DisciplineCooldowns = {}
local DisciplineHistory = {}

-- Open discipline menu
function OpenDisciplineMenu(girlIndex, girl)
    -- Create options
    local options = {}
    
    -- Add discipline options
    for disciplineType, disciplineConfig in pairs(DisciplineConfig) do
        -- Check if discipline is on cooldown
        local onCooldown = false
        local cooldownKey = disciplineType .. '_' .. girl.id
        
        if DisciplineCooldowns[cooldownKey] and DisciplineCooldowns[cooldownKey] > GetGameTimer() then
            onCooldown = true
        end
        
        -- Add option
        table.insert(options, {
            title = disciplineConfig.name,
            description = disciplineConfig.description,
            icon = 'hand-paper',
            disabled = onCooldown,
            onSelect = function()
                DisciplineGirl(girl.id, girl.name, disciplineType)
            end
        })
    end
    
    -- Register and show context menu
    lib.registerContext({
        id = 'pimp_discipline_menu',
        title = 'Discipline: ' .. girl.name,
        menu = 'pimp_girl_menu_' .. girl.id,
        options = options
    })
    
    lib.showContext('pimp_discipline_menu')
end

-- Discipline girl
function DisciplineGirl(girlId, girlName, disciplineType)
    -- Get discipline config
    local disciplineConfig = DisciplineConfig[disciplineType]
    
    -- Check if discipline config exists
    if not disciplineConfig then
        ShowNotification('Invalid discipline type', 'error')
        return
    end
    
    -- Check if discipline is on cooldown
    local cooldownKey = disciplineType .. '_' .. girlId
    
    if DisciplineCooldowns[cooldownKey] and DisciplineCooldowns[cooldownKey] > GetGameTimer() then
        local remainingTime = math.ceil((DisciplineCooldowns[cooldownKey] - GetGameTimer()) / 1000)
        ShowNotification('You must wait ' .. remainingTime .. ' seconds before using this discipline again', 'error')
        return
    end
    
    -- Find the girl ped
    local girlPed = nil
    
    -- First check if girl is following
    local isFollowing = false
    for _, followingGirl in ipairs(followingGirls or {}) do
        if followingGirl.id == girlId then
            girlPed = followingGirl.ped
            isFollowing = true
            break
        end
    end
    
    -- If not following, check GirlPeds
    if not girlPed and GirlPeds and GirlPeds[girlId] then
        girlPed = GirlPeds[girlId]
    end
    
    -- Check working girls
    if not girlPed and workingGirlPeds and workingGirlPeds[girlId] then
        girlPed = workingGirlPeds[girlId]
    end
    
    -- Play animation
    if disciplineConfig.animation then
        local playerPed = PlayerPedId()
        
        -- Special handling for slap animation
        if disciplineType == "slap" then
            -- Make sure girl is positioned correctly for the slap
            if girlPed and DoesEntityExist(girlPed) then
                -- Trigger server event to sync the animation to all players
                TriggerServerEvent('pimp:syncDisciplineAnimationToAll', girlId, disciplineType, NetworkGetNetworkIdFromEntity(playerPed))
                
                -- Use the enhanced slap animation function
                PerformEnhancedSlapAnimation(playerPed, girlPed)
            else
                -- Fallback to default animation if girl ped not found
                RequestAnimDict(disciplineConfig.animation.dict)
                
                while not HasAnimDictLoaded(disciplineConfig.animation.dict) do
                    Citizen.Wait(0)
                end
                
                TaskPlayAnim(playerPed, disciplineConfig.animation.dict, disciplineConfig.animation.anim, 8.0, -8.0, -1, 0, 0, false, false, false)
                Citizen.Wait(disciplineConfig.animation.duration or 1000)
                ClearPedTasks(playerPed)
            end
        else
            -- Normal animation handling for other discipline types
            if disciplineConfig.animation.dict then
                RequestAnimDict(disciplineConfig.animation.dict)
                
                while not HasAnimDictLoaded(disciplineConfig.animation.dict) do
                    Citizen.Wait(0)
                end
                
                TaskPlayAnim(playerPed, disciplineConfig.animation.dict, disciplineConfig.animation.anim, 8.0, -8.0, -1, 0, 0, false, false, false)
                
                -- If we have the girl ped, make her react
                if girlPed and DoesEntityExist(girlPed) then
                    -- Make girl face player
                    TaskTurnPedToFaceEntity(girlPed, playerPed, 2000)
                    
                    -- Play reaction animation based on discipline type
                    if disciplineType == "verbal" then
                        LoadAnimDict("missfbi3_party_d")
                        TaskPlayAnim(girlPed, "missfbi3_party_d", "stand_talk_loop_a_male", 8.0, -8.0, 4000, 0, 0, false, false, false)
                    elseif disciplineType == "beat" then
                        LoadAnimDict("misscarsteal4@actor")
                        TaskPlayAnim(girlPed, "misscarsteal4@actor", "stumble", 8.0, -8.0, 3500, 0, 0, false, false, false)
                    elseif disciplineType == "threaten" then
                        LoadAnimDict("missfbi3_party_d")
                        TaskPlayAnim(girlPed, "missfbi3_party_d", "stand_talk_loop_b_female", 8.0, -8.0, 4000, 0, 0, false, false, false)
                    end
                end
                
                Citizen.Wait(disciplineConfig.animation.duration or 1000)
                
                ClearPedTasks(playerPed)
            end
        end
    end
    
    -- Play sound
    if disciplineConfig.sound then
        -- Play sound
        -- This is a placeholder function that should be replaced with the actual implementation
        -- based on the framework being used (ESX, QB-Core, etc.)
    end
    
    -- Show notification
    if disciplineConfig.notification then
        ShowNotification(string.format(disciplineConfig.notification, girlName), 'info')
    end
    
    -- Set cooldown
    if disciplineConfig.cooldown then
        DisciplineCooldowns[cooldownKey] = GetGameTimer() + disciplineConfig.cooldown
    end
    
    -- Trigger server event
    TriggerServerEvent('pimp:disciplineGirl', girlId, disciplineType)
    
    -- If girl is working, resume her work after discipline (if not following)
    if not isFollowing and girlPed and DoesEntityExist(girlPed) then
        -- Find girl data
        local girlData = nil
        for _, g in ipairs(PlayerData.girls or {}) do
            if g.id == girlId then
                girlData = g
                break
            end
        end
        
        if girlData and girlData.status == 'working' and girlData.workLocation then
            -- Find work location
            local workLocation = nil
            for _, location in ipairs(Config.WorkLocations) do
                if girlData.workLocation == location.name then
                    workLocation = location
                    break
                end
            end
            
            if workLocation then
                -- Resume working after a short delay
                Citizen.SetTimeout(5000, function()
                    if DoesEntityExist(girlPed) then
                        local scenarios = GetAppropriateScenarios(girlData, workLocation)
                        TaskStartScenarioInPlace(girlPed, GetRandomFromTable(scenarios), 0, true)
                    end
                end)
            end
        end
    end
end

-- Update discipline cooldowns
RegisterNetEvent('pimp:updateDisciplineCooldowns')
AddEventHandler('pimp:updateDisciplineCooldowns', function(cooldowns)
    DisciplineCooldowns = cooldowns
end)

-- Show notification
function ShowNotification(message, type)
    if lib and lib.notify then
        lib.notify({
            title = 'Pimp Management',
            description = message,
            type = type or 'info'
        })
    else
        -- Fallback to default notification system
        SetNotificationTextEntry('STRING')
        AddTextComponentString(message)
        DrawNotification(false, false)
    end
end