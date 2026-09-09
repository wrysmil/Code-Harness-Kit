# Cursor 平台绑定

逻辑原语 → Cursor API。语义以 `core/capabilities/` 与 `core/orchestration/` 为准。

| 原语 | Cursor 绑定 |
| --- | --- |
| `DetectPlatform()` | `.cursor/` + subagent 可委派 → `cursor` |
| `SpawnWorker(role)` | `Use <role> subagent`（原生 role 子代理；`.cursor/agents/<role>.md` 由**平台自动加载**）。适用于 coder / implementer / reviewer / test-engineer / explorer / debugger / web-investigator / …。**不手工读 `.agents/agents/<role>.md` 内联进 prompt**——仅当 `.cursor/agents/<role>.md` 缺失时才降级内联。`reviewer` readonly 见下 |
| `ParallelBatch` | 并行 Task/subagent，≤5 |
| `WorktreeInit` | `scripts/harness-worktree.sh` 或 git worktree 步骤 |
| `StructuredAsk` | `AskQuestion` |
| `EmitHook` | Cursor hooks 机制（可选，用户自行配置） |
| `LoadSkill(slug)` | Read `.agents/skills/<slug>/SKILL.md`（共享层）或 `.cursor/skills/<slug>/SKILL.md`（平台层覆盖） |
| `LoadAgent(role)` | Read `.agents/agents/<role>.md`（共享层） |
| `LoadCapability(orchestration.dispatch)` | `orchestration` skill → core dispatcher |

**Skill 路径：** 共享 `.agents/skills/`（含 `git-xywh` 等通用 skill）；平台特有 `.cursor/skills/`。

**reviewer/explorer 等只读角色：** 原生 role 子代理仍能写文件，`readonly` 靠「独立实例 + prompt 纪律」维持，派发时须验证未越权写（非平台门禁）。

**降级：** 见 `capability-matrix.yaml`。
