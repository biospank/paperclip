require "net/http"
require "uri"
require 'open-uri'
require 'socket'


module Helpers
  module HTTPHelper
    # Token used to terminate the file in the post body. Make sure it is not
    # present in the file you're uploading.
    BOUNDARY = "AaB03x"
    
    def send_file(path, url) #:doc:
      uri = URI.parse(url) #URI.parse("http://localhost:8080/uploads")
      file = path #"/path/to/your/testfile.txt"

      post_body = []
      post_body << "--#{BOUNDARY}\r\n"
      post_body << "Content-Disposition: form-data; name=\"datafile\"; filename=\"#{File.basename(file)}\"\r\n"
      post_body << "Content-Type: text/plain\r\n"
      post_body << "\r\n"
      post_body << File.read(file)
      post_body << "\r\n--#{BOUNDARY}--\r\n"

      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Post.new(uri.request_uri)
      request.body = post_body.join
      request["Content-Type"] = "multipart/form-data, boundary=#{BOUNDARY}"

      http.request(request)

      # Alternative method, using Nick Sieger's multipart-post gem
      #require "rubygems"
      #require "net/http/post/multipart"
      #
      #reqest = Net::HTTP::Post::Multipart.new uri.request_uri, "file" => UploadIO.new(file, "application/octet-stream")
      #http = Net::HTTP.new(uri.host, uri.port)
      #http.request(request)

    end

    def get_file(url, version)
      open(url) do |io|
        File.open("updates/#{version}.zip", 'wb') do |f|
          while !io.eof
            f.write io.read(1024)
          end
        end
      end
    end

    def local_ip
      orig, Socket.do_not_reverse_lookup = Socket.do_not_reverse_lookup, true  # turn off reverse DNS resolution temporarily

      UDPSocket.open do |s|
        s.connect '64.233.187.99', 1
        s.addr.last
      end
    ensure
      Socket.do_not_reverse_lookup = orig
    end
  
    def send_verify
      begin
        if configatron.env == 'production'
          uri = URI.parse("http://localhost:3000/license_verify")

          http = Net::HTTP.new(uri.host, uri.port)
          http.read_timeout = 5
          request = Net::HTTP::Get.new(uri.request_uri)
          request.basic_auth("bratech", "8743342106303a9cb104d2484a6fcbf516d2f8be")
          response = http.request(request)
          response.body
        else
          :ok
        end
      rescue Net::ReadTimeout => e  
        :ko
      end
    end

  end
end