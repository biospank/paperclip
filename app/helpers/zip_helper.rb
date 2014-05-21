# encoding: utf-8
if Running.mingw?
  require 'zip'
else
  require 'zip/zip'
end

module Helpers
  module ZipHelper
    IGNORE = ['lib/sqlite.dll']

    def create_archive(file_name, *entries)
      if Running.ruby_18?
        Zip::ZipOutputStream.open(file_name) do |zos|
          entries.each do |e|
            if File.directory? e
              Dir.glob("#{e}/**/*") do |filename|
                next if File.directory? filename
                add_new_entry(zos, filename) unless IGNORE.include? filename
              end
            else
              add_new_entry(zos, e) unless IGNORE.include? e
            end
          end
        end
      else
        Zip::OutputStream.open(file_name) do |zos|
          entries.each do |e|
            if File.directory? e
              Dir.glob("#{e}/**/*") do |filename|
                next if File.directory? filename
                add_new_entry(zos, filename) unless IGNORE.include? filename
              end
            else
              add_new_entry(zos, e) unless IGNORE.include? e
            end
          end
        end
      end

    end

    def create_7z_archive(file_name, *entries)
      if configatron.env == 'production'
        system("bin/7za a #{file_name} #{entries.join(' ')} -x!*.so -x!*.dll -r")
        #%x{bin/7za a #{file_name} #{entries.join(' ')} -x!*.so -x!*.dll -r}
      else
        system("7za a #{file_name} #{entries.join(' ')} -x!*.so -x!*.dll -r")
        #%x{7za a #{file_name} #{entries.join(' ')} -x!*.so -x!*.dll -r}
        #`7za.exe a #{file_name} #{entries.join(' ')}`
      end
      $?.exitstatus == 0
    end


    def extract_archive(file, destination)
      Zip::ZipFile.open(file) do |zipfile|
        zipfile.each do |entry|
          entry_path = File.join(destination, entry.name)
          FileUtils.mkdir_p(File.dirname(entry_path))
          zipfile.extract(entry, entry_path) { |en, path| true } # force overwrite
        end
      end
    end

    def extract_7z_archive(file, destination)
      if configatron.env == 'production'
        system("bin/7za.exe x #{file} -o#{destination} -y")
        #%x{bin/7za.exe x #{file} -o#{destination} -y}
      else
        system("7za.exe x #{file} -o#{destination} -y")
        #%x{7za.exe x #{file} -o#{destination} -y}
        #`7za.exe x #{file} -o#{destination} -y`
      end
      $?.exitstatus == 0
    end

    private

    def add_new_entry(zos, e)
      zos.put_next_entry(e)
      zos.print IO.read(e)
    end

  end

end
