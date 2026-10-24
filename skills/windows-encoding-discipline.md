---
name: windows-encoding-discipline
description: "Windows 文本编码纪律：先跑探针拿本机事实（PowerShell 版本、chcp、控制台编码、Python stdout 编码），再按症状选写法，改完读回字节自证。用于乱码、UTF-8/GBK 报错、重定向后文件变 UTF-16、Python 输出中文崩溃时。"
whenToUse: "任何涉及中文文本读写、日志重定向、Python/Node 输出、跨机器迁移脚本的任务。"
---

# Windows 文本编码：先测，再写，再自证

同一份脚本在这台机器正常、在另一台乱码，原因几乎总是三个默认值不同：PowerShell 版本、控制台代码页、Python 的 stdout 编码。**先把这三个值测出来**，再决定写法；不要凭「Windows 都是 GBK」或「PS7 都是 UTF-8」下结论。

## 1. 跑探针（10 秒）

```powershell
powershell -ExecutionPolicy Bypass -File .\probe-encoding.ps1
```

只看四行：`PSVersion`、`chcp`、`Console.OutputEncoding`、`python stdout`。把这四行记进当次任务，它是后面所有判断的基线。

## 2. 按症状选写法

| 症状 | 真实原因 | 写法 |
| 重定向出的文件乱码，开头 `FF FE` | 5.1 的 `>` `>>` `*>` 写 UTF-16LE | `Out-File -Encoding utf8` / `Set-Content -Encoding utf8` |
| `Get-Content` 读 UTF-8 文件出问号方块 | 5.1 默认按当前代码页解码 | 永远显式 `-Encoding utf8` |
| Python 报 `UnicodeEncodeError: cp1252/gbk` | stdout 编码取自控制台，不是 UTF-8 | 先 `$env:PYTHONIOENCODING='utf-8'`，或脚本内 `sys.stdout.reconfigure(encoding='utf-8')` |
| 控制台里中文正常、写进文件却坏（或反之） | 显示解码与文件字节是两回事 | 读回字节看 BOM 和码点，别看屏幕 |
| 老程序（cscript、cmd 批处理、注册表值）读中文出错 | 它们按 ANSI/OEM 解码 | 这类文件内容强制纯 ASCII |

## 3. 写文件的默认动作

- 源码、JSON、Markdown：**UTF-8 无 BOM**，用
  `[IO.File]::WriteAllText($p, $s, (New-Object Text.UTF8Encoding($false)))`
- 日志：`Out-File -Encoding utf8`（5.1 下带 BOM；要无 BOM 就同上）
- 需要被其他程序读的文本，一律不用 `>` `>>` `*>` 写

## 4. 自证：改完必须读回

「编码修好了」的声明要附读回证据，三选一：

```powershell
[IO.File]::ReadAllBytes($p)[0..3] | % { $_.ToString('X2') }    # BOM
(Get-Content $p -Encoding utf8 -Raw) -eq $expected               # 内容
[Text.Encoding]::UTF8.GetString([IO.File]::ReadAllBytes($p))     # 解码
```

屏幕显示正常不算证据：控制台解码器可能把坏字节显示得像对的。

## 5. 边界

- 探针只测当前机器、当前账户、当前 shell；换机器、换服务账户都要重测。
- 改大脚本前，先写 3 行最小复现（写一个文件、读回、比较），跑通再动真的。
