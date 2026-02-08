# Sandbox GitHub Access Workflow

## Overview
Enable sandboxes to push to GitHub using ephemeral SSH keys that are created per-session and automatically cleaned up.

## Architecture

**Problem:** Sandboxes have read-only workspace access and can't push to GitHub.

**Solution:** Generate temporary Ed25519 SSH key pairs for each sandbox session:
1. Main session generates ephemeral key pair
2. Adds public key to GitHub via `gh ssh-key add`
3. Mounts keys in sandbox environment
4. Sandbox can push to GitHub using the temporary key
5. Main session removes key from GitHub after sandbox completes

## Implementation Status

### ✅ Completed
- [x] Key generation script
- [x] Cleanup script
- [x] Documentation

### 🔧 TODO: Integration with sessions_spawn
The following needs to be implemented in Clawdbot core or as a wrapper:

1. **Before spawning sandbox:**
   ```bash
   TIMESTAMP=$(date +%s)
   ssh-keygen -t ed25519 -f "/tmp/sandbox-key-${TIMESTAMP}" -N "" -C "sandbox-temp-${TIMESTAMP}"
   gh ssh-key add "/tmp/sandbox-key-${TIMESTAMP}.pub" --title "sandbox-temp-${TIMESTAMP}"
   ```

2. **During sandbox spawn:**
   - Mount `/tmp/sandbox-key-${TIMESTAMP}` → `/root/.ssh/id_ed25519` in sandbox
   - Mount `/tmp/sandbox-key-${TIMESTAMP}.pub` → `/root/.ssh/id_ed25519.pub` in sandbox
   - Set env: `GIT_SSH_COMMAND="ssh -i /root/.ssh/id_ed25519 -o StrictHostKeyChecking=accept-new"`
   - Track `TIMESTAMP` in session metadata for cleanup

3. **After sandbox completes:**
   ```bash
   gh ssh-key delete "sandbox-temp-${TIMESTAMP}" --yes
   rm -f "/tmp/sandbox-key-${TIMESTAMP}" "/tmp/sandbox-key-${TIMESTAMP}.pub"
   ```

## Manual Workflow (Until Automated)

### Before spawning sandbox:
```bash
./scripts/spawn-sandbox-with-github.sh
# Note the timestamp for cleanup
```

### After sandbox completes:
```bash
./scripts/cleanup-sandbox-key.sh <timestamp>
```

## Scripts

- **`scripts/spawn-sandbox-with-github.sh`** - Generate key and add to GitHub
- **`scripts/cleanup-sandbox-key.sh`** - Remove key from GitHub and local system

## Security Benefits

✅ **Ephemeral credentials** - Keys exist only for the duration of the sandbox session  
✅ **Automatic cleanup** - No long-lived credentials to manage  
✅ **Scoped access** - Uses existing `gh` permissions, no new PATs  
✅ **Audit trail** - Key titles include timestamp for tracking  

## Example Usage

```bash
# Generate key
TIMESTAMP=$(date +%s)
ssh-keygen -t ed25519 -f "/tmp/sandbox-key-${TIMESTAMP}" -N "" -C "sandbox-temp-${TIMESTAMP}"
gh ssh-key add "/tmp/sandbox-key-${TIMESTAMP}.pub" --title "sandbox-temp-${TIMESTAMP}"

# Spawn sandbox (manual for now - needs clawdbot integration)
# ... pass keys to sandbox somehow ...

# Cleanup
gh ssh-key delete "sandbox-temp-${TIMESTAMP}" --yes
rm -f "/tmp/sandbox-key-${TIMESTAMP}" "/tmp/sandbox-key-${TIMESTAMP}.pub"
```

## Next Steps

1. **Immediate:** Document manual workflow for agent to follow
2. **Short-term:** Create wrapper skill that agent uses before `sessions_spawn`
3. **Long-term:** Integrate into Clawdbot core sandbox spawn mechanism

---

*Created: 2026-02-08*
