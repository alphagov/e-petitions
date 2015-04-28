Then /^I should (not |)be connected to the server via an ssl connection$/ do |ssl_or_not|
  if ssl_or_not.blank?
    expect(current_url).to match(%r!^https://!)
  else
    expect(current_url).to match(%r!^http://!)
  end
end
