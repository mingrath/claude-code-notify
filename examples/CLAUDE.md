# Claude Code Rules

## Notifications

Whenever you need my decision or input, notify me via terminal-notifier before asking. If ntfy is available (Apple Watch), also send to ntfy.

```bash
terminal-notifier -title "Claude Code" -message "Your input is needed" -sound default && curl -s -d "Claude Code needs your input" ntfy.sh/YOUR_TOPIC_NAME > /dev/null 2>&1
```
