-- Cleansing Revival Debug - Enhanced with Visible UI-- Diagnostic tool to identify Cleansing Revival activation events

local CRD = {}
CRD.name = "CleansingRevivalDebug"
CRD.eventCount = 0
CRD.matchedEvents = 0
CRD.verboseMode = false
CRD.verboseEndTime = 0
CRD.superVerboseMode = false
CRD.superVerboseEndTime = 0
CRD.cleanseMode = false
CRD.cleanseEndTime = 0

-- Constants
local PASSIVE_ABILITY_ID = 142003 -- Cleansing Revival ability ID from Srendarr

-- Result code lookup table for human-readable output
local RESULT_CODES = {
    [ACTION_RESULT_ABILITY_ON_COOLDOWN] = "ABILITY_ON_COOLDOWN",
    [ACTION_RESULT_BAD_TARGET] = "BAD_TARGET",
    [ACTION_RESULT_CANT_SEE_TARGET] = "CANT_SEE_TARGET",
    [ACTION_RESULT_CRITICAL_DAMAGE] = "CRITICAL_DAMAGE",
    [ACTION_RESULT_CRITICAL_HEAL] = "CRITICAL_HEAL",
    [ACTION_RESULT_DAMAGE] = "DAMAGE",
    [ACTION_RESULT_DAMAGE_SHIELDED] = "DAMAGE_SHIELDED",
    [ACTION_RESULT_DEBUFF_REMOVED] = "DEBUFF_REMOVED",
    [ACTION_RESULT_DOT_TICK] = "DOT_TICK",
    [ACTION_RESULT_DOT_TICK_CRITICAL] = "DOT_TICK_CRITICAL",
    [ACTION_RESULT_EFFECT_FADED] = "EFFECT_FADED",
    [ACTION_RESULT_EFFECT_GAINED] = "EFFECT_GAINED",
    [ACTION_RESULT_EFFECT_GAINED_DURATION] = "EFFECT_GAINED_DURATION",
    [ACTION_RESULT_HEAL] = "HEAL",
    [ACTION_RESULT_HOT_TICK] = "HOT_TICK",
    [ACTION_RESULT_HOT_TICK_CRITICAL] = "HOT_TICK_CRITICAL",
    [ACTION_RESULT_BUFF_REMOVED] = "BUFF_REMOVED",
}

local function GetResultCodeName(result)
    return RESULT_CODES[result] or "UNKNOWN_" .. tostring(result)
end

-- UI Elements
local statusLabel = nil
local eventLogLabel = nil

-- Create visible on-screen UI
local function CreateUI()
    -- Main container
    local container = WINDOW_MANAGER:CreateTopLevelWindow("CRD_StatusDisplay")
    container:SetDimensions(400, 120)
    container:SetAnchor(TOP, GuiRoot, TOP, 0, 100)
    container:SetMovable(true)
    container:SetMouseEnabled(true)
    container:SetHidden(false)

    -- Background
    local bg = WINDOW_MANAGER:CreateControl(nil, container, CT_BACKDROP)
    bg:SetAnchorFill()
    bg:SetCenterColor(0, 0, 0, 0.8)
    bg:SetEdgeColor(1, 0.8, 0, 1)
    bg:SetEdgeTexture("", 2, 2, 1)

    -- Status label
    statusLabel = WINDOW_MANAGER:CreateControl(nil, container, CT_LABEL)
    statusLabel:SetFont("ZoFontWinH2")
    statusLabel:SetColor(0, 1, 0, 1)
    statusLabel:SetAnchor(TOP, container, TOP, 0, 10)
    statusLabel:SetText("CRD: ACTIVE - Monitoring ID 142003")

    -- Event counter
    local counterLabel = WINDOW_MANAGER:CreateControl(nil, container, CT_LABEL)
    counterLabel:SetFont("ZoFontWinH3")
    counterLabel:SetColor(1, 1, 1, 1)
    counterLabel:SetAnchor(TOP, statusLabel, BOTTOM, 0, 5)
    CRD.counterLabel = counterLabel

    -- Event log display
    eventLogLabel = WINDOW_MANAGER:CreateControl(nil, container, CT_LABEL)
    eventLogLabel:SetFont("ZoFontWinH4")
    eventLogLabel:SetColor(1, 0.8, 0, 1)
    eventLogLabel:SetAnchor(TOP, counterLabel, BOTTOM, 0, 5)
    eventLogLabel:SetDimensions(380, 40)
    eventLogLabel:SetText("Waiting for events...")

    -- Instructions
    local helpLabel = WINDOW_MANAGER:CreateControl(nil, container, CT_LABEL)
    helpLabel:SetFont("ZoFontGameSmall")
    helpLabel:SetColor(0.7, 0.7, 0.7, 1)
    helpLabel:SetAnchor(BOTTOM, container, BOTTOM, 0, -5)
    helpLabel:SetText("Type /crd hide to hide this display | /crd show to show it")

    CRD.container = container

    -- Update counter initially
    CRD.counterLabel:SetText("Events Processed: 0 | Matches: 0")
end

-- Update the on-screen counter
local function UpdateCounter()
    if CRD.counterLabel then
        CRD.counterLabel:SetText(string.format("Events Processed: %d | Matches: %d",
            CRD.eventCount, CRD.matchedEvents))
    end
end

-- Log an event to the on-screen display
local function LogEvent(message)
    d(message)
    CHAT_SYSTEM:AddMessage(message)

    if eventLogLabel then
        eventLogLabel:SetText(message)
    end

    -- Also show as alert for important events
    if string.find(message, "HEAL EVENT") or string.find(message, "CLEANSE EVENT") then
        ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.GENERAL_ALERT_ERROR, message)
        PlaySound(SOUNDS.GENERAL_ALERT_ERROR)
    end
end

-- Event Handler
function CRD.OnCombatEvent(_, result, isError, abilityName, abilityGraphic,
                           abilityActionSlotType, sourceName, sourceType,
                           targetName, targetType, hitValue, powerType,
                           damageType, log, sourceUnitId, targetUnitId, abilityId)

    CRD.eventCount = CRD.eventCount + 1

    -- Update counter every 10 events to avoid spam
    if CRD.eventCount % 10 == 0 then
        UpdateCounter()
    end

    local playerName = GetUnitName("player")
    local playerUnitId = GetUnitTag("player")
    
    -- SUPER VERBOSE MODE: Log EVERYTHING for 10 seconds
    if CRD.superVerboseMode then
        if GetGameTimeMilliseconds() > CRD.superVerboseEndTime then
            CRD.superVerboseMode = false
            d("[CRD] === SUPER VERBOSE MODE ENDED ===")
            d("[CRD] Total events captured: " .. CRD.eventCount)
            ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.ABILITY_ULTIMATE_READY, "[CRD] Super verbose capture complete!")
            if statusLabel then
                statusLabel:SetText("CRD: ACTIVE - Monitoring ID 142003")
                statusLabel:SetColor(0, 1, 0, 1)
            end
        else
            local timeLeft = math.ceil((CRD.superVerboseEndTime - GetGameTimeMilliseconds()) / 1000)
            local resultName = GetResultCodeName(result)
            local msg = string.format("[CRD ALL] %s | ID:%d | Result:%s(%d) | Src:%s | Tgt:%s | Val:%d | (%ds)",
                abilityName or "nil", abilityId or 0, resultName, result, 
                sourceName or "nil", targetName or "nil", hitValue or 0, timeLeft)
            d(msg)
        end
        return -- Don't process other filters in super verbose mode
    end

    -- CLEANSE MODE: Log only debuff/effect removal events
    if CRD.cleanseMode then
        if GetGameTimeMilliseconds() > CRD.cleanseEndTime then
            CRD.cleanseMode = false
            d("[CRD] === CLEANSE MODE ENDED ===")
            ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.ABILITY_ULTIMATE_READY, "[CRD] Cleanse capture complete!")
            if statusLabel then
                statusLabel:SetText("CRD: ACTIVE - Monitoring ID 142003")
                statusLabel:SetColor(0, 1, 0, 1)
            end
        else
            if (result == ACTION_RESULT_EFFECT_FADED or
                result == ACTION_RESULT_DEBUFF_REMOVED or
                result == ACTION_RESULT_BUFF_REMOVED) then
                
                local timeLeft = math.ceil((CRD.cleanseEndTime - GetGameTimeMilliseconds()) / 1000)
                local resultName = GetResultCodeName(result)
                local msg = string.format("[CRD CLEANSE] %s | ID:%d | Result:%s | Src:%s | Tgt:%s | SrcUnit:%s | TgtUnit:%s | (%ds)",
                    abilityName or "nil", abilityId or 0, resultName,
                    sourceName or "nil", targetName or "nil",
                    tostring(sourceUnitId), tostring(targetUnitId), timeLeft)
                d(msg)
                CHAT_SYSTEM:AddMessage(msg)
                
                if eventLogLabel then
                    eventLogLabel:SetText(string.format("CLEANSE: %s (ID:%d)", abilityName or "nil", abilityId or 0))
                end
            end
        end
        return -- Don't process other filters in cleanse mode
    end

    -- Player filter for regular modes
    local isPlayerInvolved = (sourceName == playerName) or (targetName == playerName)
    if not isPlayerInvolved then return end

    -- VERBOSE MODE: Log ALL events involving the player (not just heals)
    if CRD.verboseMode then
        if GetGameTimeMilliseconds() > CRD.verboseEndTime then
            CRD.verboseMode = false
            d("[CRD] === VERBOSE MODE ENDED ===")
            ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.ABILITY_ULTIMATE_READY, "[CRD] Verbose capture complete!")
            if statusLabel then
                statusLabel:SetText("CRD: ACTIVE - Monitoring ID 142003")
                statusLabel:SetColor(0, 1, 0, 1)
            end
        else
            -- Log ALL events where player is involved
            local timeLeft = math.ceil((CRD.verboseEndTime - GetGameTimeMilliseconds()) / 1000)
            local resultName = GetResultCodeName(result)
            local isSelfProc = (sourceName == playerName and targetName == playerName)
            local selfFlag = isSelfProc and "[SELF]" or ""
            
            local msg = string.format("[CRD VERBOSE] %s %s | ID:%d | Result:%s(%d) | Src:%s | Tgt:%s | Val:%d | (%ds)",
                selfFlag, abilityName or "nil", abilityId or 0, resultName, result,
                sourceName or "nil", targetName or "nil", hitValue or 0, timeLeft)
            d(msg)
            
            if eventLogLabel then
                eventLogLabel:SetText(string.format("VERBOSE: %s (ID:%d) Result:%s", 
                    abilityName or "nil", abilityId or 0, resultName))
            end
        end
    end

    -- Normalize ability name for case-insensitive comparison
    local lowerAbilityName = string.lower(abilityName or "")
    local hasCleansingName = string.find(lowerAbilityName, "cleans") ~= nil or 
                             string.find(lowerAbilityName, "revival") ~= nil
    local isPassiveAbility = (abilityId == PASSIVE_ABILITY_ID) and (PASSIVE_ABILITY_ID > 0)

    -- Filter 1: Healing events
    if (result == ACTION_RESULT_HEAL or
        result == ACTION_RESULT_HOT_TICK or
        result == ACTION_RESULT_CRITICAL_HEAL) then
        if hasCleansingName or isPassiveAbility then
            CRD.matchedEvents = CRD.matchedEvents + 1
            local resultName = GetResultCodeName(result)
            LogEvent(string.format("[CRD] HEAL EVENT - Name: %s | ID: %d | Result: %s(%d) | Value: %d | Source: %s | Target: %s",
                abilityName, abilityId, resultName, result, hitValue, sourceName, targetName))
            UpdateCounter()
        end
    end

    -- Filter 2: Cleansing events
    if (result == ACTION_RESULT_EFFECT_FADED or
        result == ACTION_RESULT_DEBUFF_REMOVED or
        result == ACTION_RESULT_BUFF_REMOVED) then
        if hasCleansingName or isPassiveAbility then
            CRD.matchedEvents = CRD.matchedEvents + 1
            local resultName = GetResultCodeName(result)
            LogEvent(string.format("[CRD] CLEANSE EVENT - Name: %s | ID: %d | Result: %s(%d) | Source: %s | Target: %s",
                abilityName, abilityId, resultName, result, sourceName, targetName))
            UpdateCounter()
        end
    end

    -- Filter 3: All events matching the passive ability ID
    if isPassiveAbility then
        CRD.matchedEvents = CRD.matchedEvents + 1
        local resultName = GetResultCodeName(result)
        LogEvent(string.format("[CRD] PASSIVE ID EVENT - Name: %s | Result: %s(%d) | Value: %d",
            abilityName, resultName, result, hitValue))
        UpdateCounter()
    end
end

-- Initialize Function
function CRD.Initialize(_, addonName)
    if addonName ~= CRD.name then return end

    -- Create the on-screen UI
    CreateUI()

    -- Register EVENT_COMBAT_EVENT
    EVENT_MANAGER:RegisterForEvent(CRD.name, EVENT_COMBAT_EVENT, CRD.OnCombatEvent)

    -- Register slash commands
    SLASH_COMMANDS["/crd"] = function(args)
        if args == "test" then
            d("[CRD] ✓ Addon is ACTIVE and responding!")
            d("[CRD] ✓ Monitoring ability ID: " .. PASSIVE_ABILITY_ID)
            ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.ABILITY_ULTIMATE_READY, "[CRD] Addon is ACTIVE!")
        elseif args == "status" then
            d("[CRD] Status Report:")
            d("[CRD] - Events processed: " .. CRD.eventCount)
            d("[CRD] - Matched events: " .. CRD.matchedEvents)
            d("[CRD] - Player name: " .. GetUnitName("player"))
            d("[CRD] - Monitoring ID: " .. PASSIVE_ABILITY_ID)
        elseif args == "verbose" then
            CRD.verboseMode = true
            CRD.verboseEndTime = GetGameTimeMilliseconds() + 120000  -- 120 seconds
            d("===========================================")
            d("[CRD] VERBOSE MODE ACTIVATED for 120 seconds")
            d("[CRD] Logging ALL events involving you")
            d("[CRD] Trigger Cleansing Revival NOW!")
            d("===========================================")
            ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.GENERAL_ALERT_ERROR, "[CRD] VERBOSE MODE - Trigger Cleansing Revival now!")
            PlaySound(SOUNDS.GENERAL_ALERT_ERROR)
            if statusLabel then
                statusLabel:SetText("CRD: VERBOSE MODE ACTIVE (120s)")
                statusLabel:SetColor(1, 1, 0, 1)  -- Yellow text
            end
        elseif args == "all" then
            CRD.superVerboseMode = true
            CRD.superVerboseEndTime = GetGameTimeMilliseconds() + 10000  -- 10 seconds
            d("===========================================")
            d("[CRD] SUPER VERBOSE MODE - 10 SECONDS")
            d("[CRD] WARNING: This will spam chat HEAVILY!")
            d("[CRD] Logging EVERY combat event")
            d("[CRD] Trigger Cleansing Revival NOW!")
            d("===========================================")
            ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.GENERAL_ALERT_ERROR, "[CRD] SUPER VERBOSE - Capturing ALL events!")
            PlaySound(SOUNDS.GENERAL_ALERT_ERROR)
            if statusLabel then
                statusLabel:SetText("CRD: SUPER VERBOSE (10s) - ALL EVENTS")
                statusLabel:SetColor(1, 0, 0, 1)  -- Red text
            end
        elseif args == "cleanse" then
            CRD.cleanseMode = true
            CRD.cleanseEndTime = GetGameTimeMilliseconds() + 30000  -- 30 seconds
            d("===========================================")
            d("[CRD] CLEANSE MODE ACTIVATED for 30 seconds")
            d("[CRD] Logging only debuff/effect removals")
            d("[CRD] Get debuffed and trigger Cleansing Revival!")
            d("===========================================")
            ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.GENERAL_ALERT_ERROR, "[CRD] CLEANSE MODE - Get debuffed now!")
            PlaySound(SOUNDS.GENERAL_ALERT_ERROR)
            if statusLabel then
                statusLabel:SetText("CRD: CLEANSE MODE ACTIVE (30s)")
                statusLabel:SetColor(0, 1, 1, 1)  -- Cyan text
            end
        elseif args == "hide" then
            CRD.container:SetHidden(true)
            d("[CRD] Display hidden. Type /crd show to show it again")
        elseif args == "show" then
            CRD.container:SetHidden(false)
            d("[CRD] Display shown")
        else
            d("[CRD] Commands:")
            d("  /crd test - Test addon is active")
            d("  /crd status - Show statistics")
            d("  /crd verbose - Log all events on you (120s)")
            d("  /crd all - Log EVERYTHING (10s, HEAVY SPAM)")
            d("  /crd cleanse - Log only cleanses (30s)")
            d("  /crd hide/show - Toggle display")
        end
    end

    -- Print to chat
    d("===========================================")
    d("[CRD] Cleansing Revival Debug addon loaded!")
    d("[CRD] Look for the YELLOW BOX at top of screen")
    d("[CRD] Type /crd verbose to start capture mode")
    d("===========================================")

    -- Visual and audio confirmation
    ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.ABILITY_ULTIMATE_READY, "[CRD] Debug addon loaded! Check top of screen for status display")
    PlaySound(SOUNDS.ABILITY_ULTIMATE_READY)
end

-- Event Registration
EVENT_MANAGER:RegisterForEvent(CRD.name, EVENT_ADD_ON_LOADED, CRD.Initialize)
