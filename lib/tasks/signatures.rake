namespace :epets do
  namespace :signatures do
    desc "Add a task to the queue to close petitions at midnight"
    task :anonymise => :environment do
      Task.run("epets:signatures:anonymise") do
        time = Date.tomorrow.beginning_of_day
        AnonymiseSignaturesJob.set(wait_until: time).perform_later(time.iso8601)
      end
    end
  end
end
