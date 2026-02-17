# Claude Code Notify

**Get notified on your Mac, iPhone, and Apple Watch when Claude Code needs your input.**

When running Claude Code in autonomous mode (YOLO mode), tasks can take minutes to complete. Instead of staring at the terminal, this setup sends push notifications to all your Apple devices — so you can walk away and get pinged the moment Claude needs a decision.

## How It Works

```
Claude Code needs your input
  │
  ├──→ terminal-notifier  →  macOS Notification Center  →  Mac banner + sound
  │
  ├──→ ntfy.sh (HTTP POST) →  ntfy server  →  ntfy app  →  iPhone  →  Apple Watch
  │
  └──→ Claude Code hook    →  plays custom sound via afplay
```

Three independent notification channels ensure you never miss a prompt:

| Channel | Reaches | Latency | Requires |
|---------|---------|---------|----------|
| `terminal-notifier` | Mac | Instant | macOS |
| `ntfy.sh` | iPhone + Apple Watch | ~1-3s | ntfy app installed |
| Hook sound (`afplay`) | Mac speakers | Instant | Audio file |

## Prerequisites

- macOS (Apple Silicon or Intel)
- [Homebrew](https://brew.sh/)
- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) installed
- iPhone with [ntfy app](https://apps.apple.com/app/ntfy/id1625396347) (optional but recommended)
- Apple Watch paired with iPhone (optional)

## Quick Start

```bash
# 1. Clone the repo
git clone https://github.com/mingrath/claude-code-notify.git
cd claude-code-notify

# 2. Run the setup script
chmod +x setup.sh
./setup.sh

# 3. Follow the prompts to configure your ntfy topic name
```

Or set it up manually — see below.

## Manual Setup

### Step 1: Install terminal-notifier

```bash
brew install terminal-notifier
```

Verify it works:

```bash
terminal-notifier -title "Test" -message "Hello from terminal!" -sound default
```

You should see a macOS notification banner.

### Step 2: Set Up ntfy.sh

[ntfy.sh](https://ntfy.sh) is a free, open-source push notification service. No account required.

**Install the CLI (optional, for testing):**

```bash
brew install ntfy
```

**Choose a unique topic name:**

Your topic name acts like a private channel. Pick something unique and hard to guess:

```bash
# Good: includes your name + random suffix
MY_TOPIC="yourname-claude-notify-x7k2"

# Bad: too generic, anyone could subscribe
MY_TOPIC="claude-notifications"
```

**Test it:**

```bash
# Terminal 1: Subscribe (or just open the topic in the ntfy app)
ntfy subscribe $MY_TOPIC

# Terminal 2: Send a test message
curl -d "Hello from Claude Code!" ntfy.sh/$MY_TOPIC
```

**Install the ntfy app on your phone:**

1. Install [ntfy for iOS](https://apps.apple.com/app/ntfy/id1625396347) or [ntfy for Android](https://play.google.com/store/apps/details?id=io.heckel.ntfy)
2. Open the app and tap **+** to subscribe
3. Enter your topic name (e.g., `yourname-claude-notify-x7k2`)
4. Enable notifications when prompted
5. If you have an Apple Watch, notifications will automatically mirror from iPhone

### Step 3: Configure Claude Code CLAUDE.md

Add this to your global `~/.claude/CLAUDE.md`:

````markdown
## Notifications

Whenever you need my decision or input, notify me via terminal-notifier before asking. If ntfy is available (Apple Watch), also send to ntfy.

```bash
terminal-notifier -title "Claude Code" -message "Your input is needed" -sound default && curl -s -d "Claude Code needs your input" ntfy.sh/YOUR_TOPIC_NAME > /dev/null 2>&1
```
````

> Replace `YOUR_TOPIC_NAME` with your chosen ntfy topic.

This tells Claude to run the notification command every time it needs your input.

### Step 4: Add Sound Hooks (Optional)

Claude Code supports [hooks](https://docs.anthropic.com/en/docs/claude-code/hooks) — shell commands that fire on specific events. Add audio cues so you hear when Claude needs you or finishes a task.

**Prepare sound files:**

```bash
mkdir -p ~/.claude/sounds

# Use macOS built-in sounds, or add your own .mp3/.wav files
# Example: copy system sounds
cp /System/Library/Sounds/Ping.aiff ~/.claude/sounds/need-human.aiff
cp /System/Library/Sounds/Glass.aiff ~/.claude/sounds/finish.aiff
```

**Add hooks to `~/.claude/settings.json`:**

```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "afplay -v 0.3 '$HOME/.claude/sounds/need-human.aiff'"
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "afplay -v 0.3 '$HOME/.claude/sounds/finish.aiff'"
          }
        ]
      }
    ]
  }
}
```

| Hook | Fires When | Purpose |
|------|------------|---------|
| `Notification` | Claude needs your input | Alert sound so you look at the terminal |
| `Stop` | Claude finishes a task | Completion chime |

> `afplay` is built into macOS. The `-v` flag controls volume (0.0 to 1.0).

### Step 5: Grant Permissions

Add `terminal-notifier` to your allowed commands in `~/.claude/settings.local.json`:

```json
{
  "permissions": {
    "allow": [
      "Bash(terminal-notifier:*)"
    ]
  }
}
```

This prevents Claude Code from prompting you to approve every notification command.

## Full Configuration Reference

Here's the complete setup across all config files:

```
~/.claude/
├── CLAUDE.md                 # Notification instructions for Claude
├── settings.json             # Hooks (sound effects on events)
├── settings.local.json       # Permission grants
└── sounds/
    ├── need-human.aiff       # Played on Notification hook
    └── finish.aiff           # Played on Stop hook
```

## How It Looks in Practice

```
$ claude

> Claude is working autonomously...
> [10 minutes pass, you're making coffee]
>
> 🔔 Mac: notification banner pops up
> 🔔 iPhone: push notification from ntfy
> 🔔 Apple Watch: tap on wrist
> 🔊 Mac: plays alert sound
>
> You walk back and see:
> "I've completed the refactor but need your input on
>  the database migration strategy. Should I..."
```

## Security Notes

- **ntfy topics are public by default.** Anyone who knows your topic name can subscribe to it. Use a hard-to-guess name, or [self-host ntfy](https://docs.ntfy.sh/install/) for private use.
- **No sensitive data is sent.** The notification message is generic ("Claude Code needs your input") and doesn't include code or context.
- **terminal-notifier is local only.** Desktop notifications never leave your machine.

## Self-Hosting ntfy (Optional)

For maximum privacy, run your own ntfy server:

```bash
# Using Docker
docker run -p 8080:80 binwiederhier/ntfy serve

# Update your CLAUDE.md to use your server
# curl -d "message" http://localhost:8080/your-topic
```

See the [ntfy self-hosting docs](https://docs.ntfy.sh/install/) for full setup instructions.

## Troubleshooting

### Notifications not showing on Mac

```bash
# Check terminal-notifier is installed
which terminal-notifier

# Check macOS notification permissions
# System Settings → Notifications → terminal-notifier → Allow Notifications
```

### ntfy not reaching iPhone

```bash
# Test the topic directly
curl -d "test" ntfy.sh/your-topic-name

# Check the ntfy app:
# - Is the topic name correct?
# - Are notifications enabled for the ntfy app?
# - Is Do Not Disturb off?
```

### No sound playing

```bash
# Test afplay manually
afplay -v 0.3 /System/Library/Sounds/Ping.aiff

# Check your sound file exists
ls -la ~/.claude/sounds/
```

### Apple Watch not getting notifications

- Ensure the ntfy app is installed on iPhone (not just Watch)
- Check iPhone → Watch app → Notifications → ntfy is enabled
- Apple Watch only shows notifications when iPhone is locked

## Credits

- [terminal-notifier](https://github.com/julienXX/terminal-notifier) by Julien Blanchard
- [ntfy.sh](https://ntfy.sh) by Philipp C. Heckel
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) by Anthropic

## License

MIT
