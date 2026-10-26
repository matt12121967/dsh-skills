---
name: superpowers-workflow
description: "多步开发任务的标准工作流（源自 obra/superpowers）：头脑风暴→写计划→子代理/内联执行→TDD→代码审查→收尾，全部映射到 DSH 原生工具；动手前先确认规格。"
whenToUse: "多步开发任务（多个文件、多阶段、需要测试或审查的任务）开始时。"
---

# Superpowers 工作流（映射到 DSH 原生工具）

核心链：**头脑风暴 → 写计划 → 执行 → TDD → 代码审查 → 收尾**。

| 环节 | DSH 对应工具/做法 |
|---|---|
| brainstorming（先问清意图再写码） | 动手前向用户澄清目标，设计分块展示 |
| writing-plans（2–5 分钟粒度任务） | `todo_write` 任务清单，每步带验证标准 |
| subagent-driven-development | `subagent` / `subagent_fork` 派任务，完成后 Lead 复查 diff |
| executing-plans | 顺序执行 + 末尾整体自查 |
| test-driven-development | 先写失败测试 → 最小实现 → 测试通过 → 提交 |
| requesting-code-review | 每任务完成后自查，严重问题阻塞继续 |
| finishing-a-development-branch | 收尾验证 + 给出 merge/PR/丢弃选项 |

## 铁律

**「动手前先确认规格」**：看到任务不要立即开写，先澄清目标与验收标准，再动手。
