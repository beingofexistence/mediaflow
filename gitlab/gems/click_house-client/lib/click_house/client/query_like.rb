# frozen_string_literal: true

module ClickHouse
  module Client
    class QueryLike
      # Build a SQL string that can be executed on a ClickHouse database.
      def to_sql
        raise NotImplementedError
      end

      # Redacted version of the SQL query generated by the to_sql method where the
      # placeholders are stripped. These queries are meant to be exported to external
      # log aggregation systems.
      def to_redacted_sql(bind_index_manager = BindIndexManager.new)
        raise NotImplementedError
      end
    end
  end
end