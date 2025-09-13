class DatabaseController < ApplicationController
  SESSION_DATA_KEYS = [ :database_name, :host, :port, :user, :tables, :selected_table, :columns, :data ].freeze

  def connect
    if request.post?
      # Clear previous session data for fresh connection
      clear_session_data

      # Create service and attempt connection
      service = DatabaseConnectionService.new
      success = service.connect(
        host: params[:host],
        port: params[:port],
        database_name: params[:database_name],
        user: params[:user],
        password: params[:password]
      )

      if success
        # Store successful connection data in session
        store_connection_data(service)
        flash[:notice] = service.success_message
      else
        flash[:alert] = service.error_message
      end

      redirect_to database_connect_path
    else
      # GET request - load from session
      load_session_data
    end
  end

  private

  def clear_session_data
    session.delete(*SESSION_DATA_KEYS)
  end

  def store_connection_data(service)
    session.merge!(
      database_name: service.connection_info[:database_name],
      host: service.connection_info[:host],
      port: service.connection_info[:port],
      user: service.connection_info[:user],
      tables: service.tables,
      selected_table: service.selected_table,
      columns: service.columns,
      data: service.data
    )
  end

  def load_session_data
    @database_name = session[:database_name]
    @host = session[:host]
    @port = session[:port]
    @user = session[:user]
    @tables = session[:tables]
  end
end
