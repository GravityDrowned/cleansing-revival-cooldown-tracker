-- Cleansing Revival Debug
-- Diagnostic tool to identify Cleansing Revival activation events

local CRD = {}
CRD.name = "CleansingRevivalDebug"
CRD.eventCount = 0

-- Constants
local PASSIVE_ABILITY_ID = 142003 -- Cleansing Revival ability ID from Srendarr

-- Helper function for more visible output
local function LogEvent(message)
    d(message)
    CHAT_SYSTEM:AddMessage(message)
end

-- Event Handler
function CRD.OnCombatEvent(_, result, isError, abilityName, abilityGraphic, 
                           abilityActionSlotType, sourceName, sourceType, 
                           targetName, targetType, hitValue, powerType, 
                           damageType, log, sourceUnitId, targetUnitId, abilityId)
    
    CRD.eventCount = CRD.eventCount + 1
    
    -- Player filter: only process if sourceName or targetName matches player
    local playerName = GetUnitName("player")
    local isPlayerInvolved = (sourceName == playerName) or (targetName == playerName)
    
    if not isPlayerInvolved then return end
    
    -- Normalize ability name for case-insensitive comparison
    local lowerAbilityName = string.lower(abilityName or "")
    local hasCleansingName = string.find(lowerAbilityName, "cleans") ~= nil
    local isPassiveAbility = (abilityId == PASSIVE_ABILITY_ID) and (PASSIVE_ABILITY_ID > 0)
    
    -- Filter 1: Healing events
    if (result == ACTION_RESULT_HEAL or 
        result == ACTION_RESULT_HOT_TICK or 
        result == ACTION_RESULT_CRITICAL_HEAL) then
        if hasCleansingName or isPassiveAbility then
            LogEvent(string.format("[CRD] HEAL EVENT - Name: %s | ID: %d | Result: %d | Value: %d | Source: %s | Target: %s",
                abilityName, abilityId, result, hitValue, sourceName, targetName))
        end
    end
    
    -- Filter 2: Cleansing events
    if (result == ACTION_RESULT_EFFECT_FADED or 
        result == ACTION_RESULT_DEBUFF_REMOVED or 
        result == ACTION_RESULT_BUFF_REMOVED) then
        if hasCleansingName or isPassiveAbility then
            LogEvent(string.format("[CRD] CLEANSE EVENT - Name: %s | ID: %d | Result: %d | Source: %s | Target: %s",
                abilityName, abilityId, result, sourceName, targetName))
        end
    end
    
    -- Filter 3: All events matching the passive ability ID
    if isPassiveAbility then
        LogEvent(string.format("[CRD] PASSIVE ID EVENT - Name: %s | Result: %d | Value: %d",
            abilityName, result, hitValue))
    end
end

-- Initialize Function
function CRD.Initialize(_, addonName)
    if addonName ~= CRD.name then return end
    
    -- Register EVENT_COMBAT_EVENT
    EVENT_MANAGER:RegisterForEvent(CRD.name, EVENT_COMBAT_EVENT, CRD.OnCombatEvent)
    
    -- Print helpful instructions
    d("[CRD] Cleansing Revival Debug addon loaded!")
    d("[CRD] INSTRUCTIONS:")
    d("[CRD] 1. Get into combat and trigger Cleansing Revival")
    d("[CRD] 2. Take damage below health threshold with negative effects")
    d("[CRD] 3. Check chat for logged events")
    d("[CRD] Currently monitoring passive ID: " .. PASSIVE_ABILITY_ID)
    
    -- Register slash command for testing
    SLASH_COMMANDS["/crd"] = function(args)
        if args == "test" then
            d("[CRD] ✓ Addon is ACTIVE and responding!")
            d("[CRD] ✓ Monitoring ability ID: " .. PASSIVE_ABILITY_ID)
            d("[CRD] ✓ Watching for: healing events, cleansing events, and ability name 'cleans'")
            d("[CRD] Type /crd status for event counts")
        elseif args == "status" then
            d("[CRD] Status Report:")
            d("[CRD] - Events logged: " .. (CRD.eventCount or 0))
            d("[CRD] - Player name: " .. GetUnitName("player"))
            d("[CRD] - Monitoring ID: " .. PASSIVE_ABILITY_ID)
        else
            d("[CRD] Commands: /crd test | /crd status")
        end
    end
    
    -- Visual confirmation
    ZO_Alert(UI_ALERT_CATEGORY_ALERT, nil, "[CRD] Debug addon loaded - Type /crd test to verify")
end

-- Event Registration
EVENT_MANAGER:RegisterForEvent(CRD.name, EVENT_ADD_ON_LOADED, CRD.Initialize)
