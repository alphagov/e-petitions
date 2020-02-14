namespace :epets do
  namespace :constituencies do
    desc "Add task to the queue to fetch constituency information from the Parliament API"
    task :refresh => :environment do
      Task.run("epets:constituencies:refresh") do
        FetchConstituenciesJob.perform_later
      end
    end
  end
end
