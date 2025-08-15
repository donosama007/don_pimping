-- Pimp Management System - Territory System
-- Created by Donald Draper
-- Enhanced by NinjaTech AI

-- Local variables
local Territories = {}
local PlayerTerritories = {}
local TerritoryUpgrades = {}
local DiscoveredTerritories = {}
local ActiveRaids = {}

-- Initialize territory system
function InitializeTerritorySystem()
    -- Load territory definitions
    MySQL.query('SELECT * FROM pimp_territory_definitions', {}, function(result)
        if result and #result > 0 then
            for _, territory in ipairs(result) do
                Territories[territory.name] = territory
            end
            print("^2Loaded " .. #result .. " territory definitions^7")
        else
            print("^1No territory definitions found in database^7")
        end
    end)
    
    -- Load territory ownership data
    MySQL.query('SELECT * FROM pimp_territory', {}, function(result)
        if result and #result > 0 then
            for _, territory in ipairs(result) do
                if not PlayerTerritories[territory.owner] then
                    PlayerTerritories[territory.owner] = {}
                end
                
                PlayerTerritories[territory.owner][territory.location] = {
                    control = territory.control,
                    lastUpdated = territory.last_updated,
                    lastUpkeep = territory.last_upkeep or territory.last_updated,
                    nextUpkeep = territory.next_upkeep,
                    upkeepPaid = territory.upkeep_paid == 1,
                    contested = territory.contested == 1
                }
            end
            print("^2Loaded " .. #result .. " territory ownership records^7")
        end
    end)
    
    -- Load territory upgrades
    MySQL.query('SELECT * FROM pimp_territory_upgrades', {}, function(result)
        if result and #result > 0 then
            for _, upgrade in ipairs(result) do
                if not TerritoryUpgrades[upgrade.owner] then
                    TerritoryUpgrades[upgrade.owner] = {}
                end
                
                if not TerritoryUpgrades[upgrade.owner][upgrade.territory_name] then
                    TerritoryUpgrades[upgrade.owner][upgrade.territory_name] = {}
                end
                
                TerritoryUpgrades[upgrade.owner][upgrade.territory_name][upgrade.upgrade_type] = upgrade.level
            end
            print("^2Loaded " .. #result .. " territory upgrades^7")
        end
    end)
    
    -- Load discovered territories
    MySQL.query('SELECT * FROM pimp_territory_discovered', {}, function(result)
        if result and #result > 0 then
            for _, discovery in ipairs(result) do
                if not DiscoveredTerritories[discovery.owner] then
                    DiscoveredTerritories[discovery.owner] = {}
                end
                
                DiscoveredTerritories[discovery.owner][discovery.territory_name] = true
            end
            print("^2Loaded " .. #result .. " territory discovery records^7")
        end
    end)
    
    -- Start territory raid check timer
    if Config.TerritorySystem.raids.enabled then
        Citizen.CreateThread(function()
            while true do
                CheckForNPCRaids()
                Citizen.Wait(60 * 60 * 1000) -- Check every hour
            end
        end)
    end
    
    -- Start territory upkeep check timer
    if Config.TerritorySystem.upkeepEnabled then
        Citizen.CreateThread(function()
            -- Wait a bit for everything to initialize
            Citizen.Wait(10000)
            
            -- Check upkeep every hour
            while true do
                CheckTerritoryUpkeep()
                Citizen.Wait(60 * 60 * 1000) -- Check every hour
            end
        end)
    end
    
    -- Alter the territory table if needed to add upkeep columns
    MySQL.query([[
        ALTER TABLE pimp_territory 
        ADD COLUMN IF NOT EXISTS last_upkeep DATETIME DEFAULT CURRENT_TIMESTAMP,
        ADD COLUMN IF NOT EXISTS next_upkeep DATETIME DEFAULT NULL,
        ADD COLUMN IF NOT EXISTS upkeep_paid TINYINT(1) DEFAULT 1,
        ADD COLUMN IF NOT EXISTS contested TINYINT(1) DEFAULT 0
    ]])
end

-- Get all territories
function GetAllTerritories()
    return Territories
end

-- Get player territories
function GetPlayerTerritories(identifier)
    return PlayerTerritories[identifier] or {}
end

-- Get discovered territories for a player
function GetDiscoveredTerritories(identifier)
    local discovered = DiscoveredTerritories[identifier] or {}
    local result = {}
    
    -- Add all territories that are discovered by default
    for name, territory in pairs(Territories) do
        if territory.is_discovered == 1 then
            result[name] = true
        end
    end
    
    -- Add player-specific discoveries
    for name, _ in pairs(discovered) do
        result[name] = true
    end
    
    return result
end

-- Check if player has discovered a territory
function HasDiscoveredTerritory(identifier, territoryName)
    -- Check if territory exists
    if not Territories[territoryName] then
        return false
    end
    
    -- Check if territory is discovered by default
    if Territories[territoryName].is_discovered == 1 then
        return true
    end
    
    -- Check player-specific discoveries
    if DiscoveredTerritories[identifier] and DiscoveredTerritories[identifier][territoryName] then
        return true
    end
    
    return false
end

-- Discover a territory
function DiscoverTerritory(identifier, territoryName)
    -- Check if territory exists
    if not Territories[territoryName] then
        return false, "Territory does not exist"
    end
    
    -- Check if already discovered
    if HasDiscoveredTerritory(identifier, territoryName) then
        return false, "Territory already discovered"
    end
    
    -- Add to discovered territories
    if not DiscoveredTerritories[identifier] then
        DiscoveredTerritories[identifier] = {}
    end
    
    DiscoveredTerritories[identifier][territoryName] = true
    
    -- Save to database
    MySQL.insert('INSERT INTO pimp_territory_discovered (owner, territory_name) VALUES (?, ?)',
        {identifier, territoryName}, function(insertId)
        if insertId > 0 then
            -- Log discovery
            LogTerritoryEvent(territoryName, "discovery", "Territory discovered by " .. GetPlayerName(identifier), identifier)
        end
    end)
    
    return true, "Territory discovered"
end

-- Discover random territories
function DiscoverRandomTerritories(identifier, count, includeVIP)
    local undiscoveredTerritories = {}
    
    -- Get all undiscovered territories
    for name, territory in pairs(Territories) do
        if not HasDiscoveredTerritory(identifier, name) then
            -- Filter VIP territories if not included
            if includeVIP or territory.is_vip == 0 then
                table.insert(undiscoveredTerritories, name)
            end
        end
    end
    
    -- Shuffle the territories
    for i = #undiscoveredTerritories, 2, -1 do
        local j = math.random(i)
        undiscoveredTerritories[i], undiscoveredTerritories[j] = undiscoveredTerritories[j], undiscoveredTerritories[i]
    end
    
    -- Discover up to count territories
    local discovered = {}
    for i = 1, math.min(count, #undiscoveredTerritories) do
        local territoryName = undiscoveredTerritories[i]
        local success, message = DiscoverTerritory(identifier, territoryName)
        
        if success then
            table.insert(discovered, territoryName)
        end
    end
    
    return discovered
end

-- Claim a territory
function ClaimTerritory(identifier, territoryName)
    -- Check if territory exists
    if not Territories[territoryName] then
        return false, "Territory does not exist"
    end
    
    -- Check if player has discovered the territory
    if not HasDiscoveredTerritory(identifier, territoryName) then
        return false, "Territory not discovered yet"
    end
    
    -- Check if territory is already claimed by this player
    if PlayerTerritories[identifier] and PlayerTerritories[identifier][territoryName] then
        return false, "You already control this territory"
    end
    
    -- Check if territory is claimed by another player
    local isClaimedByOther = false
    local currentOwner = nil
    
    for owner, territories in pairs(PlayerTerritories) do
        if territories[territoryName] and territories[territoryName].control > 0 then
            isClaimedByOther = true
            currentOwner = owner
            break
        end
    end
    
    -- If claimed by another player, start contest
    if isClaimedByOther then
        return StartTerritoryContest(identifier, currentOwner, territoryName)
    end
    
    -- Otherwise, claim the territory
    if not PlayerTerritories[identifier] then
        PlayerTerritories[identifier] = {}
    end
    
    PlayerTerritories[identifier][territoryName] = {
        control = 100.0, -- Full control
        lastUpdated = os.date("%Y-%m-%d %H:%M:%S")
    }
    
    -- Save to database
    MySQL.insert('INSERT INTO pimp_territory (owner, location, control) VALUES (?, ?, ?)',
        {identifier, territoryName, 100.0}, function(insertId)
        if insertId > 0 then
            -- Log claim
            LogTerritoryEvent(territoryName, "claim", "Territory claimed by " .. GetPlayerName(identifier), identifier)
            
            -- Notify player
            local source = GetPlayerSource(identifier)
            if source then
                TriggerClientEvent('pimp:notification', source, "Territory Claimed", "You've successfully claimed " .. Territories[territoryName].label, "success")
                TriggerClientEvent('pimp:territoryClaimed', source, territoryName, Territories[territoryName])
            end
        end
    end)
    
    return true, "Territory claimed successfully"
end

-- Start a territory contest
function StartTerritoryContest(challenger, defender, territoryName)
    -- Check if territory exists
    if not Territories[territoryName] then
        return false, "Territory does not exist"
    end
    
    -- Check if there's an active contest for this territory
    if ActiveRaids[territoryName] then
        return false, "There's already an active contest for this territory"
    end
    
    -- Check cooldown
    local cooldownKey = "territory_contest_" .. territoryName
    if IsOnCooldown(challenger, cooldownKey) then
        local remainingTime = GetCooldownRemaining(challenger, cooldownKey)
        return false, "You must wait " .. FormatTime(remainingTime) .. " before contesting this territory again"
    end
    
    -- Create contest data
    ActiveRaids[territoryName] = {
        challenger = challenger,
        defender = defender,
        startTime = os.time(),
        endTime = os.time() + (Config.TerritorySystem.contestDuration * 60),
        territoryName = territoryName,
        challengerScore = 0,
        defenderScore = 0,
        status = "active"
    }
    
    -- Set cooldown
    SetCooldown(challenger, cooldownKey, Config.TerritorySystem.contestCooldown * 60)
    
    -- Notify players
    local challengerSource = GetPlayerSource(challenger)
    local defenderSource = GetPlayerSource(defender)
    
    if challengerSource then
        TriggerClientEvent('pimp:notification', challengerSource, "Territory Contest Started", "You've started a contest for " .. Territories[territoryName].label, "info")
        TriggerClientEvent('pimp:territoryContestStarted', challengerSource, territoryName, "challenger", Config.TerritorySystem.contestDuration)
    end
    
    if defenderSource then
        TriggerClientEvent('pimp:notification', defenderSource, "Territory Under Attack", "Your territory " .. Territories[territoryName].label .. " is being contested!", "warning")
        TriggerClientEvent('pimp:territoryContestStarted', defenderSource, territoryName, "defender", Config.TerritorySystem.contestDuration)
    end
    
    -- Log contest start
    LogTerritoryEvent(territoryName, "contest_start", "Territory contest started by " .. GetPlayerName(challenger) .. " against " .. GetPlayerName(defender), challenger, defender)
    
    -- Start contest timer
    Citizen.CreateThread(function()
        Citizen.Wait(Config.TerritorySystem.contestDuration * 60 * 1000)
        EndTerritoryContest(territoryName)
    end)
    
    return true, "Territory contest started"
end

-- End a territory contest
function EndTerritoryContest(territoryName)
    -- Check if contest exists
    if not ActiveRaids[territoryName] then
        return false, "No active contest for this territory"
    end
    
    local contest = ActiveRaids[territoryName]
    local winner = nil
    local loser = nil
    
    -- Determine winner
    if contest.challengerScore > contest.defenderScore then
        winner = contest.challenger
        loser = contest.defender
    else
        winner = contest.defender
        loser = contest.challenger
    end
    
    -- Update territory ownership
    if winner == contest.challenger then
        -- Challenger wins, transfer territory
        if not PlayerTerritories[winner] then
            PlayerTerritories[winner] = {}
        end
        
        -- Set control to 50% initially
        PlayerTerritories[winner][territoryName] = {
            control = 50.0,
            lastUpdated = os.date("%Y-%m-%d %H:%M:%S")
        }
        
        -- Remove from defender
        if PlayerTerritories[loser] then
            PlayerTerritories[loser][territoryName] = nil
        end
        
        -- Update database
        MySQL.update('DELETE FROM pimp_territory WHERE owner = ? AND location = ?', 
            {loser, territoryName}, function()
            MySQL.insert('INSERT INTO pimp_territory (owner, location, control) VALUES (?, ?, ?)',
                {winner, territoryName, 50.0})
        end)
    else
        -- Defender wins, reduce control by 10%
        if PlayerTerritories[winner][territoryName] then
            local currentControl = PlayerTerritories[winner][territoryName].control
            PlayerTerritories[winner][territoryName].control = math.max(10.0, currentControl - 10.0)
            PlayerTerritories[winner][territoryName].lastUpdated = os.date("%Y-%m-%d %H:%M:%S")
            
            -- Update database
            MySQL.update('UPDATE pimp_territory SET control = ?, last_updated = CURRENT_TIMESTAMP WHERE owner = ? AND location = ?',
                {PlayerTerritories[winner][territoryName].control, winner, territoryName})
        end
    end
    
    -- Notify players
    local winnerSource = GetPlayerSource(winner)
    local loserSource = GetPlayerSource(loser)
    
    if winnerSource then
        TriggerClientEvent('pimp:notification', winnerSource, "Territory Contest Won", "You've won the contest for " .. Territories[territoryName].label, "success")
        TriggerClientEvent('pimp:territoryContestEnded', winnerSource, territoryName, "won")
    end
    
    if loserSource then
        TriggerClientEvent('pimp:notification', loserSource, "Territory Contest Lost", "You've lost the contest for " .. Territories[territoryName].label, "error")
        TriggerClientEvent('pimp:territoryContestEnded', loserSource, territoryName, "lost")
    end
    
    -- Log contest end
    LogTerritoryEvent(territoryName, "contest_end", "Territory contest won by " .. GetPlayerName(winner) .. " against " .. GetPlayerName(loser), winner, loser)
    
    -- Clear contest data
    ActiveRaids[territoryName] = nil
    
    return true, "Territory contest ended"
end

-- Contribute to territory contest
function ContributeToContest(identifier, territoryName, amount)
    -- Check if contest exists
    if not ActiveRaids[territoryName] then
        return false, "No active contest for this territory"
    end
    
    local contest = ActiveRaids[territoryName]
    
    -- Check if player is involved in contest
    if identifier ~= contest.challenger and identifier ~= contest.defender then
        return false, "You are not involved in this contest"
    end
    
    -- Add score
    if identifier == contest.challenger then
        contest.challengerScore = contest.challengerScore + amount
    else
        contest.defenderScore = contest.defenderScore + amount
    end
    
    return true, "Contributed to contest"
end

-- Upgrade territory
function UpgradeTerritory(identifier, territoryName, upgradeType)
    -- Check if territory exists
    if not Territories[territoryName] then
        return false, "Territory does not exist"
    end
    
    -- Check if player controls the territory
    if not PlayerTerritories[identifier] or not PlayerTerritories[identifier][territoryName] then
        return false, "You don't control this territory"
    end
    
    -- Check if upgrade type exists
    if not Config.TerritorySystem.upgrades[upgradeType] then
        return false, "Invalid upgrade type"
    end
    
    -- Get current upgrade level
    local currentLevel = 0
    if TerritoryUpgrades[identifier] and TerritoryUpgrades[identifier][territoryName] and TerritoryUpgrades[identifier][territoryName][upgradeType] then
        currentLevel = TerritoryUpgrades[identifier][territoryName][upgradeType]
    end
    
    -- Check if max level reached
    if currentLevel >= #Config.TerritorySystem.upgrades[upgradeType] then
        return false, "Maximum upgrade level reached"
    end
    
    -- Get next upgrade
    local nextUpgrade = Config.TerritorySystem.upgrades[upgradeType][currentLevel + 1]
    
    -- Check if player can afford upgrade
    local playerMoney = GetPlayerMoney(identifier)
    if playerMoney < nextUpgrade.cost then
        return false, "You can't afford this upgrade"
    end
    
    -- Deduct money
    if not RemovePlayerMoney(identifier, nextUpgrade.cost) then
        return false, "Failed to deduct money"
    end
    
    -- Apply upgrade
    if not TerritoryUpgrades[identifier] then
        TerritoryUpgrades[identifier] = {}
    end
    
    if not TerritoryUpgrades[identifier][territoryName] then
        TerritoryUpgrades[identifier][territoryName] = {}
    end
    
    TerritoryUpgrades[identifier][territoryName][upgradeType] = currentLevel + 1
    
    -- Save to database
    MySQL.query('SELECT id FROM pimp_territory_upgrades WHERE owner = ? AND territory_name = ? AND upgrade_type = ?',
        {identifier, territoryName, upgradeType}, function(result)
        if result and #result > 0 then
            -- Update existing
            MySQL.update('UPDATE pimp_territory_upgrades SET level = ? WHERE id = ?',
                {currentLevel + 1, result[1].id})
        else
            -- Insert new
            MySQL.insert('INSERT INTO pimp_territory_upgrades (owner, territory_name, upgrade_type, level) VALUES (?, ?, ?, ?)',
                {identifier, territoryName, upgradeType, currentLevel + 1})
        end
    end)
    
    -- Notify player
    local source = GetPlayerSource(identifier)
    if source then
        TriggerClientEvent('pimp:notification', source, "Territory Upgraded", "You've upgraded " .. upgradeType .. " to level " .. (currentLevel + 1), "success")
        TriggerClientEvent('pimp:territoryUpgraded', source, territoryName, upgradeType, currentLevel + 1)
    end
    
    -- Log upgrade
    LogTerritoryEvent(territoryName, "upgrade", "Territory " .. upgradeType .. " upgraded to level " .. (currentLevel + 1) .. " by " .. GetPlayerName(identifier), identifier)
    
    return true, "Territory upgraded successfully"
end

-- Get territory upgrade level
function GetTerritoryUpgradeLevel(identifier, territoryName, upgradeType)
    if not TerritoryUpgrades[identifier] or not TerritoryUpgrades[identifier][territoryName] or not TerritoryUpgrades[identifier][territoryName][upgradeType] then
        return 0
    end
    
    return TerritoryUpgrades[identifier][territoryName][upgradeType]
end

-- Get territory upgrade effect
function GetTerritoryUpgradeEffect(identifier, territoryName, effectType)
    local totalEffect = 0
    
    -- Check if player controls the territory
    if not PlayerTerritories[identifier] or not PlayerTerritories[identifier][territoryName] then
        return 0
    end
    
    -- Check each upgrade type
    for upgradeType, upgrades in pairs(Config.TerritorySystem.upgrades) do
        local level = GetTerritoryUpgradeLevel(identifier, territoryName, upgradeType)
        
        if level > 0 and level <= #upgrades then
            local upgrade = upgrades[level]
            
            -- Check if this upgrade has the requested effect
            if upgrade.effect and upgrade.effect[effectType] then
                if type(upgrade.effect[effectType]) == "number" then
                    totalEffect = totalEffect + upgrade.effect[effectType]
                elseif upgrade.effect[effectType] == true then
                    return true -- For boolean effects
                end
            end
        end
    end
    
    return totalEffect
end

-- Check for NPC raids
function CheckForNPCRaids()
    if not Config.TerritorySystem.raids.enabled then
        return
    end
    
    -- Check each player's territories
    for identifier, territories in pairs(PlayerTerritories) do
        for territoryName, data in pairs(territories) do
            -- Check if territory is eligible for raid
            local cooldownKey = "npc_raid_" .. territoryName
            if not IsOnCooldown(identifier, cooldownKey) and math.random() < Config.TerritorySystem.raids.npcRaidChance then
                -- Start NPC raid
                StartNPCRaid(identifier, territoryName)
                
                -- Set cooldown
                SetCooldown(identifier, cooldownKey, Config.TerritorySystem.raids.npcRaidCooldown * 60 * 60)
            end
        end
    end
end

-- Start NPC raid
function StartNPCRaid(identifier, territoryName)
    -- Check if territory exists
    if not Territories[territoryName] then
        return false
    end
    
    -- Check if player controls the territory
    if not PlayerTerritories[identifier] or not PlayerTerritories[identifier][territoryName] then
        return false
    end
    
    -- Calculate defense chance
    local securityLevel = GetTerritoryUpgradeEffect(identifier, territoryName, "security_boost") or 0
    local attackResistance = GetTerritoryUpgradeEffect(identifier, territoryName, "attack_resistance") or 0
    
    local defenseChance = Config.TerritorySystem.raids.defenseSuccessBaseChance +
                         (securityLevel * Config.TerritorySystem.raids.securityImpact) +
                         attackResistance
    
    -- Cap at 90% max
    defenseChance = math.min(0.9, defenseChance)
    
    -- Determine outcome
    local defenseSuccessful = math.random() < defenseChance
    
    -- Notify player
    local source = GetPlayerSource(identifier)
    if source then
        TriggerClientEvent('pimp:notification', source, "Territory Under Attack", "Your territory " .. Territories[territoryName].label .. " is being raided by local gangs!", "warning")
        
        -- Wait for raid duration
        Citizen.SetTimeout(30000, function()
            if defenseSuccessful then
                TriggerClientEvent('pimp:notification', source, "Raid Defended", "Your security successfully defended " .. Territories[territoryName].label .. " from raiders!", "success")
            else
                -- Apply consequences
                ApplyRaidConsequences(identifier, territoryName)
                
                TriggerClientEvent('pimp:notification', source, "Raid Failed", "Your security failed to defend " .. Territories[territoryName].label .. " from raiders!", "error")
            end
        end)
    end
    
    -- Log raid
    LogTerritoryEvent(territoryName, "npc_raid", "NPC raid on territory " .. (defenseSuccessful and "defended" or "successful"), identifier)
    
    return true
end

-- Check territory upkeep
function CheckTerritoryUpkeep()
    local currentTime = os.time()
    local currentDate = os.date("%Y-%m-%d %H:%M:%S", currentTime)
    
    -- Check each player's territories
    for identifier, territories in pairs(PlayerTerritories) do
        for territoryName, data in pairs(territories) do
            -- Skip if territory is already contested
            if data.contested then
                goto continue
            end
            
            -- Calculate next upkeep date if not set
            if not data.nextUpkeep then
                -- Set next upkeep date to current time + upkeep interval
                local nextUpkeepTime = currentTime + (Config.TerritorySystem.upkeepInterval * 24 * 60 * 60)
                local nextUpkeepDate = os.date("%Y-%m-%d %H:%M:%S", nextUpkeepTime)
                
                -- Update territory data
                PlayerTerritories[identifier][territoryName].nextUpkeep = nextUpkeepDate
                
                -- Update database
                MySQL.update('UPDATE pimp_territory SET next_upkeep = ? WHERE owner = ? AND location = ?',
                    {nextUpkeepDate, identifier, territoryName})
                
                goto continue
            end
            
            -- Convert nextUpkeep string to timestamp
            local nextUpkeepTime = 0
            local year, month, day, hour, min, sec = string.match(data.nextUpkeep, "(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)")
            if year and month and day and hour and min and sec then
                local nextUpkeepDate = os.time({year=year, month=month, day=day, hour=hour, min=min, sec=sec})
                nextUpkeepTime = nextUpkeepDate
            end
            
            -- Check if upkeep is due soon (within notification time)
            local upkeepDueSoon = (nextUpkeepTime - currentTime) <= (Config.TerritorySystem.upkeepNotificationTime * 60 * 60)
            
            -- Check if upkeep is overdue
            local upkeepOverdue = nextUpkeepTime <= currentTime
            
            -- Send notification if upkeep is due soon and not paid
            if upkeepDueSoon and not data.upkeepPaid then
                local source = GetPlayerSource(identifier)
                if source then
                    local timeLeft = math.floor((nextUpkeepTime - currentTime) / 3600)
                    local territoryLabel = Territories[territoryName] and Territories[territoryName].label or territoryName
                    
                    TriggerClientEvent('pimp:notification', source, "Territory Upkeep Due", 
                        "Upkeep for " .. territoryLabel .. " is due in " .. timeLeft .. " hours. Pay $" .. 
                        Config.TerritorySystem.upkeepCost .. " to maintain control.", "warning")
                end
            end
            
            -- If upkeep is overdue and not paid, mark as contested after grace period
            if upkeepOverdue and not data.upkeepPaid then
                -- Calculate how many days overdue
                local daysOverdue = math.floor((currentTime - nextUpkeepTime) / (24 * 60 * 60))
                
                -- If past grace period, mark as contested
                if daysOverdue >= Config.TerritorySystem.upkeepGracePeriod then
                    -- Mark territory as contested
                    PlayerTerritories[identifier][territoryName].contested = true
                    
                    -- Update database
                    MySQL.update('UPDATE pimp_territory SET contested = 1 WHERE owner = ? AND location = ?',
                        {identifier, territoryName})
                    
                    -- Notify player
                    local source = GetPlayerSource(identifier)
                    if source then
                        local territoryLabel = Territories[territoryName] and Territories[territoryName].label or territoryName
                        
                        TriggerClientEvent('pimp:notification', source, "Territory Contested", 
                            "Your territory " .. territoryLabel .. " is now contested due to unpaid upkeep! Pay immediately or risk losing it.", "error")
                    end
                end
            end
            
            ::continue::
        end
    end
end

-- Pay territory upkeep
function PayTerritoryUpkeep(identifier, territoryName)
    -- Check if territory exists
    if not Territories[territoryName] then
        return false, "Territory does not exist"
    end
    
    -- Check if player controls the territory
    if not PlayerTerritories[identifier] or not PlayerTerritories[identifier][territoryName] then
        return false, "You don't control this territory"
    end
    
    -- Calculate upkeep cost
    local upkeepCost = Config.TerritorySystem.upkeepCost
    
    -- Check if player has enough money
    local playerMoney = GetPlayerMoney(identifier)
    if playerMoney < upkeepCost then
        return false, "You don't have enough money"
    end
    
    -- Deduct money
    if not RemovePlayerMoney(identifier, upkeepCost) then
        return false, "Failed to deduct money"
    end
    
    -- Calculate next upkeep date
    local nextUpkeepTime = os.time() + (Config.TerritorySystem.upkeepInterval * 24 * 60 * 60)
    local nextUpkeepDate = os.date("%Y-%m-%d %H:%M:%S", nextUpkeepTime)
    
    -- Update territory data
    PlayerTerritories[identifier][territoryName].upkeepPaid = true
    PlayerTerritories[identifier][territoryName].contested = false
    PlayerTerritories[identifier][territoryName].lastUpkeep = os.date("%Y-%m-%d %H:%M:%S")
    PlayerTerritories[identifier][territoryName].nextUpkeep = nextUpkeepDate
    
    -- Update database
    MySQL.update('UPDATE pimp_territory SET upkeep_paid = 1, contested = 0, last_upkeep = CURRENT_TIMESTAMP, next_upkeep = ? WHERE owner = ? AND location = ?',
        {nextUpkeepDate, identifier, territoryName})
    
    -- Log transaction
    LogTransaction(identifier, "territory_upkeep", upkeepCost, "Paid upkeep for territory: " .. territoryName)
    
    return true, "Upkeep paid successfully"
end

-- Apply raid consequences
function ApplyRaidConsequences(identifier, territoryName)
    -- Check if territory exists
    if not Territories[territoryName] then
        return false
    end
    
    -- Check if player controls the territory
    if not PlayerTerritories[identifier] or not PlayerTerritories[identifier][territoryName] then
        return false
    end
    
    -- Reduce control
    local currentControl = PlayerTerritories[identifier][territoryName].control
    PlayerTerritories[identifier][territoryName].control = math.max(10.0, currentControl - (currentControl * Config.TerritorySystem.raids.failureConsequences.controlLoss))
    PlayerTerritories[identifier][territoryName].lastUpdated = os.date("%Y-%m-%d %H:%M:%S")
    
    -- Update database
    MySQL.update('UPDATE pimp_territory SET control = ?, last_updated = CURRENT_TIMESTAMP WHERE owner = ? AND location = ?',
        {PlayerTerritories[identifier][territoryName].control, identifier, territoryName})
    
    -- Get working girls in this territory
    MySQL.query('SELECT id, name, happiness, pending_earnings FROM pimp_girls WHERE owner = ? AND status = ? AND work_location = ?',
        {identifier, 'working', territoryName}, function(result)
        if result and #result > 0 then
            for _, girl in ipairs(result) do
                -- Reduce happiness
                local newHappiness = math.max(0, girl.happiness - Config.TerritorySystem.raids.failureConsequences.girlHappinessLoss)
                
                -- Reduce earnings
                local lostEarnings = math.floor(girl.pending_earnings * Config.TerritorySystem.raids.failureConsequences.earningsLoss)
                local newEarnings = girl.pending_earnings - lostEarnings
                
                -- Check for injury
                local injured = math.random() < Config.TerritorySystem.raids.failureConsequences.girlInjuryChance
                local newStatus = injured and 'injured' or 'idle'
                
                -- Update girl
                MySQL.update('UPDATE pimp_girls SET happiness = ?, pending_earnings = ?, status = ? WHERE id = ?',
                    {newHappiness, newEarnings, newStatus, girl.id})
                
                -- Notify player
                local source = GetPlayerSource(identifier)
                if source then
                    if injured then
                        TriggerClientEvent('pimp:notification', source, "Girl Injured", girl.name .. " was injured during the raid and needs time to recover!", "error")
                    else
                        TriggerClientEvent('pimp:notification', source, "Girl Affected", girl.name .. " lost " .. FormatNumber(lostEarnings) .. " in earnings and " .. Config.TerritorySystem.raids.failureConsequences.girlHappinessLoss .. " happiness points due to the raid", "warning")
                    end
                end
            end
        end
    end)
    
    return true
end

-- Log territory event
function LogTerritoryEvent(territoryName, eventType, description, owner, target)
    MySQL.insert('INSERT INTO pimp_territory_events (territory_name, event_type, description, owner, target) VALUES (?, ?, ?, ?, ?)',
        {territoryName, eventType, description, owner, target})
end

-- Check if player is near territory
function IsPlayerNearTerritory(playerId, territoryName)
    -- Check if territory exists
    if not Territories[territoryName] then
        return false
    end
    
    -- Get player coordinates
    local playerCoords = GetEntityCoords(GetPlayerPed(playerId))
    
    -- Get territory coordinates
    local territory = Territories[territoryName]
    local territoryCoords = vector3(territory.x, territory.y, territory.z)
    
    -- Check distance
    local distance = #(playerCoords - territoryCoords)
    return distance <= Config.TerritorySystem.proximityRequirement
end

-- Register server events
RegisterNetEvent('pimp:requestTerritories')
AddEventHandler('pimp:requestTerritories', function()
    local source = source
    local identifier = GetPlayerIdentifierFromId(source)
    
    -- Get discovered territories
    local discovered = GetDiscoveredTerritories(identifier)
    local territories = {}
    
    -- Filter territories
    for name, territory in pairs(Territories) do
        if discovered[name] then
            territories[name] = territory
        end
    end
    
    -- Get player territories
    local playerTerritories = GetPlayerTerritories(identifier)
    
    -- Get territory upgrades
    local upgrades = TerritoryUpgrades[identifier] or {}
    
    TriggerClientEvent('pimp:receiveTerritories', source, territories, playerTerritories, upgrades)
end)

RegisterNetEvent('pimp:claimTerritory')
AddEventHandler('pimp:claimTerritory', function(territoryName)
    local source = source
    local identifier = GetPlayerIdentifierFromId(source)
    
    -- Check proximity
    if not IsPlayerNearTerritory(source, territoryName) then
        TriggerClientEvent('pimp:notification', source, "Too Far", "You need to be closer to claim this territory", "error")
        return
    end
    
    local success, message = ClaimTerritory(identifier, territoryName)
    TriggerClientEvent('pimp:notification', source, "Territory Claim", message, success and "success" or "error")
end)

RegisterNetEvent('pimp:upgradeTerritory')
AddEventHandler('pimp:upgradeTerritory', function(territoryName, upgradeType)
    local source = source
    local identifier = GetPlayerIdentifierFromId(source)
    
    -- Check proximity
    if not IsPlayerNearTerritory(source, territoryName) then
        TriggerClientEvent('pimp:notification', source, "Too Far", "You need to be closer to upgrade this territory", "error")
        return
    end
    
    local success, message = UpgradeTerritory(identifier, territoryName, upgradeType)
    TriggerClientEvent('pimp:notification', source, "Territory Upgrade", message, success and "success" or "error")
end)

-- Pay territory upkeep
RegisterNetEvent('pimp:payTerritoryUpkeep')
AddEventHandler('pimp:payTerritoryUpkeep', function(territoryName)
    local source = source
    local identifier = GetPlayerIdentifierFromId(source)
    
    local success, message = PayTerritoryUpkeep(identifier, territoryName)
    TriggerClientEvent('pimp:notification', source, "Territory Upkeep", message, success and "success" or "error")
    
    -- If successful, update client
    if success then
        -- Get player territories
        local playerTerritories = GetPlayerTerritories(identifier)
        
        -- Get territory upgrades
        local upgrades = TerritoryUpgrades[identifier] or {}
        
        -- Send updated data to client
        TriggerClientEvent('pimp:receiveTerritories', source, Territories, playerTerritories, upgrades)
    end
end)

RegisterNetEvent('pimp:contestTerritory')
AddEventHandler('pimp:contestTerritory', function(territoryName)
    local source = source
    local identifier = GetPlayerIdentifierFromId(source)
    
    -- Check proximity
    if not IsPlayerNearTerritory(source, territoryName) then
        TriggerClientEvent('pimp:notification', source, "Too Far", "You need to be closer to contest this territory", "error")
        return
    end
    
    -- Find current owner
    local currentOwner = nil
    
    for owner, territories in pairs(PlayerTerritories) do
        if territories[territoryName] and territories[territoryName].control > 0 then
            currentOwner = owner
            break
        end
    end
    
    if not currentOwner then
        -- If no owner, just claim it
        local success, message = ClaimTerritory(identifier, territoryName)
        TriggerClientEvent('pimp:notification', source, "Territory Claim", message, success and "success" or "error")
    else
        -- Start contest
        local success, message = StartTerritoryContest(identifier, currentOwner, territoryName)
        TriggerClientEvent('pimp:notification', source, "Territory Contest", message, success and "success" or "error")
    end
end)

RegisterNetEvent('pimp:contributeToContest')
AddEventHandler('pimp:contributeToContest', function(territoryName, amount)
    local source = source
    local identifier = GetPlayerIdentifierFromId(source)
    
    local success, message = ContributeToContest(identifier, territoryName, amount)
    TriggerClientEvent('pimp:notification', source, "Contest Contribution", message, success and "success" or "error")
end)

-- Generate territory earnings
RegisterNetEvent('pimp:generateTerritoryEarnings')
AddEventHandler('pimp:generateTerritoryEarnings', function(girlId)
    local source = source
    
    -- Find girl owner and data
    local girlOwner = nil
    local girlData = nil
    
    for identifier, playerData in pairs(PlayerData or {}) do
        if playerData.girls then
            for _, girl in ipairs(playerData.girls) do
                if girl.id == girlId then
                    girlOwner = identifier
                    girlData = girl
                    break
                end
            end
        end
        
        if girlOwner then break end
    end
    
    -- Check if girl exists and is working
    if not girlOwner or not girlData or girlData.status ~= 'working' or not girlData.workLocation then
        return
    end
    
    -- Check if territory exists
    local territoryName = girlData.workLocation
    if not Territories[territoryName] then
        return
    end
    
    -- Calculate earnings
    local baseEarnings = Config.GirlSystem.girlTypes[girlData.type] and Config.GirlSystem.girlTypes[girlData.type].baseEarnings or 100
    local appearanceBonus = (girlData.appearance or 50) / 50 -- 0.2 to 2.0
    local performanceBonus = (girlData.performance or 50) / 50 -- 0.2 to 2.0
    local territoryBonus = Territories[territoryName].earnings_multiplier or 1.0
    local timeOfDayBonus = GetTimeOfDayBonus()
    
    -- Calculate final earnings
    local earnings = math.floor(baseEarnings * appearanceBonus * performanceBonus * territoryBonus * timeOfDayBonus)
    
    -- Apply territory upgrades if any
    local upgradeBonus = GetTerritoryUpgradeEffect(girlOwner, territoryName, "earnings_boost") or 0
    earnings = math.floor(earnings * (1 + upgradeBonus))
    
    -- Add earnings to girl
    AddGirlEarnings(girlOwner, girlId, earnings)
    
    -- Log
    print("^2[Territory] Girl " .. girlData.name .. " earned $" .. earnings .. " in " .. territoryName .. "^7")
    
    -- Notify player if online
    local playerSource = GetPlayerSource(girlOwner)
    if playerSource then
        TriggerClientEvent('pimp:notification', playerSource, "Territory Earnings", girlData.name .. " earned $" .. earnings .. " in " .. territoryName, "success")
    end
end)

-- Get time of day bonus
function GetTimeOfDayBonus()
    local hour = tonumber(os.date("%H"))
    
    -- Night time bonus (10PM - 4AM)
    if hour >= 22 or hour < 4 then
        return 1.5
    -- Evening bonus (6PM - 10PM)
    elseif hour >= 18 and hour < 22 then
        return 1.2
    -- Afternoon (12PM - 6PM)
    elseif hour >= 12 and hour < 18 then
        return 1.0
    -- Morning (4AM - 12PM)
    else
        return 0.8
    end
end

-- Collect territory earnings
RegisterNetEvent('pimp:collectTerritoryEarnings')
AddEventHandler('pimp:collectTerritoryEarnings', function(territoryName)
    local source = source
    local identifier = GetPlayerIdentifierFromId(source)
    
    if not identifier then return end
    
    -- Check if territory exists
    if not Territories[territoryName] then
        TriggerClientEvent('pimp:notification', source, "Territory Earnings", "This territory doesn't exist", "error")
        return
    end
    
    -- Check if player owns the territory
    if not PlayerTerritories[identifier] or not PlayerTerritories[identifier][territoryName] then
        TriggerClientEvent('pimp:notification', source, "Territory Earnings", "You don't own this territory", "error")
        return
    end
    
    -- Get girls working in this territory
    MySQL.query('SELECT id, name, pending_earnings FROM pimp_girls WHERE owner = ? AND status = ? AND work_location = ?',
        {identifier, 'working', territoryName}, function(result)
        if not result or #result == 0 then
            TriggerClientEvent('pimp:notification', source, "Territory Earnings", "No earnings to collect", "info")
            return
        end
        
        -- Calculate total earnings
        local totalEarnings = 0
        for _, girl in ipairs(result) do
            totalEarnings = totalEarnings + (girl.pending_earnings or 0)
        end
        
        -- Reset pending earnings for all girls
        MySQL.update('UPDATE pimp_girls SET pending_earnings = 0 WHERE owner = ? AND status = ? AND work_location = ?',
            {identifier, 'working', territoryName})
        
        -- Update local data
        if PlayerData[identifier] and PlayerData[identifier].girls then
            for i, girl in ipairs(PlayerData[identifier].girls) do
                if girl.status == 'working' and girl.workLocation == territoryName then
                    PlayerData[identifier].girls[i].pending_earnings = 0
                end
            end
        end
        
        -- Add black money to player
        GiveBlackMoney(identifier, totalEarnings)
        
        -- Notify player
        TriggerClientEvent('pimp:notification', source, "Territory Earnings", "Collected $" .. totalEarnings .. " from " .. territoryName, "success")
        
        -- Update client
        UpdatePlayerData(identifier)
        
        -- Log transaction
        LogTransaction(identifier, "territory_earnings", totalEarnings, "Collected earnings from territory: " .. territoryName)
    end)
end)

-- Give black money to player
function GiveBlackMoney(identifier, amount)
    local source = GetPlayerSource(identifier)
    if not source then return false end
    
    -- Check which framework is being used
    if Config.Framework == "esx" and ESX then
        local xPlayer = ESX.GetPlayerFromIdentifier(identifier)
        if xPlayer then
            xPlayer.addAccountMoney('black_money', amount)
            return true
        end
    elseif Config.Framework == "qb-core" and QBCore then
        local Player = QBCore.Functions.GetPlayerByCitizenId(identifier)
        if Player then
            Player.Functions.AddItem('black_money', amount)
            TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items['black_money'], "add")
            return true
        end
    else
        -- Generic fallback
        TriggerClientEvent('pimp:addBlackMoney', source, amount)
        return true
    end
    
    return false
end

-- Initialize territory system on resource start
Citizen.CreateThread(function()
    Citizen.Wait(1000) -- Wait for database to be ready
    InitializeTerritorySystem()
end)

-- Store player territory waypoints
local PlayerTerritoryWaypoints = {}

-- Set territory waypoint for a player
RegisterNetEvent('pimp:setTerritoryWaypoint')
AddEventHandler('pimp:setTerritoryWaypoint', function(territoryName)
    local source = source
    local identifier = GetPlayerIdentifierFromId(source)
    
    if not identifier then return end
    
    -- Store the waypoint
    PlayerTerritoryWaypoints[identifier] = territoryName
    
    -- Log
    print("^2[Territory] Player " .. GetPlayerName(source) .. " set waypoint to territory: " .. territoryName .. "^7")
end)

-- Purchase territory
RegisterNetEvent('pimp:purchaseTerritory')
AddEventHandler('pimp:purchaseTerritory', function(territoryName, price)
    local source = source
    local identifier = GetPlayerIdentifierFromId(source)
    
    if not identifier then return end
    
    -- Check if territory exists
    if not Territories[territoryName] then
        TriggerClientEvent('pimp:notification', source, "Territory Purchase", "This territory doesn't exist", "error")
        return
    end
    
    -- Check if player has a waypoint to this territory
    if PlayerTerritoryWaypoints[identifier] ~= territoryName then
        TriggerClientEvent('pimp:notification', source, "Territory Purchase", "You need to find this territory first", "error")
        return
    end
    
    -- Check if player already owns this territory
    if PlayerTerritories[identifier] and PlayerTerritories[identifier][territoryName] then
        TriggerClientEvent('pimp:notification', source, "Territory Purchase", "You already own this territory", "error")
        return
    end
    
    -- Check if player has enough money
    local playerMoney = GetPlayerMoney(identifier)
    if playerMoney < price then
        TriggerClientEvent('pimp:notification', source, "Territory Purchase", "You don't have enough money", "error")
        return
    end
    
    -- Deduct money
    if not RemovePlayerMoney(identifier, price) then
        TriggerClientEvent('pimp:notification', source, "Territory Purchase", "Failed to deduct money", "error")
        return
    end
    
    -- Add territory to player's owned territories
    local success, message = ClaimTerritory(identifier, territoryName)
    
    if success then
        -- Clear waypoint
        PlayerTerritoryWaypoints[identifier] = nil
        
        -- Notify player
        TriggerClientEvent('pimp:notification', source, "Territory Purchase", "You've successfully purchased " .. (Territories[territoryName].label or territoryName), "success")
        
        -- Remove dealer NPC
        TriggerClientEvent('pimp:removeTerritoryDealer', source)
        
        -- Log transaction
        LogTransaction(identifier, "territory_purchase", price, "Purchased territory: " .. territoryName)
    else
        -- Refund money if claim failed
        AddPlayerMoney(identifier, price)
        TriggerClientEvent('pimp:notification', source, "Territory Purchase", message, "error")
    end
end)

-- Remove territory dealer
RegisterNetEvent('pimp:removeTerritoryDealer')
AddEventHandler('pimp:removeTerritoryDealer', function()
    -- This is handled client-side, but we keep the event for consistency
end)

-- Export functions
exports('GetAllTerritories', GetAllTerritories)
exports('GetPlayerTerritories', GetPlayerTerritories)
exports('GetDiscoveredTerritories', GetDiscoveredTerritories)
exports('HasDiscoveredTerritory', HasDiscoveredTerritory)
exports('DiscoverTerritory', DiscoverTerritory)
exports('DiscoverRandomTerritories', DiscoverRandomTerritories)
exports('ClaimTerritory', ClaimTerritory)
exports('UpgradeTerritory', UpgradeTerritory)
exports('GetTerritoryUpgradeLevel', GetTerritoryUpgradeLevel)
exports('GetTerritoryUpgradeEffect', GetTerritoryUpgradeEffect)
exports('IsPlayerNearTerritory', IsPlayerNearTerritory)