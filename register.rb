require 'rubygems'
require 'win32/service'
include Win32

# https://github.com/abstractcoder/example-ruby-windows-service

# issue command ocra register.rb to build executable

# sc start pserver (on command prompt to start the service)
# sc stop pserver (on command prompt to stop the service)

# puts "#{`echo %cd%`.chomp}\\bin\\ruby.exe -C #{`echo %cd%`.chomp}\\src app\\win_udp_server.rb"

unless defined?(Ocra)
  Service.create({
    service_name: 'pserver',
    host: nil,
    service_type: Service::WIN32_OWN_PROCESS,
    description: 'Paperclip udp server',
    start_type: Service::AUTO_START,
    error_control: Service::ERROR_NORMAL,
    #binary_path_name: "#{`echo %cd%`.chomp}\\pserver.exe",
    binary_path_name: "#{`echo %cd%`.chomp}\\bin\\ruby.exe -C #{`echo %cd%`.chomp}\\src app\\win_udp_server.rb",
    load_order_group: 'Network',
    dependencies: nil,
    display_name: 'Paperclip udp server'
  })

  Service.start("pserver")
end
