; Inno Setup Script для ZZZ Mod Manager
; Цей файл використовується для створення Windows installer
; Потрібен Inno Setup 6.0 або новіше: https://jrsoftware.org/isdl.php

#define MyAppName "ZZZ Mod Manager"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "NotionMe"
#define MyAppURL "https://github.com/NotionMe/Mod-manager"
#define MyAppExeName "mod_manager_flutter.exe"
#define MyAppId "{{B8E5F7A1-2C3D-4E5F-9A1B-3C4D5E6F7A8B}"

[Setup]
; Основні налаштування
AppId={#MyAppId}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}/issues
AppUpdatesURL={#MyAppURL}/releases
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
LicenseFile=..\LICENSE
; Іконка для installer (опціонально)
; SetupIconFile=..\assets\icon.ico
OutputDir=output
OutputBaseFilename=ZZZ-Mod-Manager-Setup-{#MyAppVersion}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
; Права адміністратора (потрібні для створення симлінків на Windows)
PrivilegesRequired=admin
PrivilegesRequiredOverridesAllowed=dialog

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "ukrainian"; MessagesFile: "compiler:Languages\Ukrainian.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "quicklaunchicon"; Description: "{cm:CreateQuickLaunchIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked; OnlyBelowVersion: 6.1; Check: not IsAdminInstallMode

[Files]
; Основні файли програми (з Windows build)
Source: "..\mod_manager_flutter\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; Іконка
Source: "..\assets\icon.png"; DestDir: "{app}\data\flutter_assets\assets"; Flags: ignoreversion

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon
Name: "{userappdata}\Microsoft\Internet Explorer\Quick Launch\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: quicklaunchicon

[Run]
; Запустити програму після установки
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Code]
// Перевірка системних вимог
function InitializeSetup(): Boolean;
var
  Version: TWindowsVersion;
begin
  GetWindowsVersionEx(Version);
  
  // Перевірка Windows 10 або новіше
  if Version.Major < 10 then
  begin
    MsgBox('Цей додаток вимагає Windows 10 або новішу версію.', mbError, MB_OK);
    Result := False;
  end
  else
    Result := True;
end;

// Повідомлення про необхідність прав адміністратора для симлінків
procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    MsgBox('Увага: Для створення мод-симлінків програма вимагає запуску від імені адміністратора.' + #13#10 + 
           'Рекомендується завжди запускати ZZZ Mod Manager від імені адміністратора.', 
           mbInformation, MB_OK);
  end;
end;
