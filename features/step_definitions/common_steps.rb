Then /^the response status should be (\d+)$/ do |code|
  page.driver.response.status.to_i.should == code
end

Then /^dump response body$/ do
  puts page.body
end

Then /^it should(| not) be an SSL page$/ do |should_or_not|
  page.driver.request.scheme.should == ( should_or_not.blank? ? 'https' : 'http' )
end

Then /^debugger$/ do
  debugger
  :debugger
end