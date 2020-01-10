namespace :epets do
  namespace :sequences do
    task :alter => :environment do
      ActiveRecord::Base.connection_pool.with_connection do |connection|
        connection.execute <<~SQL
          ALTER SEQUENCE archived_petitions_id_seq MAXVALUE 299999
        SQL

        connection.execute <<~SQL
          ALTER SEQUENCE petitions_id_seq START WITH 300000 RESTART WITH 300000 MINVALUE 300000
        SQL
      end
    end
  end
end
