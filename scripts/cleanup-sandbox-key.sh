#!/bin/bash
# cleanup-sandbox-key.sh
# Clean up ephemeral GitHub SSH key after sandbox completes

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <timestamp>"
    echo "Example: $0 1234567890"
    exit 1
fi

TIMESTAMP="$1"
KEY_PATH="/tmp/sandbox-key-${TIMESTAMP}"
KEY_TITLE="sandbox-temp-${TIMESTAMP}"

echo "🧹 Cleaning up sandbox GitHub key..."

# Remove from GitHub
if gh ssh-key list | grep -q "${KEY_TITLE}"; then
    echo "   Removing from GitHub: ${KEY_TITLE}"
    gh ssh-key delete "${KEY_TITLE}" --yes
else
    echo "   ⚠️  Key not found on GitHub (already removed?)"
fi

# Remove local files
if [ -f "${KEY_PATH}" ]; then
    echo "   Removing local key: ${KEY_PATH}"
    rm -f "${KEY_PATH}" "${KEY_PATH}.pub"
else
    echo "   ⚠️  Local key not found (already removed?)"
fi

echo "✅ Cleanup complete!"
