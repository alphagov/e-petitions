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
  debugger
  :debugger
end
