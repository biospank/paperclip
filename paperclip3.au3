#Include <Constants.au3>
#NoTrayIcon

EnvSet("PAPERCLIP_ENV", "production")

Local $val = 0
Do
  $val = RunWait(".\bin\rubyw.exe -C .\src start.rb")
  ;MsgBox(0, "Program returned with exit code:", $val)
Until $val <> 8
