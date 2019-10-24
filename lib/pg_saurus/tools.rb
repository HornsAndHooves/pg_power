module PgSaurus
  # Provides utility methods to work with PostgreSQL databases.
  # Usage:
  #   PgSaurus::Tools.create_schema "services"  # => create new PG schema "services"
  #   PgSaurus::Tools.create_schema "nets"
  #   PgSaurus::Tools.drop_schema "services"    # => remove the schema
  #   PgSaurus::Tools.schemas                   # => ["public", "information_schema", "nets"]
  #   PgSaurus::Tools.move_table_to_schema :computers, :nets
  #   PgSaurus::Tools.create_view view_name, view_definition # => creates new DB view
  #   PgSaurus::Tools.drop_view view_name       # => removes the view
  #   PgSaurus::Tools.views                     # => ["x_view", "y_view", "z_view"]
  module Tools
    extend self

    # Create a schema if it does not exist yet.
    #
    # @note
    #   Supports PostgreSQL 9.3+
    #
    # @return [void]
    def create_schema_if_not_exists(schema_name)
      sql = %{CREATE SCHEMA IF NOT EXISTS "#{schema_name}"}
      connection.execute sql
    end

    # Ensure schema does not exists.
    #
    # @return [void]
    def drop_schema_if_exists(schema_name)
      connection.drop_schema(schema_name, if_exists: true)
    end

    # Returns an array of existing schemas.
    def schemas
      sql = "SELECT nspname FROM pg_namespace WHERE nspname !~ '^pg_.*' order by nspname"
      connection.query(sql).flatten
    end

    # Move table to another schema without loosing data, indexes or constraints.
    # @param [String] table table name (schema prefix is allowed)
    # @param [String] new_schema schema where table should be moved to
    def move_table_to_schema(table, new_schema)
      schema, table = to_schema_and_table(table)
      sql = %{ALTER TABLE "#{schema}"."#{table}" SET SCHEMA "#{new_schema}"}
      connection.execute sql
    end

    # Creates PostgreSQL view
    # @param [String, Symbol] view_name
    # @param [String] view_definition
    def create_view(view_name, view_definition)
      sql = "CREATE VIEW #{view_name} AS #{view_definition}"
      connection.execute sql
    end

    # Drops PostgreSQL view
    # @param [String, Symbol] view_name
    def drop_view(view_name)
      sql = "DROP VIEW #{view_name}"
      connection.execute sql
    end

    # Returns an array of existing, non system views.
    def views
      sql = <<-SQL
      SELECT table_schema, table_name, view_definition
      FROM INFORMATION_SCHEMA.views
      WHERE table_schema NOT IN ('pg_catalog','information_schema')
      SQL
      connection.execute sql
    end

    # Return database connections
    def connection
      ActiveRecord::Base.connection
    end
    private :connection

    # Extract schema name and table name from qualified table name
    # @param [String, Symbol] table_name table name
    # @return [Array[String, String]] schema and table
    def to_schema_and_table(table_name)
      table, schema = table_name.to_s.split(".", 2).reverse
      schema ||= "public"
      [schema, table]
    end
  end
end
