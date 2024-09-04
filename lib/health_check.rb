class HealthCheck
  CUSTOM_ITEMS = %w(hostname url client_ip localtime utctime)
  BOOLEAN_ITEMS = %w(database_connection database_persistence database_integrity)

  TEST_SETTINGS_KEY = 'healthcheck_test_key'

  def self.checkup(env)
    new(env).checkup
  end

  def initialize(env)
    @env = env
  end

  def checkup
    diagnosis = {}
    CUSTOM_ITEMS.each do |symptom|
      diagnosis[symptom] = self.send(symptom)
    end
    BOOLEAN_ITEMS.each do |symptom|
      diagnosis[symptom] = stringify(self.send(symptom))
    end
    diagnosis
  end

  private

  def hostname
    Socket.gethostname
  end

  def url
    @env.fetch('REQUEST_URI', 'FAILED: no REQUEST_URI present in env')
  end

  def client_ip
    @env.fetch('REMOTE_ADDR', 'FAILED: no REMOTE_ADDR present in env')
  end

  def localtime
    Time.current.rfc2822
  end

  def utctime
    Time.current.getutc.rfc2822
  end

  def stringify(b)
    b ? 'OK' : 'FAILED'
  end

  def database_connection
    unless defined?(@connection_pool)
      ActiveRecord::Base.establish_connection
    end

    @connection_pool ||= ActiveRecord::Base.connection_pool
  rescue
    false
  end

  def database_persistence
    return false unless database_connection
    return false unless Site.first_or_create
    return false unless Site.last_checked_at!
    true
  rescue
    false
  end

  def database_integrity
    return false unless database_connection
    !database_connection.migration_context.needs_migration?
  end
end
