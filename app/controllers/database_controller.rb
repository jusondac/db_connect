class DatabaseController < ApplicationController
  def connect
    if request.post?
      host = params[:host]
      port = params[:port]
      database_name = params[:database_name]
      user = params[:user]
      password = params[:password]

      begin
        # Clear previous session data for fresh connection
        session.delete(:database_name)
        session.delete(:host)
        session.delete(:port)
        session.delete(:user)
        session.delete(:tables)
        session.delete(:selected_table)
        session.delete(:columns)
        session.delete(:data)

        # Assume PostgreSQL
        config = {
          adapter: "postgresql",
          host: host,
          port: port,
          database: database_name,
          username: user,
          password: password
        }

        # Establish connection
        ActiveRecord::Base.establish_connection(config)

        # Store connection info in session
        session[:database_name] = database_name
        session[:host] = host
        session[:port] = port
        session[:user] = user

        # Get tables
        tables = ActiveRecord::Base.connection.tables
        session[:tables] = tables

        if tables.any?
          accessible_table = nil
          accessible_columns = nil
          accessible_data = nil

          tables.each do |table|
            begin
              columns = ActiveRecord::Base.connection.columns(table).map(&:name)
              # Try to get a sample row to test access
              result = ActiveRecord::Base.connection.execute("SELECT * FROM #{table} LIMIT 1")
              accessible_table = table
              accessible_columns = columns
              # Get more data for display
              result = ActiveRecord::Base.connection.execute("SELECT * FROM #{table} LIMIT 10")
              accessible_data = result.to_a
              break
            rescue
              # Skip tables we can't access
              next
            end
          end

          if accessible_table
            session[:selected_table] = accessible_table
            session[:columns] = accessible_columns
            session[:data] = accessible_data
            flash[:notice] = "Connected successfully!"
          else
            flash[:notice] = "Connected successfully! However, you don't have permission to access any tables in this database."
          end
        else
          flash[:notice] = "Connected successfully! No tables found in this database."
        end

        redirect_to database_connect_path
      rescue PG::ConnectionBad => e
        if e.message.include?("fe_sendauth") || e.message.include?("no password")
          flash[:alert] = "Connection failed: Invalid username or password"
        elsif e.message.include?("connection refused") || e.message.include?("Connection refused")
          flash[:alert] = "Connection failed: Cannot connect to database server. Please check host and port."
        else
          flash[:alert] = "Connection failed: Unable to connect to database server"
        end
        redirect_to database_connect_path
      rescue PG::InsufficientPrivilege => e
        flash[:alert] = "Connection successful but insufficient privileges to access database tables"
        redirect_to database_connect_path
      rescue => e
        flash[:alert] = "Connection failed: #{e.message}"
        redirect_to database_connect_path
      end
    else
      # GET request - load from session
      @database_name = session[:database_name]
      @host = session[:host]
      @port = session[:port]
      @user = session[:user]
      @tables = session[:tables]
      @selected_table = session[:selected_table]
      @table_name = @selected_table
      @columns = session[:columns]
      @data = session[:data]
    end
  end
end
