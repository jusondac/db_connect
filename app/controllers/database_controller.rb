class DatabaseController < ApplicationController
  CONNECTION_FIELDS = [ :host, :port, :database_name, :user, :password ].freeze

  def connect
    if request.post?
      service = DatabaseConnectionService.new
      connection_params = CONNECTION_FIELDS.each_with_object({}) do |field, hash|
        hash[field] = params[:connection][field]
      end

      success = service.connect(**connection_params)
      if success
        save_connection_to_session(connection_params)
        session[:tables] = service.tables
        flash[:notice] = service.success_message
      else
        flash[:alert] = service.error_message
      end

      redirect_to database_connect_path
    else
      db_config = connection_config_from_session
      if db_config
        @host = db_config[:host]
        @port = db_config[:port]
        @database_name = db_config[:database]
        @user = db_config[:username]
      end
      @tables = session[:tables]
      @selected_table = session[:selected_table]

      @tables.each do |table|
        class_name = table.singularize.camelize
        Object.send(:remove_const, class_name) if Object.const_defined?(class_name)
        Object.const_set(class_name, Class.new(ActiveRecord::Base) do
          self.table_name = table
        end)
      end if @tables.present?

      if @selected_table && establish_connection_from_session
        @columns = ActiveRecord::Base.connection.columns(@selected_table).map(&:name)
        result = ActiveRecord::Base.connection.execute("SELECT * FROM #{ActiveRecord::Base.connection.quote_table_name(@selected_table)} LIMIT 10")
        @data = result.to_a
      end
    end
  end

  def select_table
    table = params[:table]
    if session[:tables]&.include?(table)
      if establish_connection_from_session
        session[:selected_table] = table
        flash[:notice] = "Selected table: #{table}"
      else
        flash[:alert] = "Failed to establish database connection"
      end
    else
      flash[:alert] = "Invalid table: #{table}"
    end
    redirect_to database_connect_path
  end

  private

  def save_connection_to_session(connection_params)
    session[:db_config] = CONNECTION_FIELDS.each_with_object({ adapter: "postgresql" }) do |field, hash|
      hash[field] = connection_params[field]
    end
  end

  def establish_connection_from_session
    return false unless session[:db_config]

    ActiveRecord::Base.establish_connection(session[:db_config])
    true
  rescue StandardError => e
    Rails.logger.error("Failed to establish connection from session: #{e.message}")
    false
  end

  def connection_config_from_session
    session[:db_config]
  end
end
