# From: https://gist.github.com/rsutphin/af06c9e3dadf658d2293
# adapted from http://stackoverflow.com/a/13423584/153896
module ActiveRecord
  class QueryCounter
    attr_reader :query_count

    def initialize
      @query_count = 0
    end

    def to_proc
      lambda(&method(:callback))
    end

    def callback(name, start, finish, message_id, values)
      @query_count += 1 unless %w(CACHE SCHEMA).include?(values[:name])
    end
  end
end
