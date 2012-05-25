Given /^the(?: date is the| time is) "([^"]*)"$/ do |description|
  time = Chronic.parse(description, :now => Time.now)
  raise "Chronic could not parse #{description}" unless time
  Timecop.travel time.utc
end

After do
  Timecop.return
end