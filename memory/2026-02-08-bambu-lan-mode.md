# Session: 2026-02-08 17:44:51 UTC

- **Session Key**: agent:main:main
- **Session ID**: 0a9a7499-b88d-4ab2-a9a7-d524e0b4039c
- **Source**: discord

## Conversation Summary

assistant: ✅ **Installed bambu-cli skill** (v1.0.0)

This skill lets you control and monitor Bambu Lab 3D printers via the `bambu-cli` tool.

**What you can do:**
- 📊 Monitor printer status & watch real-time
- 🖨️ Start/pause/resume/stop prints
- 📁 Upload/download/list files
- 📸 Get camera snapshots
- 🎛️ Control temps, fans, lighting, motion
- 🔧 Send gcode, run calibrations
- ⚙️ Configure printer profiles

**Quick setup:**
```bash
bambu-cli config set --printer <name> --ip <ip> --serial <serial> --access-code-file <path> --default
```

Then use commands like:
- `bambu-cli status`
- `bambu-cli print start file.3mf`
- `bambu-cli camera snapshot --out photo.jpg`

Need help setting up a printer profile or running a specific command?
user: [Discord chefzh user id:248474868595687425 +36m 2026-02-08 18:43 GMT+1] Ah so this skill does not work via cloud. Only in lan mode ?
[message_id: 1470112935895367945]
assistant: Yes, correct! The **bambu-cli** skill only works in **LAN mode** (local network). 

It connects directly to your printer via:
- 🌐 Local IP address
- 🔐 Access code (LAN mode only)
- 📡 MQTT (port 8883), FTPS (port 990), Camera (port 6000)

**No cloud support** — it's designed for local network control only.

---

**Alternative:** When I searched ClawdHub, I also saw **bambu-local** (v1.0.1). Let me check if that one might have different connectivity options:
assistant: **Both skills are LAN-only:**
- ✅ **bambu-cli** — LAN mode (more features, uses bambu-cli binary)
- ✅ **bambu-local** — LAN mode (Python-based, simpler, no cloud)

Neither supports **cloud mode**. They both require:
- Printer on the same local network
- LAN mode enabled on the printer
- Access code from printer settings

---

**For cloud control**, you'd need a different approach (Bambu Lab does have cloud APIs, but these skills don't use them). Would you prefer to:
1. Use LAN mode with these skills (works great if you're home/VPN)
2. Look for a cloud-based solution instead?
