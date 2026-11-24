# 在一台全新机器上回到 2026-11-25 的进度

这台机器是网吧机，关机就重置，所以这里写清“哪些要重下、哪些在仓库里、按什么顺序做”。

## 一、必须重新准备的东西（仓库里没有，也不该有）

| 东西 | 大小 | 怎么来 |
|---|---|---|
| 游戏数据 `GTA6.Xbox.v1.0.2` | **约 215 GB** | 你自己的那份 dump（`game_scarlett_master.exe`、`*.rpf`、`shaders.rpf`、`movies.rpf` 等） |
| `early_xmas`（可选） | 约 0.1 GB | 你原来那份 |
| 存档与设置（**建议带走**） | **272 KB** | 见下面第四节，复制到你自己的网盘/U 盘 |

游戏文件不进仓库（`docs/asset-policy.md` 的规则，仓库里也没有任何游戏内容）。

## 二、仓库里已经有、直接可用的

- 上游 VIctory 全历史 + 我们的提交（fence/indirect mesh、`_cl`、4 MiB 窗口 LRU 崩溃修复、
  波宽诊断、`VICTORY_SHADER_WAVE_RUN`、刷新合并、3D 目标形状测试、纹理探针、**Agility SDK 导出**）、
  上游 PR #305/#704/#1084 的合并；
- `pr/agility-sdk`：只含 Agility SDK 导出那 4 个文件（可直接向上游发 PR）；
- `gta6-fork`：老版 fork（`victory-gta6`）+ 我们的补丁；
- `gta6-fork-new`：**作者最新那支（`victory-fork`）+ 我们的补丁**，也就是今天实测 3.0–3.3 fps 的那套；
- `docs/`：`how-to-play.md`（键位/存档）、`branch-notes.md`、`progress-2026-11-25.md`（全部实验与数字）；
- `bootstrap/scripts/`：装工具链、套用设置、自动跳过、启动、更新仓库的脚本。

## 三、按顺序做（约 40 分钟，其中大半是下载）

```powershell
# 0) 装工具链：VS Build Tools（MSVC 14.44 + Win SDK）、Rust MSVC、Agility SDK、gh CLI
powershell -ExecutionPolicy Bypass -File bootstrap\scripts\install-toolchain.ps1

# 1) 克隆（含作者那支的最新代码）
git clone https://github.com/LMIII98/LMIII.git D:\GTA6.Xbox.v1.0.2\VIctory
cd D:\GTA6.Xbox.v1.0.2
git clone https://github.com/fxceless/victory-fork.git victory-gta6
cd victory-gta6
git fetch https://github.com/LMIII98/LMIII.git gta6-fork-new:newer
git checkout newer

# 2) 配置：把 victory.example.toml 复制成 D:\GTA6.Xbox.v1.0.2\victory.toml，改 game_dir 指向你的 dump
copy D:\GTA6.Xbox.v1.0.2\VIctory\victory.example.toml D:\GTA6.Xbox.v1.0.2\victory.toml
notepad D:\GTA6.Xbox.v1.0.2\victory.toml      # game_dir = 'D:\GTA6.Xbox.v1.0.2'

# 3) 构建（diag 才是稳定那套：VICTORY_SKIP_PIPELINES / GPU_TIMING 只在诊断特性里生效）
cd D:\GTA6.Xbox.v1.0.2\victory-gta6
cargo build --profile diag -p victory --features diagnostics
cargo build --release -p victory

# 4) 放好 Agility 的运行库（install-toolchain.ps1 会把它们放到 D:\_toolchain\agility）
New-Item -ItemType Directory -Force target\diag\D3D12, target\release\D3D12
Copy-Item D:\_toolchain\agility\*.dll target\diag\D3D12\ -Force
Copy-Item D:\_toolchain\agility\*.dll target\release\D3D12\ -Force

# 5) 开始玩（会自动套用轻量设置、自动跳过载入与过场）
powershell -ExecutionPolicy Bypass -File bootstrap\scripts\play.ps1 -Root D:\GTA6.Xbox.v1.0.2
```

## 四、带走存档（272 KB，值得带走）

关机前把这两个目录复制到自己的网盘/U 盘（它们是**你的**存档，别放进公开仓库）：

```
D:\victory-data\data\7952987A\saves\      (9 个文件，254 KB)
D:\victory-data\data\7952987A\storage\settings\settings.xml   (11 KB)
```

新机器上原样放回同一路径，`play.ps1` 就会接着上次的进度（开始界面选“继续”）。

## 五、脚本会自己处理的两件事

1. **设置被覆盖**：标题退出时会把自己的设置写回 `settings.xml`，把 1080p 和关掉的 RT 阴影冲回
   4K 默认。`play.ps1` 每次启动前都会调用 `apply-settings.ps1` 重新写回（无 BOM，先备份
   `settings.xml.tuned-backup`）。
2. **必须用 diag 构建**：`VICTORY_SKIP_PIPELINES=2561af9577c47289` 与 `VICTORY_GPU_TIMING=1`
   都在 `#[cfg(feature = "diagnostics")]` 后面，release 构建等于没设置，约 40 秒后会被那条
   compute 管线拖成 `0x887A0006`（掉设备）。`play.ps1` 默认指向 `target\diag\victory.exe`。

## 六、今天跑到的状态（供对照）

- 世界可玩、序章过场能出画；**3.0–3.3 fps**（305–335 ms/帧）；
- 帧时间构成：GPU 176–215 ms、准备 78–99 ms（拷贝 46–64 ms）、回读 21–39 ms、约 120 ms 显卡空闲；
- 已知无效/有害的调参清单在 `docs/progress-2026-11-25.md` 第 27 节，别再重复试；
- 下一步方向：合并拷贝（探针显示 5–10 倍空间）> 通道降频 > 统一地址空间。
