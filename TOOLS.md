# TOOLS.md - Local Notes

Skills define *how* tools work. This file is for *your* specifics — the stuff that's unique to your setup.

## What Goes Here

Things like:
- Camera names and locations
- SSH hosts and aliases  
- Preferred voices for TTS
- Speaker/room names
- Device nicknames
- Anything environment-specific

## Examples

```markdown
### Cameras
- living-room → Main area, 180° wide angle
- front-door → Entrance, motion-triggered

### SSH
- home-server → 192.168.1.100, user: admin

### TTS
- Preferred voice: "Nova" (warm, slightly British)
- Default speaker: Kitchen HomePod
```

## Why Separate?

Skills are shared. Your setup is yours. Keeping them apart means you can update skills without losing your notes, and share skills without leaking your infrastructure.

---

### Voice Calls
⚠️ **MANDATORY**: Before ANY voice call, check `voice-call-guard` skill.
- NEVER call emergency numbers (911, 112, 117, 118, 144, etc.)
- NEVER call short codes (< 7 digits)
- Always validate E.164 format (+countrycode...)
- Twilio/Telnyx will ban the account for emergency calls

**System validators** (belt + suspenders + duct tape):
```bash
# Bash validator
./scripts/voice-call-validator.sh "+41791234567"

# Node.js validator
node scripts/voice-call-validator.js "+41791234567"
```

Always run validator before executing any call command.

---

### Speech-to-Text (STT) / Transcription
**Default preference: Local Whisper CLI**

When transcribing audio files:
- **Always use local Whisper** by default (`whisper` command)
- Model preference: `turbo` (best balance of speed/accuracy)
- Only use cloud APIs (OpenAI Whisper API, Deepgram, etc.) when explicitly requested
- Local Whisper protects privacy and has no API costs

Command:
```bash
whisper /path/to/audio.ogg --model turbo --output_format txt --output_dir /tmp
```

---

### Sandbox Environment

When running in a sandbox (group chats, channels), you're inside a Docker container with these constraints:

**What's available (pre-installed in the image):**
- git, curl, wget, jq, ripgrep
- python3, pip, python3-venv
- nodejs 18, npm 9
- build-essential (gcc, g++, make)

**What you CANNOT do:**
- `apt-get install` — will fail with "Operation not permitted" (capabilities are dropped for security)
- Access host config files — `/home/linus/.clawdbot/` is NOT mounted. You only have `/workspace/`
- Install system packages at runtime — all tools must be baked into the Docker image

**If you need a tool that's not installed:**
- Tell the user: "This tool isn't in the sandbox image. Ask me in a DM (unsandboxed) to add it, or have Claude Code update the Dockerfile at `/home/linus/ClawdBot/sandbox/Dockerfile` and run `./sandbox/build.sh`."
- Do NOT try `apt-get` — it will always fail in the sandbox

**pip/npm work fine:**
- `python3 -m venv /tmp/myenv && /tmp/myenv/bin/pip install <package>` — works
- `npm install <package>` — works
- These don't need system capabilities

**Config changes:**
- You cannot read or edit `clawdbot.json` from inside the sandbox
- If you need config changes, tell the user to make them via Claude Code or DM

---

### TTS (ElevenLabs)
- Preferred voice ID: `N8RXoLEWQWUCCrT8uDK7`

---

Add whatever helps you do your job. This is your cheat sheet.
