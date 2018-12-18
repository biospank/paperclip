module Helpers
  module Xml
    attr_accessor :xml

    def generate_xml(template, opts = {})
      #FileUtils.rm './tmp/*.*'
      logger.debug "rendering xml document..."
      self.xml = File.new("./tmp/#{template}.xml", 'w')
      render_xml(opts)
      xml.close

      Thread.fork do
        system("cmd /c start notepad ./tmp/#{template}.xml") if opts[:preview]
      end
    end

    def render_xml(opts={})

    end
  end
end
