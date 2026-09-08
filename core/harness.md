
# Harness Engineering

本文件描述可迁移 Agent Harness 的通用架构。它不包含具体项目业务背景；项目业务画像放在 `harness-kit/project.profile.md`。

## 三层架构

### Runtime Layer

由 AI 工具运行时管理：

- `AGENTS.md`
- 平台 skills、prompts、agents、hooks

这层负责多 Agent 编排、workflow 调度和运行时能力。

### Project Overlay Layer

由 `harness-kit/` 管理：

- `project.profile.md`：当前项目画像，迁移到新项目后必须重新生成。
- `context-map.md`：目录、模块和关键入口地图，初始化后由 AI 生成。
- `project.verification.md`：当前项目验证命令，初始化后由 AI 生成。
- `project.git.md`：相对组织 `git-xywh` skill 的 Git 协作差异（MR 平台、commitlint、AI 是否可 push 等）；组织通用流程不复制进仓库。
- `core/routing.md`：任务路由、阶段门禁、按判定加载、references 索引。
- `core/artifacts.md`：过程产物规范。
- `core/verification.md`：通用验证门禁。
- `core/runbooks.md`：常见任务流程。
- `platform/`：编程工具适配目录模板。
- `scripts/`：Harness 内部脚本。
- `artifact-templates/`：过程产物模板。

这层负责项目边界、产物协议、验证门禁和可迁移约束。

### Tool Bootstrap Layer

由根目录投影和 Harness 内部脚本组成：

- `AGENTS.md`（Harness 覆盖层，直接引用 `core/routing.md` 等）
- 适配器入口文件（见 `platform/*/README.md`）
- `harness-kit/scripts/install-ai-skills.sh`
- `harness-kit/scripts/harness-check.sh`

这层负责让不同工具进入同一套 Harness。适配器目录从 `harness-kit/platform/` 投影；脚本直接在 `harness-kit/scripts/` 内执行，不投影到根目录。

## 新项目初始化顺序

1. 将 `harness-kit/` 放入新项目。
2. 对 AI 发送 **`harness-kit/init/onboarding-handoff.txt`** 全文；详版见 **`harness-kit/init/bootstrap.prompt.md`**。
3. AI 生成或更新：
   - `harness-kit/project.profile.md`
   - `harness-kit/context-map.md`
   - `harness-kit/project.verification.md`
   - `harness-kit/project.git.md`
4. AI 用 `project.profile.md` 摘要替换根目录 `AGENTS.md` 中的 `{{PROJECT_BACKGROUND}}`。
5. 人 review `project.profile.md` 与 `project.git.md` 中的推断项和待确认项。
