# encoding: utf-8
require 'odf-report'

module Helpers
  module ODF
    module Report
      def generate(template, doc = nil, preview = true, dest = nil)
        report = ODFReport::Report.new(template) do |r|

          render_header(r, doc)

          render_body(r, doc)

          render_footer(r, doc)

        end

        if dest
          new_file = report.generate(dest)
        else
          new_file = report.generate()
        end

        if preview
          if configatron.env == 'production'
            system("bin/tmviewer.exe #{new_file}")
          else
            system("c:/programmi/softmaker/tmviewer.exe #{new_file}")
            #`d:/programmi/softmaker/tmviewer.exe #{new_file}`
          end
        end
      end
      
      def render_header(r, doc=nil)
        
      end

      def render_body(r, doc=nil)
        
      end

      def render_footer(r, doc=nil)
        
      end
    end
  end
end