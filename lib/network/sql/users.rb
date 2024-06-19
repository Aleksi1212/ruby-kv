# frozen_string_literal: true

require 'sqlite3'

class Users
  def initialize(db_name = 'users.db')
    @db = SQLite3::Database.new(db_name)
    @db.results_as_hash = true

    @db.execute <<-SQL
      CREATE TABLE IF NOT EXISTS users (
        name TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL
      );
    SQL
  end

  def create_user(name, password)
    @db.execute 'INSERT INTO users (name, password) VALUES (?, ?)', name, password
    'OK'
  rescue SQLite3::ConstraintException
    "User: #{name}. Already exists"
  rescue StandardError => e
    e.message
  end

  def get_user(name, password)
    results = @db.query 'SELECT * FROM users WHERE name=? AND password=?', name, password
    !results.next.nil?
  rescue StandardError
    false
  end
end
