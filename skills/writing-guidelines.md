---
name: writing-guidelines
description: "审查文档/文案是否符合 Writing Guidelines（主动语态、禁用夸大词、标题句首大写、代码块语言标注等）。用户要求 review docs、检查写作风格、审查文案文风时使用。"
whenToUse: "用户要求「review my docs」「check writing style」「audit prose」或按写作手册检查页面/文档时。"
---

# Writing Guidelines 审查

审查文档/文案是否符合 [Writing Guidelines](https://github.com/vercel-labs/writing-guidelines)。

## 流程

1. 先拉取最新规则（每次审查前都要拉，不要用旧缓存）：
   `web_fetch https://raw.githubusercontent.com/vercel-labs/writing-guidelines/main/command.md`
2. 读取用户指定（或询问）的文件/目录；
3. 按拉取到的全部规则逐条检查；
4. 按规则文档要求的输出格式（简洁的 `file:line` 格式）给出发现。

用户没指定文件时，先问要审查哪些文件。
