class DatabaseController < ApplicationController
  def connect
    if request.post?
      host = params[:host]
      database_name = params[:database_name]
      user = params[:user]
      password = params[:password]

      begin
        # Assume PostgreSQL
        config = {
          adapter: "postgresql",
          host: host,
          database: database_name,
          username: user,
          password: password
        }

        # Establish connection
        ActiveRecord::Base.establish_connection(config)

        @database_name = database_name
        @host = host

        # Get tables
        @tables = ActiveRecord::Base.connection.tables

        if @tables.any?
          @selected_table = @tables.first
          @table_name = @selected_table
          @columns = ActiveRecord::Base.connection.columns(@selected_table).map(&:name)
          # Get some data
          result = ActiveRecord::Base.connection.execute("SELECT * FROM #{@selected_table} LIMIT 10")
          @data = result.to_a
        end

        flash[:notice] = "Connected successfully!"
      rescue => e
        flash[:alert] = "Connection failed: #{e.message}"
      end
    end
  end
end
