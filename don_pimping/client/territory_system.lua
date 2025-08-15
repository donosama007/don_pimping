-- Pimp Management System - Territory System (Client)
-- Created by NinjaTech AI
-- Integrated with main.lua

-- Local variables
-- Silence F8 console unless debugging is explicitly enabled in Config
local print = function(...)
    if Config and Config.Debug then
        _G.print(...)
    end
end

local territories = {}
local playerTerritories = {}
local discoveredTerritories = {}
local contestedTerritories = {}
local territoryBlips = {}
local territoryMarkers = {}
local activeContests = {}
local territoryData = {}
local currentTerritoryWaypoint = nil
local territoryDealerPed = nil
local territoryDealerBlip = nil
local workingGirlPeds = {}
local workingGirlBlips = {}
local customerPeds = {}
local customerQueues = {}

-- Territory system initialization
Citizen.CreateThread(function()
    Citizen.Wait(2000) -- Wait for everything to load
    
    -- Request initial territory data
    TriggerServerEvent('pimp:requestTerritories')
    
    -- Start territory update loop
    Citizen.CreateThread(function()
        while true do
            UpdateTerritoryMarkers()
            Citizen.Wait(1000) -- Update every second
        end
    end)
end)

-- Update territory markers
function UpdateTerritoryMarkers()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    
    -- Check if player is near any territories
    for name, territory in pairs(territories) do
        if territory.x and territory.y and territory.z then
            local territoryCoords = vector3(territory.x, territory.y, territory.z)
            local distance = #(playerCoords - territoryCoords)
            
            -- Show marker if within range
            if distance < 50.0 then
                local isOwned = playerTerritories[name] ~= nil
                local color = isOwned and {r = 0, g = 255, b = 0, a = 100} or {r = 255, g = 0, b = 0, a = 100}
                
                -- Draw marker
                DrawMarker(1, territory.x, territory.y, territory.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 
                          5.0, 5.0, 1.0, color.r, color.g, color.b, color.a, false, true, 2, nil, nil, false)
                
                -- Show interaction text if close enough
                if distance < 3.0 then
                    local text = isOwned and "~g~[E] Manage Territory" or "~r~[E] Claim Territory"
                    DrawText3D(territory.x, territory.y, territory.z + 1.0, text)
                    
                    -- Handle interaction
                    if IsControlJustPressed(0, 38) then -- E key
                        HandleTerritoryInteraction(name, territory, isOwned)
                    end
                end
            end
        end
    end
end

-- Handle territory interaction
function HandleTerritoryInteraction(name, territory, isOwned)
    if isOwned then
        OpenOwnedTerritoryInteractionMenu(name, territory)
    else
        OpenUnownedTerritoryInteractionMenu(name, territory)
    end
end

-- Open owned territory interaction menu
function OpenOwnedTerritoryInteractionMenu(name, territory)
    local playerTerritory = playerTerritories[name]
    local control = playerTerritory and playerTerritory.control or 0
    
    local options = {
        {
            title = 'Territory Status',
            description = 'Control: ' .. math.floor(control) .. '%',
            icon = 'info-circle',
            metadata = {
                {label = 'Name', value = territory.label or name},
                {label = 'Control', value = math.floor(control) .. '%'},
                {label = 'Status', value = 'Owned'}
            }
        },
        {
            title = 'Manage Girls',
            description = 'Assign girls to work in this territory',
            icon = 'female',
            onSelect = function()
                OpenTerritoryGirlManagementMenu(name, territory)
            end
        },
        {
            title = 'Upgrade Territory',
            description = 'Improve territory capabilities',
            icon = 'arrow-up',
            onSelect = function()
                OpenTerritoryUpgradeMenu(name, territory)
            end
        },
        {
            title = 'Collect Earnings',
            description = 'Collect passive income from territory',
            icon = 'money-bill-wave',
            onSelect = function()
                TriggerServerEvent('pimp:collectTerritoryEarnings', name)
                ShowNotification('Collecting earnings from ' .. (territory.label or name), 'info')
            end
        },
        {
            title = 'Territory Defense',
            description = 'Defend territory from rivals',
            icon = 'shield-alt',
            onSelect = function()
                StartTerritoryDefense(name, territory)
            end
        }
    }
    
    if lib and lib.registerContext then
        lib.registerContext({
            id = 'pimp_territory_interaction_owned_' .. name,
            title = territory.label or name,
            options = options
        })
        
        lib.showContext('pimp_territory_interaction_owned_' .. name)
    end
end

-- Open unowned territory interaction menu
function OpenUnownedTerritoryInteractionMenu(name, territory)
    local options = {
        {
            title = 'Territory Info',
            description = 'View information about this territory',
            icon = 'info-circle',
            metadata = {
                {label = 'Name', value = territory.label or name},
                {label = 'Status', value = 'Available'},
                {label = 'Risk Level', value = territory.riskLevel or 'Unknown'}
            }
        },
        {
            title = 'Claim Territory',
            description = 'Attempt to claim this territory',
            icon = 'flag',
            onSelect = function()
                TriggerServerEvent('pimp:claimTerritory', name)
                ShowNotification('Attempting to claim ' .. (territory.label or name), 'info')
            end
        },
        {
            title = 'Scout Territory',
            description = 'Gather information about this territory',
            icon = 'eye',
            onSelect = function()
                ScoutTerritory(name, territory)
            end
        }
    }
    
    -- Check if territory is owned by someone else
    local isOwnedByOther = false
    for owner, territories in pairs(territoryData) do
        if territories[name] then
            isOwnedByOther = true
            break
        end
    end
    
    if isOwnedByOther then
        table.insert(options, {
            title = 'Contest Territory',
            description = 'Challenge the current owner',
            icon = 'fist-raised',
            onSelect = function()
                TriggerServerEvent('pimp:contestTerritory', name)
                ShowNotification('Starting territory contest for ' .. (territory.label or name), 'warning')
            end
        })
    end
    
    if lib and lib.registerContext then
        lib.registerContext({
            id = 'pimp_territory_interaction_unowned_' .. name,
            title = territory.label or name,
            options = options
        })
        
        lib.showContext('pimp_territory_interaction_unowned_' .. name)
    end
end

-- Open territory girl management menu
function OpenTerritoryGirlManagementMenu(territoryName, territory)
    local options = {}
    
    -- Get girls assigned to this territory
    local assignedGirls = GetGirlsInTerritory(territoryName)
    
    -- Show assigned girls
    for _, girl in ipairs(assignedGirls) do
        table.insert(options, {
            title = girl.name,
            description = 'Status: ' .. (girl.status or 'Working'),
            icon = 'female',
            metadata = {
                {label = 'Earnings', value = '$' .. (girl.territoryEarnings or 0) .. '/hr'},
                {label = 'Happiness', value = (girl.happiness or 50) .. '%'},
                {label = 'Safety', value = (girl.safety or 100) .. '%'}
            },
            onSelect = function()
                OpenTerritoryGirlMenu(territoryName, girl)
            end
        })
    end
    
    -- Check if max girls reached
    local maxGirls = Config.TerritorySystem.maxGirlsPerTerritory or 3
    local canAddMore = #assignedGirls < maxGirls
    
    -- Add option to assign new girl
    table.insert(options, {
        title = 'Assign New Girl',
        description = canAddMore 
            and 'Assign a girl to work in this territory' 
            or 'Maximum number of girls reached (' .. maxGirls .. ')',
        icon = 'plus',
        disabled = not canAddMore,
        onSelect = function()
            OpenAssignGirlToTerritoryMenu(territoryName)
        end
    })
    
    -- Add menu ID based on context
    local menuId = 'pimp_territory_interaction_owned_' .. territoryName
    if currentMenuId == 'pimp_single_territory_management_' .. territoryName then
        menuId = 'pimp_single_territory_management_' .. territoryName
    end
    
    if lib and lib.registerContext then
        lib.registerContext({
            id = 'pimp_territory_girl_management_' .. territoryName,
            title = (territory.label or territoryName) .. ' - Girl Management',
            menu = menuId,
            options = options
        })
        
        lib.showContext('pimp_territory_girl_management_' .. territoryName)
    end
end

-- Open assign girl to territory menu
function OpenAssignGirlToTerritoryMenu(territoryName)
    local options = {}
    
    -- Get available girls (not assigned to any territory)
    local availableGirls = GetAvailableGirls()
    
    for _, girl in ipairs(availableGirls) do
        table.insert(options, {
            title = girl.name,
            description = 'Type: ' .. (girl.type or 'Unknown') .. ' | Status: ' .. (girl.status or 'idle'),
            icon = 'female',
            metadata = {
                {label = 'Happiness', value = (girl.happiness or 50) .. '%'},
                {label = 'Loyalty', value = (girl.loyalty or (girl.attributes and girl.attributes.loyalty) or 50) .. '%'},
                {label = 'Experience', value = (girl.experience or 0) .. '%'}
            },
            onSelect = function()
                TriggerServerEvent('pimp:assignGirlToTerritory', girl.id, territoryName)
                ShowNotification(girl.name .. ' assigned to territory', 'success')
            end
        })
    end
    
    if #options == 0 then
        table.insert(options, {
            title = 'No Available Girls',
            description = 'All girls are either working or assigned to other territories',
            icon = 'times-circle',
            disabled = true
        })
    end
    
    if lib and lib.registerContext then
        lib.registerContext({
            id = 'pimp_assign_girl_territory_' .. territoryName,
            title = 'Assign Girl to Territory',
            menu = 'pimp_territory_girl_management_' .. territoryName,
            options = options
        })
        
        lib.showContext('pimp_assign_girl_territory_' .. territoryName)
    end
end

-- Open territory girl menu
function OpenTerritoryGirlMenu(territoryName, girl)
    local options = {
        {
            title = 'Girl Status',
            description = girl.name .. ' - ' .. (girl.status or 'Working'),
            icon = 'info-circle',
            metadata = {
                {label = 'Name', value = girl.name},
                {label = 'Status', value = girl.status or 'Working'},
                {label = 'Earnings', value = '$' .. (girl.territoryEarnings or 0) .. '/hr'},
                {label = 'Happiness', value = (girl.happiness or 50) .. '%'},
                {label = 'Safety', value = (girl.safety or 100) .. '%'}
            }
        },
        {
            title = 'Check on Girl',
            description = 'Visit ' .. girl.name .. ' in person',
            icon = 'eye',
            onSelect = function()
                CheckOnGirlInTerritory(girl, territoryName)
            end
        },
        {
            title = 'Recall Girl',
            description = 'Stop ' .. girl.name .. ' from working and recall her',
            icon = 'arrow-circle-left',
            onSelect = function()
                TriggerServerEvent('pimp:recallGirlFromTerritory', girl.id, territoryName)
                ShowNotification('Recalling ' .. girl.name .. ' from territory', 'info')
            end
        },
        {
            title = 'Discipline',
            description = 'Discipline ' .. girl.name,
            icon = 'hand-paper',
            onSelect = function()
                OpenDisciplineMenu(girl.id, girl)
            end
        },
        {
            title = 'Boost Security',
            description = 'Temporarily increase security for ' .. girl.name,
            icon = 'shield-alt',
            onSelect = function()
                TriggerServerEvent('pimp:boostGirlSecurity', girl.id, territoryName)
                ShowNotification('Security boosted for ' .. girl.name, 'success')
            end
        }
    }
    
    if lib and lib.registerContext then
        lib.registerContext({
            id = 'pimp_territory_girl_' .. territoryName .. '_' .. girl.id,
            title = girl.name,
            menu = 'pimp_territory_girl_management_' .. territoryName,
            options = options
        })
        
        lib.showContext('pimp_territory_girl_' .. territoryName .. '_' .. girl.id)
    end
end

-- Open territory upgrade menu
function OpenTerritoryUpgradeMenu(territoryName, territory)
    local options = {
        {
            title = 'Security Upgrade',
            description = 'Improve territory security to protect your girls',
            icon = 'shield-alt',
            onSelect = function()
                TriggerServerEvent('pimp:upgradeTerritory', territoryName, 'security')
                ShowNotification('Upgrading security for ' .. (territory.label or territoryName), 'info')
            end
        },
        {
            title = 'Earnings Upgrade',
            description = 'Increase passive income from this territory',
            icon = 'dollar-sign',
            onSelect = function()
                TriggerServerEvent('pimp:upgradeTerritory', territoryName, 'earnings')
                ShowNotification('Upgrading earnings for ' .. (territory.label or territoryName), 'info')
            end
        },
        {
            title = 'Capacity Upgrade',
            description = 'Allow more girls to work in this territory',
            icon = 'users',
            onSelect = function()
                TriggerServerEvent('pimp:upgradeTerritory', territoryName, 'capacity')
                ShowNotification('Upgrading capacity for ' .. (territory.label or territoryName), 'info')
            end
        },
        {
            title = 'Defense Upgrade',
            description = 'Better defend against rival attacks',
            icon = 'fist-raised',
            onSelect = function()
                TriggerServerEvent('pimp:upgradeTerritory', territoryName, 'defense')
                ShowNotification('Upgrading defense for ' .. (territory.label or territoryName), 'info')
            end
        }
    }
    
    if lib and lib.registerContext then
        lib.registerContext({
            id = 'pimp_territory_upgrade_' .. territoryName,
            title = (territory.label or territoryName) .. ' - Upgrades',
            menu = 'pimp_territory_interaction_owned_' .. territoryName,
            options = options
        })
        
        lib.showContext('pimp_territory_upgrade_' .. territoryName)
    end
end

-- Scout territory
function ScoutTerritory(territoryName, territory)
    ShowNotification('Scouting ' .. (territory.label or territoryName) .. '...', 'info')
    
    -- Add scouting animation
    local playerPed = PlayerPedId()
    TaskStartScenarioInPlace(playerPed, "WORLD_HUMAN_BINOCULARS", 0, true)
    
    -- Simulate scouting time
    Citizen.SetTimeout(5000, function()
        ClearPedTasksImmediately(playerPed)
        
        -- Generate random intel
        local intel = {
            security = math.random(1, 5),
            earnings = math.random(100, 500),
            riskLevel = {'Low', 'Medium', 'High'}[math.random(1, 3)],
            girlCount = math.random(0, 3)
        }
        
        -- Show intel results
        ShowScoutingResults(territoryName, territory, intel)
    end)
end

-- Show scouting results
function ShowScoutingResults(territoryName, territory, intel)
    local options = {
        {
            title = 'Scouting Report',
            description = 'Intelligence gathered on ' .. (territory.label or territoryName),
            icon = 'clipboard-list',
            metadata = {
                {label = 'Security Level', value = intel.security .. '/5'},
                {label = 'Estimated Earnings', value = '$' .. intel.earnings .. '/hr'},
                {label = 'Risk Level', value = intel.riskLevel},
                {label = 'Girls Working', value = intel.girlCount}
            }
        },
        {
            title = 'Plan Attack',
            description = 'Use this intel to plan a territory takeover',
            icon = 'crosshairs',
            onSelect = function()
                PlanTerritoryAttack(territoryName, territory, intel)
            end
        }
    }
    
    if lib and lib.registerContext then
        lib.registerContext({
            id = 'pimp_scouting_results_' .. territoryName,
            title = 'Scouting Results',
            options = options
        })
        
        lib.showContext('pimp_scouting_results_' .. territoryName)
    end
end

-- Plan territory attack
function PlanTerritoryAttack(territoryName, territory, intel)
    local options = {
        {
            title = 'Direct Assault',
            description = 'High risk, high reward frontal attack',
            icon = 'fist-raised',
            onSelect = function()
                TriggerServerEvent('pimp:contestTerritory', territoryName)
                ShowNotification('Starting direct assault on ' .. (territory.label or territoryName), 'warning')
            end
        },
        {
            title = 'Stealth Takeover',
            description = 'Lower risk, gradual control gain',
            icon = 'user-ninja',
            onSelect = function()
                TriggerServerEvent('pimp:stealthTakeover', territoryName)
                ShowNotification('Beginning stealth takeover of ' .. (territory.label or territoryName), 'info')
            end
        },
        {
            title = 'Economic Warfare',
            description = 'Undercut prices to force out competition',
            icon = 'chart-line-down',
            onSelect = function()
                TriggerServerEvent('pimp:economicWarfare', territoryName)
                ShowNotification('Starting economic warfare for ' .. (territory.label or territoryName), 'info')
            end
        }
    }
    
    if lib and lib.registerContext then
        lib.registerContext({
            id = 'pimp_attack_plan_' .. territoryName,
            title = 'Attack Planning',
            menu = 'pimp_scouting_results_' .. territoryName,
            options = options
        })
        
        lib.showContext('pimp_attack_plan_' .. territoryName)
    end
end

-- Start territory defense
function StartTerritoryDefense(territoryName, territory)
    ShowNotification('Defending ' .. (territory.label or territoryName) .. '...', 'warning')
    
    -- Trigger defense event
    TriggerServerEvent('pimp:defendTerritory', territoryName)
    
    -- Add defense scenario
    local playerPed = PlayerPedId()
    TaskStartScenarioInPlace(playerPed, "WORLD_HUMAN_GUARD_STAND", 0, true)
    
    Citizen.SetTimeout(10000, function()
        ClearPedTasksImmediately(playerPed)
        ShowNotification('Territory defense complete', 'success')
    end)
end

-- Check on girl in territory
function CheckOnGirlInTerritory(girl, territoryName)
    -- Set waypoint to territory
    if territories[territoryName] then
        local territory = territories[territoryName]
        SetNewWaypoint(territory.x, territory.y)
        ShowNotification('Waypoint set to ' .. girl.name .. '\'s location in ' .. territoryName, 'info')
    end
    
    TriggerServerEvent('pimp:checkOnGirlInTerritory', girl.id, territoryName)
end

-- Get girls in territory
function GetGirlsInTerritory(territoryName)
    local girlsInTerritory = {}
    
    if PlayerData and PlayerData.girls then
        for _, girl in ipairs(PlayerData.girls) do
            if girl.territoryAssignment == territoryName or girl.workLocation == territoryName then
                table.insert(girlsInTerritory, girl)
            end
        end
    end
    
    return girlsInTerritory
end

-- Get available girls
function GetAvailableGirls()
    local availableGirls = {}
    
    if PlayerData and PlayerData.girls then
        for _, girl in ipairs(PlayerData.girls) do
            if not girl.territoryAssignment and (girl.status == 'idle' or not girl.status) then
                table.insert(availableGirls, girl)
            end
        end
    end
    
    return availableGirls
end

-- Draw 3D text
function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x, _y)
    
    local factor = (string.len(text)) / 370
    DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 41, 11, 41, 68)
end

-- Show notification (uses main.lua function if available, fallback otherwise)
function ShowNotification(message, type)
    if _G.ShowNotification then
        _G.ShowNotification(message, type)
    elseif lib and lib.notify then
        lib.notify({
            title = 'Territory System',
            description = message,
            type = type or 'info'
        })
    else
        SetNotificationTextEntry('STRING')
        AddTextComponentString(message)
        DrawNotification(false, false)
    end
end

-- Event handlers
RegisterNetEvent('pimp:receiveTerritories')
AddEventHandler('pimp:receiveTerritories', function(allTerritories, playerOwnedTerritories, upgrades)
    print("^2[Territory] Received territories data^7")
    
    territories = allTerritories or {}
    playerTerritories = playerOwnedTerritories or {}
    
    -- Update blips
    UpdateTerritoryBlips()
    
    print("^2[Territory] Loaded " .. CountTable(territories) .. " territories, " .. CountTable(playerTerritories) .. " owned^7")
end)

RegisterNetEvent('pimp:territoryDiscovered')
AddEventHandler('pimp:territoryDiscovered', function(territoryName)
    if territories[territoryName] then
        ShowNotification('New territory discovered: ' .. (territories[territoryName].label or territoryName), 'success')
        UpdateTerritoryBlips()
    end
end)

RegisterNetEvent('pimp:territoryClaimed')
AddEventHandler('pimp:territoryClaimed', function(territoryName, territoryData)
    ShowNotification('Successfully claimed ' .. (territoryData.label or territoryName) .. '!', 'success')
    
    -- Update local data
    playerTerritories[territoryName] = {
        control = 100,
        lastUpdated = os.date("%Y-%m-%d %H:%M:%S")
    }
    
    UpdateTerritoryBlips()
end)

RegisterNetEvent('pimp:territoryContestStarted')
AddEventHandler('pimp:territoryContestStarted', function(territoryName, role, duration)
    local message = role == 'challenger' and 'You started a contest for ' or 'Your territory is being contested: '
    ShowNotification(message .. territoryName, 'warning')
    
    -- Store contest info
    activeContests[territoryName] = {
        role = role,
        endTime = GetGameTimer() + (duration * 60 * 1000)
    }
end)

RegisterNetEvent('pimp:territoryContestEnded')
AddEventHandler('pimp:territoryContestEnded', function(territoryName, result)
    local message = result == 'won' and 'You won the contest for ' or 'You lost the contest for '
    ShowNotification(message .. territoryName, result == 'won' and 'success' or 'error')
    
    -- Clear contest info
    activeContests[territoryName] = nil
    
    -- Request updated territory data
    TriggerServerEvent('pimp:requestTerritories')
end)

RegisterNetEvent('pimp:territoryUpgraded')
AddEventHandler('pimp:territoryUpgraded', function(territoryName, upgradeType, level)
    ShowNotification('Upgraded ' .. upgradeType .. ' to level ' .. level .. ' for ' .. territoryName, 'success')
end)

-- Remove territory dealer
RegisterNetEvent('pimp:removeTerritoryDealer')
AddEventHandler('pimp:removeTerritoryDealer', function()
    -- Remove dealer ped
    if territoryDealerPed and DoesEntityExist(territoryDealerPed) then
        DeleteEntity(territoryDealerPed)
        territoryDealerPed = nil
    end
    
    -- Remove dealer blip
    if territoryDealerBlip then
        RemoveBlip(territoryDealerBlip)
        territoryDealerBlip = nil
    end
    
    -- Remove waypoint
    if currentTerritoryWaypoint then
        RemoveBlip(currentTerritoryWaypoint)
        currentTerritoryWaypoint = nil
    end
end)

-- Update territory blips
function UpdateTerritoryBlips()
    -- Remove existing blips
    for _, blip in pairs(territoryBlips) do
        RemoveBlip(blip)
    end
    territoryBlips = {}
    
    -- Create new blips
    for name, territory in pairs(territories) do
        if territory.x and territory.y and territory.z then
            local blip = AddBlipForCoord(territory.x, territory.y, territory.z)
            
            local isOwned = playerTerritories[name] ~= nil
            local isContested = activeContests[name] ~= nil
            
            if isOwned then
                SetBlipSprite(blip, 84) -- Owned territory
                SetBlipColour(blip, 2) -- Green
            elseif isContested then
                SetBlipSprite(blip, 84) -- Contested territory
                SetBlipColour(blip, 6) -- Yellow
            else
                SetBlipSprite(blip, 84) -- Available territory
                SetBlipColour(blip, 1) -- Red
            end
            
            SetBlipScale(blip, 0.8)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(territory.label or name)
            EndTextCommandSetBlipName(blip)
            
            territoryBlips[name] = blip
        end
    end
end

-- Find random available territory
function FindRandomTerritory()
    local availableTerritories = {}
    
    -- Get all territories that are not owned by the player
    for name, territory in pairs(territories) do
        if not playerTerritories[name] then
            table.insert(availableTerritories, {name = name, territory = territory})
        end
    end
    
    -- Check if there are any available territories
    if #availableTerritories == 0 then
        ShowNotification('No available territories found', 'error')
        return false
    end
    
    -- Select a random territory
    local randomIndex = math.random(#availableTerritories)
    local selectedTerritory = availableTerritories[randomIndex]
    
    -- Clear previous waypoint and dealer if exists
    if currentTerritoryWaypoint then
        RemoveBlip(currentTerritoryWaypoint)
        currentTerritoryWaypoint = nil
    end
    
    if territoryDealerPed and DoesEntityExist(territoryDealerPed) then
        DeleteEntity(territoryDealerPed)
        territoryDealerPed = nil
    end
    
    if territoryDealerBlip then
        RemoveBlip(territoryDealerBlip)
        territoryDealerBlip = nil
    end
    
    -- Create waypoint
    currentTerritoryWaypoint = AddBlipForCoord(selectedTerritory.territory.x, selectedTerritory.territory.y, selectedTerritory.territory.z)
    SetBlipSprite(currentTerritoryWaypoint, 162) -- Different sprite for territory waypoint
    SetBlipColour(currentTerritoryWaypoint, 5) -- Purple
    SetBlipScale(currentTerritoryWaypoint, 1.0)
    SetBlipAsShortRange(currentTerritoryWaypoint, false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Available Territory")
    EndTextCommandSetBlipName(currentTerritoryWaypoint)
    SetBlipRoute(currentTerritoryWaypoint, true)
    
    -- Spawn territory dealer NPC
    SpawnTerritoryDealer(selectedTerritory.name, selectedTerritory.territory)
    
    -- Show notification
    ShowNotification('Territory found! Go to the marked location to claim it', 'success')
    
    -- Store the territory location data
    TriggerServerEvent('pimp:setTerritoryWaypoint', selectedTerritory.name)
    
    return true
end

-- Spawn territory dealer NPC
function SpawnTerritoryDealer(territoryName, territory)
    -- Create a thread to spawn the dealer when player gets close
    Citizen.CreateThread(function()
        -- Wait until player is close to the territory
        local dealerSpawned = false
        
        while not dealerSpawned do
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local territoryCoords = vector3(territory.x, territory.y, territory.z)
            local distance = #(playerCoords - territoryCoords)
            
            -- When player is close enough, spawn the dealer
            if distance < 100.0 then
                -- Choose a random male ped model
                local dealerModels = {
                    "s_m_m_bouncer_01",
                    "s_m_m_ciasec_01",
                    "s_m_m_highsec_01",
                    "s_m_m_highsec_02",
                    "s_m_m_marine_01",
                    "s_m_m_marine_02",
                    "s_m_m_security_01",
                    "s_m_y_dealer_01"
                }
                
                local dealerModel = dealerModels[math.random(#dealerModels)]
                local modelHash = GetHashKey(dealerModel)
                
                -- Request model
                RequestModel(modelHash)
                while not HasModelLoaded(modelHash) do
                    Citizen.Wait(10)
                end
                
                -- Create the dealer ped
                territoryDealerPed = CreatePed(4, modelHash, territory.x, territory.y, territory.z, 0.0, false, true)
                FreezeEntityPosition(territoryDealerPed, true)
                SetEntityInvincible(territoryDealerPed, true)
                SetBlockingOfNonTemporaryEvents(territoryDealerPed, true)
                
                -- Add blip for the dealer
                territoryDealerBlip = AddBlipForEntity(territoryDealerPed)
                SetBlipSprite(territoryDealerBlip, 280)
                SetBlipColour(territoryDealerBlip, 5) -- Purple
                SetBlipScale(territoryDealerBlip, 0.8)
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString("Territory Dealer")
                EndTextCommandSetBlipName(territoryDealerBlip)
                
                -- Make dealer targetable with third-eye
                exports['qb-target']:AddTargetEntity(territoryDealerPed, {
                    options = {
                        {
                            type = "client",
                            event = "pimp:openTerritoryDealerMenu",
                            icon = "fas fa-map-marker",
                            label = "Talk to Territory Dealer",
                            territoryName = territoryName,
                            territory = territory
                        }
                    },
                    distance = 2.5
                })
                
                dealerSpawned = true
            end
            
            Citizen.Wait(1000)
        end
    end)
end

-- Open territory dealer menu
RegisterNetEvent('pimp:openTerritoryDealerMenu')
AddEventHandler('pimp:openTerritoryDealerMenu', function(data)
    local territoryName = data.territoryName
    local territory = data.territory
    
    -- Get territory price from config
    local territoryPrice = Config.TerritorySystem.territoryPrice or 25000
    
    -- Create menu options
    local options = {
        {
            title = 'Territory Information',
            description = 'View details about this territory',
            icon = 'info-circle',
            metadata = {
                {label = 'Name', value = territory.label or territoryName},
                {label = 'Type', value = territory.type or 'Standard'},
                {label = 'Risk Level', value = territory.risk_level or 'Medium'},
                {label = 'Price', value = '$' .. territoryPrice}
            }
        },
        {
            title = 'Purchase Territory',
            description = 'Buy this territory for $' .. territoryPrice,
            icon = 'dollar-sign',
            onSelect = function()
                TriggerServerEvent('pimp:purchaseTerritory', territoryName, territoryPrice)
            end
        },
        {
            title = 'Cancel',
            description = 'Leave without purchasing',
            icon = 'times',
            onSelect = function()
                ShowNotification('You decided not to purchase the territory', 'info')
            end
        }
    }
    
    -- Show menu
    if lib and lib.registerContext then
        lib.registerContext({
            id = 'pimp_territory_dealer_menu',
            title = 'Territory Dealer',
            options = options
        })
        
        lib.showContext('pimp_territory_dealer_menu')
    end
end)

-- Open territory management menu
function OpenTerritoryManagementMenu()
    local options = {}
    local ownedTerritoriesCount = 0
    
    -- Add owned territories
    for name, territory in pairs(playerTerritories) do
        ownedTerritoriesCount = ownedTerritoriesCount + 1
        
        -- Get territory data
        local territoryData = territories[name] or {label = name}
        
        -- Calculate upkeep status
        local upkeepStatus = "Paid"
        local upkeepColor = "^2" -- Green
        
        if territory.contested then
            upkeepStatus = "CONTESTED"
            upkeepColor = "^1" -- Red
        elseif not territory.upkeepPaid then
            upkeepStatus = "Payment Due"
            upkeepColor = "^3" -- Yellow
        end
        
        -- Format next upkeep date
        local nextUpkeep = "Unknown"
        if territory.nextUpkeep then
            local year, month, day = string.match(territory.nextUpkeep, "(%d+)-(%d+)-(%d+)")
            if year and month and day then
                nextUpkeep = day .. "/" .. month .. "/" .. year
            end
        end
        
        -- Get working girls count
        local girlsWorking = GetGirlsInTerritory(name)
        
        -- Add territory option
        table.insert(options, {
            title = territoryData.label or name,
            description = "Control: " .. math.floor(territory.control or 0) .. "% | Upkeep: " .. upkeepColor .. upkeepStatus .. "^7",
            icon = territory.contested and 'exclamation-triangle' or 'map-marker-alt',
            metadata = {
                {label = 'Status', value = territory.contested and "CONTESTED" or "Active"},
                {label = 'Control', value = math.floor(territory.control or 0) .. "%"},
                {label = 'Upkeep Due', value = nextUpkeep},
                {label = 'Girls Working', value = #girlsWorking .. "/" .. Config.TerritorySystem.maxGirlsPerTerritory}
            },
            onSelect = function()
                OpenSingleTerritoryManagementMenu(name, territoryData, territory)
            end
        })
    end
    
    -- Add "Find Territory" option if no territories owned
    if ownedTerritoriesCount == 0 then
        table.insert(options, {
            title = 'No Territories Owned',
            description = 'You don\'t own any territories yet',
            icon = 'info-circle',
            disabled = true
        })
    end
    
    -- Add "Find Territory" option
    table.insert(options, {
        title = 'Find Territory',
        description = 'Search for a new territory to claim',
        icon = 'search',
        onSelect = function()
            FindRandomTerritory()
        end
    })
    
    -- Register and show context menu
    if lib and lib.registerContext then
        lib.registerContext({
            id = 'pimp_territory_management',
            title = 'Territory Management',
            options = options
        })
        
        lib.showContext('pimp_territory_management')
    end
end

-- Open single territory management menu
function OpenSingleTerritoryManagementMenu(territoryName, territoryData, territoryStatus)
    local options = {}
    
    -- Territory info
    table.insert(options, {
        title = 'Territory Information',
        description = 'View details about this territory',
        icon = 'info-circle',
        metadata = {
            {label = 'Name', value = territoryData.label or territoryName},
            {label = 'Type', value = territoryData.type or 'Standard'},
            {label = 'Risk Level', value = territoryData.risk_level or 'Medium'},
            {label = 'Control', value = math.floor(territoryStatus.control or 0) .. "%"},
            {label = 'Earnings Multiplier', value = territoryData.earnings_multiplier or 1.0}
        }
    })
    
    -- Upkeep status and payment
    local upkeepStatus = "Paid"
    local upkeepColor = "^2" -- Green
    
    if territoryStatus.contested then
        upkeepStatus = "CONTESTED"
        upkeepColor = "^1" -- Red
    elseif not territoryStatus.upkeepPaid then
        upkeepStatus = "Payment Due"
        upkeepColor = "^3" -- Yellow
    end
    
    table.insert(options, {
        title = 'Upkeep Status: ' .. upkeepColor .. upkeepStatus .. "^7",
        description = 'Pay upkeep to maintain control of this territory',
        icon = territoryStatus.contested and 'exclamation-triangle' or 'money-bill',
        onSelect = function()
            TriggerServerEvent('pimp:payTerritoryUpkeep', territoryName)
        end
    })
    
    -- Girl management
    table.insert(options, {
        title = 'Girl Management',
        description = 'Manage girls working in this territory',
        icon = 'female',
        onSelect = function()
            OpenTerritoryGirlManagementMenu(territoryName, territoryData)
        end
    })
    
    -- Collect earnings
    table.insert(options, {
        title = 'Collect Earnings',
        description = 'Collect earnings from this territory',
        icon = 'hand-holding-usd',
        onSelect = function()
            TriggerServerEvent('pimp:collectTerritoryEarnings', territoryName)
        end
    })
    
    -- Upgrades
    table.insert(options, {
        title = 'Upgrades',
        description = 'Upgrade this territory',
        icon = 'arrow-up',
        onSelect = function()
            OpenTerritoryUpgradeMenu(territoryName, territoryData)
        end
    })
    
    -- Set waypoint
    table.insert(options, {
        title = 'Set Waypoint',
        description = 'Set a waypoint to this territory',
        icon = 'map-marker',
        onSelect = function()
            SetNewWaypoint(territoryData.x, territoryData.y)
            ShowNotification('Waypoint set to ' .. (territoryData.label or territoryName), 'info')
        end
    })
    
    -- Register and show context menu
    if lib and lib.registerContext then
        lib.registerContext({
            id = 'pimp_single_territory_management_' .. territoryName,
            title = territoryData.label or territoryName,
            menu = 'pimp_territory_management',
            options = options
        })
        
        lib.showContext('pimp_single_territory_management_' .. territoryName)
    end
end

-- Spawn working girl in territory
RegisterNetEvent('pimp:spawnWorkingGirl')
AddEventHandler('pimp:spawnWorkingGirl', function(girlId, girlName, territoryName, x, y, z)
    -- Check if territory exists
    if not territories[territoryName] then return end
    
    -- Check if girl is already spawned
    if workingGirlPeds[girlId] and DoesEntityExist(workingGirlPeds[girlId]) then
        DeleteEntity(workingGirlPeds[girlId])
        workingGirlPeds[girlId] = nil
    end
    
    -- Remove blip if exists
    if workingGirlBlips[girlId] then
        RemoveBlip(workingGirlBlips[girlId])
        workingGirlBlips[girlId] = nil
    end
    
    -- Create a thread to spawn the girl when player gets close
    Citizen.CreateThread(function()
        -- Wait until player is close to the territory
        local girlSpawned = false
        
        while not girlSpawned do
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local girlCoords = vector3(x, y, z)
            local distance = #(playerCoords - girlCoords)
            
            -- When player is close enough, spawn the girl
            if distance < 100.0 then
                -- Choose a random female model
                local girlModels = Config.GirlModels or {
                    "a_f_y_beach_01",
                    "a_f_y_bevhills_01",
                    "a_f_y_bevhills_02",
                    "a_f_y_business_01",
                    "a_f_y_business_02",
                    "a_f_y_clubcust_01",
                    "a_f_y_eastsa_01",
                    "a_f_y_fitness_01",
                    "a_f_y_genhot_01",
                    "s_f_y_stripper_01",
                    "s_f_y_stripper_02",
                    "csb_stripper_01",
                    "csb_stripper_02"
                }
                
                local girlModel = girlModels[math.random(#girlModels)]
                local modelHash = GetHashKey(girlModel)
                
                -- Request model
                RequestModel(modelHash)
                while not HasModelLoaded(modelHash) do
                    Citizen.Wait(10)
                end
                
                -- Create the girl ped
                workingGirlPeds[girlId] = CreatePed(4, modelHash, x, y, z, 0.0, false, true)
                
                -- Set ped properties
                SetEntityAsMissionEntity(workingGirlPeds[girlId], true, true)
                SetBlockingOfNonTemporaryEvents(workingGirlPeds[girlId], true)
                
                -- Add blip for the girl
                workingGirlBlips[girlId] = AddBlipForEntity(workingGirlPeds[girlId])
                SetBlipSprite(workingGirlBlips[girlId], 280)
                SetBlipColour(workingGirlBlips[girlId], 3) -- Yellow
                SetBlipScale(workingGirlBlips[girlId], 0.6)
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString(girlName .. " (Working)")
                EndTextCommandSetBlipName(workingGirlBlips[girlId])
                
                -- Start girl working animation
                StartGirlWorkingAnimation(workingGirlPeds[girlId])
                
                -- Initialize customer queue for this girl
                customerQueues[girlId] = {}
                
                -- Start customer spawning thread for this girl
                StartCustomerSpawning(girlId, x, y, z)
                
                girlSpawned = true
            end
            
            Citizen.Wait(1000)
        end
    end)
end)

-- Remove working girl from territory
RegisterNetEvent('pimp:removeWorkingGirl')
AddEventHandler('pimp:removeWorkingGirl', function(girlId, territoryName)
    -- Check if girl is spawned
    if workingGirlPeds[girlId] and DoesEntityExist(workingGirlPeds[girlId]) then
        DeleteEntity(workingGirlPeds[girlId])
        workingGirlPeds[girlId] = nil
    end
    
    -- Remove blip if exists
    if workingGirlBlips[girlId] then
        RemoveBlip(workingGirlBlips[girlId])
        workingGirlBlips[girlId] = nil
    end
    
    -- Remove all customers for this girl
    if customerQueues[girlId] then
        for _, customerId in ipairs(customerQueues[girlId]) do
            if customerPeds[customerId] and DoesEntityExist(customerPeds[customerId]) then
                DeleteEntity(customerPeds[customerId])
                customerPeds[customerId] = nil
            end
        end
        customerQueues[girlId] = nil
    end
end)

-- Start girl working animation
function StartGirlWorkingAnimation(girlPed)
    if not DoesEntityExist(girlPed) then return end
    
    -- List of idle animations
    local animations = {
        {dict = "mini@strip_club@idles@stripper", anim = "stripper_idle_01"},
        {dict = "mini@strip_club@idles@stripper", anim = "stripper_idle_02"},
        {dict = "mini@strip_club@idles@stripper", anim = "stripper_idle_03"},
        {dict = "amb@world_human_prostitute@cokehead@idle_a", anim = "idle_a"},
        {dict = "amb@world_human_prostitute@cokehead@idle_a", anim = "idle_b"},
        {dict = "amb@world_human_prostitute@cokehead@idle_a", anim = "idle_c"},
        {dict = "amb@world_human_prostitute@french@idle_a", anim = "idle_a"},
        {dict = "amb@world_human_prostitute@french@idle_a", anim = "idle_b"},
        {dict = "amb@world_human_prostitute@french@idle_a", anim = "idle_c"}
    }
    
    -- Choose random animation
    local anim = animations[math.random(#animations)]
    
    -- Load animation dictionary
    RequestAnimDict(anim.dict)
    while not HasAnimDictLoaded(anim.dict) do
        Citizen.Wait(10)
    end
    
    -- Play animation
    TaskPlayAnim(girlPed, anim.dict, anim.anim, 8.0, -8.0, -1, 1, 0, false, false, false)
end

-- Start customer spawning for a girl
function StartCustomerSpawning(girlId, x, y, z)
    Citizen.CreateThread(function()
        while workingGirlPeds[girlId] and DoesEntityExist(workingGirlPeds[girlId]) do
            -- Check if player is nearby
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local girlCoords = vector3(x, y, z)
            local distance = #(playerCoords - girlCoords)
            
            -- Only spawn customers if player is nearby
            if distance < 100.0 then
                -- Check if we should spawn a new customer (30-60 seconds interval)
                if #(customerQueues[girlId] or {}) < 3 then -- Max 3 customers in queue
                    -- Random chance to spawn customer
                    if math.random() < 0.5 then -- 50% chance every check
                        SpawnCustomer(girlId, x, y, z)
                    end
                end
            end
            
            -- Wait 30-60 seconds before next check
            Citizen.Wait(math.random(30000, 60000))
        end
    end)
end

-- Spawn a customer for a girl
function SpawnCustomer(girlId, x, y, z)
    -- Check if girl still exists
    if not workingGirlPeds[girlId] or not DoesEntityExist(workingGirlPeds[girlId]) then
        return
    end
    
    -- Choose a random male model
    local customerModels = Config.ClientModels or {
        "a_m_m_business_01",
        "a_m_m_bevhills_01",
        "a_m_m_bevhills_02",
        "a_m_m_eastsa_01",
        "a_m_m_eastsa_02",
        "a_m_m_farmer_01",
        "a_m_m_fatlatin_01",
        "a_m_m_genfat_01",
        "a_m_m_genfat_02",
        "a_m_m_golfer_01",
        "a_m_m_hasjew_01",
        "a_m_m_hillbilly_01",
        "a_m_m_hillbilly_02",
        "a_m_m_indian_01",
        "a_m_m_ktown_01",
        "a_m_m_malibu_01",
        "a_m_m_mexcntry_01",
        "a_m_m_mexlabor_01",
        "a_m_m_og_boss_01",
        "a_m_m_paparazzi_01",
        "a_m_m_polynesian_01",
        "a_m_m_prolhost_01",
        "a_m_m_rurmeth_01",
        "a_m_m_salton_01",
        "a_m_m_salton_02",
        "a_m_m_salton_03",
        "a_m_m_salton_04",
        "a_m_m_skater_01",
        "a_m_m_skidrow_01",
        "a_m_m_socenlat_01",
        "a_m_m_soucent_01",
        "a_m_m_soucent_02",
        "a_m_m_soucent_03",
        "a_m_m_soucent_04",
        "a_m_m_stlat_02",
        "a_m_m_tennis_01",
        "a_m_m_tourist_01",
        "a_m_m_tramp_01",
        "a_m_m_trampbeac_01"
    }
    
    local customerModel = customerModels[math.random(#customerModels)]
    local modelHash = GetHashKey(customerModel)
    
    -- Request model
    RequestModel(modelHash)
    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 5000 do
        Citizen.Wait(10)
        timeout = timeout + 10
    end
    
    if not HasModelLoaded(modelHash) then
        return
    end
    
    -- Calculate spawn position (50-100 meters away from girl)
    local angle = math.random() * 2 * math.pi
    local distance = math.random(50, 100) / 1.0
    local spawnX = x + math.cos(angle) * distance
    local spawnY = y + math.sin(angle) * distance
    local spawnZ = z
    
    -- Create the customer ped
    local customerId = "customer_" .. girlId .. "_" .. math.random(1000000)
    customerPeds[customerId] = CreatePed(4, modelHash, spawnX, spawnY, spawnZ, 0.0, false, true)
    
    -- Set ped properties
    SetEntityAsMissionEntity(customerPeds[customerId], true, true)
    SetBlockingOfNonTemporaryEvents(customerPeds[customerId], true)
    
    -- Add to queue
    if not customerQueues[girlId] then
        customerQueues[girlId] = {}
    end
    table.insert(customerQueues[girlId], customerId)
    
    -- Start customer behavior
    StartCustomerBehavior(customerId, girlId, x, y, z)
end

-- Start customer behavior
function StartCustomerBehavior(customerId, girlId, x, y, z)
    Citizen.CreateThread(function()
        -- Check if customer and girl exist
        if not customerPeds[customerId] or not DoesEntityExist(customerPeds[customerId]) then
            return
        end
        
        if not workingGirlPeds[girlId] or not DoesEntityExist(workingGirlPeds[girlId]) then
            -- Girl doesn't exist anymore, delete customer
            DeleteEntity(customerPeds[customerId])
            customerPeds[customerId] = nil
            return
        end
        
        -- Get customer position in queue
        local queuePosition = 0
        for i, id in ipairs(customerQueues[girlId]) do
            if id == customerId then
                queuePosition = i
                break
            end
        end
        
        -- If not first in queue, wait
        while queuePosition > 1 do
            -- Check if customer and girl still exist
            if not customerPeds[customerId] or not DoesEntityExist(customerPeds[customerId]) then
                return
            end
            
            if not workingGirlPeds[girlId] or not DoesEntityExist(workingGirlPeds[girlId]) then
                -- Girl doesn't exist anymore, delete customer
                DeleteEntity(customerPeds[customerId])
                customerPeds[customerId] = nil
                return
            end
            
            -- Update queue position
            queuePosition = 0
            for i, id in ipairs(customerQueues[girlId]) do
                if id == customerId then
                    queuePosition = i
                    break
                end
            end
            
            -- Wait a bit
            Citizen.Wait(1000)
        end
        
        -- Now it's this customer's turn
        -- Walk to girl
        local girlCoords = GetEntityCoords(workingGirlPeds[girlId])
        TaskGoToCoordAnyMeans(customerPeds[customerId], girlCoords.x, girlCoords.y, girlCoords.z, 1.0, 0, false, 786603, 0)
        
        -- Wait until customer reaches girl
        local reachedGirl = false
        local timeout = 0
        while not reachedGirl and timeout < 60 do
            -- Check if customer and girl still exist
            if not customerPeds[customerId] or not DoesEntityExist(customerPeds[customerId]) then
                return
            end
            
            if not workingGirlPeds[girlId] or not DoesEntityExist(workingGirlPeds[girlId]) then
                -- Girl doesn't exist anymore, delete customer
                DeleteEntity(customerPeds[customerId])
                customerPeds[customerId] = nil
                return
            end
            
            -- Check distance
            local customerCoords = GetEntityCoords(customerPeds[customerId])
            girlCoords = GetEntityCoords(workingGirlPeds[girlId])
            local distance = #(customerCoords - girlCoords)
            
            if distance < 2.0 then
                reachedGirl = true
            end
            
            timeout = timeout + 1
            Citizen.Wait(1000)
        end
        
        -- If reached girl, perform service
        if reachedGirl then
            -- Face each other
            TaskTurnPedToFaceEntity(customerPeds[customerId], workingGirlPeds[girlId], 2000)
            TaskTurnPedToFaceEntity(workingGirlPeds[girlId], customerPeds[customerId], 2000)
            Citizen.Wait(2000)
            
            -- Play service animation
            PlayServiceAnimation(customerPeds[customerId], workingGirlPeds[girlId])
            
            -- Wait for service to complete (10-15 seconds)
            Citizen.Wait(math.random(10000, 15000))
            
            -- Generate earnings after 15 seconds
            Citizen.SetTimeout(15000, function()
                -- Generate earnings
                TriggerServerEvent('pimp:generateTerritoryEarnings', girlId)
            end)
            
            -- Walk away
            local angle = math.random() * 2 * math.pi
            local distance = math.random(50, 100) / 1.0
            local walkX = x + math.cos(angle) * distance
            local walkY = y + math.sin(angle) * distance
            TaskGoToCoordAnyMeans(customerPeds[customerId], walkX, walkY, z, 1.0, 0, false, 786603, 0)
            
            -- Wait until customer walks away
            local walkedAway = false
            timeout = 0
            while not walkedAway and timeout < 60 do
                -- Check if customer still exists
                if not customerPeds[customerId] or not DoesEntityExist(customerPeds[customerId]) then
                    return
                end
                
                -- Check distance
                local customerCoords = GetEntityCoords(customerPeds[customerId])
                girlCoords = vector3(x, y, z)
                local distance = #(customerCoords - girlCoords)
                
                if distance > 50.0 then
                    walkedAway = true
                end
                
                timeout = timeout + 1
                Citizen.Wait(1000)
            end
        end
        
        -- Remove from queue
        for i, id in ipairs(customerQueues[girlId]) do
            if id == customerId then
                table.remove(customerQueues[girlId], i)
                break
            end
        end
        
        -- Delete customer
        DeleteEntity(customerPeds[customerId])
        customerPeds[customerId] = nil
    end)
end

-- Play service animation
function PlayServiceAnimation(customerPed, girlPed)
    if not DoesEntityExist(customerPed) or not DoesEntityExist(girlPed) then
        return
    end
    
    -- List of service animations
    local animations = {
        {
            customer = {dict = "mini@prostitutes@sexlow_veh", anim = "low_car_bj_to_prop_female"},
            girl = {dict = "mini@prostitutes@sexlow_veh", anim = "low_car_bj_to_prop_male"}
        },
        {
            customer = {dict = "mini@strip_club@private_dance@part1", anim = "priv_dance_p1"},
            girl = {dict = "mini@strip_club@private_dance@part1", anim = "priv_dance_p1"}
        },
        {
            customer = {dict = "mini@strip_club@lap_dance@ld_girl_a_song_a_p1", anim = "ld_girl_a_song_a_p1_f"},
            girl = {dict = "mini@strip_club@lap_dance@ld_girl_a_song_a_p1", anim = "ld_girl_a_song_a_p1_m"}
        }
    }
    
    -- Choose random animation
    local anim = animations[math.random(#animations)]
    
    -- Load animation dictionaries
    RequestAnimDict(anim.customer.dict)
    RequestAnimDict(anim.girl.dict)
    
    while not HasAnimDictLoaded(anim.customer.dict) or not HasAnimDictLoaded(anim.girl.dict) do
        Citizen.Wait(10)
    end
    
    -- Play animations
    TaskPlayAnim(customerPed, anim.customer.dict, anim.customer.anim, 8.0, -8.0, -1, 1, 0, false, false, false)
    TaskPlayAnim(girlPed, anim.girl.dict, anim.girl.anim, 8.0, -8.0, -1, 1, 0, false, false, false)
end

-- Debug commands
RegisterCommand('territories', function()
    print("^3=== TERRITORY DEBUG ===^7")
    print("^3Total territories: " .. CountTable(territories) .. "^7")
    print("^3Owned territories: " .. CountTable(playerTerritories) .. "^7")
    print("^3Active contests: " .. CountTable(activeContests) .. "^7")
    print("^3Working girls: " .. CountTable(workingGirlPeds) .. "^7")
    print("^3Customers: " .. CountTable(customerPeds) .. "^7")
    
    for name, territory in pairs(territories) do
        local isOwned = playerTerritories[name] ~= nil
        print("^3  " .. name .. " - " .. (territory.label or "No Label") .. " (" .. (isOwned and "OWNED" or "AVAILABLE") .. ")^7")
    end
    print("^3=====================^7")
end, false)

-- Open territory management command
RegisterCommand('myterritories', function()
    OpenTerritoryManagementMenu()
end, false)

-- Utility function to count table entries
function CountTable(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

-- Export functions for integration with main.lua
exports('GetTerritories', function() return territories end)
exports('GetPlayerTerritories', function() return playerTerritories end)
exports('GetActiveContests', function() return activeContests end)
exports('UpdateTerritoryBlips', UpdateTerritoryBlips)
exports('FindRandomTerritory', FindRandomTerritory)