#Include <Constants.au3>
#NoTrayIcon

EnvSet("PAPERCLIP_ENV", "production")

Local $val = 0
Do
  $val = RunWait(".\bin\rubyw.exe -C .\src start.rb")
Until $val <> 8

;RunWait(".\bin\rubyw.exe -C .\src start.rb")
