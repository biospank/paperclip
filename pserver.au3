#Include <Constants.au3>
#NoTrayIcon

EnvSet("PAPERCLIP_ENV", "server")
If(@Compiled) Then
    If( Not FileExists(@StartupDir & '\pserver.lnk') ) Then
        FileCreateShortcut(@AutoItExe, @StartupDir & "\pserver.lnk", @WorkingDir)
        RunWait("ruby.exe init.rb", @WorkingDir, @SW_HIDE)
    Else
        RunWait("ruby.exe init.rb", @WorkingDir, @SW_HIDE)
    EndIf
EndIf

