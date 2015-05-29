class HealthCheck
  CUSTOM_ITEMS = %w(hostname fqdn url host_ip client_ip localtime utctime)
  BOOLEAN_ITEMS = %w(database_connection database_persistence database_integrity search_connection)

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
    Socket.gethostname.split('.')[0]
  end

  def fqdn
    Socket.gethostname
  end

  def url
    @env.fetch('REQUEST_URI', 'FAILED: no REQUEST_URI present in env')
  end

  def host_ip
    Socket.getaddrinfo(Socket.gethostname, nil, Socket::AF_INET)[0][3]
  rescue
    "UNKNOWN"
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
    ActiveRecord::Base.establish_connection
    ActiveRecord::Base.connection
    true
  rescue
    false
  end

  def database_persistence
    return false unless database_connection
    SystemSetting.destroy_all key: TEST_SETTINGS_KEY
    SystemSetting.create!(key: TEST_SETTINGS_KEY, value: 'only used for testing')
    s = SystemSetting.find_by_key(TEST_SETTINGS_KEY)
    s.value == 'only used for testing' or raise
    s.destroy
    true
  rescue
    false
  end

  def database_integrity
    return false unless database_connection
    !ActiveRecord::Migrator.needs_migration?
  end

  def search_connection
    Petition.search do |query|
      query.fulltext 'hello this is a test search'
      query.paginate page: 1, per_page: 1
    end
    true
  rescue
    false
  end
end
