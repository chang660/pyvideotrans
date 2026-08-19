; ============================================================================
; VideoTrans AI (pyVideoTrans) — Windows 安装包 (Inno Setup 6)
;
; 编译:  "%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe" installer.iss
;       (build_win.bat 会自动调用, 或加 /DMyAppVersion=4.09 指定版本号)
;
; 前置: 先运行 PyInstaller 生成 dist\sp\ (onedir), 并把 videotrans/ 运行时
;       配置树、ffmpeg/、f5-tts/ 复制到 dist\sp\ 下(见 build_win.bat)
; ============================================================================

#ifndef MyAppVersion
  #define MyAppVersion "4.09"
#endif

#define MyAppName "VideoTrans AI"
#define MyAppPublisher "VideoTrans AI"
#define MyAppExeName "sp.exe"

[Setup]
AppId={{B3417DDE-60A6-445D-95BD-161E704944F3}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\VideoTransAI
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir=installer
OutputBaseFilename=VideoTransAI-{#MyAppVersion}-setup
SetupIconFile=videotrans\styles\icon.ico
UninstallDisplayIcon={app}\videotrans\styles\icon.ico
Compression=lzma2/ultra
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
; 完整版安装包可达数 GB, 允许大文件
MinVersion=10.0

[Tasks]
Name: "desktopicon"; Description: "创建桌面快捷方式"; GroupDescription: "附加任务:"; Flags: unchecked

[Files]
; 整个打包目录(含 _internal、videotrans 配置树、ffmpeg、f5-tts)
Source: "dist\sp\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\videotrans\styles\icon.ico"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\videotrans\styles\icon.ico"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "立即运行 {#MyAppName}"; Flags: nowait postinstall skipifsilent

; 卸载时保留用户数据(models 模型、tmp 缓存、logs 日志、output 产物均位于 {app} 下, 不删除)
