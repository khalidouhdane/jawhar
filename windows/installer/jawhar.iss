; Jawhar Windows installer
; Compiled by iscc in CI (windows.yml) and locally.
; Source: build\windows\x64\runner\Release\* (quran_app.exe + DLLs + data/)
; Output: jawhar-setup.exe

#ifndef AppVersion
  #define AppVersion "1.0.0"
#endif

[Setup]
AppName=Jawhar
AppVersion={#AppVersion}
AppPublisher=Alphafoundr
AppPublisherURL=https://jawhar.alphafoundr.com
AppSupportURL=https://jawhar.alphafoundr.com
AppUpdatesURL=https://github.com/khalidouhdane/jawhar/releases
DefaultDirName={autopf}\Jawhar
DefaultGroupName=Jawhar
DisableProgramGroupPage=yes
OutputDir=..\..\
OutputBaseFilename=jawhar-setup
Compression=lzma2/ultra64
SolidCompression=yes
PrivilegesRequired=admin
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
UninstallDisplayIcon={app}\quran_app.exe
UninstallDisplayName=Jawhar
WizardStyle=modern
; Icon reused from the Flutter Windows project
SetupIconFile=..\runner\resources\app_icon.ico

; --- Code signing placeholder (future) ---
; Uncomment and set SignTool when a code-signing certificate is obtained.
; SignTool=signtool sign /f $fCertPath /p $fCertPassword /tr http://timestamp.digicert.com /td sha256 /fd sha256 $f
; SignedOutput=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; The Flutter release build output (exe + DLLs + data/). Everything recursed.
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Jawhar"; Filename: "{app}\quran_app.exe"; IconFilename: "{app}\quran_app.exe"
Name: "{group}\{cm:UninstallProgram,Jawhar}"; Filename: "{uninstallexe}"
Name: "{commondesktop}\Jawhar"; Filename: "{app}\quran_app.exe"; IconFilename: "{app}\quran_app.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\quran_app.exe"; Description: "{cm:LaunchProgram,Jawhar}"; Flags: nowait postinstall skipifsilent
