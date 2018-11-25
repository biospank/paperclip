module Helpers
  module Xml
    attr_accessor :xml

    def generate_xml(template, opts = {})
      #FileUtils.rm './tmp/*.*'
      logger.debug "rendering xml document..."
      self.xml = File.new("./tmp/#{template}.xml", 'w')
      render_xml(opts)
      xml.close
    end

    def render_xml(opts={})

    end
  end
end
