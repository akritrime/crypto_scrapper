require 'bundler'

Bundler.require

require 'open-uri'
DB = {
    conn: SQLite3::Database.new("db/coins.sqlite")
}

require_all 'lib'