# frozen_string_literal: true

require 'socket'
require 'openssl'

require_relative 'lib/server'
require_relative '../../openssl/generate_certificate'

Thread.abort_on_exception = true

TCP_PORT = 4443
HOST = Socket.gethostname

tcp_server = TCPServer.open(TCP_PORT)

tcp_server.setsockopt(Socket::Option.bool(:INET, :SOCKET, :REUSEADDR, true))
tcp_server.setsockopt(Socket::Option.bool(:INET, :SOCKET, :KEEPALIVE, true))

puts "TCP server started on port: #{TCP_PORT}"

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
