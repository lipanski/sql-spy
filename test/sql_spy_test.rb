require "minitest/autorun"
require "active_record"
require "pg"
require "sqlite3"
require_relative "../lib/sql_spy"

ENV["DATABASE_URL"] ||= "sqlite3://" + File.expand_path("../test.sqlite", __dir__)
ActiveRecord::Base.establish_connection(ENV["DATABASE_URL"])

ActiveRecord::Schema.define do
  unless table_exists?(:users)
    create_table :users do |t|
      t.string :name
    end
  end

  unless table_exists?(:posts)
    create_table :posts do |t|
      t.references :user
      t.string :title
    end
  end
end

class User < ActiveRecord::Base
  has_many :posts
end

class Post < ActiveRecord::Base
  belongs_to :user
end

Minitest.after_run do
  config = ActiveRecord::Base.connection_config
  if config[:adapter] == "sqlite3" && File.file?(config[:database])
    File.delete(config[:database])
  end
end

class SqlSpyTest < Minitest::Test
  def setup
    ActiveRecord::Base.connection.truncate("users", "posts")
  end

  def test_single_select_query
    queries = SqlSpy.track do
      User.where(name: "mario").to_a
    end

    assert_instance_of Array, queries
    assert_equal 1, queries.count

    query = queries.first
    assert query.select?
    assert_equal "User", query.model_name
  end

  def test_single_insert_query
    queries = SqlSpy.track do
      User.create(name: "mario")
    end

    assert_instance_of Array, queries
    assert_equal 3, queries.count

    assert_match %r{(begin transaction|begin)}i, queries[0].sql

    assert queries[1].insert?
    assert_equal "User", queries[1].model_name

    assert_match %r{(end transaction|commit)}i, queries[2].sql
  end

  def test_single_update_query
    User.create(name: "mario")

    queries = SqlSpy.track do
      User.where(name: "mario").update_all(name: "luigi")
    end

    assert_instance_of Array, queries
    assert_equal 1, queries.count

    query = queries.first
    assert query.update?
    assert_equal "User", query.model_name
  end

  def test_single_delete_query
    queries = SqlSpy.track do
      User.where(name: "mario").delete_all
    end

    assert_instance_of Array, queries
    assert_equal 1, queries.count

    query = queries.first
    assert query.delete?
    assert_equal "User", query.model_name
  end

  def test_n_plus_1_queries
    5.times { |i| User.create(name: "mario #{i}") }

    queries = SqlSpy.track do
      users = User.all
      users.each { |user| user.posts.to_a }
    end

    assert_equal 6, queries.count

    queries_grouped_by_table = queries.group_by(&:model_name)

    user_queries = queries_grouped_by_table["User"]
    assert_equal 1, user_queries.count

    post_queries = queries_grouped_by_table["Post"]
    assert_equal 5, post_queries.count
  end

  def test_duration
    queries = SqlSpy.track do
      User.where(name: "mario").to_a
    end

    query = queries.first
    assert_instance_of Float, query.duration
    refute query.duration.zero?
  end

  def test_execute_raw_sql
    queries = SqlSpy.track do
      ActiveRecord::Base.connection.execute("SELECT COUNT(*) FROM users;")
    end

    assert_equal 1, queries.count

    query = queries.first
    assert_equal "SELECT COUNT(*) FROM users;", query.sql
    assert_nil query.model_name
    assert query.select?
    refute query.insert?
    refute query.update?
    refute query.delete?
  end
end
