require "socket"

module Bunny
  begin
    require "openssl"

    # TLS-enabled TCP socket that implements convenience
    # methods found in Bunny::Socket.
    class SSLSocket < OpenSSL::SSL::SSLSocket

    # IO::WaitReadable is 1.9+ only
    READ_RETRY_EXCEPTION_CLASSES = [Errno::EAGAIN, Errno::EWOULDBLOCK, OpenSSL::SSL::SSLError]
    READ_RETRY_EXCEPTION_CLASSES << IO::WaitReadable if IO.const_defined?(:WaitReadable)


      # Reads given number of bytes with an optional timeout
      #
      # @param [Integer] count How many bytes to read
      # @param [Integer] timeout Timeout
      #
      # @return [String] Data read from the socket
      # @api public
      def read_fully(count, timeout = nil)
        return nil if @__bunny_socket_eof_flag__

        value = ''
        begin
          loop do
            value << read_nonblock(count - value.bytesize)
            break if value.bytesize >= count
          end
        rescue EOFError => e
          puts e.inspect
          @__bunny_socket_eof_flag__ = true
        rescue *READ_RETRY_EXCEPTION_CLASSES => e
          puts e.inspect
          if IO.select([self], nil, nil, timeout)
            retry
          else
            raise Timeout::Error, "IO timeout when reading #{count} bytes"
          end
        end
        value
      end
    end
  rescue LoadError => le
    puts "Could not load OpenSSL"
  end
end
