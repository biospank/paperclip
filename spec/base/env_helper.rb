require 'wx'
require 'configatron'
require 'active_record'
require 'app/models/base'
require 'app/helpers/logger_helper'

module EnvHelper
  configatron.configure_from_yaml('conf/paperclip.yml')

  ActiveRecord::Base.logger = Helpers::Logger::LoggerHelper.instance()

  #configatron.set_default(:env, (ENV['PAPERCLIP_ENV'] || 'development'))
  configatron.env = 'development'

  ActiveRecord::Base.establish_connection(
    :adapter => 'sqlite3',
    :database => File.join('db', configatron.env, 'bra.db'),
    :encoding => 'utf8'

  )

  ActiveRecord::Base.extend Models::Base::Searchable

  # load dei modelli
  model = File.dirname(__FILE__) + "/../../app/models"
  Dir.foreach(model) { |f|
    require "#{model}/#{f}" if f[-3..-1] == '.rb'
  }


end

