# dsh-skills

DSH 客户端的基础纪律技能包。装到任何一台机器上，模型就带上：**编码先测后写**、**结论分三档核实**、**受控系统诊断方法**。

## 新机器两条命令

```powershell
irm https://raw.githubusercontent.com/matt12121967/dsh-skills/main/install.ps1 -OutFile $env:TEMP\dsh-install.ps1
powershell -ExecutionPolicy Bypass -File $env:TEMP\dsh-install.ps1
```

装完新开一个 DSH 会话，技能目录里应出现三条。第二行可以加参数：

```powershell
# 只装一条
powershell -ExecutionPolicy Bypass -File $env:TEMP\dsh-install.ps1 -Only windows-encoding-discipline
# 覆盖已有
powershell -ExecutionPolicy Bypass -File $env:TEMP\dsh-install.ps1 -Force
```

（不要用 `irm ... | iex`：管道会把脚本按行拆开，`param()` 块直接语法错误。本仓库实测踩过。）

网络访问 GitHub 慢或被拦时：下载仓库 zip，解压后在该目录运行 `powershell -ExecutionPolicy Bypass -File .\install.ps1`，本地装，效果一样。

## 装了什么

| 技能 | 管什么 |
| `windows-encoding-discipline` | 乱码、UTF-16、`UnicodeEncodeError`：先跑探针拿本机事实，再按症状选写法，改完读回字节 |
| `verify-before-claim` | 幻觉与「没实测就下结论」：每句话分跑过/读过/推测，外部事实查原文，判定「被拦」要有对照 |
| `engineering-cybernetics` | 钱学森《工程控制论》方法：建模→判稳→定结构→配指标→覆盖不确定性→验证；诊断「反复出错」的闭环 |

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
