#!/bin/bash
# sandbox-github-spawn.sh
# Integrated wrapper for spawning sandboxes with ephemeral GitHub SSH keys

set -e

usage() {
    cat << EOF
Usage: $0 --label <label> --task <task> [options]

Required:
  --label <label>       Session label for the sandbox
  --task <task>         Task description for the sandbox

Optional:
  --agent <agent>       Agent ID (default: main)
  --model <model>       Model to use
  --timeout <seconds>   Timeout in seconds
  --cleanup             Cleanup mode (default: keep)

Example:
  $0 --label "my-task" --task "Research pricing for components"
EOF
    exit 1
}

# Parse arguments
LABEL=""
TASK=""
AGENT="main"
MODEL=""
TIMEOUT=""
CLEANUP="keep"

while [[ $# -gt 0 ]]; do
    case $1 in
        --label)
            LABEL="$2"
            shift 2
            ;;
        --task)
            TASK="$2"
            shift 2
            ;;
        --agent)
            AGENT="$2"
            shift 2
            ;;
        --model)
            MODEL="$2"
            shift 2
            ;;
        --timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        --cleanup)
            CLEANUP="$2"
            shift 2
            ;;
        --help|-h)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

if [ -z "$LABEL" ] || [ -z "$TASK" ]; then
    echo "Error: --label and --task are required"
    usage
fi

# Generate timestamp and key
TIMESTAMP=$(date +%s)
KEY_PATH="/tmp/sandbox-key-${TIMESTAMP}"
KEY_TITLE="sandbox-temp-${TIMESTAMP}"

echo "🔑 Generating ephemeral SSH key pair..."
ssh-keygen -t ed25519 -f "${KEY_PATH}" -N "" -C "${KEY_TITLE}" -q

echo "📤 Adding public key to GitHub..."
gh ssh-key add "${KEY_PATH}.pub" --title "${KEY_TITLE}"

echo ""
echo "✅ GitHub SSH key ready!"
echo "   Key: ${KEY_PATH}"
echo "   GitHub title: ${KEY_TITLE}"
echo ""

# Save cleanup info for later
CLEANUP_INFO="/tmp/sandbox-cleanup-${TIMESTAMP}.sh"
cat > "${CLEANUP_INFO}" << EOF
#!/bin/bash
# Auto-generated cleanup script for sandbox session

echo "🧹 Cleaning up sandbox GitHub key..."

if gh ssh-key list | grep -q "${KEY_TITLE}"; then
    echo "   Removing from GitHub: ${KEY_TITLE}"
    gh ssh-key delete "${KEY_TITLE}" --yes
else
    echo "   ⚠️  Key not found on GitHub (already removed?)"
fi

if [ -f "${KEY_PATH}" ]; then
    echo "   Removing local key files..."
    rm -f "${KEY_PATH}" "${KEY_PATH}.pub"
else
    echo "   ⚠️  Local key files not found (already removed?)"
fi

rm -f "${CLEANUP_INFO}"
echo "✅ Cleanup complete!"
EOF
chmod +x "${CLEANUP_INFO}"

echo "⚠️  IMPORTANT: Sandbox keys are ready but mounting not yet automated!"
echo ""
echo "📋 TODO for Clawdbot agent:"
echo "   1. Call sessions_spawn with:"
echo "      - label: ${LABEL}"
echo "      - task: ${TASK}"
echo "      - agentId: ${AGENT}"
echo ""
echo "   2. Sandbox needs these keys mounted (manual for now):"
echo "      Host: ${KEY_PATH} → Sandbox: /root/.ssh/id_ed25519"
echo "      Host: ${KEY_PATH}.pub → Sandbox: /root/.ssh/id_ed25519.pub"
echo ""
echo "   3. Sandbox needs env var:"
echo "      GIT_SSH_COMMAND=\"ssh -i /root/.ssh/id_ed25519 -o StrictHostKeyChecking=accept-new\""
echo ""
echo "   4. After sandbox completes, run cleanup:"
echo "      ${CLEANUP_INFO}"
echo ""
echo "🔧 Full automation pending Clawdbot core integration."

# Store cleanup path for agent to retrieve
echo "${CLEANUP_INFO}" > "/tmp/sandbox-cleanup-latest.txt"
echo ""
echo "💾 Cleanup script saved: ${CLEANUP_INFO}"
echo "   (Also available at: /tmp/sandbox-cleanup-latest.txt)"
