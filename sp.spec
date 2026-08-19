# -*- mode: python ; coding: utf-8 -*-
"""
VideoTrans AI (pyVideoTrans) — Windows 打包配置 (PyInstaller onedir)

用法 (Windows 或 GitHub Actions windows-latest):
    uv run pyinstaller --noconfirm --clean sp.spec

完整版(打包全部本地 ML 依赖, 体积数 GB, 构建时间长):
    set BUILD_FULL=1
    uv run pyinstaller --noconfirm --clean sp.spec

说明:
- onedir 布局: dist/sp/sp.exe + dist/sp/_internal/...
- 运行时数据(videotrans/ 配置树、ffmpeg/、f5-tts/)由 build_win.bat 复制到 exe 旁,
  与代码中 ROOT_DIR(冻结时=exe 所在目录)的读取逻辑保持一致, 无需打进 _internal
- 所有经 importlib 懒加载的渠道模块(tts/translator/recognition/process/task...)
  必须用 collect_submodules 显式收集, 否则打包后渠道全部丢失
"""
import os

from PyInstaller.utils.hooks import collect_submodules

FULL = os.environ.get('BUILD_FULL') == '1'

# ---- 懒加载渠道模块(动态 importlib, 静态分析看不到) ----
_hidden_pkgs = [
    'videotrans',
    'videotrans.tts',
    'videotrans.translator',
    'videotrans.recognition',
    'videotrans.process',
    'videotrans.task',
    'videotrans.component',
    'videotrans.configure',
    'videotrans.util',
    'videotrans.winform',
    'videotrans.ui',
    'videotrans.mainwin',
    'videotrans.codes',
    'videotrans.confuciustts',
    'videotrans.mosstts',
    'videotrans.moss_transcribe_diarize',
    'videotrans.external',
]
hiddenimports = []
for _p in _hidden_pkgs:
    hiddenimports += collect_submodules(_p)

# ---- 轻量版排除项(默认): 与官方 sp.exe 一致, GUI + 在线/API 渠道可用,
# 本地 ML 渠道(faster-whisper/F5-TTS/CosyVoice 等)在冻结版中不可用并报错提示
# BUILD_FULL=1 时全量打包(需要 torch cu128 等, 体积数 GB)
excludes = [
    'torch', 'torchaudio', 'torchvision',
    'transformers', 'transformers4576', 'diffusers', 'safetensors', 'accelerate', 'peft',
    'bitsandbytes', 'datasets', 'tokenizers',
    'funasr', 'modelscope', 'pyannote',
    'sherpa_onnx', 'faster_whisper', 'ctranslate2', 'openai_whisper', 'whisper',
    'onnxruntime', 'gradio', 'tensorflow', 'keras', 'jax', 'tensorboardx',
    'pynini', 'WeTextProcessing', 'pythonnet',
    'omnivoice', 'f5_tts', 'chatterbox', 'voxcpm', 'zipvoice', 'higgs', 'piper_tts',
    'qwen_asr_pvt', 'qwen_tts_pvt', 'elevenlabs',
    # 纯死重: 由上述库连带引入, 轻量版用不到
    'torchmetrics', 'pytorch_lightning', 'lightning', 'lightning_fabric', 'ema_pytorch',
    'wandb', 'einops', 'pyarrow', 'boto3', 'botocore', 's3transfer', 'fsspec',
] if not FULL else []

a = Analysis(
    ['sp.py'],
    pathex=[SPECPATH],
    binaries=[],
    datas=[],  # 运行时数据由打包脚本复制到 exe 旁, 见 build_win.bat
    hiddenimports=hiddenimports,
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=excludes,
    noarchive=False,
    optimize=0,
)

pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    exclude_binaries=True,
    name='sp',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=False,
    console=False,  # GUI 程序, 不弹黑窗口
    disable_windowed_traceback=False,
    icon=f'{SPECPATH}/videotrans/styles/icon.ico',
)

coll = COLLECT(
    exe,
    a.binaries,
    a.datas,
    strip=False,
    upx=False,
    name='sp',
)
