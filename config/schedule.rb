# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

every :weekday, at: '7am' do
  rake "epets:admin_email_reminder", output: nil
end

every :weekday, at: '6.30am' do
  rake "epets:threshold_email_reminder", output: nil
end

every 30.minutes do
  runner "PetitionCountJob.perform_later"
end

every :weekday, at: '0.00am' do
  runner "ClosePetitionsJob.perform_later"
end

every :weekday, at: '0.00am' do
  runner "DebatedPetitionsJob.perform_later"
end
