---
name: lessons-library
description: "自维护教训库：任务收尾自动把踩过的坑写成五段式条目入库，会话开始时查到期复习，防止同类错误反复发生。条目带稳定 ID 与 SM-2 复习日期，纯 PowerShell 维护（due/mark/validate/init/new），不依赖 python。用于任何『这次又犯了同样的错』的场合。"
whenToUse: "任务或会话收尾时；出现返工、踩坑、用户纠正时；用户说『记住』『以后别再犯』时；新会话开始时查有无到期条目。"
---

# 自维护教训库（lessons-library）

每台机器各有一份库：`$env:DSH_HOME\lessons-learned.md`（没有 `DSH_HOME` 时用 `%USERPROFILE%\.dsh\lessons-learned.md`）。工具在 `$env:DSH_HOME\tools\lessons.ps1`。

库是**全局唯一事实源**：会话里的临时笔记只是副本。

## 什么时候写

1. **任务收尾**：本轮有没有「早知道就能省事」的信息？有就入库。
2. **当下踩坑**：返工、被用户纠正、工具坑、环境差异——当场记，别等收尾。
3. **会话开始**：跑一次 `due`，有到期条目就先过一遍再干活。

## 五段式（缺一段就不算合格）

```markdown
### YYYY-MM-DD 一句话标题
<!-- lesson id=L-YYYY-MM-DD-NN evidence=实测 last=… due=… ease=2.50 reps=0 -->

- 场景：当时怎么错的（现象、报错原文、试过什么）
- 教训：正确做法 1~3 条，要能直接照做
- 预防：固化到哪（技能、脚本、文档、PATH）
- 适用：哪个项目、环境、版本——把隐性上下文写出来
- 失效条件：什么情况下这条不再成立（防过期教训误导）
```

标题下一行必须是元数据注释；**不要手算 `due`/`last`**，用 `mark` 更新，避免算错。

## 工具

```powershell
$tool = "$env:DSH_HOME\tools\lessons.ps1"

powershell -ExecutionPolicy Bypass -File $tool stats      # 条数、到期、逾期、证据分布
powershell -ExecutionPolicy Bypass -File $tool due        # 今天到期的条目
powershell -ExecutionPolicy Bypass -File $tool new -Title "一句话标题"
powershell -ExecutionPolicy Bypass -File $tool mark L-2026-10-24-01 -Grade 4
powershell -ExecutionPolicy Bypass -File $tool validate   # 0 错误才算过
powershell -ExecutionPolicy Bypass -File $tool init       # 给缺元数据的条目补齐（幂等）
```

`new` 会生成骨架和 ID；把五段内容填进去即可。

## 复习评分（grade）

| 分 | 含义 | 效果 |
| 5 | 仍成立，且本次复测过 | 间隔按 ease 递增 |
| 3 | 只静态确认，没复测 | 间隔递增但放慢 |
| 1 | 已失效，需要改写 | 重置为 1 天后 |
| 0 | 已过期，归档 | 重置为 1 天后 |

低于 3 分视为「忘了」，明天再来。

## 维护（每周一次，或条目 > 40 条时）

1. `validate` 必须 0 错误；`stats` 看逾期。
2. **合并**：同主题或结论冲突的条目合并成一条分场景条目，保留全部场景细节。
3. **裁决**：新条目推翻旧条目时，旧条写「~~已取代~~ 见 L-…」，禁止两说并存。
4. **归档**：热库超过 40 条时，按最旧优先移到 `archive/lessons-YYYYMM.md`，降到 30 条以内。
5. **技能同步**：同一类错误犯第二次，说明规则不够硬——把它从技能里的「建议」改成「必须附证据」，或写进脚本自动检查。
6. 更新库头「上次整理」日期。

## 会话开始的动作

```powershell
powershell -ExecutionPolicy Bypass -File $env:DSH_HOME\tools\lessons.ps1 due
```

有到期条目：逐条判断「失效条件是否已触发」，然后 `mark <ID> -Grade N`。没有就跳过，不要整库通读。

## 边界

- 只记**可复用**的教训；一次性的项目细节留在项目文档里。
- 条目里不放密码、token、私钥；写得再具体，也只写「见本地 secrets」。
- 库超过 40 条不归档，检索会变慢、噪声会变大——维护不是可选项。
