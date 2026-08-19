# Windows 安装包打包指南

本目录下的 `sp.spec`、`build_win.bat`、`installer.iss` 用于把本项目打包成 Windows 安装包。

> ⚠️ **重要前提**: PyInstaller **不支持跨平台交叉编译** —— Windows 的 .exe 必须在
> Windows 环境(真机 / 虚拟机 / GitHub Actions)上构建。macOS 上无法直接生成 .exe。

---

## 方案 A: GitHub Actions 云打包(推荐, 无需 Windows 机器)

1. 把本地代码推到**你自己的 GitHub 仓库**(fork 或新建仓库)。注意 `.gitignore`
   忽略了 `*.spec` 和 `*.bat`, 必须强制加入:

   ```bash
   git add -f sp.spec build_win.bat
   git add installer.iss .github/workflows/build-win-installer.yml
   git commit -m "add windows build kit"
   git push -u fork dev     # 本机工作分支是 dev; 建议把 fork 默认分支设为 dev
   ```

2. 到仓库 Actions 页面 → **Build Windows Installer** → `Run workflow`
   (模式选 `light` 轻量或 `full` 完整, ref 选 dev)。

3. 构建约 10~30 分钟, 完成后在 workflow 运行页下载 `VideoTransAI-installer`
   artifact, 里面就是 `VideoTransAI-4.09-setup.exe`。

4. (可选) 推送 `v*` 标签(如 `git tag v4.09-win && git push fork v4.09-win`)会自动构建
   并把安装包附加到 Release 页面。

## 方案 B: Windows 本机打包

在 Windows 10/11 机器上, 把整个项目文件夹(源码)拷过去, 然后:

```bat
:: 轻量版(默认, 与官方 sp.exe 一致)
build_win.bat

:: 完整版(打包全部本地模型依赖, 体积数 GB)
build_win.bat full
```

脚本会自动: 安装 uv → `uv sync` 装依赖 → 下载 ffmpeg → PyInstaller 打包 →
组装运行时目录 → 调用 Inno Setup 生成安装包(未装 Inno 则生成便携 zip)。

安装 Inno Setup 可选: `winget install JRSoftware.InnoSetup`

---

## 两种模式的区别

| | 轻量版 `light`(默认) | 完整版 `full` |
|---|---|---|
| 体积 | ~550 MB(实测) | 数 GB |
| 构建时间 | ~10-20 分钟 | 30-60 分钟 |
| GUI / WebUI / CLI | ✅ | ✅ |
| 在线渠道(Edge-TTS、OpenAI、DeepSeek、Gemini、MiniMax...) | ✅ | ✅ |
| 本地 ML 引擎(faster-whisper、F5-TTS、CosyVoice、VoxCPM、IndexTTS...) | ❌ | ✅ |
| 与官方 sp.exe 行为 | 一致 | 增强 |

> 轻量版本地 ML 渠道不可用是**预期行为**(官方 sp.exe 一直如此), 程序会给出
> 明确报错提示, 不影响其他功能。需要本地模型选 `full`。

## 打包产物结构

```
dist/sp/
├── sp.exe              # 主程序(onedir)
├── _internal/          # PyInstaller 依赖库
├── videotrans/         # 运行时配置树(cfg.json/params.json/styles/prompts/...)
├── ffmpeg/             # ffmpeg.exe / ffprobe.exe / ffplay.exe
└── f5-tts/             # 参考音频(可自放 wav)
```

安装后 models(模型)、tmp(缓存)、logs(日志)、output(产物)自动创建在程序目录下,
卸载时保留(用户数据)。

## 常见问题

- **`sp.spec` 未找到**: Actions 打包前记得 `git add -f sp.spec`。
- **构建报 module not found**: 渠道模块是懒加载的, 若新增了渠道文件, 确认
  `sp.spec` 的 `_hidden_pkgs` 覆盖了对应子包(或直接加 `collect_submodules`)。
- **exe 双击无反应**: 查看 `logs/` 下日志; 轻量版选中了本地 ML 渠道属正常报错。
- **ffmpeg 下载慢**: 国内网络可手动把 ffmpeg.exe/ffprobe.exe 放入 `ffmpeg/`
  目录后重跑, 脚本检测到已存在会跳过下载。
