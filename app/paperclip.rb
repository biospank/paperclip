# encoding: utf-8

require 'rubygems'
require 'wx'
require 'app/config/environment'
require 'app/helpers/application_helper'
require 'app/helpers/wx_helper'
require 'app/views/main_frame'
# debug
#require 'ruby-debug' if configatron.env == 'development'

include Wx

class PaperclipApp < App
  include Views::Base::View
  
  def on_init
    begin
      logger.info("Environment: #{configatron.env}")
      logger.info('loading application...')
      main = Views::MainFrame.new
      main.min_size = [1000, 680]
      main.maximize(true)
      main.show
      main.request_user_attention
      main.login
    rescue Exception => e
      logger.fatal('Unrecoverable Error: ' + e.message)
      logger.fatal('Backtrace: ' + "\n" + e.backtrace.join("\n")) if e.backtrace
      exit(1)
    end
  end
  
#  def on_exit
#    logger.info('Exiting..')
#    non funziona il fork sotto windows
#    utilizzo win32-process
#    exec("ruby init.rb")
#    logger.info('Exited!')
#  end
  
end

PaperclipApp.new.main_loop
