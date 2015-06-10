Given /^the(?: date is the| time is) "([^"]*)"$/ do |description|
  travel_to description.in_time_zone
end

After do
  travel_back
end
