# encoding: utf-8

require 'logging'
require 'singleton'

module Helpers
  module Logger
    
    class LoggerHelper < Logging::Logger
      include Singleton

      def initialize()
        super('PaperClip')
        ruby_version = RbConfig::CONFIG['ruby_version'].split('.').join.to_i
        if ruby_version > 186
          self.add_appenders(Logging.appenders.stdout) if configatron.env == 'development'
          self.add_appenders(Logging.appenders.file(configatron.logging_config.filename))
        else
          self.add_appenders(Logging::Appender.stdout) if configatron.env == 'development'
          self.add_appenders(Logging::Appenders::File.new(configatron.logging_config.filename))
        end
        self.level = (configatron.env == 'development') ? :debug : :info
        $stdout = self
      end

      # per compatibilità con la write di stdout
      def write(text)
        self.debug(text)
      end

    end

    def Logger.included(mod)
      LoggerHelper.instance()
      
    end
    
    def logger
      LoggerHelper.instance()
    end
      
  end
end
