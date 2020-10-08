namespace :wpets do
  namespace :members do
    desc "Add task to the queue to fetch member information from the Senedd API"
    task :refresh => :environment do
      Task.run("wpets:members:refresh") do
        FetchMembersJob.perform_later
      end
    end
  end
end
