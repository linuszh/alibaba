# Agent Configuration Reference

## Model Routing Strategy

| Agent | Purpose | Model | Why |
|-------|---------|-------|-----|
| gatekeeper | Triage, privacy classification, routing | ollama/qwen3:30b | Local, no data leaves network |
| coder | Coding, GitHub, container creation | anthropic/claude-sonnet-4-5 | Best tool-use for code |
| devops | Proxmox, Dokploy, Docker, OPNsense | anthropic/claude-opus-4-5 | Complex infra reasoning |
| comms | Email, phone, Google Drive | openai/gpt-4o | Good at conversational tasks |
| research | Web search, analysis, documents | zai/glm-4.6 | Strong reasoning, cheap |
| private | Sensitive/personal data | ollama/qwen3:30b | Never leaves network |

## Sandbox Configuration

| Agent | Sandbox Mode | Reason |
|-------|--------------|--------|
| gatekeeper | off | Host access for orchestration |
| coder | all | Docker sandbox IS the security boundary |
| devops | off | Needs host access for infra management |
| comms | all | Sandbox + network bridge for APIs |
| research | all | Sandbox + network bridge for web |
| private | all | Isolated, local-only model |

## Key Principles

### Coder Agent
- **NO tools.allow/deny restrictions** — let it use everything within sandbox
- The Docker sandbox IS the security boundary
- Needs: read/write/edit, exec (git, npm, pip, docker), browser, web_search, grep/find/ls, process, sessions_spawn

### DevOps Agent
- `sandbox.mode: "off"` for host access
- Manages Proxmox, Dokploy, OPNsense, Caddy
- Can spawn coder for code tasks

### Network Requirements
- **coder**: needs `network: "bridge"` for GitHub access
- **comms**: needs `network: "bridge"` for Google API
- **research**: needs `network: "bridge"` for web access
- **private**: `network: "none"` — truly isolated

## Correct Delegation Pattern

```javascript
// CORRECT:
sessions_spawn({
  agentId: "coder",  // The defined agent ID
  label: "task-name",  // Optional tracking label
  task: "Description..."
})

// WRONG:
sessions_spawn({
  label: "coder",  // Just a name, not an agent!
  task: "..."
})
```

## Fallback Strategy

Gatekeeper fallbacks (when Ollama slow):
1. `venice/llama-3.3-70b` — Venice private mode (no logging)
2. `venice/deepseek-v3.2` — Venice private, strong reasoning

## Tool Restrictions by Agent

### comms
```json
"tools": {
  "allow": ["read", "write", "exec", "browser"],
  "deny": ["edit", "apply_patch"]
}
```
- Can read/write files and execute commands
- No edit/apply_patch (comms shouldn't modify code)
- Browser for Google OAuth flows

### research
```json
"tools": {
  "allow": ["read", "write", "exec", "browser"]
}
```
- Web access for research
- Can write reports

### private
```json
"tools": {
  "allow": ["read", "write", "exec"],
  "deny": ["browser"]
}
```
- NO internet access
- Local Ollama only
- For sensitive data processing

## Current Issues to Fix

1. **main/gatekeeper**: Model `venice/zai-org-glm-5` → should be `ollama/qwen3:30b`
2. **coder**: `network: "openclaw-isolated"` → `bridge` for GitHub
3. **comms**: `network: "openclaw-isolated"` → `bridge` for Google API
4. **research**: `network: "openclaw-isolated"` → `bridge` for web
5. **Tool restrictions**: Not defined in current config — should match above

## Skills to Install

```bash
clawdhub install github
clawdhub install docker
clawdhub install tmux
clawdhub install coding-agent
clawdhub install google-workspace
```
