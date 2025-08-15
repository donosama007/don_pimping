-- Shared variables between client scripts
DisciplineCooldowns = {}
GirlPeds = {}
TemporaryEffects = {}

-- Debug function to help diagnose issues
function DebugPrint(message)
    if Config and Config.Debug then
        print("^3[Debug] " .. message .. "^7")
    end
end

-- Function to get GirlPeds
function GetGirlPeds()
    return GirlPeds
end

-- Function to set GirlPeds
function SetGirlPeds(peds)
    if peds and type(peds) == "table" then
        GirlPeds = peds
        DebugPrint("GirlPeds updated with " .. #peds .. " entries")
    end
end

-- Register events for variable sharing
RegisterNetEvent('pimp:getSharedVariables')
AddEventHandler('pimp:getSharedVariables', function()
    TriggerEvent('pimp:setSharedVariables', {
        GirlPeds = GirlPeds,
        DisciplineCooldowns = DisciplineCooldowns,
        TemporaryEffects = TemporaryEffects
    })
end)

RegisterNetEvent('pimp:setSharedVariables')
AddEventHandler('pimp:setSharedVariables', function(variables)
    if variables.GirlPeds then GirlPeds = variables.GirlPeds end
    if variables.DisciplineCooldowns then DisciplineCooldowns = variables.DisciplineCooldowns end
    if variables.TemporaryEffects then TemporaryEffects = variables.TemporaryEffects end
    DebugPrint("Shared variables updated")
end)

-- Export functions
exports('GetGirlPeds', GetGirlPeds)
exports('SetGirlPeds', SetGirlPeds)