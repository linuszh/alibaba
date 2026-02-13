# Custom Skills Reference

## Proxmox Skill (Read-Only)

**Location:** `~/.openclaw/skills/proxmox/SKILL.md`

**Environment:**
- `PROXMOX_API_URL`: e.g., https://proxmox.local:8006
- `PROXMOX_API_TOKEN`: format USER@REALM!TOKENID=SECRET

**Operations:**

```bash
# List all VMs/CTs
curl -sk -H "Authorization: PVEAPIToken=${PROXMOX_API_TOKEN}" \
  "${PROXMOX_API_URL}/api2/json/cluster/resources?type=vm" | jq '.data'

# Get VM status
curl -sk -H "Authorization: PVEAPIToken=${PROXMOX_API_TOKEN}" \
  "${PROXMOX_API_URL}/api2/json/nodes/{node}/qemu/{vmid}/status/current" | jq '.data'

# Get node status
curl -sk -H "Authorization: PVEAPIToken=${PROXMOX_API_TOKEN}" \
  "${PROXMOX_API_URL}/api2/json/nodes/{node}/status" | jq '.data'

# List storage
curl -sk -H "Authorization: PVEAPIToken=${PROXMOX_API_TOKEN}" \
  "${PROXMOX_API_URL}/api2/json/storage" | jq '.data'
```

**Rules:**
- READ-ONLY access. Never POST/PUT/DELETE
- Always verify node name before querying

---

## Dokploy Skill (Docker Deployment)

**Location:** `~/.openclaw/skills/dokploy/SKILL.md`

**Environment:**
- `DOKPLOY_API_URL`: e.g., https://dokploy.your-domain.ch
- `DOKPLOY_API_TOKEN`: Get from Dokploy dashboard → Settings → API

**Important:** Dokploy does NOT manage domains or TLS. All reverse proxy / domain routing is handled by OPNsense's Caddy plugin.

### Workflow: Deploy a Container

```bash
# 1. Create a project (if needed)
curl -s -X POST "${DOKPLOY_API_URL}/api/project.create" \
  -H "Authorization: Bearer ${DOKPLOY_API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"name": "my-project", "description": "Created by OpenClaw"}' | jq

# 2. Create a service from Docker image
curl -s -X POST "${DOKPLOY_API_URL}/api/application.create" \
  -H "Authorization: Bearer ${DOKPLOY_API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "my-app",
    "projectId": "<project-id>",
    "sourceType": "docker",
    "dockerImage": "nginx:latest"
  }' | jq

# 3. Deploy
curl -s -X POST "${DOKPLOY_API_URL}/api/application.deploy" \
  -H "Authorization: Bearer ${DOKPLOY_API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"applicationId": "<app-id>"}' | jq

# 4. Get the container's internal IP/port
curl -s "${DOKPLOY_API_URL}/api/application.one?applicationId=<app-id>" \
  -H "Authorization: Bearer ${DOKPLOY_API_TOKEN}" | jq '.ports, .applicationStatus'
```

### From GitHub Repo

```bash
curl -s -X POST "${DOKPLOY_API_URL}/api/application.create" \
  -H "Authorization: Bearer ${DOKPLOY_API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "my-app",
    "projectId": "<project-id>",
    "sourceType": "github",
    "repository": "https://github.com/lini1990/my-repo",
    "branch": "main",
    "buildType": "dockerfile"
  }' | jq
```

### List running services

```bash
curl -s "${DOKPLOY_API_URL}/api/application.all" \
  -H "Authorization: Bearer ${DOKPLOY_API_TOKEN}" | jq '.[].name'
```

**Rules:**
- Always confirm with user before deploying new services
- Use descriptive project/service names
- After deployment, note internal IP:port and coordinate with opnsense-caddy skill
- Never attempt to configure domains through Dokploy

---

## OPNsense Caddy Skill

**Location:** `~/.openclaw/skills/opnsense-caddy/SKILL.md`

**Environment:**
- `OPNSENSE_API_URL`: e.g., https://opnsense.local
- `OPNSENSE_API_KEY`: API key from OPNsense
- `OPNSENSE_API_SECRET`: API secret

**Authentication:**
```bash
OPNSENSE_AUTH="${OPNSENSE_API_KEY}:${OPNSENSE_API_SECRET}"
```

### Add a Reverse Proxy Route

```bash
# 1. Search existing handlers
curl -sk -u "${OPNSENSE_AUTH}" \
  "${OPNSENSE_API_URL}/api/caddy/ReverseProxy/searchHandler" | jq

# 2. Add new handler
curl -sk -u "${OPNSENSE_AUTH}" -X POST \
  "${OPNSENSE_API_URL}/api/caddy/ReverseProxy/addHandler" \
  -H "Content-Type: application/json" \
  -d '{
    "handler": {
      "FromDomain": "myapp.your-domain.ch",
      "FromPort": "443",
      "ToDomain": "192.168.1.x",
      "ToPort": "8080",
      "HttpTls": "1",
      "Description": "Created by OpenClaw"
    }
  }' | jq

# 3. Apply changes
curl -sk -u "${OPNSENSE_AUTH}" -X POST \
  "${OPNSENSE_API_URL}/api/caddy/service/reconfigure" | jq
```

**Rules:**
- Always apply (reconfigure) after making changes
- Verify route doesn't already exist before adding
- Default to TLS enabled

---

## Communication Setup

### Google Workspace (Gmail, Calendar, Drive)

**Install GOG:**
```bash
sudo snap install go --classic
git clone https://github.com/steipete/gogcli.git
cd gogcli && make build
sudo cp bin/gog /usr/local/bin/
```

**Configure:**
```bash
gog auth login --scopes gmail,calendar,drive
```

**Systemd environment:**
```
Environment=GOG_KEYRING_PASSWORD=<your-password>
Environment=GOG_ACCOUNT=<your-email>
```

### Twilio (Phone/SMS)

**Environment:**
- `TWILIO_ACCOUNT_SID`
- `TWILIO_AUTH_TOKEN`
- `TWILIO_PHONE_NUMBER`

**Send SMS:**
```bash
curl -X POST "https://api.twilio.com/2010-04-01/Accounts/${TWILIO_ACCOUNT_SID}/Messages.json" \
  -u "${TWILIO_ACCOUNT_SID}:${TWILIO_AUTH_TOKEN}" \
  -d "Body=Your message here" \
  -d "From=${TWILIO_PHONE_NUMBER}" \
  -d "To=+41XXXXXXXXX"
```

**Rules:**
- Always confirm before sending SMS or making calls
- Log all outbound communications

---

## Channel Bindings

Map messaging channels to gatekeeper:

```json
{
  "channels": {
    "telegram": {
      "accounts": {
        "main": { "token": "<TELEGRAM_BOT_TOKEN>" }
      },
      "allowFrom": ["<your-telegram-id>"]
    }
  },
  "bindings": [
    { "agentId": "gatekeeper", "match": { "channel": "telegram" } },
    { "agentId": "gatekeeper", "match": { "channel": "discord" } }
  ]
}
```

When asked to create and deploy a new service:

1. **coder** builds the code (if needed)
2. **devops** creates Dokploy deployment
3. **devops** configures Caddy route via OPNsense
4. Report back with live URL

The division of labor:
- **coder**: Code, Dockerfile, build
- **devops**: Infrastructure, deployment, routing
