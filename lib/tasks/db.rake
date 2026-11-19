namespace :epets do
  namespace :sequences do
    task :alter => :environment do
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
end

namespace :db do
  namespace :migrate do
    desc "Migrate the database, waiting if another server is already migrating it"
    task :wait => :environment do
      attempts = 0

      # Calls the migrations directly rather than invoking db:migrate because
      # AppSignal reports errors raised by a task even when they're rescued
      begin
        ActiveRecord::Tasks::DatabaseTasks.migrate_all
      rescue ActiveRecord::ConcurrentMigrationError
        raise if (attempts += 1) >= 60

        puts "Another server is migrating the database, retrying in 5 seconds"
        Kernel.sleep 5
        retry
      end
    end
  end
end
