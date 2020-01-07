namespace :wpets do
  namespace :constituencies do
    desc "Add task to the queue to constituency information from the Parliament API"
    task :import => :environment do
      Task.run("wpets:constituencies:import") do
        ImportConstituenciesJob.perform_later
      end
    end

    desc "Add task to the queue to refresh constituency information from the Parliament API"
    task :refresh => :environment do
      Task.run("wpets:constituencies:refresh") do
        RefreshConstituenciesJob.perform_later
      end
    end

    desc "Add task to the queue to refresh constituency party information from the Parliament API"
    task :refresh => :environment do
      Task.run("wpets:constituencies:refresh_party") do
        RefreshConstituencyPartyJob.perform_later
      end
    end
  end
end
