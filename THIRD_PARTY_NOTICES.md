# 第三方技能归属声明 / Third-Party Notices

Code-Harness-Kit 以 MIT 许可发布其自有编排与文档（见 `LICENSE`）。本仓库 bundling 的第三方
agent skill 保留各自上游许可，分发时必须附带归属。逐条来源与许可登记于
`.agents/skills/_vendor-sources.yaml`（每条含 `upstream:` 与 `license:` 字段）。

## 上游许可汇总

| 上游仓库 | 许可 | 涉及 skill（本仓库内） |
| --- | --- | --- |
| `obra/superpowers` | MIT | brainstorming, writing-plans, test-driven-development, systematic-debugging, verification-before-completion, requesting-code-review, receiving-code-review |
| `addyosmani/agent-skills` | MIT | code-review-and-quality, source-driven-development, context-engineering, incremental-implementation, doubt-driven-development, api-and-interface-design, security-and-hardening, performance-optimization, code-simplification, observability-and-instrumentation, shipping-and-launch, interview-me, frontend-ui-engineering, browser-testing-with-devtools |
| `anthropics/skills` | Apache-2.0 | frontend-design |
| `nextlevelbuilder/ui-ux-pro-max` | MIT | ui-ux-pro-max |
| `inference.sh`（agent-browser） | **unknown — 待核** | agent-browser |
| harness-kit 自有 / 内部 | MIT | orchestration, git-xywh, github, document-review, 以及各 dev agent（`agents/*.md`） |

## 本仓库的改动概要

- 多数 skill 仅将产物落盘路径改写为 `.ai-runtime-artifacts/`，方法论正文保持上游原样。
- `orchestration` 由 claude/cursor/trae 三平台特化合并为平台无关版本。
- 命名空间引用由 `superpowers:<slug>` 归一为裸 `<slug>`（见 `core/routing.md`）。

## 待办（合规）

- `agent-browser`（inference.sh）上游许可未确认，暂标 `unknown`。**对外发布 marketplace 前须核实其
  LICENSE**；若不允许再分发，应从 plugin 打包中剔除该 skill。
- `ui-ux-pro-max` 为整目录投影（含 `data/`、`scripts/`），其内嵌资源许可应随上游 LICENSE 一并核对。

> 若上游许可为 copyleft 或含额外条款，本文件与对应 skill 目录内的 LICENSE/声明须同步更新。
