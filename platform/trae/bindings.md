# Trae 平台绑定

逻辑原语 → Trae API。语义以 `core/capabilities/` 与 `core/orchestration/` 为准。

| 原语 | Trae 绑定 |
| --- | --- |
| `DetectPlatform()` | Trae 工作区 → `trae` |
| `SpawnWorker(role)` | Trae **Agent 模式**（原生 role 子代理；`.trae/agents/<role>.md` 由平台自动加载）。适用于 coder / implementer / reviewer / test-engineer / explorer / debugger / web-investigator / …。**不手工读 `.agents/agents/<role>.md` 内联进 prompt**——仅当 `.trae/agents/<role>.md` 缺失时才降级内联 |
| `ParallelBatch` | Trae Agent 并行任务; max 3 |
| `WorktreeInit` | 同 `scripts/harness-worktree.sh` / git worktree |
| `StructuredAsk` | Trae structured Ask（通过 Task 工具） |
| `EmitHook` | Trae hooks 机制（可选，用户自行配置） |
| `LoadSkill(slug)` | Read `.agents/skills/<slug>/SKILL.md`（共享层）或 `.trae/skills/<slug>/SKILL.md`（平台层覆盖） |
| `LoadAgent(role)` | Read `.agents/agents/<role>.md`（共享层） |
| `LoadCapability(orchestration.dispatch)` | `orchestration` skill → core dispatcher |

**SpawnWorker 委派 prompt 必含：** WU id、wu_type、agent_role、允许文件、禁止项、done criteria、worktree_path（若启用）、本 WU Skills、返回格式。

**reviewer/explorer 等只读角色：** 原生 Agent 模式仍能写文件，`readonly` 靠「独立实例 + prompt 纪律」维持，派发时须验证未越权写（非平台门禁）。

**降级记录：** matrix 为 `degraded` 时，DISPATCH-TRACK 写 `Detail: capability <id> degraded`。

**Skill 路径：** 共享 `.agents/skills/`（含 `git-xywh`、`orchestration` 等通用 skill）；平台特有 `.trae/skills/`。
