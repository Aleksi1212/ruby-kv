# frozen_string_literal: true

require 'openssl'

class String
  def encrypt(key = 'test_key')
    cipher = OpenSSL::Cipher.new('aes-256-cbc').encrypt
    cipher.key = Digest::MD5.hexdigest(key)
    s = cipher.update(self) + cipher.final

    s.unpack1('H*').upcase
  end

  def decrypt(key = 'test_key')
    cipher = OpenSSL::Cipher.new('aes-256-cbc').decrypt
    cipher.key = Digest::MD5.hexdigest(key)
    s = [self].pack('H*').unpack('C*').pack('c*')

    cipher.update(s) + cipher.final
  end
end
