# MEMORY.md - Long-Term Memory

## Security Policies

### Code Review Policy (2026-02-13)
**Code muss IMMER von Linus reviewed werden bevor er auf dem Server ausgeführt wird.**

- **Sandbox-Ausführung:** OK — Code kann in Sandbox getestet werden
- **Server/Production:** Requires Linus review + approval
- **GitHub Push:** OK — Review passiert vor Deploy
- **Gilt für:** Alle Agents (coder, devops, comms, etc.)

---

## Infrastructure Notes

### Sandbox Configuration
- Dockerfile: `/home/linus/ClawdBot/sandbox/Dockerfile`
- Image: `openclaw-sandbox:bookworm-slim`
- Tools installiert: git, gh, curl, jq, python3, nodejs, npm, build-essential
- **Problem:** `network: "openclaw-isolated"` blockiert GitHub-Zugang
- **Lösung:** `sandbox.mode: "off"` für Agent oder `network: "bridge"`

### Agent Tool Access
- **main** (Telegram/Discord): Kein exec, nur read/write/message
- **coder**: Hat exec (via Sandbox oder mode: off)
- **devops**: sandbox.mode: "off" — voller Zugang
- **comms**: sandbox.mode: "all" — limitiert

### Specialist Agents Routing
| Task | Agent | Model |
|------|-------|-------|
| Code, bugs, scripts | coder | Opus 4.6 |
| Proxmox, Docker, DNS | devops | Opus 4.6 |
| Email, calls, calendar | comms | GPT-5.3 Codex |
| Web research | research | GLM-5 |
| Long docs, Asian languages | kimi | Kimi K2.5 |
| Sensitive data | private | Qwen3 (local) |

---

## Important Files

- Config: `/home/linus/.openclaw/openclaw.json`
- Skills: `/home/linus/clawd/skills/`
- Memory: `/home/linus/clawd/memory/YYYY-MM-DD.md`
- Bitwarden credentials: `/home/linus/.openclaw/.bw-credentials` ⚠️ (should be deleted)
