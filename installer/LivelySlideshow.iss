#define MyAppName "LivelySlideshow"
#ifndef MyAppVersion
  #define MyAppVersion "1.0.0"
#endif
#define MyAppPublisher "LivelySlideshow contributors"
#define MyAppURL "https://github.com/rocksdanister/lively"
#define LivelyCUVersion "v2.0.4.0"
#define LivelyCUUrl "https://github.com/rocksdanister/lively/releases/download/v2.0.4.0/lively_command_utility.zip"

[Setup]
AppId={{A8B6D7CB-2CB7-4DE1-A135-B95B8FB3D712}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={localappdata}\LivelySlideshow
DisableDirPage=yes
DisableProgramGroupPage=yes
DisableReadyPage=yes
DisableWelcomePage=no
Compression=lzma
SolidCompression=yes
OutputDir=..\dist
OutputBaseFilename=LivelySlideshowSetup
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
SetupLogging=yes
WizardStyle=modern
UninstallDisplayName=LivelySlideshow

[Files]
Source: "..\app\*"; DestDir: "{app}\app"; Flags: recursesubdirs createallsubdirs ignoreversion
Source: "..\LICENSE"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\third_party_licenses\*"; DestDir: "{app}\third_party_licenses"; Flags: recursesubdirs createallsubdirs ignoreversion
Source: "..\README.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "Download-LivelyCU.ps1"; DestDir: "{tmp}"; Flags: deleteafterinstall

[Run]
Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{tmp}\Download-LivelyCU.ps1"" -DestinationPath ""{app}\app\livelycu.exe"""; Flags: runhidden waituntilterminated
Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\app\scripts\Register-StartupTask.ps1"""; Flags: runhidden waituntilterminated
Filename: "wscript.exe"; Parameters: """{app}\app\scripts\LaunchHidden.vbs"""; Flags: runhidden nowait

[UninstallRun]
Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\app\scripts\Uninstall-LivelySlideshow.ps1"""; RunOnceId: "UninstallLivelySlideshow"; Flags: runhidden waituntilterminated skipifdoesntexist

[UninstallDelete]
Type: files; Name: "{app}\app\livelycu.exe"
Type: files; Name: "{app}\data\config.json"
Type: files; Name: "{app}\data\state.json"
Type: filesandordirs; Name: "{app}\data\logs"
Type: filesandordirs; Name: "{app}\data"

[Code]
function IsLivelyInstalled: Boolean;
var
  FindRec: TFindRec;
  PackagePattern: string;
begin
  Result :=
    FileExists(ExpandConstant('{localappdata}\Programs\Lively Wallpaper\Lively.exe')) or
    FileExists(ExpandConstant('{localappdata}\Programs\Lively Wallpaper\lively.exe')) or
    FileExists(ExpandConstant('{localappdata}\Programs\Lively Wallpaper\Livelywpf.exe')) or
    FileExists(ExpandConstant('{localappdata}\Programs\Lively Wallpaper\livelywpf.exe'));

  if Result then
  begin
    exit;
  end;

  PackagePattern := ExpandConstant('{localappdata}\Packages\12030rocksdanister.LivelyWallpaper*');
  if FindFirst(PackagePattern, FindRec) then
  begin
    try
      Result := True;
    finally
      FindClose(FindRec);
    end;
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    if not IsLivelyInstalled then
    begin
      MsgBox(
        'Lively Wallpaper is required for LivelySlideshow to change wallpapers.' + #13#10 + #13#10 +
        'Install Lively Wallpaper from:' + #13#10 +
        'https://github.com/rocksdanister/lively',
        mbInformation,
        MB_OK
      );
    end;
  end;
end;
