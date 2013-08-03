module Helpers
  module Wk
    module HtmlToPdf

      attr_accessor :header, :body, :footer

      DEFATULT_GENERATE_OPTS = {
        :header => true,
        :body => true,
        :footer => true,
        :preview => true
      }

      DEFATULT_MERGE_ALL_OPTS = {
        :preview => true
      }

      def generate(template, opts = {})
        # merge non distruttivo
        opts.merge!(DEFATULT_GENERATE_OPTS) { |key, oldval, newval| oldval }

        #FileUtils.rm './tmp/*.*'

        if opts[:header]
          logger.debug "rendering header..."
          self.header = File.new('./tmp/header.html', 'w')
          render_header(opts)
          header.close
        end

        if opts[:body]
          logger.debug "rendering body..."
          self.body = File.new('./tmp/body.html', 'w')
          render_body(opts)
          body.close
        end

        if opts[:footer]
          logger.debug "rendering footer..."
          self.footer = File.new('./tmp/footer.html', 'w')
          render_footer(opts)
          footer.close
        end

        params = []
        params << "-O #{opts[:layout]}" if opts[:layout]
        params << "--header-html #{header.path}" if opts[:header]
        params << "--footer-html #{footer.path}" if opts[:footer]
        params << "--margin-top #{opts[:margin_top]}" if opts[:margin_top]
        params << "--margin-bottom #{opts[:margin_bottom]}" if opts[:margin_bottom]
        params << "--header-spacing #{opts[:header_spacing]}" if opts[:header_spacing]
        params << "--footer-spacing #{opts[:footer_spacing]}" if opts[:footer_spacing]
        params << "--header-line" if opts[:header_line]
        params << "--footer-line" if opts[:footer_line]
        params << "#{body.path} ./tmp/#{template}.pdf"

        cmd_params = wk_cmd % params.join(' ')
        logger.info "executing: #{cmd_params}"
        system(cmd_params)

        system(sumatra_cmd % "./tmp/#{template}.pdf") if opts[:preview]

      end

      def merge_all(docs, opts = {})
        # merge non distruttivo
        opts.merge!(DEFATULT_MERGE_ALL_OPTS) { |key, oldval, newval| oldval }
        
        params = []
        docs.each {|doc| params << "./tmp/#{doc}.pdf"}
        params << "output ./tmp/#{opts[:output]}.pdf"

        cmd_params = tk_cmd % params.join(' ')
        logger.info "executing: #{cmd_params}"
        system(cmd_params)

        system(sumatra_cmd % "./tmp/#{opts[:output]}.pdf") if opts[:preview]

      end
      
      def render_header(opts={})

      end

      def render_body(opts={})

      end

      def render_footer(opts={})

      end

      private

      def wk_cmd
        if configatron.env == 'production'
          '.\bin\hstart.exe /NOCONSOLE /WAIT "./bin/wkhtmltopdf.exe %s"'
        else
          '.\bin\win\hstart.exe /NOCONSOLE /WAIT "./bin/win/wkhtmltopdf.exe %s"'
        end
      end

      def tk_cmd
        if configatron.env == 'production'
          '.\bin\hstart.exe /NOCONSOLE /WAIT "./bin/pdftk.exe %s"'
        else
          '.\bin\win\hstart.exe /NOCONSOLE /WAIT "./bin/win/pdftk.exe %s"'
        end
      end

      def sumatra_cmd
        if configatron.env == 'production'
          "./bin/sumatra.exe %s"
        else
          "./bin/win/sumatra.exe %s"
        end
      end

    end
  end
end