Then(/^I should see the cookie message$/) do
  expect(page).to have_text('We use cookies to make this service simpler')
end

Then(/^I should not see the cookie message$/) do
  expect(page).not_to have_text('We use cookies to make this service simpler')
end

Then(/^I wait for (\d+) ((?:day|week|month|year|)s?)$/) do |duration, period|
  travel(duration.to_i.send(period) + 1.second)
end

Then /^the response status should be (\d+)$/ do |code|
  expect(page.driver.response.status.to_i).to eq code
end

Then /^dump response body$/ do
  puts page.body
end

Then /^it should(| not) be an SSL page$/ do |should_or_not|
  expect(page.driver.request.scheme).to eq ( should_or_not.blank? ? 'https' : 'http' )
end

Then /^debugger$/ do
  binding.pry
  :debugger
end
