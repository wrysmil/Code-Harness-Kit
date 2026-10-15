---
artifact: spec
route: superpowers:brainstorming
skills:
  - brainstorming
skills_evidence:
  - ~/.agents/skills/brainstorming/SKILL.md
source:
  - AGENTS.md
  - core/routing.md
  - https://github.com/dietrichgebert/ponytail
created_at: 2026-10-15
status: draft
approved: false
---

# Code-Harness Kit 改造为 Claude Code plugin marketplace 形式

## 背景

参考 ponytail（github.com/dietrichgebert/ponytail）的形态：它把「一个 agentic skill」打包成可直接
`/plugin marketplace add DietrichGebert/ponytail` 一键安装的 plugin，用户无需为每个业务项目跑初始化脚本。

当前 Code-Harness Kit 接入业务项目要走 `init/onboarding-handoff.txt` 描述的 7 步流程
（清理 git 元数据 → 建根 AGENTS.md → `harness-project.sh project` 投影 → `install-ai-skills.sh` 检查
→ 建 `.ai-runtime-artifacts/` → project-profiler → `harness-check.sh`）。目标是用 marketplace 形态消除
其中大部分步骤。

### ponytail 实测形态（已验证）

```jsonc
// .claude-plugin/marketplace.json
{
  "$schema": "https://anthropic.com/claude-code/marketplace.schema.json",
  "name": "ponytail",
  "owner": { "name": "...", "url": "..." },
  "plugins": [ { "name": "ponytail", "source": "./", "category": "productivity" } ]
}
// .claude-plugin/plugin.json
{ "name": "ponytail", "version": "5.2.0", "hooks": "./hooks/claude-codex-hooks.json" }
```

仓库根即 plugin，`.agents/` 作跨 agent 兜底，`.clinerules/` 等其他目录作 fallback。

## 目标 / 非目标

**目标**
- Claude Code 用户通过一行 `/plugin marketplace add` 安装 harness-kit，skills + agents 全局可用。
- 把 superpowers 系列转为 harness 自有 skill，一并打包，消除 `npx skills add obra/superpowers -g` 前置。
- 业务项目根仅保留一份瘦 `AGENTS.md` 入口，其余初始化按需自建。

**非目标（v1）**
- 不改造 Cursor/Trae 的接入路径（它们无 marketplace 等价物，维持现状）。
- 不用 SessionStart hook 彻底消除项目根 AGENTS.md（激进档，留作后续）。
- 不改 `core/routing.md` 的路由语义本身，只改 skill 引用命名空间（见下）。

## 方案：打包整个仓库为单一 plugin

### 1. 新增 `.claude-plugin/`

- `marketplace.json`：声明 `name: code-harness-kit`、owner、一个 plugin 条目 `source: "./"`。
- `plugin.json`：name / version / description / author。

业务项目侧体验：
```
/plugin marketplace add <your-org>/Code-Harness-Kit
/plugin install code-harness-kit
```

### 2. 打包 skills 与 agents

- 把 `.agents/skills/*`（约 29 个，含 superpowers 系列 + agent-skills 系列 + orchestration）
- 和 `.agents/agents/*`（约 11 个）
作为 plugin 内容分发。装完后 Claude Code 全局可发现，无需投影到 `.claude/skills/`。

### 3. superpowers 自有化

仓库其实已通过 `.agents/skills/_vendor-sources.yaml` 记录了 vendored 来源（多数来自 obra/superpowers
+ agent-skills，并已微调产物落盘路径为 `.ai-runtime-artifacts/`）。本方案把它从"vendored 副本"升格为
"一等公民自有 skill"：

- `install-ai-skills.sh` 删除 superpowers 存在性检查段（或降级为可选诊断，用于未走 marketplace 的回退场景）。
- `routing.md` / `AGENTS.md` / platform bindings 中的 `superpowers:<slug>` 前缀统一改写为裸 `<slug>`
  （命名空间归一到 harness 自身）。**影响范围：仅 markdown 引用，无代码逻辑。**

### 4. 许可与归属

上游许可已核实：obra/superpowers = MIT，anthropics/skills = Apache-2.0，ponytail = MIT，
均允许 fork/分发/商用，前提是保留 attribution。

- 仓库根新增 `LICENSE`（harness-kit 自身，**默认 MIT**，可改 Apache-2.0）。
- 新增 `THIRD_PARTY_NOTICES.md`：逐条列上游路径、原作者、上游 license、本仓库改动概要。
  可由 `_vendor-sources.yaml` 生成。
- `_vendor-sources.yaml` 每条新增 `license:` 字段。

### 5. "按需自建"语义（消除预初始化）

在 rules / 瘦 AGENTS.md 入口中声明：
- 落盘任何 spec/plan/review 前，若 `.ai-runtime-artifacts/<子目录>` 不存在 → Agent 自行 `mkdir -p`。
- 首次会话发现项目根 `project.profile.md` 等四份不存在 → 触发 `project-profiler.prompt.md`。

## 免初始化边界（收敛结果）

| 原步骤 | 新形态 | 机制 |
| --- | --- | --- |
| 投影 skills/rules 到 `.claude/` | **消除** | marketplace 全局安装 |
| `install-ai-skills.sh` superpowers 检查 | **消除** | harness 自有并打包 |
| `.ai-runtime-artifacts/` 预建 | **消除** | rules 声明 + Agent 按需 mkdir |
| project.* 四份 profiler | **按需** | 首次会话触发 profiler prompt |
| 根 `AGENTS.md` | **保留瘦版** | Claude Code 项目级发现机制不可替代 |
| `harness-check.sh` | 降为可选诊断 | 由 Agent 在收口时跑 |

净结果：从 7 步 → 业务项目只需「一份瘦 AGENTS.md」。

## 开放验证点（实现阶段第一步，需真机确认）

1. **目录约定**：Claude Code plugin 是否强制仓库根 `skills/`、`agents/`？能否用 `plugin.json` 字段指向
   `.agents/skills/`、`.agents/agents/`？若都不行 → fallback 方案：新增 `skills → .agents/skills`
   与 `agents → .agents/agents` 软链，或一次性改名。ponytail 用 `source: "./"` + 根级 `skills/`，倾向
   需要根级目录约定。
2. **私有源**：私有 git 仓库能否作为 marketplace 源被 `add`。影响是否需要公开仓库。

## 测试策略

- 在隔离临时目录起一个干净 Claude Code 会话，跑 `marketplace add`（本地 `--plugin-dir` 模拟）→
  验证 `/skills` 能列出 harness skill、`/agents` 能列出 harness agent。
- 验证一个全新业务项目：仅放置瘦 AGENTS.md，触发 brainstorming→spec 流程，观察 Agent 是否按需自建
  `.ai-runtime-artifacts/specs/`。
- 验证 superpowers 引用改写后，routing 表里 `brainstorming`、`writing-plans`、`test-driven-development`
  等仍能正确加载。

## 风险与回滚

- 引用面 `superpowers:` → 裸名的批量替换可能误伤（例如 `~/.claude/plugins/superpowers/...` 物理路径）。
  缓解：用精确边界正则 + 替换前先 grep 出清单，逐类核对。
- marketplace schema 版本演进风险：锚定 `$schema` URL，验证点 1 先做。
- 回滚：新增文件（`.claude-plugin/*`、`LICENSE`、`THIRD_PARTY_NOTICES.md`）独立提交；引用替换单独提交，
  任一失败可单独 revert。

## Next

**（写入后须暂停，等用户明确继续 — 见 `harness-kit/core/routing.md` § 阶段门禁）**

- 确认方案无误 → 说「写计划」或「制定实施计划」
- 变更范围小、无需计划 → 说「直接实现」或「直接做」
- 需要调整方案 → 直接说修改意见
