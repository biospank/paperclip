$:.unshift File.dirname(__FILE__)
Encoding.default_external = 'UTF-8'
ENV['PAPERCLIP_BUILD'] = 'true' if defined?(Ocra)
require 'app/paperclip.rb'
