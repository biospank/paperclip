# encoding: utf-8

require 'app/helpers/yaml_db.rb'

module Helpers
  module ConfigurazioneHelper
    WXBRA_AZIENDA_FOLDER = 0
    WXBRA_PROGRESSIVI_FOLDER = 1
    WXBRA_DATABASE_FOLDER = 2
    WXBRA_UTENTI_FOLDER = 3
    
    # dimensioni del logo
    WXBRA_LOGO_HEIGHT = 113
    WXBRA_LOGO_WIDTH = 302
    
    module Db
      module Schema
        # Create a db/schema.rb file that can be portably used against any DB supported by AR
        def dump
          require 'active_record/schema_dumper'
          File.open(ENV['SCHEMA'] || "db/schema.rb", "w") do |file|
            ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, file)
          end
        end
        
        module_function :dump

        # Load a schema.rb file into the database
        def restore
          file = ENV['SCHEMA'] || "db/schema.rb"
          if File.exists?(file)
            load(file)
            sm_table = ActiveRecord::Migrator.schema_migrations_table_name
            conn = ActiveRecord::Base.connection
            migrated = conn.select_values("SELECT version FROM #{sm_table}").last
            puts("Table #{sm_table} migrate to version #{migrated}")
            conn.execute "DELETE FROM #{sm_table}"
            1.upto(migrated.to_i) do |v|
              conn.execute "INSERT INTO #{sm_table} (version) VALUES ('#{v}')"
            end
          else
            abort %{#{file} doesn't exist yet. Run "rake db:migrate" to create it then try again. If you do not intend to use a database, you should instead alter #{Rails.root}/config/boot.rb to limit the frameworks that will be loaded}
          end
        end

        module_function :restore

      end
      
      module Data
        def db_dump_data_file (extension = "yml")
          "#{dump_dir}/data.#{extension}"
        end

        module_function :db_dump_data_file

        def dump_dir(dir = "")
          "db#{dir}"
        end

        module_function :dump_dir
        
        # Dump contents of database to db/data.extension (defaults to yaml)
        def dump
          format_class = ENV['class'] || "YamlDb::Helper"
          helper = format_class.constantize
          SerializationHelper::Base.new(helper).dump(db_dump_data_file(helper.extension))
        end
        
        module_function :dump

        # Load contents of db/data.extension (defaults to yaml) into database
        def restore
          format_class = ENV['class'] || "YamlDb::Helper"
          helper = format_class.constantize
          SerializationHelper::Base.new(helper).load(db_dump_data_file(helper.extension))
        end

        module_function :restore

      end
    end
  end
end
