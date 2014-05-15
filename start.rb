$:.unshift File.dirname(__FILE__)
Encoding.default_external = 'UTF-8'
ENV['PAPERCLIP_BUILD'] = 'true' if defined?(Ocra)
if ENV['PAPERCLIP_ENV'] == 'server'
  require 'app/udp_server.rb'
else
  require 'app/paperclip.rb'
end
