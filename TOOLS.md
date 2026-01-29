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

Add whatever helps you do your job. This is your cheat sheet.
