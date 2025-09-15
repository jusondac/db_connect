class DatabaseConnectionService
  attr_reader :error_message

  def initialize
    @error_message = nil
  end

  def connect(host:, port:, database_name:, user:, password:)
    config = {
      adapter: "postgresql",
      host: host,
      port: port,
      database: database_name,
      username: user,
      password: password
    }
    ActiveRecord::Base.establish_connection(config)
  rescue StandardError => e
    @error_message = "Connection failed: #{e.message}"
    false
  end

  def success_message
    "Connected successfully!"
  end

  def tables
    ActiveRecord::Base.connection.tables
  end
end
