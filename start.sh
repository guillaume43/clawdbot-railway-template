#!/bin/sh
set -e

mkdir -p ~/.openclaw/credentials

# Génère la config depuis les variables Railway
cat > ~/.openclaw/openclaw.json << EOF
{
  "gateway": {
    "port": ${PORT:-8080},
    "mode": "network",
    "bind": "network",
    "auth": {
      "mode": "token",
      "token": "${OPENCLAW_GATEWAY_TOKEN}"
    },
    "controlUi": {
      "allowedOrigins": ["*"]
    }
  },
  "channels": {
    "telegram": {
      "enabled": true,
      "dmPolicy": "pairing",
      "botToken": "${TELEGRAM_BOT_TOKEN}",
      "groupPolicy": "allowlist"
    }
  },
  "hooks": {
    "enabled": true,
    "token": "${OPENCLAW_HOOKS_TOKEN}",
    "path": "/hooks",
    "mappings": [
      {
        "name": "linear",
        "action": "agent",
        "deliver": true,
        "channel": "telegram",
        "allowUnsafeExternalContent": true,
        "template": {
          "message": "Nouveau bug Linear dans le workspace joya.\n\nPayload recu:\n{{ body }}\n\nAnalyse ce bug, propose une solution concrete avec du code si pertinent, et presente-la clairement a Guillaume."
        }
      }
    ]
  }
}
EOF

# Pré-approuve le Telegram de Guillaume (id: 6360066352)
cat > ~/.openclaw/credentials/telegram-default-allowFrom.json << EOF
{
  "version": 1,
  "allowFrom": ["6360066352"]
}
EOF

# Copie le workspace initial si le volume est vide
if [ -d /data ] && [ ! -f /data/workspace/SOUL.md ]; then
  mkdir -p /data/workspace
  cp -r /app/workspace/* /data/workspace/ 2>/dev/null || true
fi

# Configure le provider Anthropic
if [ -n "$ANTHROPIC_API_KEY" ]; then
  mkdir -p ~/.openclaw/providers
  echo "{\"anthropic\":{\"apiKey\":\"${ANTHROPIC_API_KEY}\"}}" > ~/.openclaw/providers/config.json
fi

echo "Starting OpenClaw gateway..."
exec openclaw gateway run --port ${PORT:-8080}
