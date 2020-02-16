namespace :epets do
  namespace :countries do
    desc "Add task to the queue to fetch department information from the Parliament API"
    task :fetch => :environment do
      Task.run("epets:departments:fetch") do
        FetchDepartmentsJob.perform_later
      end
    end
  end
end
