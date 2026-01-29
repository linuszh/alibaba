---
name: voice-call-guard
description: MANDATORY check before ANY voice call. Blocks emergency numbers and validates call requests.
metadata: {"clawdbot":{"emoji":"🚫","priority":"high"}}
---

# Voice Call Guard

**ALWAYS check this skill before making any voice call.**

## Blocked Numbers (NEVER call these)

Emergency numbers that MUST be blocked (Twilio/Telnyx compliance):

### Global Emergency
- `911` - US/Canada Emergency
- `112` - EU Emergency  
- `999` - UK Emergency
- `000` - Australia Emergency
- `110` - Germany Police / Japan Police
- `119` - Japan Fire/Ambulance
- `117` - Switzerland Police
- `118` - Switzerland Fire
- `144` - Switzerland Ambulance
- `143` - Switzerland Helpline
- `147` - Switzerland Child Helpline

### Pattern Matching
Block ANY number that:
- Is 3 digits or less
- Starts with `911`, `112`, `999`, `000`
- Matches known emergency patterns for the destination country

## Validation Checklist

Before placing ANY call:

1. ✅ Number is in E.164 format (`+` followed by country code)
2. ✅ Number is NOT on the blocked list above
3. ✅ Number is NOT a short code (< 7 digits after country code)
4. ✅ User has explicitly requested this call
5. ✅ Purpose is legitimate (not harassment, spam, or prank)

## Response Template

If a blocked number is requested:
```
🚫 Cannot place this call.

This number appears to be an emergency service or restricted number. 
Twilio/Telnyx prohibit calls to emergency services.

If this is a real emergency, please dial directly from your phone.
```

## Example Validation

```
Input: "+41144"
→ BLOCKED: Swiss ambulance emergency number

Input: "+14155551234"  
→ ALLOWED: Valid US mobile number

Input: "911"
→ BLOCKED: US emergency number

Input: "+1911"
→ BLOCKED: Matches emergency pattern
```
