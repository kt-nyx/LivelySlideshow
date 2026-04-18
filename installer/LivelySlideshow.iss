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
SetupIconFile=..\tray.ico
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
UninstallDisplayIcon={app}\tray.ico

[Files]
Source: "..\app\*"; DestDir: "{app}\app"; Flags: recursesubdirs createallsubdirs ignoreversion
Source: "..\LICENSE"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\third_party_licenses\*"; DestDir: "{app}\third_party_licenses"; Flags: recursesubdirs createallsubdirs ignoreversion
Source: "..\README.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\tray.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "Download-LivelyCU.ps1"; DestDir: "{tmp}"; Flags: deleteafterinstall; AfterInstall: FinalizeInstall

[UninstallRun]
Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\app\scripts\Uninstall-LivelySlideshow.ps1"""; RunOnceId: "UninstallLivelySlideshow"; Flags: runhidden waituntilterminated skipifdoesntexist

[UninstallDelete]
Type: files; Name: "{app}\app\livelycu.exe"
Type: files; Name: "{app}\data\config.json"
Type: files; Name: "{app}\data\state.json"
Type: filesandordirs; Name: "{app}\data\logs"
Type: filesandordirs; Name: "{app}\data"

[Code]
function RunHiddenPowerShell(const ScriptPath, ScriptArguments: String; var ResultCode: Integer): Boolean;
var
  Parameters: string;
begin
  Parameters :=
    '-NoProfile -ExecutionPolicy Bypass -File "' + ScriptPath + '"';

  if ScriptArguments <> '' then
  begin
    Parameters := Parameters + ' ' + ScriptArguments;
  end;

  Result := Exec(
    ExpandConstant('{sys}\WindowsPowerShell\v1.0\powershell.exe'),
    Parameters,
    '',
    SW_HIDE,
    ewWaitUntilTerminated,
    ResultCode
  );
end;

procedure FailInstall(const ErrorMessage: string);
begin
  MsgBox(ErrorMessage, mbCriticalError, MB_OK);
  RaiseException(ErrorMessage);
end;

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

procedure FinalizeInstall;
var
  ResultCode: Integer;
begin
  if not RunHiddenPowerShell(
    ExpandConstant('{tmp}\Download-LivelyCU.ps1'),
    '-DestinationPath "' + ExpandConstant('{app}\app\livelycu.exe') + '"',
    ResultCode
  ) then
  begin
    FailInstall('Setup could not start the livelycu.exe download step. Setup will now roll back.');
  end;

  if ResultCode <> 0 then
  begin
    FailInstall(
      'Setup could not download livelycu.exe.' + #13#10 + #13#10 +
      'Check your internet connection and try again. Setup will now roll back.'
    );
  end;

  if not RunHiddenPowerShell(
    ExpandConstant('{app}\app\scripts\Register-StartupTask.ps1'),
    '',
    ResultCode
  ) then
  begin
    FailInstall('Setup could not register the LivelySlideshow startup task. Setup will now roll back.');
  end;

  if ResultCode <> 0 then
  begin
    FailInstall('Setup could not register the LivelySlideshow startup task. Setup will now roll back.');
  end;

  if IsLivelyInstalled then
  begin
    if not Exec(
      'wscript.exe',
      '"' + ExpandConstant('{app}\app\scripts\LaunchHidden.vbs') + '"',
      '',
      SW_HIDE,
      ewNoWait,
      ResultCode
    ) then
    begin
      Log('LivelySlideshow could not be launched automatically after setup.');
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
