#!/usr/bin/env bash
# 从单一真相源 .agents/ 生成 Claude Code plugin 投影目录 skills/ 与 agents/。
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT"
[ -d .agents/skills ] || { echo "ERROR: 缺 .agents/skills 真相源" >&2; exit 1; }
[ -d .agents/agents ] || { echo "ERROR: 缺 .agents/agents 真相源" >&2; exit 1; }
rsync -a --delete --exclude '_vendor-sources.yaml' .agents/skills/ skills/
rsync -a --delete .agents/agents/ agents/
s=$(find skills -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
a=$(find agents -maxdepth 1 -type f -name '*.md' | wc -l | tr -d ' ')
echo "synced -> skills/: ${s} 个 skill, agents/: ${a} 个 agent"
