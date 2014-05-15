#Include <Constants.au3>
#NoTrayIcon

EnvSet("PAPERCLIP_ENV", "server")
If(@Compiled) Then
;~     If( Not FileExists(@StartupDir & '\pserver.lnk') ) Then
;~         FileCreateShortcut(@AutoItExe, @StartupDir & "\pserver.lnk", @WorkingDir)
        RunWait("bin\ruby.exe -C .\src app\udp_server.rb", @WorkingDir, @SW_HIDE)
;~     Else
;~         RunWait("bin\ruby.exe -C .\src app\udp_server.rb", @WorkingDir, @SW_HIDE)
;~     EndIf
Else
  RunWait("ruby.exe app\udp_server.rb")
EndIf
