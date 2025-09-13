class DatabaseController < ApplicationController
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
    session.delete(:database_name)
    session.delete(:host)
    session.delete(:port)
    session.delete(:user)
    session.delete(:tables)
    session.delete(:selected_table)
    session.delete(:columns)
    session.delete(:data)
  end

  def store_connection_data(service)
    session[:database_name] = service.connection_info[:database_name]
    session[:host] = service.connection_info[:host]
    session[:port] = service.connection_info[:port]
    session[:user] = service.connection_info[:user]
    session[:tables] = service.tables
    session[:selected_table] = service.selected_table
    session[:columns] = service.columns
    session[:data] = service.data
  end

  def load_session_data
    @database_name = session[:database_name]
    @host = session[:host]
    @port = session[:port]
    @user = session[:user]
    @tables = session[:tables]
  end
end
