#!/bin/bash
# Sync API keys from Bitwarden vault to ~/.openclaw/.env
# Run via systemd timer every 24h or manually
# Requires: bw CLI, jq, BW_SESSION or ~/.openclaw/.bw-credentials

set -uo pipefail

ENV_FILE="$HOME/.openclaw/.env"
BW_CREDS="$HOME/.openclaw/.bw-credentials"
LOG_TAG="bw-sync-env"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"; }

# Ensure session
if [ -z "${BW_SESSION:-}" ]; then
    BW_SESSION=$(grep '^BW_SESSION=' "$ENV_FILE" 2>/dev/null | cut -d'=' -f2- || true)
    export BW_SESSION
fi

# Check if vault is accessible
vault_status=$(bw status 2>/dev/null | jq -r '.status' 2>/dev/null || echo "error")
if [ "$vault_status" = "locked" ]; then
    log "Vault locked, attempting unlock..."
    if [ ! -f "$BW_CREDS" ]; then
        log "ERROR: No credentials file at $BW_CREDS"
        exit 1
    fi
    BW_PASSWORD="$(tail -1 "$BW_CREDS")"
    export BW_PASSWORD
    BW_SESSION=$(bw unlock --passwordenv BW_PASSWORD --raw 2>/dev/null)
    export BW_SESSION
    unset BW_PASSWORD
    if [ -z "$BW_SESSION" ]; then
        log "ERROR: Failed to unlock vault"
        exit 1
    fi
    log "Vault unlocked"
elif [ "$vault_status" = "unauthenticated" ]; then
    log "ERROR: Not logged in to Bitwarden. Run: bw login"
    exit 1
elif [ "$vault_status" = "error" ]; then
    log "ERROR: Cannot reach Bitwarden CLI"
    exit 1
fi

# Sync with server
log "Syncing vault..."
bw sync >/dev/null 2>&1

# Get all items as JSON
items=$(bw list items 2>/dev/null)
if [ -z "$items" ]; then
    log "ERROR: No items returned from vault"
    exit 1
fi

# Build new env values
# Simple items: vault item name = env var name, password = value
SIMPLE_KEYS=(
    ANTHROPIC_API_KEY
    BRAVE_API_KEY
    DISCORD_BOT_TOKEN
    DISCORD_VENICE_BOT_TOKEN
    DOKPLOY_API_TOKEN
    ELEVENLABS_API_KEY
    GOOGLE_PLACES_API_KEY
    LTX_API_KEY
    META_ACCESS_TOKEN
    MOONSHOT_API_KEY
    N8N_API_KEY
    OPENAI_API_KEY
    OPENAI_MEMORY_KEY
    OPENCLAW_GATEWAY_PASSWORD
    PERPLEXITY_API_KEY
    PVE_TOKEN
    SAG_API_KEY
    SHOPIFY_CLIENT_ID
    SHOPIFY_CLIENT_SECRET
    SHOPIFY_STORE_DOMAIN
    TELEGRAM_BOT_TOKEN
    TELEGRAM_CONFIDENTIAL_BOT_TOKEN
    VENICE_API_KEY
    WHISPER_API_KEY
    ZAI_API_KEY
)

log "Reading keys from vault..."
UPDATED=0
ERRORS=0

# Read current .env into associative array (preserve non-synced vars)
declare -A ENV_VARS
while IFS='=' read -r key value; do
    [ -n "$key" ] && ENV_VARS["$key"]="$value"
done < "$ENV_FILE"

# Sync simple keys (name = env var, password = value)
for key in "${SIMPLE_KEYS[@]}"; do
    val=$(echo "$items" | jq -r --arg name "$key" '.[] | select(.name == $name) | .login.password // empty')
    if [ -n "$val" ]; then
        ENV_VARS["$key"]="$val"
        UPDATED=$((UPDATED + 1))
    else
        log "WARN: No password found for $key"
        ERRORS=$((ERRORS + 1))
    fi
done

# Special: Twilio (username=SID, password=token)
twilio_sid=$(echo "$items" | jq -r '.[] | select(.name == "TWILIO_API") | .login.username // empty')
twilio_token=$(echo "$items" | jq -r '.[] | select(.name == "TWILIO_API") | .login.password // empty')
if [ -n "$twilio_sid" ] && [ -n "$twilio_token" ]; then
    ENV_VARS["TWILIO_ACCOUNT_SID"]="$twilio_sid"
    ENV_VARS["TWILIO_AUTH_TOKEN"]="$twilio_token"
    UPDATED=$((UPDATED + 2))
else
    log "WARN: Could not read Twilio credentials"
    ((ERRORS++))
fi

# Special: OPNsense (username=key, password=secret)
opn_key=$(echo "$items" | jq -r '.[] | select(.name == "OPNSENSE_API_KEY") | .login.username // empty')
opn_secret=$(echo "$items" | jq -r '.[] | select(.name == "OPNSENSE_API_KEY") | .login.password // empty')
if [ -n "$opn_key" ] && [ -n "$opn_secret" ]; then
    ENV_VARS["OPNSENSE_API_KEY"]="$opn_key"
    ENV_VARS["OPNSENSE_API_SECRET"]="$opn_secret"
    UPDATED=$((UPDATED + 2))
else
    log "WARN: Could not read OPNsense credentials"
    ((ERRORS++))
fi

# Special: Shopify — refresh access token from client credentials (expires 24h)
shopify_client_id="${ENV_VARS[SHOPIFY_CLIENT_ID]:-}"
shopify_client_secret="${ENV_VARS[SHOPIFY_CLIENT_SECRET]:-}"
shopify_domain="${ENV_VARS[SHOPIFY_STORE_DOMAIN]:-}"
if [ -n "$shopify_client_id" ] && [ -n "$shopify_client_secret" ] && [ -n "$shopify_domain" ]; then
    shopify_token=$(curl -s -X POST "https://${shopify_domain}/admin/oauth/access_token" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "grant_type=client_credentials&client_id=${shopify_client_id}&client_secret=${shopify_client_secret}" \
        2>/dev/null | jq -r '.access_token // empty')
    if [ -n "$shopify_token" ]; then
        ENV_VARS["SHOPIFY_ACCESS_TOKEN"]="$shopify_token"
        UPDATED=$((UPDATED + 1))
        log "Shopify access token refreshed"
    else
        log "WARN: Shopify token refresh failed (credentials may be empty placeholders)"
    fi
else
    log "WARN: Shopify credentials not yet filled in — skipping token refresh"
fi

# Update BW_SESSION (may have changed during unlock)
ENV_VARS["BW_SESSION"]="$BW_SESSION"

# Write new .env file atomically
TMPFILE=$(mktemp "${ENV_FILE}.XXXXXX")
for key in $(echo "${!ENV_VARS[@]}" | tr ' ' '\n' | sort); do
    echo "${key}=${ENV_VARS[$key]}" >> "$TMPFILE"
done
chmod 600 "$TMPFILE"
mv "$TMPFILE" "$ENV_FILE"

log "Sync complete: $UPDATED keys updated, $ERRORS warnings"

# Signal OpenClaw to reload env (hot-reload if supported)
if command -v openclaw >/dev/null 2>&1; then
    openclaw config reload 2>/dev/null && log "OpenClaw config reloaded" || true
fi
