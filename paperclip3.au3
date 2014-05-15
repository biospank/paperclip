#Include <Constants.au3>
#NoTrayIcon

EnvSet("PAPERCLIP_ENV", "production")
RunWait("bin\rubyw.exe -C .\src start.rb")
