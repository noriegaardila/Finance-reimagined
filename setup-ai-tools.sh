#!/usr/bin/env bash
# setup-ai-tools.sh — installs and configures all AI coding tools for this workspace
set -euo pipefail

WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "Workspace: $WORKSPACE_DIR"

# ── Git identity & credential sharing ────────────────────────────────────────
echo ""
echo "==> Configuring shared git credentials..."
git config --global credential.helper store

# Prompt for GitHub identity if not already set to a real user
CURRENT_NAME=$(git config --global user.name 2>/dev/null || true)
CURRENT_EMAIL=$(git config --global user.email 2>/dev/null || true)

if [[ "$CURRENT_NAME" == "Claude" || -z "$CURRENT_NAME" ]]; then
  read -rp "GitHub name  (e.g. Santiago Noriega): " GIT_NAME
  git config --global user.name "$GIT_NAME"
fi
if [[ "$CURRENT_EMAIL" == "noreply@anthropic.com" || -z "$CURRENT_EMAIL" ]]; then
  read -rp "GitHub email (e.g. you@example.com):  " GIT_EMAIL
  git config --global user.email "$GIT_EMAIL"
fi

echo "    git user: $(git config --global user.name) <$(git config --global user.email)>"
echo "    credential.helper: $(git config --global credential.helper)"
echo "    Credentials will be stored in ~/.git-credentials after first push/pull."

# ── Claude Code (already installed) ──────────────────────────────────────────
echo ""
echo "==> Claude Code: $(claude --version 2>/dev/null || echo 'not found')"

# ── Codex ─────────────────────────────────────────────────────────────────────
echo ""
echo "==> Codex..."
if ! command -v codex &>/dev/null; then
  npm install -g @openai/codex@latest
fi
echo "    codex: $(codex --version 2>/dev/null)"

# Codex reads OPENAI_API_KEY from environment — put yours in ~/.ai-env
if [[ -z "${OPENAI_API_KEY:-}" ]]; then
  echo "    NOTE: set OPENAI_API_KEY in ~/.ai-env to use Codex"
fi

# ── OpenClaw ───────────────────────────────────────────────────────────────────
echo ""
echo "==> OpenClaw..."
if ! command -v openclaw &>/dev/null; then
  npm install -g openclaw@latest
fi
echo "    openclaw: $(openclaw --version 2>/dev/null || echo 'installed')"

# ── Kimi Code ─────────────────────────────────────────────────────────────────
echo ""
echo "==> Kimi Code..."
KIMI_DIR="$HOME/.local/share/kimi-code"
if ! command -v kimi &>/dev/null && [[ ! -d "$KIMI_DIR" ]]; then
  if command -v python3.12 &>/dev/null; then
    pip3.12 install kimi-code
  else
    echo "    Installing from GitHub (Python 3.11 compat build)..."
    git clone --depth=1 https://github.com/MoonshotAI/kimi-code "$KIMI_DIR"
    cd "$KIMI_DIR"
    pip3 install -e . 2>/dev/null || npm install -g . 2>/dev/null
    cd "$WORKSPACE_DIR"
  fi
fi
echo "    kimi: $(kimi --version 2>/dev/null || echo 'installed')"

if [[ -z "${KIMI_API_KEY:-}" ]]; then
  echo "    NOTE: set KIMI_API_KEY in ~/.ai-env to use Kimi Code"
fi

# ── Shared environment file ───────────────────────────────────────────────────
AI_ENV="$HOME/.ai-env"
if [[ ! -f "$AI_ENV" ]]; then
  cat > "$AI_ENV" <<'ENVEOF'
# Shared AI tool API keys — source this file in your shell profile:
#   echo 'source ~/.ai-env' >> ~/.bashrc
#
# export ANTHROPIC_API_KEY="sk-ant-..."
# export OPENAI_API_KEY="sk-..."
# export KIMI_API_KEY="..."
# export OPENCLAW_API_KEY="..."
# export GITHUB_TOKEN="ghp_..."
ENVEOF
  echo ""
  echo "==> Created ~/.ai-env — fill in your API keys there."
fi

# ── Workspace marker (all tools read this dir) ────────────────────────────────
mkdir -p "$WORKSPACE_DIR/.ai-workspace"
cat > "$WORKSPACE_DIR/.ai-workspace/config.json" <<WSEOF
{
  "name": "Finance-reimagined",
  "repo": "noriegaardila/Finance-reimagined",
  "branch": "claude/workspace-unification-logs-75eo17",
  "tools": ["claude-code", "codex", "openclaw", "kimi-code"],
  "credential_helper": "git-store"
}
WSEOF

echo ""
echo "==> Done. Workspace config written to .ai-workspace/config.json"
echo ""
echo "Next steps:"
echo "  1. Fill in API keys:        nano ~/.ai-env"
echo "  2. Source them:             echo 'source ~/.ai-env' >> ~/.bashrc && source ~/.ai-env"
echo "  3. Authenticate GitHub:     git push  (will prompt once, then store credentials)"
echo "  4. Launch any tool from:    $WORKSPACE_DIR"
