@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
cd /d "%~dp0"

echo ============================================================
echo   VideoTrans AI (pyVideoTrans) Windows 一键打包
echo ============================================================
echo.
echo  用法:  build_win.bat           轻量版(默认, 与官方 sp.exe 一致)
echo         build_win.bat full      完整版(打包全部本地模型依赖, 数GB)
echo.

set "FULL=0"
if /i "%~1"=="full" set "FULL=1"
if "%FULL%"=="1" (
  echo  [模式] 完整版: 含 faster-whisper/F5-TTS/CosyVoice 等全部本地引擎
) else (
  echo  [模式] 轻量版: GUI + 全部在线/API 渠道(Edge-TTS/OpenAI/DeepSeek/...)
  echo         本地 ML 渠道在打包版中不可用(与官方 sp.exe 行为一致)
)
echo.

REM ---------------- 1. 检查 uv ----------------
where uv >nul 2>nul
if errorlevel 1 (
  echo [1/6] 未检测到 uv, 正在安装...
  powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
  if errorlevel 1 ( echo uv 安装失败, 请手动安装后重试 & exit /b 1 )
  set "PATH=%USERPROFILE%\.local\bin;%PATH%"
)
echo [1/6] uv: & uv --version

REM ---------------- 2. 安装依赖 ----------------
echo [2/6] 安装依赖 (uv sync, 含 torch 首次约 10-30 分钟)...
uv sync --no-dev
if errorlevel 1 ( echo 依赖安装失败 & exit /b 1 )

REM ---------------- 3. ffmpeg ----------------
if not exist "ffmpeg\ffmpeg.exe" (
  echo [3/6] 下载 ffmpeg (BtbN 官方构建)...
  .venv\Scripts\python.exe videotrans\task\update_ffmpeg.py
  if errorlevel 1 ( echo ffmpeg 下载失败, 可重跑本脚本 & exit /b 1 )
) else (
  echo [3/6] ffmpeg 已存在, 跳过下载
)

REM ---------------- 4. PyInstaller 打包 ----------------
echo [4/6] PyInstaller 打包 (onedir, 首次约 10-30 分钟)...
if "%FULL%"=="1" set "BUILD_FULL=1"
.venv\Scripts\python.exe -m PyInstaller --noconfirm --clean sp.spec
if errorlevel 1 ( echo PyInstaller 打包失败, 查看上方日志 & exit /b 1 )

REM ---------------- 5. 组装运行时目录到 dist\sp\ ----------------
echo [5/6] 组装运行时数据 (videotrans 配置树 / ffmpeg / f5-tts)...
set "PKG=dist\sp"

for %%d in (styles prompts voicejson language) do (
  if exist "videotrans\%%d" xcopy /e /i /y "videotrans\%%d" "%PKG%\videotrans\%%d\" >nul
)
if not exist "%PKG%\videotrans\codes" mkdir "%PKG%\videotrans\codes"
if exist "videotrans\codes\model.py" copy /y "videotrans\codes\model.py" "%PKG%\videotrans\codes\" >nul
for %%f in (cfg.json codec.json params.json ass.json glossary.txt newlang.txt) do (
  if exist "videotrans\%%f" copy /y "videotrans\%%f" "%PKG%\videotrans\" >nul
)
if exist "ffmpeg" xcopy /e /i /y "ffmpeg" "%PKG%\ffmpeg\" >nul
if not exist "%PKG%\f5-tts" mkdir "%PKG%\f5-tts"
if exist "f5-tts\*.wav" copy /y "f5-tts\*.wav" "%PKG%\f5-tts\" >nul

REM 读版本号用于安装包命名
set "APPVER=4.09"
for /f "tokens=2 delims=^"" %%v in ('findstr /C:"VERSION = " videotrans\__init__.py') do set "APPVER=%%v"

REM ---------------- 6. 生成安装包 ----------------
set "ISCC="
where iscc >nul 2>nul && set "ISCC=iscc"
if not defined ISCC if exist "%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe" set "ISCC=%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe"

if defined ISCC (
  echo [6/6] 使用 Inno Setup 生成安装包...
  "%ISCC%" installer.iss /DMyAppVersion=%APPVER%
  if errorlevel 1 ( echo 安装包生成失败 & exit /b 1 )
  echo.
  echo ============================================================
  echo   打包完成!
  echo   可执行文件: dist\sp\sp.exe
  echo   安装包:     installer\VideoTransAI-%APPVER%-setup.exe
  echo ============================================================
) else (
  echo [6/6] 未安装 Inno Setup, 生成便携 zip 包...
  echo        (可运行: winget install JRSoftware.InnoSetup 后重跑)
  powershell -NoProfile -Command "Compress-Archive -Path '%PKG%\*' -DestinationPath 'dist\VideoTransAI-%APPVER%-portable.zip' -Force"
  echo.
  echo ============================================================
  echo   打包完成! (便携版, 无安装程序)
  echo   可执行文件: dist\sp\sp.exe
  echo   便携包:     dist\VideoTransAI-%APPVER%-portable.zip
  echo ============================================================
)

pause
endlocal
