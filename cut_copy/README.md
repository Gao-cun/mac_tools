# cut_copy

macOS 菜单栏工具：把系统截图统一保存到 `~/Pictures/CutCopyShots`，并在开启时自动复制截图到剪贴板。

## 功能

- 菜单栏一键开关自动复制（全屏/区域/窗口截图都生效）
- 首次启动自动设置系统截图保存目录为 `~/Pictures/CutCopyShots`
- 一键清除截图（移到废纸篓，可恢复）
- 可切换开机启动

## 开发运行

```bash
cd mac_tools/cut_copy
swift run CutCopyApp
```

或使用脚本：

```bash
cd mac_tools/cut_copy
./scripts/dev_run.sh
```

## 打包成 App

仅打包到 `dist/CutCopy.app`：

```bash
cd mac_tools/cut_copy
./scripts/package_app.sh
```

打包并安装到 `~/Applications/CutCopy.app`：

```bash
cd mac_tools/cut_copy
./scripts/package_app.sh --install
```

安装后可直接在 Launchpad / Spotlight 搜索 `CutCopy` 启动。

## 验收步骤

1. 启动应用后，菜单栏出现 `CutCopy`。
2. 截图目录应为 `~/Pictures/CutCopyShots`。
3. 执行 `Cmd+Shift+3`、`Cmd+Shift+4`、`Cmd+Shift+4` 后按空格，均可直接 `Cmd+V` 粘贴。
4. 点击“一键清除截图”后，截图被移到废纸篓。

## 说明

- 当前项目为 Swift Package 形态，适合本地开发和运行。
- 开机启动调用 `SMAppService`，在未打包签名场景下可能被系统拒绝，菜单会提示错误信息。
