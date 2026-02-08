#!/bin/bash
# spawn-sandbox-with-github.sh
# Wrapper to spawn sandboxes with ephemeral GitHub SSH keys

set -e

TIMESTAMP=$(date +%s)
KEY_PATH="/tmp/sandbox-key-${TIMESTAMP}"
KEY_TITLE="sandbox-temp-${TIMESTAMP}"

echo "🔑 Generating ephemeral SSH key pair..."
ssh-keygen -t ed25519 -f "${KEY_PATH}" -N "" -C "${KEY_TITLE}" -q

echo "📤 Adding public key to GitHub..."
gh ssh-key add "${KEY_PATH}.pub" --title "${KEY_TITLE}"

echo "🚀 Spawning sandbox with GitHub access..."
echo "   Keys: ${KEY_PATH}"
echo ""

# TODO: Integrate with actual sandbox spawn command
# This will need to:
# 1. Mount ${KEY_PATH} and ${KEY_PATH}.pub in sandbox
# 2. Set GIT_SSH_COMMAND in sandbox environment
# 3. Track sandbox session ID for cleanup

echo "⚠️  MANUAL CLEANUP NEEDED AFTER SANDBOX:"
echo "   gh ssh-key delete \"${KEY_TITLE}\" --yes"
echo "   rm -f ${KEY_PATH} ${KEY_PATH}.pub"
echo ""
echo "   Or run: ./scripts/cleanup-sandbox-key.sh ${TIMESTAMP}"
