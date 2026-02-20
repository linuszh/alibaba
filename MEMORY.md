# MEMORY.md - Long-Term Memory

## Architecture Decisions

### Two-Bot Design (2026-02-13)
- **Public bots** (Telegram "Clawd" + Discord "Clawd") → Gateway (zai/glm-5) → specialists
- **Private bots** (Telegram "Confidential" + Discord "Venice") → Private Agent directly
- User controls privacy at UX level — no AI classification needed
- Gateway is pure router, NEVER answers questions itself

### Coder Agent Removed (2026-02-13)
- DevOps absorbs all coding tasks via `coding-agent` skill
- **Claude Code is the default** coding tool (not Codex)
- DevOps has host access — can directly spawn Claude Code/Codex in project dirs
- Old coder agent was broken anyway (sandboxed on isolated network, couldn't reach GitHub)

### Gateway Model Change (2026-02-13)
- Changed from ollama/qwen3:30b-a3b to zai/glm-5
- Qwen3 30B was too weak — kept trying to answer instead of delegating
- GLM-5 is strong enough for intelligent routing, cheaper than Venice
- Fallbacks: zai/glm-4.7 → venice/glm-4.7-flash

### Network Fixes (2026-02-13)
- Comms: openclaw-isolated → bridge (needs Google APIs for gogcli)
- Research: openclaw-isolated → bridge (needs web + Google Drive)
- Both now have gogcli installed + gog creds mounted read-only
- Private: stays network:none, Venice.ai fallback handled by OpenClaw host process

---

## Security Policies

### Code Review Policy
**Code must ALWAYS be reviewed by Linus before server execution.**

- **Sandbox execution:** OK — Code can be tested in sandbox
- **Server/Production:** Requires Linus review + approval
- **GitHub Push:** OK — Review happens before deploy
- **Applies to:** All agents (devops, comms, etc.)

---

## Infrastructure Notes

### Agent Configuration
| Agent | Model | Network | Purpose |
|-------|-------|---------|---------|
| gateway (main) | zai/glm-5 | host | Route to specialists, never answer |
| devops | Opus 4.6 | host | Code + infra (coding-agent, proxmox, dokploy, caddy) |
| comms | GPT 5.3 | bridge | Email, calendar, Drive (gogcli, twilio) |
| research | GLM-5 | bridge | Web search, analysis, Drive (gogcli) |
| kimi | Kimi K2.5 | isolated | Long docs, Asian languages |
| private | Qwen3 local (Venice fallback) | none | Sensitive data, finances, health |

### Important Files
- Config: `/home/linus/.openclaw/openclaw.json`
- Skills: `/home/linus/clawd/skills/`
- Memory: `/home/linus/clawd/memory/YYYY-MM-DD.md`
- Env: `/home/linus/.openclaw/.env`
