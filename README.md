# Cleansing Revival Debug Addon

## Purpose
This diagnostic addon helps identify the exact combat event signature when the \"Cleansing Revival\" champion point ability activates. This information is needed to build the full Cleansing Revival cooldown tracker.

## Current Configuration
-

**Ability ID**: 142003 (from Srendarr)
- **Cooldown Duration
**: 24 seconds (known from game mechanics)

## Installation

1. Ensure this folder is located at:

```
   <ESO Install>/live/AddOns/CleansingRevivalDebug/
   ```

2. In-game, type
`/reloadui` to load the addon

3. Check that you see the loading message:

```
   [CRD] Cleansing Revival Debug addon loaded!
   [CRD] Currently monitoring passive ID: 142003
   ```

##
Testing Procedure

To capture the activation event for Cleansing Revival:

### Step 1: Enter Combat
- Find enemies
to fight
- Enable your chat window to see debug output

### Step 2: Trigger Cleansing Revival
According to ESO
mechanics, Cleansing Revival activates when:
- You drop below a certain health threshold (typically 60% or lower)
-
You have negative effects (poison, disease, debuffs) active
- The ability is off cooldown (24-second cooldown)


**Recommended method:
**
1. Get into combat with multiple enemies
2. Take damage until you're below ~50% health
3. Ensure you have DOT
effects or debuffs on you
4. Wait for Cleansing Revival to proc (you'll see healing and effects removed)

### Step 3:
Check Chat Output

Look for one of these message types:


**HEAL EVENT** - Most likely signature

```
[CRD] HEAL EVENT - Name: <ability> | ID: <id> | Result: <code> | Value: <heal> | Source: <you> | Target: <you>
```



**CLEANSE EVENT** - When debuffs are removed

```
[CRD] CLEANSE EVENT - Name: <ability> | ID: <id> | Result: <code> | Source: <you> | Target: <you>
```

**PASSIVE
ID EVENT** - Any event matching 142003

```
[CRD] PASSIVE ID EVENT - Name: <ability> | Result: <code> | Value: <value>
```

## What to Look For

When
Cleansing Revival activates, you should see:

1.
**Ability ID** - Might be 142003 OR a different ID
2. **Result Code
** - The ACTION_RESULT_* constant (numeric value)
3. **Ability Name
** - May contain \"Cleansing\", \"Revival\", or something else
4. **Timing
** - Events should appear every 24 seconds when conditions are met

## Enhanced Debugging Modes

### Mode 1: Verbose Mode (`/crd verbose`)
- **Duration:** 120 seconds
- **Captures:** All combat events where you are the source OR target
- **Use when:** You want to see everything happening to/from you
- **Look for:** Self-targeted heals with unusual names or IDs

### Mode 2: Super Verbose Mode (`/crd all`)
- **Duration:** 10 seconds
- **Captures:** EVERY SINGLE combat event (even ones not involving you)
- **WARNING:** This will spam chat extremely heavily!
- **Use when:** You need to catch an event that doesn't target you specifically
- **Look for:** Any unusual ability IDs firing when Cleansing Revival procs

### Mode 3: Cleanse Mode (`/crd cleanse`)
- **Duration:** 30 seconds
- **Captures:** Only EFFECT_FADED, DEBUFF_REMOVED, BUFF_REMOVED events
- **Use when:** You want to focus on the \"cleansing\" aspect of Cleansing Revival
- **Look for:** Debuff removals with unusual source abilities

## Testing Strategy

**Recommended approach:**
1. Start with `/crd verbose` (120s) - this is the least spammy
2. Get into combat, take damage, get debuffed
3. Drop below 60% health while debuffed
4. Look for self-targeted heals: `[SELF]` flag in output
5. If nothing found, try `/crd cleanse` to focus on debuff removals
6. As last resort, use `/crd all` for 10 seconds of complete capture

**What we're looking for:**
- Ability name containing \"Cleansing\", \"Revival\", or similar
- Self-targeted heal (Source = Target = your character name)
- Ability ID that is NOT 142003
- Events that fire every 24 seconds when conditions are met

## Expected Outcomes

### Scenario A: Same ID (
142003)
- The passive ID fires with a specific result code when it activates
- Example:
`Result: 2240` = ACTION_RESULT_HEAL
- **Next step
**: Filter on both ID + result code

### Scenario B: Different Activation ID
- A new ability ID appears that's
different from 142003
- This is the \"proc\" ID we need to track
-
**Next step
**: Track the new ID instead

### Scenario C: No Events Logged
- Champion abilities may not fire detectable combat
events
-
**Next step**: Use manual cooldown tracking (slash command)

## Troubleshooting

**No output at all:
**
- Check addon is loaded:
`/reloadui`
- Verify chat window is visible
- Try taking more damage / getting more debuffs

**Too much spam:
**
- This is normal - the addon logs many events
- Look specifically for patterns when you KNOW Cleansing Revival just
triggered
- Visual cue: You get healed + debuffs removed


**Not sure if it triggered:
**
- Watch for the healing/cleansing visual effects
- Check your buff bar - debuffs should disappear
- Monitor your
health bar for sudden healing

## Next Steps

Once you identify the event signature:
1. Note the ability ID, result
code, and any patterns
2. Disable this debug addon
3. Build the full cooldown tracker using the discovered event
signature

## Files

-
`CleansingRevivalDebug.txt` - Addon manifest
- `CleansingRevivalDebug.lua` - Event logger implementation
-
`README.md` - This file