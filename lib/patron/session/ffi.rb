require 'ffi'
require 'curl_ffi'

module Patron
  class Session
    module FFI
      def connection
        @connection ||= CurlFFI::Easy.new
      end

      def escape(_string)
        self.connection.escape(_string)
      end

      def unescape(_string)
        self.connection.unescape(_string)
      end

      def self.libcurl_version
        # @TODO in the CurlFFI Library
        # CurlFFI.libcurl_version
        "I AM A BANANA"
      end

      def perform
        
      end
      
      # Let's just assume the world is a perfect place, ok?
      def validate_request_options(request)
        # validation steps
        #  Verify that headers is a Hash
        if request.headers.is_a?(Hash)
          request.headers.each_pair do |key_and_value|
            self.request_headers = CurlFFI.slist_append(self.request_headers, key_and_value.join(": "))
          end
        else; raise ArgumentError; end

        case request.method
        when :get     then  connection.setopt :HTTPGET,        1
          # @TODO: "download_file" - file system (FILE *) pointer
        when :head    then  connection.setopt :NOBODY,         1
        when :post    then  connection.setopt :POST,           1
                            connection.setopt :POSTFIELDS,     options[:payload]
                            connection.setopt :POSTFIELDSIZE,  options[:payload].size
        when :put     then  connection.setopt :CUSTOMREQUEST,  "PUT"
                            connection.setopt :POSTFIELDS,     options[:payload]
                            connection.setopt :POSTFIELDSIZE,  options[:payload].size
        when :delete  then  connection.setopt :CUSTOMREQUEST,  "DELETE"
        else                connection.setopt :CUSTOMREQUEST,  request.method.to_s
        end

        connection.setopt :URL,             FFI::MemoryPointer.from_string(url)
        connection.setopt :WRITEHEADER,     self.request_headers
        connection.setopt :ERRORBUFFER,     self.error_buffer

        connection.setopt(:TIMEOUT,         request.timeout)          if Fixnum === request.timeout
        connection.setopt(:CONNECTTIMEOUT,  request.connect_timeout)  if Fixnum === request.connect_timeout

        if Fixnum === request.max_redirects
          if request.max_redirects == 0
            connection.setopt(:FOLLOWLOCATION,  0)
          else
            connection.setopt(:FOLLOWLOCATION,  1)
          end
          connection.setopt(:MAXREDIRS, request.max_redirects)
        end



      end

      # request must be a hash
      def handle_request(request)
        raise ArgumentError unless request.is_a?(Patron::Request)
        self.validate_request_options(request)
      end

      def header_cast(pointer)
        CurlFFI::CurlSlist.new(pointer)
      end

      def request_headers(pointer=nil)
        @request_headers ||= header_cast(FFI::MemoryPointer.new(:char, CurlFFI::CurlSlist.size))
      end

      def error_buffer
        @error_buffer ||= FFI::MemoryPointer.new(:char, CurlFFI::ERROR_SIZE, :clear)
      end
      
    end
  end
end
