namespace :epets do
  namespace :petitions do
    desc "Add a task to the queue to close petitions at midnight"
    task :close => :environment do
      Task.run("epets:petitions:close") do
        time = Date.tomorrow.beginning_of_day
        ClosePetitionsJob.set(wait_until: time).perform_later(time.iso8601)
      end
    end

    desc "Add a task to the queue to validate petition counts"
    task :count => :environment do
      Task.run("epets:petitions:count") do
        PetitionCountJob.perform_later
      end
    end

    desc "Add a task to the queue to mark petitions as debated at midnight"
    task :debated => :environment do
      Task.run("epets:petitions:debated") do
        date = Date.tomorrow
        DebatedPetitionsJob.set(wait_until: date.beginning_of_day).perform_later(date.iso8601)
      end
    end
  end
end
