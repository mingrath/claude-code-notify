#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo ""
echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Claude Code Notify - Setup Script    ║${NC}"
echo -e "${BLUE}║  Mac + iPhone + Apple Watch Notifications ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
echo ""

# ─── Check Homebrew ──────────────────────────────────────────────────────────

if ! command -v brew &> /dev/null; then
    echo -e "${RED}Homebrew is not installed.${NC}"
    echo "Install it from https://brew.sh/ and re-run this script."
    exit 1
fi

# ─── Install terminal-notifier ───────────────────────────────────────────────

echo -e "${YELLOW}[1/5] Checking terminal-notifier...${NC}"
if command -v terminal-notifier &> /dev/null; then
    echo -e "  ${GREEN}Already installed:${NC} $(terminal-notifier -version 2>/dev/null || echo 'OK')"
else
    echo "  Installing terminal-notifier via Homebrew..."
    brew install terminal-notifier
    echo -e "  ${GREEN}Installed!${NC}"
fi

# ─── Install ntfy (optional CLI) ────────────────────────────────────────────

echo ""
echo -e "${YELLOW}[2/5] Checking ntfy CLI...${NC}"
if command -v ntfy &> /dev/null; then
    echo -e "  ${GREEN}Already installed:${NC} $(ntfy --version 2>/dev/null || echo 'OK')"
else
    echo "  Installing ntfy via Homebrew..."
    brew install ntfy
    echo -e "  ${GREEN}Installed!${NC}"
fi

# ─── Configure ntfy topic ───────────────────────────────────────────────────

echo ""
echo -e "${YELLOW}[3/5] Configure your ntfy topic...${NC}"
echo ""
echo "  Your ntfy topic is like a private channel for notifications."
echo "  Pick a unique name that's hard to guess."
echo ""

# Generate a suggestion
SUGGESTED_TOPIC="$(whoami)-claude-notify-$(LC_ALL=C tr -dc 'a-z0-9' < /dev/urandom | head -c 4)"
echo -e "  Suggested: ${GREEN}${SUGGESTED_TOPIC}${NC}"
echo ""
read -p "  Enter your topic name (or press Enter for suggested): " TOPIC_NAME
TOPIC_NAME=${TOPIC_NAME:-$SUGGESTED_TOPIC}

echo ""
echo -e "  ${GREEN}Topic set to:${NC} ${TOPIC_NAME}"
echo -e "  ${BLUE}URL:${NC} https://ntfy.sh/${TOPIC_NAME}"

# Test the topic
echo ""
echo "  Sending test notification..."
curl -s -d "Claude Code Notify setup test" "ntfy.sh/${TOPIC_NAME}" > /dev/null 2>&1
echo -e "  ${GREEN}Sent!${NC} Check your ntfy app to verify."

# ─── Set up sound files ─────────────────────────────────────────────────────

echo ""
echo -e "${YELLOW}[4/5] Setting up notification sounds...${NC}"
SOUND_DIR="$HOME/.claude/sounds"
mkdir -p "$SOUND_DIR"

if [ ! -f "$SOUND_DIR/need-human.aiff" ]; then
    cp /System/Library/Sounds/Ping.aiff "$SOUND_DIR/need-human.aiff"
    echo -e "  ${GREEN}Created:${NC} $SOUND_DIR/need-human.aiff"
else
    echo -e "  ${GREEN}Exists:${NC} $SOUND_DIR/need-human.aiff"
fi

if [ ! -f "$SOUND_DIR/finish.aiff" ]; then
    cp /System/Library/Sounds/Glass.aiff "$SOUND_DIR/finish.aiff"
    echo -e "  ${GREEN}Created:${NC} $SOUND_DIR/finish.aiff"
else
    echo -e "  ${GREEN}Exists:${NC} $SOUND_DIR/finish.aiff"
fi

# ─── Generate config snippets ───────────────────────────────────────────────

echo ""
echo -e "${YELLOW}[5/5] Generating configuration...${NC}"

CONFIG_DIR="$(pwd)/generated-config"
mkdir -p "$CONFIG_DIR"

# CLAUDE.md snippet
cat > "$CONFIG_DIR/CLAUDE.md.snippet" << HEREDOC
## Notifications

Whenever you need my decision or input, notify me via terminal-notifier before asking. If ntfy is available (Apple Watch), also send to ntfy.

\`\`\`bash
terminal-notifier -title "Claude Code" -message "Your input is needed" -sound default && curl -s -d "Claude Code needs your input" ntfy.sh/${TOPIC_NAME} > /dev/null 2>&1
\`\`\`
HEREDOC

# settings.json hooks snippet
cat > "$CONFIG_DIR/settings-hooks.json" << HEREDOC
{
  "hooks": {
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "afplay -v 0.3 '\$HOME/.claude/sounds/need-human.aiff'"
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
            "command": "afplay -v 0.3 '\$HOME/.claude/sounds/finish.aiff'"
          }
        ]
      }
    ]
  }
}
HEREDOC

# settings.local.json permissions snippet
cat > "$CONFIG_DIR/settings-permissions.json" << HEREDOC
{
  "permissions": {
    "allow": [
      "Bash(terminal-notifier:*)"
    ]
  }
}
HEREDOC

echo -e "  ${GREEN}Generated config files in:${NC} $CONFIG_DIR/"

# ─── Summary ────────────────────────────────────────────────────────────────

echo ""
echo -e "${BLUE}══════════════════════════════════════════${NC}"
echo -e "${GREEN}  Setup complete!${NC}"
echo -e "${BLUE}══════════════════════════════════════════${NC}"
echo ""
echo "  Next steps:"
echo ""
echo -e "  1. ${YELLOW}Add notification instructions to CLAUDE.md:${NC}"
echo "     Copy the content from: $CONFIG_DIR/CLAUDE.md.snippet"
echo "     Paste into: ~/.claude/CLAUDE.md"
echo ""
echo -e "  2. ${YELLOW}Add hooks to settings.json:${NC}"
echo "     Merge hooks from: $CONFIG_DIR/settings-hooks.json"
echo "     Into: ~/.claude/settings.json"
echo ""
echo -e "  3. ${YELLOW}Add permissions to settings.local.json:${NC}"
echo "     Merge permissions from: $CONFIG_DIR/settings-permissions.json"
echo "     Into: ~/.claude/settings.local.json"
echo ""
echo -e "  4. ${YELLOW}Install ntfy app on your iPhone:${NC}"
echo "     https://apps.apple.com/app/ntfy/id1625396347"
echo "     Subscribe to topic: ${TOPIC_NAME}"
echo ""
echo -e "  5. ${YELLOW}Test it:${NC}"
echo "     terminal-notifier -title 'Test' -message 'Hello!' -sound default"
echo "     curl -d 'Test notification' ntfy.sh/${TOPIC_NAME}"
echo ""
echo -e "  ${BLUE}Your ntfy topic URL:${NC} https://ntfy.sh/${TOPIC_NAME}"
echo ""
