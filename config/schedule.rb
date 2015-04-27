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

every :weekday, :at => '7am' do # Use any day of the week or :weekend, :weekday
  rake "epets:admin_email_reminder", :output => nil
end

every :weekday, :at => '6.30am' do # Use any day of the week or :weekend, :weekday
  rake "epets:threshold_email_reminder", :output => nil
end

every 5.minutes do
  runner "Petition.update_all_signature_counts", :output => nil
  runner "TrendingPetition.update_homepage_trends", :output => nil
end

every :weekday, :at => '9am' do
  runner "Petition.email_all_who_passed_finding_mp_threshold", :output => nil
end
