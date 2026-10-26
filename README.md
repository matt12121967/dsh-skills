# dsh-skills

DSH 客户端的基础纪律技能包。装到任何一台机器上，模型就带上：**编码先测后写**、**改动只动该动的**、**结论分三档核实**、**教训自动入库并按期复习**、**受控系统诊断方法**、**卡顿先定层再定因**、**先检索再自研**、**脚本先过闸门再执行**。

## 新机器一条命令

在 PowerShell 里整行粘贴（注意是**同一行**）：

```powershell
$z="$env:TEMP\dsh-skills.zip"; irm https://codeload.github.com/matt12121967/dsh-skills/zip/refs/heads/main -OutFile $z; Expand-Archive $z "$env:TEMP\dsh-skills-src" -Force; powershell -ExecutionPolicy Bypass -File "$env:TEMP\dsh-skills-src\dsh-skills-main\install.ps1"
```

装完新开一个 DSH 会话，技能目录里应出现八条，另外 `$env:DSH_HOME\tools\` 会被放好 `lessons.ps1`、`check-script.ps1`、`elevate.ps1`。

想改参数就再跑一次已解压的安装脚本：

```powershell
powershell -ExecutionPolicy Bypass -File "$env:TEMP\dsh-skills-src\dsh-skills-main\install.ps1" -Only windows-encoding-discipline
powershell -ExecutionPolicy Bypass -File "$env:TEMP\dsh-skills-src\dsh-skills-main\install.ps1" -Force
```

（为什么不用 `irm install.ps1 | iex`：管道会把脚本按行拆开，`param()` 块直接语法错误。为什么不用 `irm install.ps1 -OutFile`：raw.githubusercontent 有 CDN 缓存，刚推送后几分钟内可能取到旧版；codeload 的 zip 是现生成的，不受影响。）

网络访问 GitHub 慢或被拦时：下载仓库 zip 拷过去，解压后在该目录运行 `powershell -ExecutionPolicy Bypass -File .\install.ps1`，效果一样。

## 装了什么

| 技能 | 管什么 |
| `windows-encoding-discipline` | 乱码、UTF-16、`UnicodeEncodeError`：先跑探针拿本机事实，再按症状选写法，改完读回字节 |
| `surgical-edit-discipline` | 改一个错带出十个：只动目标片段，保留全半角、引号、缩进；改完 diff + 字符自证 |
| `verify-before-claim` | 幻觉与「没实测就下结论」：每句话分跑过/读过/推测，外部事实查原文，判定「被拦」要有对照 |
| `lessons-library` | 同类错误反复犯：任务收尾自动入库，新会话查到期复习，条目带 ID 与 SM-2 日期 |
| `engineering-cybernetics` | 钱学森《工程控制论》方法：建模→判稳→定结构→配指标→覆盖不确定性→验证；诊断「反复出错」的闭环 |
| `layer-before-cause` | 联网软件「卡/慢/时好时坏」：TTFB 分段 + 换网络对照 + 服务端状态，先定层再说原因；无层判定不改配置，两次修复无效全回退 |
| `search-before-build` | 「做个 X」先检索：本地 / 生态目录 / 通用检索三行记录 + 完全匹配/部分匹配/没有的结论，再决定复用还是自研 |
| `script-safety-gate` | 脚本跑之前先拦：纯 ASCII、语法、`-f` 占位符个数三项静态检查；提权一律 pwsh 7 + 隐藏窗口；编码乱码、格式串差一个、控制台选择冻结三类失效都有判别方法和修法 |

## 脚本闸门工具

`tools\check-script.ps1` 和 `tools\elevate.ps1` 会随技能一起放到 `$env:DSH_HOME\tools`：

```powershell
pwsh -File tools\check-script.ps1 .\deploy.ps1                  # ASCII + 语法 + -f 占位符个数
pwsh -File tools\elevate.ps1 -Script .\deploy.ps1 -CheckOnly    # 只做静态检查，不提权
pwsh -File tools\elevate.ps1 -Script .\deploy.ps1               # 提权运行，检查不过直接拒绝
```

`elevate.ps1` 只找 `pwsh.exe`（PowerShell 7），找不到就报错退出，不会悄悄退回 5.1。检查器是 AST 级判断，不是正则猜——`"#{0} {1} {2} BusType={3}" -f $a,$b,$c` 这种语法完全合法、运行时才炸的写法会被静态拦下。

## 教训库

每台机器各有一份，装完自动在本地生长，不需要联网同步：

```powershell
$tool = "$env:DSH_HOME\tools\lessons.ps1"
powershell -ExecutionPolicy Bypass -File $tool due         # 今天该复习哪些
powershell -ExecutionPolicy Bypass -File $tool new -Title "一句话标题"
powershell -ExecutionPolicy Bypass -File $tool mark L-2026-10-24-01 -Grade 4
powershell -ExecutionPolicy Bypass -File $tool stats
```

库文件：`$env:DSH_HOME\lessons-learned.md`。纯 PowerShell，不依赖 python；条目格式五段式（场景/教训/预防/适用/失效条件），复习间隔用 SM-2 算。

`probe-encoding.ps1` 单独放着，装完建议先跑一次：

```powershell
powershell -ExecutionPolicy Bypass -File .\probe-encoding.ps1
```

它输出四行本机事实（PS 版本、chcp、控制台编码、Python stdout 编码），顺带复现 Python 输出中文的失败。不同机器这几行经常不同，所以技能里写的是「按测到的值选」，不是「一律 UTF-8」。

## 这个仓库故意不放什么

- **本机事实**：代理配置、VPS 地址、服务名、本机解释器路径。换台机器就不成立，还会制造错误结论。
- **第三方技能包**：版权与署名不属于我，要装请回原仓库。
- **教训库**：里面混有机器状态和过程中的敏感信息。

要带机器特定的东西，用私有仓库或 U 盘，不要放这里。

## 更新

```powershell
cd dsh-skills
git pull
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Force
```

没有 git 的机器：重新下载 zip，再跑一次 `install.ps1 -Force`。
