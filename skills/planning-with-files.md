---
name: planning-with-files
description: "Manus 式文件计划：多步任务在 docs/ 或工作区根建 plan-<任务名>.md 持久化计划（目标、步骤、进度），防上下文腐烂，崩溃/清空后可恢复，配合 create_goal 做长任务持久化。"
whenToUse: "多步任务（预计超过 3 个步骤）开始时创建计划文件。"
---

# planning-with-files（Manus 式文件计划）

多步任务在工作区根（或 docs/）建 `plan-<任务名>.md`，包含：

1. **最终目标与成功标准**（怎么算做完）
2. **步骤清单**：每步写「做什么 + 如何验证」
3. **进度区**：每轮完成后追加更新（时间 + 结论）
4. 完成后标记 DONE，文件保留作为记录

配合 `create_goal` 做长任务持久化（DSH 原生，重启/续聊可恢复）。
