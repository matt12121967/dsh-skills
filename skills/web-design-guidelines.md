---
name: web-design-guidelines
description: "审查 UI/网页代码是否符合 Web Interface Guidelines（可访问性、焦点态、表单、动画、深色模式、触摸交互等）。用户要求 review UI、检查无障碍、审查设计、审查 UX 时使用。"
whenToUse: "用户要求「review my UI」「检查无障碍」「audit design」「review UX」或按最佳实践检查网站/页面时。"
---

# Web Design Guidelines 审查

审查 UI 代码是否符合 [Web Interface Guidelines](https://github.com/vercel-labs/web-interface-guidelines)。

## 流程

1. 先拉取最新规则（每次审查前都要拉，不要用旧缓存）：
   `web_fetch https://raw.githubusercontent.com/vercel-labs/web-interface-guidelines/main/command.md`
2. 读取用户指定（或询问）的文件/目录；
3. 按拉取到的全部规则逐条检查；
4. 按规则文档要求的输出格式（简洁的 `file:line` 格式）给出发现。

用户没指定文件时，先问要审查哪些文件。
