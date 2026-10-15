# Code-Harness Kit → Claude Code Plugin Marketplace 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: 用 superpowers:subagent-driven-development（推荐）或 superpowers:executing-plans 逐任务实现。步骤用 checkbox（`- [ ]`）跟踪。

**Goal:** 把 Code-Harness-Kit 仓库做成可 `/plugin marketplace add wrysmil/Code-Harness-Kit` 一键安装的 Claude Code plugin，业务项目免 7 步初始化。

**Architecture:** 仓库根新增 `.claude-plugin/` 清单（marketplace.json + plugin.json，`source:"./"`）；以顶层 `skills/`、`agents/` 作 Claude Code 投影目录，`.agents/` 仍为单一真相源、用 rsync 脚本同步；把 vendored 的 superpowers 系列升格为自有 skill 并全量打包；markdown 里 `superpowers:` 命名空间归一为裸 `<slug>`。

**Tech Stack:** Bash（sync/检查脚本）、JSON（plugin 清单）、Markdown（skills/agents/routing）、rsync、jq（清单校验）、git。

**Spec:** `.ai-runtime-artifacts/specs/2026-10-15-harness-kit-claude-marketplace-spec.md`

## Global Constraints

- 面向用户/子 Agent 的文字、产物摘要一律**中文**；代码标识符、路径、命令、API 名保留英文（AGENTS.md § 沟通语言）。
- 所有 AI 过程产物落 `.ai-runtime-artifacts/` 对应子目录，禁止 `docs/superpowers/`（harness-check.sh 会告警）。
- harness-kit 自身 LICENSE = **MIT**（spec 已锁定，owner=wrysmil）。
- 不改动 Cursor/Trae 的 onboarding 路径；本计划只新增 Claude marketplace 通道 + 归一命名空间。
- plugin 版本号从 `0.1.0` 起。
- 命名空间归一只作用于 `superpowers:` 这个**带冒号的 token**；物理路径（`obra/superpowers`、`~/.claude/plugins/superpowers`、`npx skills add obra/superpowers`）不改。
- 每次提交只 add 明确文件，不用 `git add -A`。

---

### Task 1: plugin 清单（marketplace.json + plugin.json）

**Files:**
- Create: `.claude-plugin/marketplace.json`
- Create: `.claude-plugin/plugin.json`

**Interfaces:**
- Produces: plugin 名 `code-harness-kit`；Task 2 顶层 `skills/`、`agents/` 依赖此名被 Claude 扫描。

- [ ] **Step 1: 写失败校验（清单缺失或非法 JSON 应报错）**

```bash
cd "$(git rev-parse --show-toplevel)"
jq -e '.name=="code-harness-kit" and (.plugins[0].source=="./")' .claude-plugin/marketplace.json
jq -e '.name=="code-harness-kit" and .license=="MIT"' .claude-plugin/plugin.json
```
Expected: FAIL（文件不存在 / jq 报错）。

- [ ] **Step 2: 创建 `.claude-plugin/marketplace.json`**

```json
{
  "name": "code-harness-kit",
  "description": "Agentic scaffolding: routing, stage skills, multi-platform adapters. One-command marketplace install.",
  "owner": {
    "name": "wrysmil",
    "url": "https://github.com/wrysmil"
  },
  "plugins": [
    {
      "name": "code-harness-kit",
      "description": "Harness routing + vendored stage skills (brainstorming, writing-plans, TDD, debugging, verification, orchestration) and dev agents.",
      "version": "0.1.0",
      "source": "./",
      "category": "productivity"
    }
  ]
}
```

- [ ] **Step 3: 创建 `.claude-plugin/plugin.json`**

```json
{
  "name": "code-harness-kit",
  "description": "Harness routing + vendored stage skills and dev agents.",
  "version": "0.1.0",
  "author": { "name": "wrysmil", "url": "https://github.com/wrysmil" },
  "homepage": "https://github.com/wrysmil/Code-Harness-Kit",
  "repository": "https://github.com/wrysmil/Code-Harness-Kit",
  "license": "MIT",
  "keywords": ["harness", "routing", "skills", "agents", "orchestration", "tdd", "brainstorming"]
}
```

- [ ] **Step 4: 复跑校验**

Run: Step 1 两条 `jq -e`。Expected: 均输出 `true`，exit 0。

- [ ] **Step 5: Commit**

```bash
git add .claude-plugin/marketplace.json .claude-plugin/plugin.json
git commit -m "feat(plugin): 新增 .claude-plugin marketplace/plugin 清单"
```

---

### Task 2: 顶层 skills/ agents/ 投影（sync 脚本）

**Files:**
- Create: `scripts/sync-plugin-dirs.sh`
- Create: `skills/`（由脚本从 `.agents/skills/` rsync 生成后提交）
- Create: `agents/`（由脚本从 `.agents/agents/` rsync 生成后提交）

**Interfaces:**
- Consumes: Task 1 的 plugin 名（Claude 用 `source:"./"` 扫描根下 `skills/`、`agents/`）。
- Produces: 顶层 `skills/<name>/SKILL.md` 与 `agents/<name>.md`，与 `.agents/` 内容一致。

- [ ] **Step 1: 写失败校验（顶层目录数量应等于 .agents）**

```bash
cd "$(git rev-parse --show-toplevel)"
test "$(find skills -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')" \
  = "$(find .agents/skills -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')"
test "$(find agents -maxdepth 1 -type f -name '*.md' 2>/dev/null | wc -l | tr -d ' ')" \
  = "$(find .agents/agents -maxdepth 1 -type f -name '*.md' | wc -l | tr -d ' ')"
```
Expected: FAIL（skills/、agents/ 尚不存在）。

- [ ] **Step 2: 创建 `scripts/sync-plugin-dirs.sh`**

```bash
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
```

- [ ] **Step 3: 执行 sync**

Run: `bash scripts/sync-plugin-dirs.sh`
Expected: 打印 `synced -> skills/: <N> 个 skill, agents/: <M> 个 agent`。

- [ ] **Step 4: 复跑 Step 1 校验**

Expected: 两条 `test` 均 exit 0（数量一致）。

- [ ] **Step 5: 幂等验证**

Run: `bash scripts/sync-plugin-dirs.sh && git status --short skills agents`
Expected: 第二次运行不产生新的差异（rsync --delete 幂等），`git status` 只显示首次新增、无二次改动噪声。

- [ ] **Step 6: Commit**

```bash
git add scripts/sync-plugin-dirs.sh skills agents
git commit -m "feat(plugin): 顶层 skills/agents 投影目录 + sync 脚本"
```

---

### Task 3: LICENSE + 第三方归属 + vendor license 字段

**Files:**
- Create: `LICENSE`
- Create: `THIRD_PARTY_NOTICES.md`
- Modify: `.agents/skills/_vendor-sources.yaml`（每条加 `license:`）

**Interfaces:**
- Produces: `LICENSE`（MIT）与 `THIRD_PARTY_NOTICES.md`，Task 1 `plugin.json` 的 `license:"MIT"` 由此坐实。

- [ ] **Step 1: 写失败校验**

```bash
cd "$(git rev-parse --show-toplevel)"
test -f LICENSE && grep -q "Permission is hereby granted, free of charge" LICENSE
grep -qi "license:" .agents/skills/_vendor-sources.yaml || { echo "vendor license 字段缺失"; exit 1; }
```
Expected: FAIL（LICENSE 不存在）。

- [ ] **Step 2: 创建 `LICENSE`（MIT 全文）**

```
MIT License

Copyright (c) 2026 wrysmil

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

- [ ] **Step 3: 给 `_vendor-sources.yaml` 每条 skill 加 `license:`**

已知上游许可：obra/superpowers = `MIT`；anthropics/skills = `Apache-2.0`；agent-skills 增强条目按其上游（无明确上游时记 `license: MIT`，note 补"derived"）。对以下条目至少补：
```yaml
  test-driven-development:
    upstream: obra/superpowers + agent-skills 增强
    license: MIT
  verification-before-completion:
    upstream: obra/superpowers
    license: MIT
  systematic-debugging:
    upstream: obra/superpowers + agent-skills 增强
    license: MIT
  frontend-design:
    upstream: anthropics/skills (frontend-design)
    license: Apache-2.0
```
（其余逐条补 `license:`；不确定的填 `unknown` 并在 note 说明待核。）

- [ ] **Step 4: 创建 `THIRD_PARTY_NOTICES.md`**

按 `_vendor-sources.yaml` 生成三段式列表：`skill 名 | 上游仓库 | 上游 license | 本仓库改动概要`。至少含表头与逐行数据；顶部写归属声明：
```markdown
# 第三方技能归属声明

本项目 bundling 的第三方 skill 保留各自上游许可。以下为逐条来源与许可，
依据 `.agents/skills/_vendor-sources.yaml`。

| skill | 上游 | license | 改动概要 |
| --- | --- | --- | --- |
| brainstorming | obra/superpowers (MIT) | MIT | 产物路径改为 .ai-runtime-artifacts/；适配 Qoder 工具名 |
| ... | ... | ... | ... |
```

- [ ] **Step 5: 复跑 Step 1 校验**

Expected: 全部 exit 0。

- [ ] **Step 6: Commit**

```bash
git add LICENSE THIRD_PARTY_NOTICES.md .agents/skills/_vendor-sources.yaml
git commit -m "docs(license): MIT + 第三方归属声明 + vendor license 字段"
```

---

### Task 4: 命名空间归一（`superpowers:` → 裸 slug）

**Files:**
- Modify: `core/routing.md`（9 处）
- Modify: `platform/claude/bindings.md`（3 处）
- Modify: `artifact-templates/spec.harness-overlay.md`、`plan.harness-overlay.md`、`verification.md`、`document-review.md`（各 1 处 FM 示例）

**Interfaces:**
- Consumes: `scripts/scan-artifacts-graph.js:223` 已"去掉 superpowers: 前缀归一"，故裸 slug 与前缀形式等价。
- Produces: routing 表内 skill 引用均为裸 slug（`brainstorming` 等）。

- [ ] **Step 1: 写失败校验（目标文件内仍含 `superpowers:`）**

```bash
cd "$(git rev-parse --show-toplevel)"
for f in core/routing.md platform/claude/bindings.md \
         artifact-templates/spec.harness-overlay.md artifact-templates/plan.harness-overlay.md \
         artifact-templates/verification.md artifact-templates/document-review.md; do
  test "$(grep -c 'superpowers:' "$f")" -eq 0 || echo "PENDING: $f 仍含 superpowers:"
done
```
Expected: 输出若干 `PENDING:`（改写前）。

- [ ] **Step 2: 先确认物理路径不含 `superpowers:` 冒号形式（防误伤）**

```bash
grep -rn "superpowers:" core/routing.md platform/claude/bindings.md artifact-templates/
```
Expected: 命中均为 skill-load 引用（如 `superpowers:brainstorming`、`superpowers:writing-plans`），无 `obra/superpowers:` 这类。若发现异常行，改用逐行精确 Edit 而非全局 sed。

- [ ] **Step 3: 对 6 个文件执行 token 替换**

```bash
for f in core/routing.md platform/claude/bindings.md \
         artifact-templates/spec.harness-overlay.md artifact-templates/plan.harness-overlay.md \
         artifact-templates/verification.md artifact-templates/document-review.md; do
  sed -i '' 's/superpowers://g' "$f"   # macOS BSD sed；Linux 用 sed -i 's/superpowers://g'
done
```

- [ ] **Step 4: 复跑 Step 1 校验**

Expected: 无任何 `PENDING:`（全部为 0）。

- [ ] **Step 5: harness-check 绿灯**

Run: `bash scripts/harness-check.sh`
Expected: 不因命名空间改动新增 ERROR（现有告警维持）。若新增，回看被误改行。

- [ ] **Step 6: Commit**

```bash
git add core/routing.md platform/claude/bindings.md artifact-templates/
git commit -m "refactor(routing): superpowers: 命名空间归一为裸 slug（自有 skill）"
```

---

### Task 5: install-ai-skills.sh 去掉 superpowers 硬检查

**Files:**
- Modify: `scripts/install-ai-skills.sh`（删 `SUPERPOWERS_SKILLS` 数组、`check_skill_set superpowers ...` 三处调用、usage 中 `STRICT_SUPERPOWERS` 文档、`case superpowers)` 分支）

**Interfaces:**
- Consumes: Task 2 打包后 superpowers 系列随 plugin 分发，本机 `~/.claude/skills` 不再需要单独安装。

- [ ] **Step 1: 写失败校验（脚本仍含 superpowers 逻辑）**

```bash
cd "$(git rev-parse --show-toplevel)"
! grep -q "SUPERPOWERS_SKILLS" scripts/install-ai-skills.sh
```
Expected: FAIL（当前仍存在）。

- [ ] **Step 2: 移除 superpowers 相关行**

删除：`SUPERPOWERS_SKILLS=(...)` 定义（第 12 行附近）、`check_skill_set superpowers ...` 三处调用（100/106/112）、usage 里 `STRICT_SUPERPOWERS=1` 行（23 行）、`case "$set_name" ... superpowers) ... ;;` 整段（69-79）。保留 `org`（git-xywh）检查不变。

- [ ] **Step 3: 脚本可运行且不再提 superpowers**

```bash
bash scripts/install-ai-skills.sh --platform claude 2>&1 | grep -i superpowers; echo "exit=$?"
bash scripts/install-ai-skills.sh --platform claude; echo "run_exit=$?"
```
Expected: 第一条 grep 无输出（grep exit=1）；`run_exit=0`（仅 org 检查）。

- [ ] **Step 4: Commit**

```bash
git add scripts/install-ai-skills.sh
git commit -m "feat(scripts): superpowers 随 plugin 分发，移除本机硬检查"
```

---

### Task 6: 瘦 AGENTS.md 入口模板 + "按需自建" 规则文本

**Files:**
- Create: `init/templates/AGENTS.claude-entry.md`
- Modify: `init/onboarding-handoff.txt`（新增"走 marketplace 时的精简分支"说明，不改 Cursor/Trae 原分支）

**Interfaces:**
- Produces: 业务项目仅需复制此模板到项目根 `AGENTS.md`（3–5 行 routing 指针）。

- [ ] **Step 1: 写失败校验**

```bash
cd "$(git rev-parse --show-toplevel)"
test -f init/templates/AGENTS.claude-entry.md
grep -q "mkdir -p .ai-runtime-artifacts" init/templates/AGENTS.claude-entry.md
```
Expected: FAIL。

- [ ] **Step 2: 创建 `init/templates/AGENTS.claude-entry.md`**

```markdown
# AGENTS.md（项目 Harness 入口）

本项目已安装 code-harness-kit plugin。AI 入口顺序：
1. 本文件 → 2. 会话内加载 `brainstorming` / `writing-plans` 等 harness skill
   （经 plugin 全局提供，无需本机投影）。

## 按需自建（免预初始化）
- 落盘任何 spec/plan/review 前：`mkdir -p .ai-runtime-artifacts/<specs|plans|reviews|...>`
  对应子目录后再写。
- 首次会话若缺 `project.profile.md` 等四份画像：触发 `project-profiler` prompt 生成。
- 收口时运行 `harness-check` skill 做产物合规自检。

## 强制声明
每个任务首句「Harness：<route 或 Tier 0/1>」；沟通用中文（标识符/路径保留英文）。
```

- [ ] **Step 3: `onboarding-handoff.txt` 顶部加分支说明**

在第 1 行前插入一段：
```
【若已 `/plugin marketplace add wrysmil/Code-Harness-Kit` 并 `/plugin install code-harness-kit`】
可跳过第 1-4 步投影与本机检查，仅：
(a) 复制 harness-kit/init/templates/AGENTS.claude-entry.md 到项目根 AGENTS.md；
(b) 首次会话执行第 6 步 profiler。其余（.ai-runtime-artifacts/ 目录）按需自建。
以下为未走 marketplace 的传统流程（Cursor/Trae 或手动安装场景）：
```

- [ ] **Step 4: 复跑 Step 1 校验**

Expected: 全部 exit 0。

- [ ] **Step 5: Commit**

```bash
git add init/templates/AGENTS.claude-entry.md init/onboarding-handoff.txt
git commit -m "docs(init): 瘦 AGENTS.md 入口模板 + marketplace 精简分支 + 按需自建"
```

---

### Task 7: README 文档 + 端到端本地发现验证

**Files:**
- Modify: `README.md`（新增 "Claude Code marketplace 安装" 段）

- [ ] **Step 1: 本地 plugin 发现验证（不依赖远程）**

```bash
cd "$(git rev-parse --show-toplevel)"
# 用本地目录模式模拟 marketplace add 后的内容可见性
jq -e '.plugins[0].source=="./"' .claude-plugin/marketplace.json
test -f skills/brainstorming/SKILL.md && echo "skill 可见"
test -f agents/coder.md && echo "agent 可见"
```
Expected: `true` + `skill 可见` + `agent 可见`。
（真机 `claude --plugin-dir .` 或 `/plugin marketplace add` 的完整发现验证由维护人在装有 Claude Code 的环境执行一次，作为验收门槛。）

- [ ] **Step 2: README 增加安装段**

在 README 接入章节加：
```markdown
## Claude Code 一键安装（plugin marketplace）
/plugin marketplace add wrysmil/Code-Harness-Kit
/plugin install code-harness-kit
装后 skills/agents 全局可用；业务项目仅需一份瘦 AGENTS.md
（模板：harness-kit/init/templates/AGENTS.claude-entry.md）。
Cursor/Trae 走原投影脚本。
```

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs(readme): Claude Code marketplace 一键安装说明"
```

---

## Self-Review（写完后自查）

**1. Spec 覆盖：**
- marketplace 形态 → Task 1。
- 打包 skills/agents（顶层投影） → Task 2。
- superpowers 自有化 → Task 3（许可）+ Task 4（命名空间）+ Task 5（去本机检查）。
- 许可/归属 → Task 3。
- 免初始化边界（按需自建 + 瘦入口） → Task 6。
- 文档/验收 → Task 7。
- 剩余开放验证点"私有源能否 add" → Task 7 Step 1 备注 + 交由真机；未阻塞本地可验证部分。✔ 无遗漏。

**2. 占位符扫描：** THIRD_PARTIY_NOTICES 表格含 `...` 示例行 —— 属生成型内容（依据 _vendor-sources.yaml），Task 3 Step 4 已要求"逐行数据"，非 TBD。其余步骤均有实际命令/文件内容。✔

**3. 类型一致性：** plugin 名统一 `code-harness-kit`（Task 1/2/6/7 一致）；owner/repo 统一 `wrysmil/Code-Harness-Kit`（Task 1/6/7 一致）；版本 `0.1.0` 一致。✔
