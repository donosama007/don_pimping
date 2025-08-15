-- Pimp Management System - Complete Client Main with Follow System
-- Created by Donald Draper
-- Enhanced by NinjaTech AI

-- Local variables
local isMenuOpen = false
local currentMenuId = nil
local currentMenuTitle = nil
local currentMenuOptions = {}
local currentMenuPreviousMenu = nil
local activeGirls = {}
local activeGirlsCount = 0
local playerReputation = 0
local playerReputationLevel = 1
local playerReputationPoints = 0
local playerReputationNextLevel = 100
local playerEarnings = 0
local playerEarningsToday = 0
local playerEarningsWeek = 0
local playerEarningsMonth = 0
local playerEarningsTotal = 0
local playerGirlsCount = 0
local playerGirlsWorking = 0
local playerGirlsIdle = 0
local playerTerritoriesCount = 0
local playerTerritoriesControlled = 0
local playerTerritoriesContested = 0
local playerTerritoriesLost = 0
local playerTerritoriesTotal = 0
local playerTerritoryIncome = 0
local playerTerritoryExpenses = 0
local playerTerritoryProfit = 0
local ActiveCooldowns = {}

-- Silence F8 console unless debugging is explicitly enabled in Config
local print = function(...)
    if Config and Config.Debug then
        _G.print(...)
    end
end

-- ==================== FOLLOW SYSTEM ====================
-- Global variables for following system
local followingGirl = nil
local followingPed = nil
local isGirlFollowing = false

-- Female ped models for spawning
local femaleModels = {
    `a_f_y_beach_01`,
    `a_f_y_bevhills_01`,
    `a_f_y_bevhills_02`,
    `a_f_y_business_01`,
    `a_f_y_business_02`,
    `a_f_y_clubcust_01`,
    `a_f_y_eastsa_01`,
    `a_f_y_fitness_01`,
    `a_f_y_genhot_01`,
    `a_f_y_golfer_01`,
    `a_f_y_hiker_01`,
    `a_f_y_hipster_01`,
    `a_f_y_hipster_02`,
    `a_f_y_hotposh_01`,
    `a_f_y_indian_01`,
    `a_f_y_runner_01`,
    `a_f_y_skater_01`,
    `a_f_y_soucent_01`,
    `a_f_y_soucent_02`,
    `a_f_y_tennis_01`,
    `a_f_y_tourist_01`,
    `a_f_y_vinewood_01`,
    `a_f_y_vinewood_02`,
    `a_f_y_yoga_01`
}

-- Function to spawn and make girl follow
function SpawnFollowingGirl(girlData)
    -- If already following someone, despawn first
    if isGirlFollowing and DoesEntityExist(followingPed) then
        DespawnFollowingGirl()
    end
    
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local playerHeading = GetEntityHeading(playerPed)
    
    -- Choose random female model
    local model = femaleModels[math.random(#femaleModels)]
    
    -- Request model
    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) and timeout < 5000 do
        Citizen.Wait(10)
        timeout = timeout + 10
    end
    
    if not HasModelLoaded(model) then
        ShowNotification('Failed to load girl model', 'error')
        return false
    end
    
    -- Spawn position slightly behind player
    local spawnCoords = GetOffsetFromEntityInWorldCoords(playerPed, -2.0, -2.0, 0.0)
    
    -- Create the ped
    followingPed = CreatePed(4, model, spawnCoords.x, spawnCoords.y, spawnCoords.z, playerHeading, true, false)
    
    if not DoesEntityExist(followingPed) then
        ShowNotification('Failed to spawn girl', 'error')
        SetModelAsNoLongerNeeded(model)
        return false
    end

    -- Ensure discipline and other systems can find this ped by ID
    if girlData and girlData.id then
        GirlPeds = GirlPeds or {}
        GirlPeds[girlData.id] = followingPed
    end
    
    -- Configure the ped
    SetEntityAsMissionEntity(followingPed, true, true)
    SetPedRandomComponentVariation(followingPed, false)
    SetPedRandomProps(followingPed)
    SetEntityInvincible(followingPed, true)
    SetPedFleeAttributes(followingPed, 0, false)
    SetPedCombatAttributes(followingPed, 17, true)
    SetPedRelationshipGroupHash(followingPed, GetHashKey("PLAYER"))
    
    -- Make her follow the player
    TaskFollowToOffsetOfEntity(followingPed, playerPed, -2.0, -2.0, 0.0, 5.0, -1, 1.5, true)
    
    -- Store data
    followingGirl = girlData
    isGirlFollowing = true
    
    -- Clean up model
    SetModelAsNoLongerNeeded(model)
    
    ShowNotification(girlData.name .. ' is now following you!', 'success')
    return true
end

-- Function to despawn following girl
function DespawnFollowingGirl()
    if DoesEntityExist(followingPed) then
        DeleteEntity(followingPed)
    end

    -- Remove from shared GirlPeds so other systems don't reference a deleted ped
    if followingGirl and followingGirl.id and GirlPeds and GirlPeds[followingGirl.id] then
        GirlPeds[followingGirl.id] = nil
    end
    
    followingPed = nil
    followingGirl = nil
    isGirlFollowing = false
    
    ShowNotification('Girl stopped following you', 'info')
end

-- Event handler for server toggle command
RegisterNetEvent('pimp:doToggleFollow')
AddEventHandler('pimp:doToggleFollow', function(girl)
    ToggleGirlFollow(girl)
end)

-- Toggle girl follow function
function ToggleGirlFollow(girl)
    if isGirlFollowing and followingGirl and followingGirl.id == girl.id then
        -- Girl is currently following, stop her
        DespawnFollowingGirl()
    else
        -- Allow working girls to follow too
        if girl.status ~= 'idle' and girl.status ~= 'working' then
            ShowNotification(girl.name .. ' is currently ' .. girl.status .. ' and cannot follow you', 'error')
            return
        end
        
        -- If another girl is following, stop her first
        if isGirlFollowing then
            DespawnFollowingGirl()
            Citizen.Wait(500) -- Small delay
        end
        
        -- Spawn new girl
        SpawnFollowingGirl(girl)
    end
    
    -- Also call the enhanced follow system if available
    if _G.MakeGirlFollow then
        _G.MakeGirlFollow(girl)
    end
end

-- Update following task periodically
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5000) -- Check every 5 seconds
        
        if isGirlFollowing and DoesEntityExist(followingPed) then
            local playerPed = PlayerPedId()
            
            -- Check if ped is still following
            if not IsPedActiveInScenario(followingPed) then
                -- Restart follow task if needed
                TaskFollowToOffsetOfEntity(followingPed, playerPed, -2.0, -2.0, 0.0, 5.0, -1, 1.5, true)
            end
            
            -- Check distance and teleport if too far
            local playerCoords = GetEntityCoords(playerPed)
            local pedCoords = GetEntityCoords(followingPed)
            local distance = #(playerCoords - pedCoords)
            
            if distance > 50.0 then
                -- Teleport ped closer to player
                local newCoords = GetOffsetFromEntityInWorldCoords(playerPed, -2.0, -2.0, 0.0)
                SetEntityCoords(followingPed, newCoords.x, newCoords.y, newCoords.z, false, false, false, true)
                TaskFollowToOffsetOfEntity(followingPed, playerPed, -2.0, -2.0, 0.0, 5.0, -1, 1.5, true)
            end
        end
    end
end)

-- Handle vehicle enter/exit
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        
        if isGirlFollowing and DoesEntityExist(followingPed) then
            local playerPed = PlayerPedId()
            
            -- If player is in vehicle, put girl in vehicle too
            if IsPedInAnyVehicle(playerPed, false) then
                if not IsPedInAnyVehicle(followingPed, false) then
                    local vehicle = GetVehiclePedIsIn(playerPed, false)
                    local seat = GetFreeSeatInVehicle(vehicle)
                    
                    if seat ~= -1 then
                        TaskWarpPedIntoVehicle(followingPed, vehicle, seat)
                    end
                end
            else
                -- If player exits vehicle, make girl exit too
                if IsPedInAnyVehicle(followingPed, false) then
                    TaskLeaveVehicle(followingPed, GetVehiclePedIsIn(followingPed, false), 0)
                    Citizen.Wait(2000)
                    TaskFollowToOffsetOfEntity(followingPed, playerPed, -2.0, -2.0, 0.0, 5.0, -1, 1.5, true)
                end
            end
        end
    end
end)

-- Helper function to find free seat in vehicle
function GetFreeSeatInVehicle(vehicle)
    local maxSeats = GetVehicleMaxNumberOfPassengers(vehicle)
    
    for seat = 0, maxSeats do
        if IsVehicleSeatFree(vehicle, seat) then
            return seat
        end
    end
    
    return -1
end

-- Global functions for compatibility
_G.IsGirlFollowing = function(girlId)
    return isGirlFollowing and followingGirl and followingGirl.id == girlId
end

_G.StopGirlFromFollowing = function(girlId, showNotification)
    if isGirlFollowing and followingGirl and followingGirl.id == girlId then
        DespawnFollowingGirl()
        return true
    end
    return false
end

_G.MakeGirlFollow = function(girl)
    if girl and girl.id then
        ToggleGirlFollow(girl)
        return true
    end
    return false
end

-- ==================== END FOLLOW SYSTEM ====================

-- Enhanced initialization with auto data request
Citizen.CreateThread(function()
    -- Wait for the player to spawn
    while not NetworkIsPlayerActive(PlayerId()) do
        Citizen.Wait(0)
    end
    
    print("^3[Client] Player spawned, waiting before requesting data...^7")
    
    -- Wait a bit more for everything to load
    Citizen.Wait(5000)
    
    print("^3[Client] Triggering player loaded event^7")
    
    -- Initialize the script
    TriggerServerEvent('pimp:playerLoaded')
    
    -- Also request girls data directly
    Citizen.SetTimeout(2000, function()
        print("^3[Client] Requesting player girls data^7")
        TriggerServerEvent('pimp:getPlayerGirls')
    end)
    
    -- Register command to open pimp menu
    RegisterCommand('pimp', function()
        OpenPimpMenu()
    end, false)
    
    -- Register keybind to open pimp menu
    RegisterKeyMapping('pimp', 'Open Pimp Menu', 'keyboard', 'F6')
end)

-- Enhanced PlayerData handling with debugging
PlayerData = PlayerData or {}

RegisterNetEvent('pimp:updatePlayerData')
AddEventHandler('pimp:updatePlayerData', function(data)
    print("^3[Client] Received player data update^7")
    print("^3[Client] Girls count: " .. #(data.girls or {}) .. "^7")
    
    -- Update PlayerData global variable
    PlayerData = data
    
    -- Update all the local variables
    playerReputation = data.reputation or 0
    playerReputationLevel = data.reputationLevel or 1
    playerReputationPoints = data.reputationPoints or 0
    playerReputationNextLevel = data.reputationNextLevel or 100
    playerEarnings = data.earnings and data.earnings.total or 0
    playerEarningsToday = data.earnings and data.earnings.daily or 0
    playerEarningsWeek = data.earnings and data.earnings.weekly or 0
    playerEarningsMonth = data.earningsMonth or 0
    playerEarningsTotal = data.earnings and data.earnings.total or 0
    playerGirlsCount = data.girlsCount or #(data.girls or {})
    playerGirlsWorking = data.girlsWorking or 0
    playerGirlsIdle = data.girlsIdle or 0
    
    -- Territory data
    playerTerritoriesCount = data.territoriesCount or 0
    playerTerritoriesControlled = data.territoriesControlled or 0
    playerTerritoriesContested = data.territoriesContested or 0
    playerTerritoriesLost = data.territoriesLost or 0
    playerTerritoriesTotal = data.territoriesTotal or 0
    playerTerritoryIncome = data.territoryIncome or 0
    playerTerritoryExpenses = data.territoryExpenses or 0
    playerTerritoryProfit = data.territoryProfit or 0
    
    print("^2[Client] Updated PlayerData - Girls: " .. playerGirlsCount .. "^7")
    
    -- Debug: Print girl names
    if data.girls then
        for i, girl in ipairs(data.girls) do
            print("^2[Client]   " .. i .. ". " .. girl.name .. " (" .. girl.type .. ")^7")
        end
    end
    
    -- Also update global for girls.lua compatibility
    _G.PlayerData = data
end)

RegisterNetEvent('pimp:updateActiveGirls')
AddEventHandler('pimp:updateActiveGirls', function(girls)
    print("^3[Client] Received active girls update - Count: " .. #girls .. "^7")
    
    -- Update active girls
    activeGirls = girls
    activeGirlsCount = #girls
    
    -- Also update PlayerData.girls for consistency
    if not PlayerData then PlayerData = {} end
    PlayerData.girls = girls
    
    print("^2[Client] Updated activeGirls - Count: " .. activeGirlsCount .. "^7")
    
    -- Debug: Print girl names
    for i, girl in ipairs(girls) do
        print("^2[Client]   " .. i .. ". " .. girl.name .. " (" .. girl.type .. ") - Status: " .. (girl.status or "unknown") .. "^7")
    end
    
    -- Also update global for girls.lua compatibility
    if not _G.PlayerData then _G.PlayerData = {} end
    _G.PlayerData.girls = girls
end)

-- Enhanced event handler for when a girl is successfully added
RegisterNetEvent('pimp:girlAddedSuccess')
AddEventHandler('pimp:girlAddedSuccess', function(girlData)
    print("^2[Client] Girl added successfully: " .. girlData.name .. "^7")
    
    -- Request fresh data from server to ensure sync
    Citizen.SetTimeout(1000, function()
        print("^3[Client] Requesting fresh player data after girl addition^7")
        TriggerServerEvent('pimp:getPlayerGirls')
    end)
    
    -- Show success notification
    ShowNotification('Successfully hired ' .. girlData.name .. '!', 'success')
end)

-- Enhanced event handler for setting player data (compatibility with girls.lua)
RegisterNetEvent('pimp:setPlayerData')
AddEventHandler('pimp:setPlayerData', function(data)
    print("^3[Client] Setting player data for compatibility^7")
    PlayerData = data
    
    -- Also update the global for girls.lua compatibility
    _G.PlayerData = data
end)

-- Show notification function
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

-- Enhanced menu access check
function OpenPimpMenu()
    print("^3[Client] Opening pimp menu^7")
    
    -- Request fresh data if we don't have any
    if not PlayerData or not PlayerData.girls then
        print("^3[Client] No player data, requesting from server^7")
        TriggerServerEvent('pimp:getPlayerGirls')
        
        -- Show loading message and try again after delay
        ShowNotification('Loading your data...', 'info')
        
        Citizen.SetTimeout(2000, function()
            if PlayerData and PlayerData.girls then
                OpenPimpMenuActual()
            else
                ShowNotification('Failed to load data. Please try again.', 'error')
            end
        end)
        return
    end
    
    OpenPimpMenuActual()
end

function OpenPimpMenuActual()
    local options = {
        {
            title = 'Girls',
            description = 'Manage your girls (' .. (PlayerData and PlayerData.girls and #PlayerData.girls or 0) .. ' girls)',
            icon = 'female',
            onSelect = function()
                OpenGirlsMenu()
            end
        },
        {
            title = 'Reputation',
            description = 'View your reputation and perks (Level: ' .. playerReputationLevel .. ')',
            icon = 'star',
            onSelect = function()
                OpenReputationMenu()
            end
        },
        {
            title = 'Earnings',
            description = 'View your earnings ($' .. FormatNumber(playerEarningsTotal) .. ' total)',
            icon = 'dollar-sign',
            onSelect = function()
                OpenEarningsMenu()
            end
        },
        {
            title = 'Territory',
            description = 'Manage territories (' .. playerTerritoriesControlled .. ' controlled)',
            icon = 'map-marked-alt',
            onSelect = function()
                OpenTerritoryMenu()
            end
        },
        {
            title = 'Recruitment',
            description = 'Find and recruit new girls',
            icon = 'user-plus',
            onSelect = function()
                OpenRecruitmentMenu()
            end
        }
    }
    
    -- Register and show context menu
    if lib and lib.registerContext then
        lib.registerContext({
            id = 'pimp_menu',
            title = 'Pimp Management',
            options = options
        })
        
        lib.showContext('pimp_menu')
    else
        ShowNotification('Menu system not available', 'error')
    end
end

-- Enhanced OpenGirlsMenu function with better error handling and debugging
function OpenGirlsMenu()
    print("^3[Client] Opening girls menu^7")
    print("^3[Client] PlayerData exists: " .. tostring(PlayerData ~= nil) .. "^7")
    print("^3[Client] activeGirlsCount: " .. activeGirlsCount .. "^7")
    
    -- Multiple checks for player data
    local girlsToShow = nil
    local girlsCount = 0
    
    -- First check PlayerData.girls
    if PlayerData and PlayerData.girls and #PlayerData.girls > 0 then
        girlsToShow = PlayerData.girls
        girlsCount = #PlayerData.girls
        print("^2[Client] Using PlayerData.girls - Count: " .. girlsCount .. "^7")
    -- Then check activeGirls
    elseif activeGirls and #activeGirls > 0 then
        girlsToShow = activeGirls
        girlsCount = #activeGirls
        print("^2[Client] Using activeGirls - Count: " .. girlsCount .. "^7")
    else
        print("^1[Client] No girls found in any data source^7")
        print("^1[Client] PlayerData: " .. tostring(PlayerData ~= nil) .. "^7")
        if PlayerData then
            print("^1[Client] PlayerData.girls: " .. tostring(PlayerData.girls ~= nil) .. "^7")
            if PlayerData.girls then
                print("^1[Client] PlayerData.girls count: " .. #PlayerData.girls .. "^7")
            end
        end
        
        -- Request fresh data from server
        print("^3[Client] Requesting fresh data from server^7")
        TriggerServerEvent('pimp:getPlayerGirls')
        
        ShowNotification('Loading your girls... Please try again in a moment.', 'info')
        return
    end
    
    print("^2[Client] Found " .. girlsCount .. " girls to display^7")
    
    local options = {}
    
    -- Add girls to options
    for i, girl in ipairs(girlsToShow) do
        local status = girl.status or 'idle'
        local statusIcon = 'circle'
        
        if status == 'working' then
            statusIcon = 'briefcase'
        elseif status == 'idle' then
            statusIcon = 'coffee'
        elseif status == 'resting' then
            statusIcon = 'bed'
        elseif status == 'injured' then
            statusIcon = 'medkit'
        elseif status == 'arrested' then
            statusIcon = 'handcuffs'
        end
        
        local earnings = girl.earnings or girl.totalEarnings or girl.pendingEarnings or 0
        local happiness = girl.happiness or 50
        local loyalty = girl.loyalty or (girl.attributes and girl.attributes.loyalty) or 50
        
        table.insert(options, {
            title = girl.name,
            description = 'Status: ' .. status .. ' | Type: ' .. (girl.type or 'Unknown'),
            icon = statusIcon,
            metadata = {
                {label = 'Earnings', value = '$' .. earnings},
                {label = 'Happiness', value = happiness .. '%'},
                {label = 'Loyalty', value = loyalty .. '%'},
                {label = 'Type', value = girl.type or 'Unknown'},
                {label = 'ID', value = tostring(girl.id or 'Unknown')}
            },
            onSelect = function()
                print("^3[Client] Selected girl: " .. girl.name .. " (ID: " .. (girl.id or "unknown") .. ")^7")
                OpenGirlMenu(i, girl)
            end
        })
    end
    
    if #options == 0 then
        ShowNotification('No girls available. Visit a hiring location to recruit some!', 'error')
        return
    end
    
    -- Register and show context menu
    if lib and lib.registerContext then
        lib.registerContext({
            id = 'pimp_girls_menu',
            title = 'Girls Management (' .. girlsCount .. ' girls)',
            menu = 'pimp_menu',
            options = options
        })
        
        lib.showContext('pimp_girls_menu')
        print("^2[Client] Opened girls menu with " .. #options .. " options^7")
    else
        ShowNotification('Menu system not available', 'error')
    end
end

-- Open girl menu
function OpenGirlMenu(girlIndex, girl)
    -- Get follow status for button text
    local followButtonText = 'Follow Me'
    local followButtonDesc = 'Make ' .. girl.name .. ' follow you around'
    
    -- Check both local and global follow status
    local isFollowing = false
    
    -- Check main follow system
    if isGirlFollowing and followingGirl and followingGirl.id == girl.id then
        isFollowing = true
    end
    
    -- Also check enhanced follow system
    if _G.IsGirlFollowing and _G.IsGirlFollowing(girl.id) then
        isFollowing = true
    end
    
    -- Check global FollowingGirl variable from girls.lua
    if FollowingGirl == girl.id then
        isFollowing = true
    end
    
    if isFollowing then
        followButtonText = 'Stop Following'
        followButtonDesc = girl.name .. ' is currently following you'
    end
    
    -- Create options
    local options = {
        {
            title = 'View Details',
            description = 'View detailed information about ' .. girl.name,
            icon = 'info-circle',
            onSelect = function()
                OpenGirlDetailsMenu(girlIndex, girl)
            end
        },
        {
            title = 'Manage Work',
            description = 'Manage ' .. girl.name .. '\'s work',
            icon = 'briefcase',
            onSelect = function()
                OpenGirlWorkMenu(girlIndex, girl)
            end
        },
        {
            title = 'Manage Happiness',
            description = 'Manage ' .. girl.name .. '\'s happiness',
            icon = 'smile',
            onSelect = function()
                OpenGirlHappinessMenu(girlIndex, girl)
            end
        },
        {
            title = followButtonText,
            description = followButtonDesc,
            icon = 'walking',
            onSelect = function()
                if isFollowing then
                    -- If using enhanced follow system
                    if _G.StopGirlFromFollowing then
                        _G.StopGirlFromFollowing(girl.id, true)
                    else
                        -- Fallback to server event
                        TriggerServerEvent('pimp:toggleGirlFollow', girl.id)
                    end
                else
                    -- If using enhanced follow system
                    if _G.MakeGirlFollow then
                        _G.MakeGirlFollow(girl)
                    else
                        -- Fallback to server event
                        TriggerServerEvent('pimp:toggleGirlFollow', girl.id)
                    end
                end
            end
        },
        {
            title = 'Discipline',
            description = 'Discipline ' .. girl.name,
            icon = 'gavel',
            onSelect = function()
                OpenDisciplineMenu(girlIndex, girl)
            end
        },
        {
            title = 'Release',
            description = 'Release ' .. girl.name .. ' from your control',
            icon = 'door-open',
            onSelect = function()
                ReleaseGirl(girl.id)
            end
        }
    }
    
    -- Register and show context menu
    if lib and lib.registerContext then
        lib.registerContext({
            id = 'pimp_girl_menu_' .. girl.id,
            title = girl.name,
            menu = 'pimp_girls_menu',
            options = options
        })
        
        lib.showContext('pimp_girl_menu_' .. girl.id)
    end
end

-- Open girl details menu
function OpenGirlDetailsMenu(girlIndex, girl)
    -- Create options
    local options = {
        {
            title = 'Personal Information',
            description = 'View personal information about ' .. girl.name,
            icon = 'user',
            metadata = {
                {label = 'Name', value = girl.name},
                {label = 'Age', value = girl.age or 'Unknown'},
                {label = 'Nationality', value = girl.nationality or 'Unknown'},
                {label = 'Height', value = (girl.height or 170) .. ' cm'},
                {label = 'Weight', value = (girl.weight or 60) .. ' kg'}
            }
        },
        {
            title = 'Work Statistics',
            description = 'View work statistics for ' .. girl.name,
            icon = 'chart-bar',
            metadata = {
                {label = 'Earnings Today', value = '$' .. (girl.earningsToday or 0)},
                {label = 'Earnings Week', value = '$' .. (girl.earningsWeek or 0)},
                {label = 'Earnings Month', value = '$' .. (girl.earningsMonth or 0)},
                {label = 'Earnings Total', value = '$' .. (girl.earningsTotal or girl.totalEarnings or 0)},
                {label = 'Clients Today', value = girl.clientsToday or 0},
                {label = 'Clients Total', value = girl.clientsTotal or girl.clientsServed or 0}
            }
        },
        {
            title = 'Attributes',
            description = 'View attributes for ' .. girl.name,
            icon = 'sliders-h',
            metadata = {
                {label = 'Happiness', value = (girl.happiness or 50) .. '%'},
                {label = 'Loyalty', value = (girl.loyalty or (girl.attributes and girl.attributes.loyalty) or 50) .. '%'},
                {label = 'Energy', value = (girl.energy or 100) .. '%'},
                {label = 'Health', value = (girl.health or 100) .. '%'},
                {label = 'Appearance', value = (girl.attributes and girl.attributes.appearance or girl.attractiveness or 50) .. '%'},
                {label = 'Performance', value = (girl.attributes and girl.attributes.performance or girl.experience or 50) .. '%'},
                {label = 'Discretion', value = (girl.attributes and girl.attributes.discretion or 50) .. '%'}
            }
        }
    }
    
    -- Register and show context menu
    if lib and lib.registerContext then
        lib.registerContext({
            id = 'pimp_girl_details_menu_' .. girl.id,
            title = girl.name .. ' - Details',
            menu = 'pimp_girl_menu_' .. girl.id,
            options = options
        })
        
        lib.showContext('pimp_girl_details_menu_' .. girl.id)
    end
end

-- Girl work management
function OpenGirlWorkMenu(girlIndex, girl)
    local options = {
        {
            title = 'Current Status',
            description = 'Status: ' .. (girl.status or 'idle'),
            icon = 'info',
            metadata = {
                {label = 'Status', value = girl.status or 'idle'},
                {label = 'Location', value = girl.workLocation or 'None'},
                {label = 'Earnings', value = '$' .. (girl.pendingEarnings or 0)}
            }
        }
    }
    
    if girl.status == 'working' then
        table.insert(options, {
            title = 'Stop Working',
            description = 'Stop ' .. girl.name .. ' from working',
            icon = 'stop-circle',
            onSelect = function()
                TriggerServerEvent('pimp:stopGirlWorking', girl.id)
                ShowNotification(girl.name .. ' stopped working', 'info')
            end
        })
        
        table.insert(options, {
            title = 'Withdraw Earnings',
            description = 'Withdraw pending earnings ($' .. (girl.pendingEarnings or 0) .. ')',
            icon = 'money-bill-wave',
            onSelect = function()
                if (girl.pendingEarnings or 0) > 0 then
                    TriggerServerEvent('pimp:withdrawGirlEarnings', girl.id)
                    ShowNotification('Withdrew $' .. girl.pendingEarnings .. ' from ' .. girl.name, 'success')
                else
                    ShowNotification(girl.name .. ' has no earnings to withdraw', 'error')
                end
            end
        })
    else
        table.insert(options, {
            title = 'Send to Work',
            description = 'Send ' .. girl.name .. ' to work at a location',
            icon = 'briefcase',
            onSelect = function()
                OpenWorkLocationMenu(girl)
            end
        })
    end
    
    -- Register and show context menu
    if lib and lib.registerContext then
        lib.registerContext({
            id = 'pimp_girl_work_menu_' .. girl.id,
            title = girl.name .. ' - Work Management',
            menu = 'pimp_girl_menu_' .. girl.id,
            options = options
        })
        
        lib.showContext('pimp_girl_work_menu_' .. girl.id)
    end
end

-- Work location selection
function OpenWorkLocationMenu(girl)
    local options = {}
    
    -- Default locations if Config is not available
    local defaultLocations = {
        {name = "Street Corner", riskLevel = "High", earningsMultiplier = 1.2},
        {name = "Hotel District", riskLevel = "Medium", earningsMultiplier = 1.5},
        {name = "Upscale Club", riskLevel = "Low", earningsMultiplier = 2.0}
    }
    
    local locations = (Config and Config.WorkLocations) and Config.WorkLocations or defaultLocations
    
    for _, location in ipairs(locations) do
        table.insert(options, {
            title = location.name,
            description = 'Risk: ' .. (location.riskLevel or 'Unknown') .. ' | Earnings: x' .. (location.earningsMultiplier or 1),
            icon = 'map-marker-alt',
            metadata = {
                {label = 'Risk Level', value = location.riskLevel or 'Unknown'},
                {label = 'Earnings Multiplier', value = 'x' .. (location.earningsMultiplier or 1)},
                {label = 'Client Density', value = (location.clientDensity or 1) .. 'x'}
            },
            onSelect = function()
                TriggerServerEvent('pimp:setGirlToWork', girl.id, location.name)
                ShowNotification(girl.name .. ' is now working at ' .. location.name, 'success')
            end
        })
    end
    
    -- Register and show context menu
    if lib and lib.registerContext then
        lib.registerContext({
            id = 'pimp_work_location_menu_' .. girl.id,
            title = 'Choose Work Location for ' .. girl.name,
            menu = 'pimp_girl_work_menu_' .. girl.id,
            options = options
        })
        
        lib.showContext('pimp_work_location_menu_' .. girl.id)
    end
end

-- Girl happiness management
function OpenGirlHappinessMenu(girlIndex, girl)
    local options = {
        {
            title = 'Current Happiness',
            description = 'Happiness level: ' .. (girl.happiness or 50) .. '%',
            icon = 'smile',
            metadata = {
                {label = 'Happiness', value = (girl.happiness or 50) .. '%'},
                {label = 'Loyalty', value = (girl.loyalty or (girl.attributes and girl.attributes.loyalty) or 50) .. '%'},
                {label = 'Energy', value = (girl.energy or 100) .. '%'},
                {label = 'Health', value = (girl.health or 100) .. '%'}
            }
        },
        {
            title = 'Buy Gift ($100)',
            description = 'Give a small gift to increase happiness',
            icon = 'gift',
            onSelect = function()
                TriggerServerEvent('pimp:giveGirlGift', girl.id, 'small')
                ShowNotification('Gave ' .. girl.name .. ' a gift', 'success')
            end
        },
        {
            title = 'Take to Dinner ($300)',
            description = 'Take to dinner to increase happiness',
            icon = 'utensils',
            onSelect = function()
                TriggerServerEvent('pimp:takeGirlToDinner', girl.id, 'casual')
                ShowNotification('Took ' .. girl.name .. ' to dinner', 'success')
            end
        },
        {
            title = 'Shopping Trip ($500)',
            description = 'Take shopping to increase happiness',
            icon = 'shopping-bag',
            onSelect = function()
                TriggerServerEvent('pimp:startGirlActivity', girl.id, 'Shopping')
                ShowNotification(girl.name .. ' went shopping', 'success')
            end
        },
        {
            title = 'Spa Day ($1000)',
            description = 'Send to spa for major happiness boost',
            icon = 'spa',
            onSelect = function()
                TriggerServerEvent('pimp:startGirlActivity', girl.id, 'Spa Day')
                ShowNotification(girl.name .. ' went to the spa', 'success')
            end
        }
    }
    
    -- Register and show context menu
    if lib and lib.registerContext then
        lib.registerContext({
            id = 'pimp_girl_happiness_menu_' .. girl.id,
            title = girl.name .. ' - Happiness Management',
            menu = 'pimp_girl_menu_' .. girl.id,
            options = options
        })
        
        lib.showContext('pimp_girl_happiness_menu_' .. girl.id)
    end
end

-- Discipline menu
function OpenDisciplineMenu(girlIndex, girl)
    local options = {
        {
            title = 'Current Status',
            description = 'Fear: ' .. ((girl.attributes and girl.attributes.fear) or 0) .. '% | Attitude: ' .. (girl.hasAttitude and 'Problem' or 'Good'),
            icon = 'info',
            metadata = {
                {label = 'Fear Level', value = ((girl.attributes and girl.attributes.fear) or 0) .. '%'},
                {label = 'Attitude', value = girl.hasAttitude and 'Problem' or 'Good'},
                {label = 'Loyalty', value = (girl.loyalty or (girl.attributes and girl.attributes.loyalty) or 50) .. '%'}
            }
        },
        {
            title = 'Verbal Warning',
            description = 'Give a stern talking to',
            icon = 'comment',
            onSelect = function()
                if DisciplineGirl then
                    DisciplineGirl(girl.id, girl.name, 'verbal')
                else
                    TriggerServerEvent('pimp:disciplineGirl', girl.id, 'verbal')
                    ShowNotification('You gave ' .. girl.name .. ' a verbal warning', 'info')
                end
            end
        },
        {
            title = 'Slap',
            description = 'Slap the girl to discipline her',
            icon = 'hand-paper',
            onSelect = function()
                if DisciplineGirl then
                    DisciplineGirl(girl.id, girl.name, 'slap')
                else
                    TriggerServerEvent('pimp:disciplineGirl', girl.id, 'slap')
                    ShowNotification('You slapped ' .. girl.name .. ' to discipline her', 'warning')
                end
            end
        },
        {
            title = 'Threaten',
            description = 'Intimidate with serious consequences',
            icon = 'exclamation-triangle',
            onSelect = function()
                if DisciplineGirl then
                    DisciplineGirl(girl.id, girl.name, 'threaten')
                else
                    TriggerServerEvent('pimp:disciplineGirl', girl.id, 'threaten')
                    ShowNotification('You threatened ' .. girl.name, 'warning')
                end
            end
        },
        {
            title = 'Punish',
            description = 'Punish the girl by taking away privileges',
            icon = 'ban',
            onSelect = function()
                if DisciplineGirl then
                    DisciplineGirl(girl.id, girl.name, 'punish')
                else
                    TriggerServerEvent('pimp:disciplineGirl', girl.id, 'punish')
                    ShowNotification('You punished ' .. girl.name .. ' by taking away privileges', 'warning')
                end
            end
        },
        {
            title = 'Beat',
            description = 'Beat the girl severely (may cause injuries)',
            icon = 'fist-raised',
            onSelect = function()
                if DisciplineGirl then
                    DisciplineGirl(girl.id, girl.name, 'beat')
                else
                    TriggerServerEvent('pimp:disciplineGirl', girl.id, 'beat')
                    ShowNotification('You beat ' .. girl.name .. ' severely', 'error')
                end
            end
        }
    }
    
    -- Register and show context menu
    if lib and lib.registerContext then
        lib.registerContext({
            id = 'pimp_discipline_menu_' .. girl.id,
            title = girl.name .. ' - Discipline',
            menu = 'pimp_girl_menu_' .. girl.id,
            options = options
        })
        
        lib.showContext('pimp_discipline_menu_' .. girl.id)
    end
end

-- Release girl
function ReleaseGirl(girlId)
    local input = lib.inputDialog('Confirm Release', {
        {type = 'checkbox', label = 'Are you sure you want to release this girl? This cannot be undone.'}
    })
    
    if input and input[1] then
        TriggerServerEvent('pimp:releaseGirl', girlId)
        ShowNotification('Girl has been released', 'info')
        -- Refresh the menu
        Citizen.SetTimeout(1000, function()
            TriggerServerEvent('pimp:getPlayerGirls')
        end)
    end
end

-- Reputation menu
function OpenReputationMenu()
    local options = {
        {
            title = 'Current Reputation',
            description = 'Level ' .. playerReputationLevel .. ' (' .. playerReputation .. ' points)',
            icon = 'star',
            metadata = {
                {label = 'Level', value = playerReputationLevel},
                {label = 'Points', value = playerReputation},
                {label = 'Next Level', value = playerReputationNextLevel}
            }
        },
        {
            title = 'Perks',
            description = 'View and purchase available perks',
            icon = 'gift',
            onSelect = function()
                OpenPerksMenu()
            end
        },
        {
            title = 'Leaderboard',
            description = 'View the reputation leaderboard',
            icon = 'trophy',
            onSelect = function()
                TriggerServerEvent('pimp:requestReputationLeaderboard')
                ShowNotification('Loading leaderboard...', 'info')
            end
        }
    }
    
    -- Register and show context menu
    if lib and lib.registerContext then
        lib.registerContext({
            id = 'pimp_reputation_menu',
            title = 'Reputation System',
            menu = 'pimp_menu',
            options = options
        })
        
        lib.showContext('pimp_reputation_menu')
    end
end

-- Perks menu
function OpenPerksMenu()
    TriggerServerEvent('pimp:requestAvailablePerks')
    ShowNotification('Loading available perks...', 'info')
end

-- Earnings menu
function OpenEarningsMenu()
    local options = {
        {
            title = 'Earnings Overview',
            description = 'Total: $' .. FormatNumber(playerEarningsTotal),
            icon = 'dollar-sign',
            metadata = {
                {label = 'Today', value = '$' .. FormatNumber(playerEarningsToday)},
                {label = 'This Week', value = '$' .. FormatNumber(playerEarningsWeek)},
                {label = 'This Month', value = '$' .. FormatNumber(playerEarningsMonth)},
                {label = 'Total', value = '$' .. FormatNumber(playerEarningsTotal)}
            }
        },
        {
            title = 'Earnings by Girl',
            description = 'View earnings breakdown by girl',
            icon = 'female',
            onSelect = function()
                OpenEarningsByGirlMenu()
            end
        },
        {
            title = 'Earnings History',
            description = 'View detailed earnings history',
            icon = 'history',
            onSelect = function()
                TriggerServerEvent('pimp:requestEarningsHistory')
                ShowNotification('Loading earnings history...', 'info')
            end
        }
    }
    
    -- Register and show context menu
    if lib and lib.registerContext then
        lib.registerContext({
            id = 'pimp_earnings_menu',
            title = 'Earnings Management',
            menu = 'pimp_menu',
            options = options
        })
        
        lib.showContext('pimp_earnings_menu')
    end
end

-- Earnings by girl
function OpenEarningsByGirlMenu()
    local options = {}
    
    if PlayerData and PlayerData.girls then
        for _, girl in ipairs(PlayerData.girls) do
            table.insert(options, {
                title = girl.name,
                description = 'Total: $' .. FormatNumber(girl.totalEarnings or 0),
                icon = 'female',
                metadata = {
                    {label = 'Total Earnings', value = '$' .. FormatNumber(girl.totalEarnings or 0)},
                    {label = 'Pending', value = '$' .. FormatNumber(girl.pendingEarnings or 0)},
                    {label = 'Clients Served', value = girl.clientsServed or 0}
                }
            })
        end
    end
    
    -- Register and show context menu
    if lib and lib.registerContext then
        lib.registerContext({
            id = 'pimp_earnings_by_girl_menu',
            title = 'Earnings by Girl',
            menu = 'pimp_earnings_menu',
            options = options
        })
        
        lib.showContext('pimp_earnings_by_girl_menu')
    end
end

-- Territory menu
function OpenTerritoryMenu()
    local options = {
        {
            title = 'Territory Overview',
            description = 'Controlled: ' .. playerTerritoriesControlled .. ' territories',
            icon = 'map-marked-alt',
            metadata = {
                {label = 'Controlled', value = playerTerritoriesControlled},
                {label = 'Contested', value = playerTerritoriesContested},
                {label = 'Income', value = '$' .. FormatNumber(playerTerritoryIncome)},
                {label = 'Profit', value = '$' .. FormatNumber(playerTerritoryProfit)}
            }
        },
        {
            title = 'Manage Territories',
            description = 'View and manage your territories',
            icon = 'cog',
            onSelect = function()
                -- Refresh territory data and open the management menu
                TriggerServerEvent('pimp:requestTerritories')
                OpenTerritoryManagementMenu()
            end
        },
        {
            title = 'Discover Territories',
            description = 'Find new territories to claim',
            icon = 'search',
            onSelect = function()
                -- Use existing client discovery flow to set waypoint and spawn dealer
                local ok = FindRandomTerritory()
                if not ok then
                    ShowNotification('No available territories found', 'error')
                end
            end
        }
    }
    
    -- Register and show context menu
    if lib and lib.registerContext then
        lib.registerContext({
            id = 'pimp_territory_menu',
            title = 'Territory Management',
            menu = 'pimp_menu',
            options = options
        })
        
        lib.showContext('pimp_territory_menu')
    end
end

-- Recruitment menu
function OpenRecruitmentMenu()
    local options = {
        {
            title = 'Find Girls',
            description = 'Search for new girls to recruit',
            icon = 'search',
            onSelect = function()
                TriggerServerEvent('pimp:getAvailableGirls')
                ShowNotification('Searching for available girls...', 'info')
            end
        },
        {
            title = 'Hiring Locations',
            description = 'Visit hiring locations on the map',
            icon = 'map-marker-alt',
            onSelect = function()
                ShowNotification('Check the map for hiring location blips!', 'info')
            end
        },
        {
            title = 'Recruitment History',
            description = 'View your recruitment history',
            icon = 'history',
            onSelect = function()
                TriggerServerEvent('pimp:getRecruitmentHistory')
                ShowNotification('Loading recruitment history...', 'info')
            end
        }
    }
    
    -- Register and show context menu
    if lib and lib.registerContext then
        lib.registerContext({
            id = 'pimp_recruitment_menu',
            title = 'Recruitment',
            menu = 'pimp_menu',
            options = options
        })
        
        lib.showContext('pimp_recruitment_menu')
    end
end

-- Helper function to format numbers
function FormatNumber(num)
    if not num then return "0" end
    if num >= 1000000 then
        return string.format("%.1fM", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.1fK", num / 1000)
    else
        return tostring(math.floor(num))
    end
end

-- Clean up when resource stops
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if isGirlFollowing and DoesEntityExist(followingPed) then
            DeleteEntity(followingPed)
        end
        followingPed = nil
        followingGirl = nil
        isGirlFollowing = false
    end
end)

-- Debug commands
RegisterCommand('testfollow', function(source, args)
    if PlayerData and PlayerData.girls and #PlayerData.girls > 0 then
        local girlIndex = tonumber(args[1]) or 1
        local girl = PlayerData.girls[girlIndex]
        if girl then
            print("^3[Client] Testing follow for: " .. girl.name .. "^7")
            ToggleGirlFollow(girl)
        else
            print("^1[Client] Girl not found at index " .. girlIndex .. "^7")
        end
    else
        print("^1[Client] No girls available to test^7")
    end
end, false)

RegisterCommand('stopfollow', function()
    if isGirlFollowing then
        DespawnFollowingGirl()
    else
        print("^1[Client] No girl is currently following^7")
    end
end, false)

RegisterCommand('followstatus', function()
    print("^3=== FOLLOW STATUS DEBUG ===^7")
    print("^3isGirlFollowing: " .. tostring(isGirlFollowing) .. "^7")
    print("^3followingPed exists: " .. tostring(DoesEntityExist(followingPed or 0)) .. "^7")
    if followingGirl then
        print("^3followingGirl: " .. followingGirl.name .. " (ID: " .. followingGirl.id .. ")^7")
    else
        print("^3followingGirl: none^7")
    end
    print("^3============================^7")
end, false)

RegisterCommand('clientdata', function()
    print("^3=== CLIENT DATA DEBUG ===^7")
    print("^3PlayerData exists: " .. tostring(PlayerData ~= nil) .. "^7")
    if PlayerData then
        print("^3PlayerData.girls exists: " .. tostring(PlayerData.girls ~= nil) .. "^7")
        if PlayerData.girls then
            print("^3PlayerData.girls count: " .. #PlayerData.girls .. "^7")
            for i, girl in ipairs(PlayerData.girls) do
                print("^3  " .. i .. ". " .. girl.name .. " (" .. girl.type .. ") - ID: " .. (girl.id or "unknown") .. "^7")
            end
        end
    end
    print("^3activeGirls count: " .. activeGirlsCount .. "^7")
    print("^3followingGirl: " .. tostring(followingGirl ~= nil) .. "^7")
    if followingGirl then
        print("^3  Following: " .. followingGirl.name .. " (ID: " .. followingGirl.id .. ")^7")
    end
    print("^3========================^7")
end, false)

RegisterCommand('refreshdata', function()
    print("^3[Client] Manually requesting fresh data^7")
    TriggerServerEvent('pimp:getPlayerGirls')
end, false)

-- Add cooldown functions
function AddCooldown(name, duration)
    ActiveCooldowns[name] = {
        startTime = GetGameTimer(),
        duration = duration
    }
end

function CheckCooldown(name)
    if not ActiveCooldowns[name] then
        return false
    end
    
    local currentTime = GetGameTimer()
    local cooldown = ActiveCooldowns[name]
    
    if currentTime - cooldown.startTime >= cooldown.duration then
        ActiveCooldowns[name] = nil
        return false
    end
    
    return true
end

function GetCooldownRemaining(name)
    if not ActiveCooldowns[name] then
        return 0
    end
    
    local currentTime = GetGameTimer()
    local cooldown = ActiveCooldowns[name]
    
    local remaining = cooldown.duration - (currentTime - cooldown.startTime)
    
    if remaining < 0 then
        ActiveCooldowns[name] = nil
        return 0
    end
    
    return remaining
end