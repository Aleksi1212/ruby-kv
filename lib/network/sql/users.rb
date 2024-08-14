# frozen_string_literal: true

require 'sequel'
require_relative '../../openssl/encryption'

class Users
  def initialize(db_name = 'users.db')
    @db = Sequel.sqlite(db_name)

    @db.create_table? :users do
      String :name, unique: true, null: false
      String :password, null: false
      Integer :admin, default: 0

      constraint(:admin_values) { Sequel.lit('admin IN ( 0, 1 )') }
    end
  end

  def create_user(name, password, admin = 0)
    @db[:users].insert(name: name, password: password.encrypt, admin: admin)
    'OK'
  rescue Sequel::UniqueConstraintViolation
    "User: #{name} already exists."
  rescue Sequel::CheckConstraintViolation
    'Admin value can only be 1 or 0'
  rescue StandardError => e
    e.message
  end

  def get_user(name, password)
    @db[:users].where(name: name).where(password: password.encrypt).prepare(:first, :sa)
    user_data = @db.call(:sa)

    {
      found: !user_data.nil?,
      isAdmin: user_data[:admin] == 1,
      error_message: user_data.nil? ? "User #{name} not found" : ''
    }
  rescue StandardError => e
    { found: false, isAdmin: false, error_message: e.message }
  end
end
