namespace :epets do
  namespace :countries do
    desc "Add task to the queue to fetch country list from the register"
    task :fetch => :environment do
      FetchCountryRegisterJob.perform_later
    end
  end
end
