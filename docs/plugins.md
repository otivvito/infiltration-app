# 🔌 Claude Code 插件说明

> 为渗透系数查询系统项目安装的 3 个 App 开发辅助插件

---

## 已完成安装

| 插件 | 版本 | 来源 |
|------|------|------|
| vgv-wingspan | 0.0.2 | Very Good Ventures |
| dev-process-toolkit | 2.32.0 | nesquikm |
| claude-full-stack-2-0 | 0.2.0 | amritmalla |

---

## 1. Wingspan（VGV）

> AI-native Flutter 开发工作流，遵循 Very Good Ventures 最佳实践

### 14 个 Skills

| Skill | 用途 |
|-------|------|
| `brainstorm` | 头脑风暴，探索方案 |
| `plan` | 制定实施计划 |
| `create` | 创建新功能 / 项目 |
| `build` | 构建功能 |
| `review` | 代码审查 |
| `create-branch` | 创建分支 |
| `create-commit` | 创建提交 |
| `create-pr` | 创建 Pull Request |
| `hotfix` | 热修复流程 |
| `rebase` | 变基操作 |
| `debrief` | 开发复盘 |
| `refine-approach` | 优化方案 |
| `plan-technical-review` | 技术评审计划 |
| `elements-of-style` | VGV 代码风格指南 |

### 其他组件
- **1 Hook**：`PreToolUse`（无模型成本）
- **1 MCP Server**：`context7`
- **Always-on token 成本**：~744 tok

---

## 2. dev-process-toolkit

> TDD + Spec-Driven Development，质量门禁，适用于任何栈

### 23 个 Skills（重点）

| Skill | 用途 |
|-------|------|
| `tdd` | TDD 完整工作流入口 |
| `tdd-write-test` | 写测试 |
| `tdd-implement` | 实现代码 |
| `tdd-refactor` | 重构 |
| `tdd-spec-review` | 规格审查 |
| `gate-check` | **门禁检查**（`flutter analyze` + `flutter test`） |
| `spec-write` | 编写规格说明 |
| `spec-research` | 规格研究 |
| `spec-review` | 规格审查 |
| `spec-archive` | 规格归档 |
| `implement` | 实现功能 |
| `debug` | 调试 |
| `deps` / `deps-research` | 依赖管理 / 依赖研究 |
| `docs` | 文档 |
| `simplify` | 代码简化 |
| `visual-check` | 可视化检查 |
| `ship-milestone` | 里程碑发布 |
| `report-issue` | 报告问题 |

### 8 个 Agents

| Agent | 用途 |
|-------|------|
| `code-reviewer` | 代码审查 |
| `tdd-test-writer` | TDD 测试编写 |
| `tdd-implementer` | TDD 代码实现 |
| `tdd-refactorer` | TDD 重构 |
| `tdd-spec-reviewer` | TDD 规格审查 |
| `spec-researcher` | 规格研究 |
| `spec-reviewer` | 规格审查 |
| `deps-researcher` | 依赖研究 |

### 其他组件
- **2 Hooks**：`PreToolUse`、`UserPromptSubmit`
- **Always-on token 成本**：~1,697 tok

---

## 3. Claude Full Stack 2.0

> 从想法到上架的全栈 AI 工程化技能库（82 skills）

### Flutter 相关 Skills（本项目的核心）

| Skill | 用途 |
|-------|------|
| `flutter-app-scaffold-and-runtime` | Flutter 脚手架与运行时 |
| `flutter-design-system-and-accessibility` | 设计系统与无障碍 |
| `flutter-navigation-and-routing` | 导航与路由 |
| `flutter-performance-and-reliability` | 性能与可靠性 |
| `flutter-state-and-data-fetching` | 状态管理与数据获取 |
| `mobile-architecture` | 移动端架构 |

### 通用工程 Skills

| Skill | 用途 |
|-------|------|
| `ai-native-engineering` | AI 原生工程化 |
| `idea-development` | 想法开发 |
| `system-design` | 系统设计 |
| `frontend-architecture` | 前端架构 |
| `backend-architecture` | 后端架构 |
| `data-architecture` | 数据架构 |
| `quality-engineering` | 质量工程 |
| `security` | 安全 |
| `performance` | 性能 |
| `reliability` | 可靠性 |
| `operations` | 运维 |
| `memory-management` | 记忆管理 |

### 其他组件
- **1 MCP Server**：`claude-repo-mem`
- **Always-on token 成本**：~10,978 tok
- **总计 82 skills**，覆盖 Anthropic API、FastAPI、Spring Boot、React、MongoDB/Postgres、K8s/Terraform、AWS 等

---

## 总 Token 成本

| 插件 | Always-on |
|------|-----------|
| vgv-wingspan | ~744 tok |
| dev-process-toolkit | ~1,697 tok |
| claude-full-stack-2-0 | ~10,978 tok |
| **合计** | **~13,419 tok** |

> 每次会话自动加载约 13k tokens。按需调用 skills/agents 时会有额外消耗。

---

## 常用命令

```bash
claude plugins list                    # 查看已装插件
claude plugins details <plugin>        # 查看插件详情
claude plugins update <plugin>         # 更新插件
claude plugins remove <plugin>         # 卸载插件
claude plugins enable <plugin>         # 启用插件
claude plugins disable <plugin>        # 禁用插件
```

---

## 使用方式

在 Claude Code 会话中用 `/` 加 skill 名即可调用，例如：

```text
/flutter-performance-and-reliability    # 检查 Flutter 性能
/gate-check                             # 运行质量门禁
/build                                  # Wingspan 构建流程
/tdd                                    # TDD 开发循环
```

---

## 安装记录

- **安装日期**：2026-06-26
- **GitHub SSH → HTTPS**：已配置 `url.https://github.com/.insteadOf git@github.com:`
- **已配置 marketplace**：
  - `claude-plugins-official`（官方）
  - `very-good-claude-code-marketplace`（VGV）
  - `dev-process-toolkit`（质量工具）
  - `amritmalla-plugins`（全栈）

---

*重启 Claude Code 后插件生效*
