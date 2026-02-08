# Sandbox GitHub Access Skill

## Purpose
Enable sandboxes to push to GitHub using ephemeral SSH keys that are automatically generated and cleaned up.

## When to Use
Use this workflow when spawning a sandbox that needs to:
- Clone private repositories
- Commit and push changes to GitHub
- Access GitHub via SSH

## How It Works

### Architecture
1. **Pre-spawn:** Generate ephemeral Ed25519 SSH key pair
2. **Pre-spawn:** Add public key to GitHub via `gh ssh-key add`
3. **Spawn:** Launch sandbox session (keys need manual mounting for now)
4. **Post-spawn:** Remove key from GitHub and delete local files

### Security Benefits
- ✅ Keys are session-scoped and ephemeral
- ✅ Automatic cleanup after sandbox completes
- ✅ No long-lived credentials to manage
- ✅ Uses existing `gh` permissions

## Usage

### Step 1: Prepare SSH Keys
```bash
./scripts/sandbox-github-spawn.sh \
  --label "my-task-label" \
  --task "Task description for the sandbox"
```

This will:
- Generate ephemeral SSH key pair
- Add public key to GitHub
- Output a cleanup script path

### Step 2: Spawn Sandbox
Call `sessions_spawn` with your task:
```
sessions_spawn(
  label="my-task-label",
  task="Your task description here. The sandbox has GitHub SSH access configured.",
  agentId="main"
)
```

**⚠️ Current Limitation:** Keys are generated but not automatically mounted in sandbox. Full automation pending Clawdbot core integration.

### Step 3: Cleanup After Completion
After the sandbox session completes:
```bash
# Get cleanup script path
CLEANUP_SCRIPT=$(cat /tmp/sandbox-cleanup-latest.txt)

# Run cleanup
bash "${CLEANUP_SCRIPT}"
```

Or manually:
```bash
# The cleanup script path is printed by sandbox-github-spawn.sh
bash /tmp/sandbox-cleanup-<timestamp>.sh
```

## Example Workflow

```bash
# 1. Generate keys and prepare
./scripts/sandbox-github-spawn.sh \
  --label "workstation-research" \
  --task "Research component pricing and update BuildIdea file"

# 2. Agent calls sessions_spawn (via tool)
# sessions_spawn(label="workstation-research", task="...", agentId="main")

# 3. Wait for sandbox to complete

# 4. Cleanup
CLEANUP_SCRIPT=$(cat /tmp/sandbox-cleanup-latest.txt)
bash "${CLEANUP_SCRIPT}"
```

## Integration Status

### ✅ Completed
- [x] SSH key generation
- [x] GitHub key management (add/remove)
- [x] Cleanup automation
- [x] Integrated spawn script

### 🔧 TODO: Clawdbot Core Integration
The following needs to be implemented in Clawdbot core:

1. **Mount SSH keys in sandbox:**
   - Host: `/tmp/sandbox-key-<timestamp>` → Sandbox: `/root/.ssh/id_ed25519`
   - Host: `/tmp/sandbox-key-<timestamp>.pub` → Sandbox: `/root/.ssh/id_ed25519.pub`

2. **Set environment variable in sandbox:**
   - `GIT_SSH_COMMAND="ssh -i /root/.ssh/id_ed25519 -o StrictHostKeyChecking=accept-new"`

3. **Track cleanup info in session metadata:**
   - Store timestamp/key-path for automatic cleanup on session end

## Alternative: Manual Key Setup

If the integrated script doesn't work, use the manual workflow:

```bash
# Generate key
TIMESTAMP=$(date +%s)
ssh-keygen -t ed25519 -f "/tmp/sandbox-key-${TIMESTAMP}" -N "" -C "sandbox-temp-${TIMESTAMP}"

# Add to GitHub
gh ssh-key add "/tmp/sandbox-key-${TIMESTAMP}.pub" --title "sandbox-temp-${TIMESTAMP}"

# ... spawn sandbox ...

# Cleanup
gh ssh-key delete "sandbox-temp-${TIMESTAMP}" --yes
rm -f "/tmp/sandbox-key-${TIMESTAMP}" "/tmp/sandbox-key-${TIMESTAMP}.pub"
```

## Troubleshooting

### Keys not working in sandbox
- Verify keys were generated: `ls -la /tmp/sandbox-key-*`
- Check GitHub: `gh ssh-key list | grep sandbox-temp`
- Ensure sandbox has keys mounted (currently manual)

### Cleanup fails
- List all sandbox keys: `gh ssh-key list | grep sandbox-temp`
- Manually remove: `gh ssh-key delete "sandbox-temp-<timestamp>" --yes`
- Clean up local files: `rm -f /tmp/sandbox-key-* /tmp/sandbox-cleanup-*`

### Old keys left behind
Clean up all sandbox keys:
```bash
gh ssh-key list | grep "sandbox-temp" | awk '{print $2}' | xargs -I {} gh ssh-key delete {} --yes
```

## References

- **Documentation:** `docs/sandbox-github-workflow.md`
- **Scripts:** 
  - `scripts/sandbox-github-spawn.sh` (integrated wrapper)
  - `scripts/spawn-sandbox-with-github.sh` (legacy pre-spawn)
  - `scripts/cleanup-sandbox-key.sh` (legacy cleanup)
- **Agent guide:** `AGENTS.md` (Sandbox GitHub Access section)

---

*Last updated: 2026-02-08*
