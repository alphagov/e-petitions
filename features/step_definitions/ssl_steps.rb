Then /^I should (not |)be connected to the server via an ssl connection$/ do |ssl_or_not|
  if ssl_or_not.blank?
    current_url.should match(%r!^https://!)
  else
    current_url.should match(%r!^http://!)
  end
end
