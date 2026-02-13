# OpenClaw Complete Setup Guide

## Container Creation Workflow

When asked: "Create a new web app container for project X and make it available at x.mydomain.ch":

1. **Gatekeeper** (Qwen3 local) classifies: PUBLIC → routes to devops
2. **DevOps** (Claude Opus) orchestrates:
   - If code needs building → spawns coder sub-agent
   - Coder pulls GitHub repo, builds Docker image, pushes to registry
   - DevOps calls Dokploy API to create + deploy the container
   - DevOps queries Dokploy for container's internal IP:port
   - DevOps calls OPNsense Caddy API to add reverse proxy route:
     - `x.mydomain.ch` → container-ip:port (with TLS via Let's Encrypt)
   - DevOps calls OPNsense Caddy reconfigure to apply changes
   - Reports back: "Container deployed, accessible at https://x.mydomain.ch"

**Split:** Dokploy = container lifecycle, OPNsense Caddy = domain routing + TLS

---

## Environment Variables

Create `~/.openclaw/.env` or set in systemd service:

```bash
# LLM Providers
ANTHROPIC_API_KEY=sk-ant-...
OPENAI_API_KEY=sk-...
MOONSHOT_API_KEY=sk-...
ZHIPU_API_KEY=...
VENICE_API_KEY=vapi_...

# Infrastructure
PROXMOX_API_URL=https://proxmox.local:8006
PROXMOX_API_TOKEN=root@pam!openclaw=<secret>
DOKPLOY_API_URL=https://dokploy.your-domain.ch
DOKPLOY_API_TOKEN=...
OPNSENSE_API_URL=https://opnsense.local
OPNSENSE_API_KEY=...
OPNSENSE_API_SECRET=...

# Communications
TWILIO_ACCOUNT_SID=...
TWILIO_AUTH_TOKEN=...
TWILIO_PHONE_NUMBER=+1...
GOG_KEYRING_PASSWORD=...
GOG_ACCOUNT=your@email.com
```

---

## Systemd Service

```ini
[Unit]
Description=OpenClaw Gateway
After=network.target docker.service

[Service]
Type=simple
User=openclaw
WorkingDirectory=/home/openclaw/.openclaw
ExecStart=/home/openclaw/.npm-global/bin/openclaw gateway start --foreground
Restart=always
RestartSec=10
EnvironmentFile=/home/openclaw/.openclaw/.env
Environment=PATH=/home/openclaw/.npm-global/bin:/usr/local/bin:/usr/bin:/bin

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable openclaw-gateway
sudo systemctl start openclaw-gateway
```

---

## Validation & Testing

```bash
# Validate config
openclaw doctor
openclaw doctor --fix  # Auto-fix schema issues

# Check model connectivity
openclaw models probe

# List configured agents
openclaw agents list

# Test via TUI
openclaw chat
```

### Test Messages

| Message | Expected Flow |
|---------|---------------|
| "What VMs are running on Proxmox?" | gatekeeper → devops |
| "Send an email to X about Y" | gatekeeper → comms |
| "Deploy my GitHub repo X as a container" | gatekeeper → devops + coder |
| "Analyze my tax documents" | gatekeeper → private (stays local) |
| "Research the latest Qwen models" | gatekeeper → research |

---

## Model Selection Rationale

| Task Type | Model | Reasoning |
|-----------|-------|-----------|
| Triage / privacy check | Qwen3 30B (local) | Zero latency, zero cost, no data leak |
| Gatekeeper fallback 1 | Venice Llama 3.3 70B | Private mode: ephemeral, no logging, no training |
| Gatekeeper fallback 2 | Venice DeepSeek V3.2 | Private mode: strong reasoning, no logging |
| Complex coding | Claude Sonnet 4.5 | Best tool-use, fast |
| Infrastructure reasoning | Claude Opus 4.5 | Deep reasoning for multi-step ops |
| Email/Calendar/Drive | GPT-4o | Strong at structured comms tasks |
| Research & analysis | Z.AI GLM-4.6 | 200k context, good reasoning, affordable |
| Private data | Qwen3 30B (local) | Data never leaves network |
| Heartbeats / status | Qwen3 30B (local) | Free, no API cost waste |
| Long-context coding | Moonshot Kimi K2.5 | 131k context, strong at code |

---

## Venice Privacy Modes

Venice offers two distinct privacy levels — ideal for gatekeeper fallback:

| Mode | How it works | Models |
|------|--------------|--------|
| **Private** | Prompts/responses never stored or logged. Fully ephemeral. Venice cannot see your data. | Llama 3.3 70B, DeepSeek V3.2, Qwen3, Venice Uncensored, etc. (15 models) |
| **Anonymized** | Proxied through Venice with metadata stripped. Underlying provider sees anonymized requests but not your identity. | Various |

---

## Channel Bindings

```json
{
  "bindings": [
    { "agentId": "gatekeeper", "match": { "channel": "telegram", "accountId": "main" } },
    { "agentId": "gatekeeper", "match": { "channel": "discord" } }
  ]
}
```

---

## Complete Workflow Summary

```
User Request
     │
     ▼
┌─────────────────┐
│   GATEKEEPER    │ ◄── Qwen3 30B (local)
│ Classify & Route│
└────────┬────────┘
         │
    ┌────┴────┬─────────┬──────────┬──────────┐
    ▼         ▼         ▼          ▼          ▼
┌───────┐ ┌───────┐ ┌───────┐ ┌────────┐ ┌────────┐
│ CODER │ │DEVOPS │ │ COMMS │ │RESEARCH│ │PRIVATE │
│Sonnet │ │ Opus  │ │ GPT-4o│ │ GLM-4.6│ │ Qwen3  │
└───────┘ └───┬───┘ └───────┘ └────────┘ └────────┘
              │
              ▼
    ┌─────────────────────────────┐
    │       INFRASTRUCTURE        │
    │  Proxmox │ Dokploy │ Caddy  │
    └─────────────────────────────┘
```
