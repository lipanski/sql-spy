require "minitest/autorun"
require "active_record"
require "sqlite3"

SQLITE_DATABASE = File.expand_path("../test.sqlite3", __dir__)
File.delete(SQLITE_DATABASE) if File.file?(SQLITE_DATABASE)

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: SQLITE_DATABASE)
ActiveRecord::Schema.define do
  create_table :users do |t|
    t.string :name
  end

  create_table :posts do |t|
    t.references :user
    t.string :title
  end
end

class User < ActiveRecord::Base
  has_many :posts
end

class Post < ActiveRecord::Base
  belongs_to :user
end

require_relative "../lib/sql_spy"

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
    assert_equal 1, queries.count

    query = queries.first
    assert query.insert?
    assert_equal "User", query.model_name
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
end
