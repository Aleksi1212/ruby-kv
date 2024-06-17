# frozen_string_literal: true

require 'socket'
require 'openssl'

require_relative 'lib/server'
require_relative '../../openssl/generate_certificate'

Thread.abort_on_exception = true

PORT = 6969
HOST = Socket.gethostname

tcp_server = TCPServer.open(PORT)

tcp_server.setsockopt(:SOCKET, :REUSEADDR, true)
tcp_server.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, true)
tcp_server.setsockopt(Socket::Option.bool(:INET, :SOCKET, :REUSEADDR, true))
tcp_server.setsockopt(Socket::Option.bool(:INET, :SOCKET, :KEEPALIVE, true))

puts "Server listening on port: #{PORT}"

ssl_context = create_ssl_context(HOST)
if ssl_context[:error]
  puts "Error creating ssl context: #{ssl_context[:ssl_context]}"
else
  tls_server = OpenSSL::SSL::SSLServer.new(tcp_server, ssl_context[:ssl_context])

  loop do
    Thread.start(tls_server.accept) do |client|
      handle_client_connection(client)
    end
  rescue Interrupt, IOError
    tls_server.close
    tcp_server.close
  end
end
