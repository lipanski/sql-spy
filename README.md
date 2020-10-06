# SqlSpy

<a href="https://travis-ci.com/github/lipanski/sql-spy"><img src="https://api.travis-ci.com/lipanski/sql-spy.svg?branch=master"></a>

A gem to track all SQL queries performed inside a given block.

You can use **SqlSpy** to test the total amount of queries performed by a piece of code, the amount of queries per table, selects vs. inserts vs. updates vs. deletes, or query duration. You can also use it to validate and debug your SQL or to prevent N+1 queries.

The implementation is inspired by how [ActiveRecord is tested](https://github.com/rails/rails/blob/6-0-stable/activerecord/test/cases/test_case.rb).

## Usage

Add the gem to your `Gemfile`:

```ruby
gem "sql_spy"
```

...and install it with:

```sh
bundle install
```

Wrap the code you'd like to track inside `SqlSpy.track {}`:

```ruby
require "sql_spy"

queries = SqlSpy.track do
  # Some code that triggers ActiveRecord queries
end
```

The `SqlSpy.track` method will return **an array containing all the queries performed inside the block**. Every object inside this array exposes the following **methods**:

- `#model_name`: The model name (e.g. "User").
- `#sql`: The SQL query that was performed.
- `#duration`: The duration of the query in milliseconds.
- `#select?`: Is this a *SELECT* query?
- `#insert?`: Is this an *INSERT* query?
- `#update?`: Is this an *UPDATE* query?
- `#delete?`: Is this a *DELETE* query?

Here are some **ideas** for how you could use this:

```ruby
# Expect less than 5 queries
assert queries.count < 5

# Expect 1 INSERT query
assert_equal 1, queries.select(&:insert?).size

# Expect 2 queries to the posts table
assert_equal 2, queries.select { |query| query.model_name == "Post" }.size

# None of the queries should be slower than 100ms
assert queries.none? { |query| query.duration > 100 }

# Fail on N+1 queries: expect no more than 1 query per table
queries_by_model = queries.group_by(&:model_name)
assert queries_by_model.none? { |model_name, queries| queries.count > 1 }
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
