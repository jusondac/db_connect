class DatabaseConnectionService
  attr_reader :connection_info, :tables, :selected_table, :columns, :data, :error_message

  SAMPLE_DATA_LIMIT = 10

  def initialize
    @connection_info = {}
    @tables = []
    @selected_table = nil
    @columns = []
    @data = []
    @error_message = nil
  end

  def connect(host:, port:, database_name:, user:, password:)
    clear_state
    config = build_config(host, port, database_name, user, password)

    establish_connection(config)
    set_connection_info(database_name, host, port, user)
    fetch_tables
    find_accessible_table if @tables.any?

    true
  rescue PG::ConnectionBad => e
    @error_message = handle_connection_error(e)
    false
  rescue PG::InsufficientPrivilege => e
    @error_message = "Connection successful but insufficient privileges to access database tables"
    false
  rescue StandardError => e
    @error_message = "Connection failed: #{e.message}"
    false
  end

  def success_message
    return "Connected successfully! No tables found in this database." if @tables.empty?
    return "Connected successfully! However, you don't have permission to access any tables in this database." if @selected_table.nil?

    "Connected successfully!"
  end

  private

  def clear_state
    @connection_info = {}
    @tables = []
    @selected_table = nil
    @columns = []
    @data = []
    @error_message = nil
  end

  def build_config(host, port, database_name, user, password)
    {
      adapter: "postgresql",
      host: host,
      port: port,
      database: database_name,
      username: user,
      password: password
    }
  end

  def establish_connection(config)
    ActiveRecord::Base.establish_connection(config)
  end

  def set_connection_info(database_name, host, port, user)
    @connection_info = {
      database_name: database_name,
      host: host,
      port: port,
      user: user
    }
  end

  def fetch_tables
    @tables = ActiveRecord::Base.connection.tables
  end

  def find_accessible_table
    @tables.each do |table|
      next unless accessible?(table)

      @selected_table = table
      @columns = ActiveRecord::Base.connection.columns(table).map(&:name)
      @data = fetch_sample_data(table)
      break
    end
  end

  def accessible?(table)
    ActiveRecord::Base.connection.execute("SELECT 1 FROM #{ActiveRecord::Base.connection.quote_table_name(table)} LIMIT 1")
    true
  rescue
    false
  end

  def fetch_sample_data(table)
    result = ActiveRecord::Base.connection.execute("SELECT * FROM #{ActiveRecord::Base.connection.quote_table_name(table)} LIMIT #{SAMPLE_DATA_LIMIT}")
    result.to_a
  end

  def handle_connection_error(error)
    case error.message
    when /fe_sendauth|no password/
      "Connection failed: Invalid username or password"
    when /connection refused|Connection refused/
      "Connection failed: Cannot connect to database server. Please check host and port."
    else
      "Connection failed: Unable to connect to database server"
    end
  end
end
