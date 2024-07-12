RSpec.configure do |config|
  config.before(:suite) do
    ActiveRecord::Base.connection_pool.with_connection do |connection|
      connection.execute <<~SQL
        ALTER SEQUENCE archived_petitions_id_seq MAXVALUE 699999
      SQL

      connection.execute <<~SQL
        ALTER SEQUENCE petitions_id_seq START WITH 700000 RESTART WITH 700000 MINVALUE 700000
      SQL
    end
  end
end
