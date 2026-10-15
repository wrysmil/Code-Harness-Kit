# Code-Harness Kit — Qoder 插件说明

本仓库以**双清单**形态分发：

- `.claude-plugin/` → Claude Code plugin（`/plugin marketplace add wrysmil/Code-Harness-Kit`）。
- `.qoder-plugin/plugin.json` → Qoder CLI 插件（`skills:./skills/`、`rules:./core/`、`agents:[...]`）。

## Qoder 侧现状（诚实声明）

- Qoder 插件仅从**官方市场 `qoder-plugins`** 分发，**无自助 `marketplace add`**；要让 Qoder 用户一键装，
  须由 Qoder 官方打包上架（参考 superpowers 的 `official_*` 登记方式）。
- 在官方上架前，本清单是**候选 manifest**，字段形态照抄自已装插件（postman / context7 / superpowers），
  **尚未在装有真 Qoder CLI 的机器上通过 `qoder plugin validate`**。发布前必须先跑：
  ```bash
  qoder plugin validate .
  ```
- 无论插件是否上架，**项目根 `AGENTS.md` 都是 Qoder 今天就生效的接入机制**（Qoder 自动加载项目
  AGENTS.md）。瘦入口模板见 `init/templates/AGENTS.claude-entry.md`。

## 目录约定

- 顶层 `skills/`、`agents/` 由 `scripts/sync-plugin-dirs.sh` 从真相源 `.agents/` 投影生成；
  改 `.agents/` 后需重跑该脚本并提交。`rules` 直接指向 `./core/`（无需投影）。
