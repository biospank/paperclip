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

  $exit_code = 0

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
    # rescue SystemExit => se
    #   exit(se.status)
    rescue Exception => e
      logger.fatal('Unrecoverable Error: ' + e.message)
      logger.fatal('Backtrace: ' + "\n" + e.backtrace.join("\n")) if e.backtrace
      exit(1)
    end
  end

  # def on_run
  #   super
  #   logger.info("Exit code: #{$exit_code}")
  #   return $exit_code
  # end

end

PaperclipApp.new.main_loop
