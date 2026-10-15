# AGENTS.md（项目 Harness 入口）

本项目已安装 code-harness-kit plugin（`/plugin marketplace add wrysmil/Code-Harness-Kit`
→ `/plugin install code-harness-kit`）。

AI 入口顺序：
1. 本文件 → 2. 会话内加载 harness skill（`brainstorming`、`writing-plans`、
   `test-driven-development`、`systematic-debugging`、`verification-before-completion`、
   `orchestration` 等，经 plugin 全局提供，**无需本机投影**）。

## 按需自建（免预初始化）
- 落盘任何 spec/plan/review 前：`mkdir -p .ai-runtime-artifacts/<specs|plans|verifications|reviews|
  execution-logs|decisions|retros|research>` 对应子目录后再写。
- 首次会话若缺 `project.profile.md` 等四份画像：触发 `project-profiler` prompt 生成
  （模板见 plugin 内 `init/templates/`）。
- 收口时运行 `harness-check` 做产物合规自检。

## 强制声明
- 每个任务首句「Harness：<route 或 Tier 0 小改动 / Tier 1 Leader 直做>」。
- 沟通用中文；代码标识符、路径、命令、API 名保留英文。
- 产物一律写入 `.ai-runtime-artifacts/`，禁止 `docs/`、`docs/superpowers/`、平台私有 plans 目录。
