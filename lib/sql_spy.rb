module SqlSpy
  Query = Struct.new(:name, :sql, :duration) do
    def model_name
      String(name).split.first
    end

    def select?
      sql.starts_with?("SELECT")
    end

    def insert?
      sql.starts_with?("INSERT")
    end

    def update?
      sql.starts_with?("UPDATE")
    end

    def delete?
      sql.starts_with?("DELETE")
    end
  end

  class Tracker
    IGNORED_NAMES = %w(SCHEMA)

    def queries
      @queries ||= []
    end

    def call(_name, start, finish, _message_id, values)
      return if IGNORED_NAMES.include?(values[:name])
      return if values[:cached]

      queries << Query.new(values[:name], values[:sql], (finish - start) * 1000)
    end
  end

  def self.track
    tracker = Tracker.new

    ActiveSupport::Notifications.subscribe("sql.active_record", tracker)
    yield
    ActiveSupport::Notifications.unsubscribe(tracker)

    tracker.queries
  end
end
