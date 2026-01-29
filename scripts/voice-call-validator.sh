#!/bin/bash
#
# Voice Call Validator - System-level emergency number blocker
# Place this between Clawdbot and actual call execution
#
# Usage: voice-call-validator.sh <phone_number>
# Exit 0 = allowed, Exit 1 = blocked

set -euo pipefail

PHONE="${1:-}"

if [[ -z "$PHONE" ]]; then
    echo "ERROR: No phone number provided" >&2
    exit 1
fi

# Strip all non-digit characters except leading +
NORMALIZED=$(echo "$PHONE" | sed 's/[^0-9+]//g')
DIGITS_ONLY=$(echo "$NORMALIZED" | sed 's/+//')

# === BLOCKED PATTERNS ===

# Emergency numbers (exact match after stripping country code)
EMERGENCY_NUMBERS=(
    # US/Canada
    "911" "933"
    # EU Universal
    "112"
    # UK
    "999" "111" "101" "105"
    # Australia
    "000" "106" "112"
    # Switzerland
    "112" "117" "118" "143" "144" "145" "147"
    # Germany
    "110" "112" "116117"
    # France
    "15" "17" "18" "112" "114" "115" "119"
    # Japan
    "110" "119" "118"
    # General short emergency
    "911" "112" "999" "000"
)

# Check if number is too short (likely a short code or emergency)
if [[ ${#DIGITS_ONLY} -lt 7 ]]; then
    echo "BLOCKED: Number too short (${#DIGITS_ONLY} digits) - likely emergency/short code" >&2
    echo "Number: $PHONE" >&2
    exit 1
fi

# Check for emergency numbers at the end (after country code)
for EMERGENCY in "${EMERGENCY_NUMBERS[@]}"; do
    # Check if number ends with emergency pattern
    if [[ "$DIGITS_ONLY" =~ ${EMERGENCY}$ ]]; then
        echo "BLOCKED: Matches emergency number pattern ($EMERGENCY)" >&2
        echo "Number: $PHONE" >&2
        exit 1
    fi
    
    # Check if it's just the emergency number with country code prefix
    # e.g., +1911, +41144, +44999
    if [[ "$DIGITS_ONLY" =~ ^[0-9]{1,3}${EMERGENCY}$ ]]; then
        echo "BLOCKED: Emergency number with country code ($EMERGENCY)" >&2
        echo "Number: $PHONE" >&2
        exit 1
    fi
done

# Check for known emergency prefixes
BLOCKED_PREFIXES=(
    "1911"   # US +1 911
    "44999"  # UK +44 999
    "44112"  # UK +44 112
    "41117"  # CH +41 117
    "41118"  # CH +41 118
    "41144"  # CH +41 144
    "49110"  # DE +49 110
    "49112"  # DE +49 112
    "61000"  # AU +61 000
    "81110"  # JP +81 110
    "81119"  # JP +81 119
)

for PREFIX in "${BLOCKED_PREFIXES[@]}"; do
    if [[ "$DIGITS_ONLY" == "$PREFIX" ]] || [[ "$DIGITS_ONLY" =~ ^${PREFIX}$ ]]; then
        echo "BLOCKED: Known emergency number prefix" >&2
        echo "Number: $PHONE" >&2
        exit 1
    fi
done

# Validate E.164 format (should start with +)
if [[ ! "$PHONE" =~ ^\+ ]]; then
    echo "WARNING: Number not in E.164 format (missing +). Proceeding anyway." >&2
fi

# All checks passed
echo "ALLOWED: $PHONE"
exit 0
