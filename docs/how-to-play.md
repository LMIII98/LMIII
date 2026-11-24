# 怎么玩过序章

## 一句命令

```powershell
powershell -ExecutionPolicy Bypass -File D:\GTA6.Xbox.v1.0.2\play-fork.ps1
```

它会用 diag 构建启动、把窗口拿到前台、**每 3 秒按一次 Enter、每 45 秒按一次 Esc**，
把载入画面和开场过场自动按过去；**前 6 分钟后停止按键**，剩下就交给你玩。
窗口可以随时点回去给焦点（脚本每 4 秒也会帮你拿一次）。

## 键位（键盘 = 手柄）

| 键盘 | 手柄 | 用途 |
|---|---|---|
| **W A S D** | 左摇杆 | 走/跑 |
| **I J K L** | 右摇杆 | 转视角 |
| **Enter** | A | 确认 / 跳 / 互动（上车、拾取） |
| **Backspace** | B | 取消 / 近战 / 返回 |
| **X** / **Y** | X / Y | 动作键（近战、换弹等） |
| **↑ ↓ ← →** | 十字键 | 菜单与快捷选择 |
| **Q** / **E** | LB / RB | 肩键（武器轮盘、电话） |
| **F** / **H** | L3 / R3 | 摇杆按下 |
| **Z** / **C** | LT / RT | 瞄准 / 开火 |
| **Tab** | View | 切换视角 |
| **Esc** | Menu | 暂停菜单 |

## 提示

- 分辨率已设为 1920×1080（`D:\victory-data\data\7952987A\storage\settings\settings.xml`，
  备份 `.bak-2026-11-25`），实测 **3 fps 左右**，10 分钟以上不掉设备；
- 背光面偏黑是这支 fork 还没接 ray-traced 光，属已知；
- 过场里按 **Enter** 可以跳过；不想跳就等前 6 分钟过去（脚本会自动停手）；
- 序章结束游戏会自存档：`D:\victory-data\data\7952987A\saves\0009000000000001\`，
  下次启动在开始界面选**继续**，不必重看开场。

## 如果中途掉设备（`0x887A0006`）

说明跑到了那条会挂住显卡的 compute 管线。确认你起的是 **diag** 构建
（`victory-gta6\target\diag\victory.exe`）——`VICTORY_SKIP_PIPELINES` 与
`VICTORY_GPU_TIMING` 只在诊断特性里生效，release 构建等于没设置。
