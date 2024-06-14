# frozen_string_literal: true

require 'openssl'

def generate_x509_certificate(host)
  server_key = OpenSSL::PKey::RSA.new(2048)

  server_cert = OpenSSL::X509::Certificate.new
  server_cert.version = 2
  server_cert.not_after = (Time.now + (86_400 * 365 * 3))
  server_cert.not_before = (Time.now - 86_400)

  ef = OpenSSL::X509::ExtensionFactory.new
  ef.subject_certificate = server_cert
  ef.issuer_certificate = server_cert

  server_cert.serial = 1
  server_cert.subject = OpenSSL::X509::Name.parse("C=FI/DC=#{host}/CN=*")
  server_cert.issuer = server_cert.subject
  server_cert.public_key = server_key.public_key

  server_cert.add_extension(ef.create_extension('basicConstraints', 'CA:true,pathlen:0', true))
  server_cert.add_extension(ef.create_extension('extendedKeyUsage', 'serverAuth,clientAuth'))
  server_cert.add_extension(ef.create_extension('keyUsage', 'cRLSign,keyCertSign,digitalSignature,nonRepudiation', true)) # rubocop:disable Layout/LineLength
  server_cert.add_extension(ef.create_extension('subjectKeyIdentifier', 'hash', false))

  server_cert.sign(server_key, OpenSSL::Digest.new('SHA384'))

  [server_cert, server_key]
end

def create_ssl_context(host)
  cert_store = OpenSSL::X509::Store.new
  cert_store.set_default_paths

  server_cert, server_key = generate_x509_certificate(host)

  ssl_context = OpenSSL::SSL::SSLContext.new(:TLSv1_2_server)
  ssl_context.cert_store = cert_store
  ssl_context.key = server_key
  ssl_context.cert = server_cert
  ssl_context.ciphers = ssl_context.ciphers.select { |c| c[3] >= 256 }

  { error: false, ssl_context: ssl_context }
rescue StandardError => e
  { error: true, ssl_context: e.message }
end
