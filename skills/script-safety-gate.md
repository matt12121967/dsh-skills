---
name: script-safety-gate
description: "脚本闸门：.ps1 执行前先过静态检查（纯 ASCII、语法、-f 占位符个数），提权一律 PowerShell 7 + 隐藏窗口。防三类已经付过代价的失效——编码乱码、格式串差一个参数、控制台选择冻结。"
whenToUse: "写或改 .ps1；需要管理员权限执行脚本；脚本要输出或匹配中文但解释器可能是 Windows PowerShell 5.1；cmd、任务计划、安装器会读取你的脚本时。"
---

# 脚本闸门：跑之前先拦

三类错误共同点：**写的时候完全合法，跑到一半才炸**，而且都发生在「用户已经点了授权、等了半天」之后。它们的成本不是改代码，是让人白等。

## 失效一：编码（最贵）

Windows PowerShell 5.1 读**没有 BOM 的 UTF-8** 脚本时按 ANSI（简中机器是 GBK）解码。脚本里的中文变成乱码，匹配永远不成立：

```powershell
# 5.1 下 $name 实际是 "Windows 10 ??????"
if ($name -match '专业版$') { ... }   # 永远进不去
```

报错现场还很迷惑：`dism` 明明列出了六个版本，脚本就是选不中。

修法不是「下次注意」，是让脚本**不含非 ASCII**：

- 注释写英文。
- 要匹配或输出中文，用码点构造：`[string]([char]0x4E13)+[char]0x4E1A+[char]0x7248`（专业版）。
- 必须带中文时，存成 UTF-8 **带 BOM**，并确认调用方是 5.1 还是 7。

## 失效二：格式串差一个参数

```powershell
"#{0} {1} {2} BusType={3}" -f $num, $name, $bus
# 运行时：Index (zero based) must be ... less than the size of the argument list
```

PowerShell 的 `-f` 没有编译期校验，语法分析也查不出来——位置参数就是手工记账，删一个字段忘了删 `{3}` 就炸。两种修法，优先第二种：

- 静态检查：`check-script.ps1` 用 AST 算出最大占位符索引与实际参数个数，不匹配直接拒绝。
- **禁用多参数 `-f`，一律插值**：`"#$num $name $bus"`。没有索引就没有记账。

## 失效三：提权窗口被「选中」冻住

`Start-Process -Verb RunAs` 弹出的控制台，只要有人用鼠标在里面拖选，进程就进入 QuickEdit 选择模式**暂停**。现象是「脚本卡死、日志停在开头、盘上一字节没写」，实际什么都没坏，按 Esc 就继续。

修法：提权一律 `-WindowStyle Hidden`，不要让窗口留在前台。

## 规则

1. `.ps1` 纯 ASCII；检查器报非 ASCII 就改，不许放行。
2. 多参数 `-f` 禁用，改插值。
3. 提权用 `pwsh` 7，加隐藏窗口；不要拿 `powershell.exe` 5.1 跑业务脚本。
4. 执行前先过静态检查，不过不运行——包括「就差一点，先跑跑看」。

## 工具

```powershell
# 静态检查：ASCII + 语法 + -f 占位符个数
pwsh -File tools\check-script.ps1 .\deploy.ps1

# 提权运行：先检查，不过就拒绝；-CheckOnly 只检查不提权
pwsh -File tools\elevate.ps1 -Script .\deploy.ps1 -CheckOnly
pwsh -File tools\elevate.ps1 -Script .\deploy.ps1
```

`elevate.ps1` 会自己找 `pwsh.exe`（PATH 优先），找不到就报错退出，不会悄悄退回 5.1。

## 反模式

- 用 `powershell.exe -ExecutionPolicy Bypass` 绕过检查，把带病脚本推给用户点 UAC
- 报错后只改现象（把中文改成拼音），不查解码链
- 提权窗口留在前台，让用户「别碰」
- 脚本里有一排 `{n}`，参数却是手数的
- 静态检查失败就加 `-SkipCheck` 继续跑
