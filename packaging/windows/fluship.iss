#ifndef AppVersion
  #define AppVersion "1.0.0"
#endif

[Setup]
AppId={{7F3C1A2E-4B58-4E1D-9C0A-6D5E8F2B1A44}
AppName=Fluship
AppVersion={#AppVersion}
AppPublisher=Huraira
DefaultDirName={autopf}\Fluship
DefaultGroupName=Fluship
DisableProgramGroupPage=yes
OutputDir=..\..\dist
OutputBaseFilename=Fluship-{#AppVersion}-windows-x64-setup
SetupIconFile=..\..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\fluship.exe
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
PrivilegesRequired=admin

[Files]
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\Fluship"; Filename: "{app}\fluship.exe"
