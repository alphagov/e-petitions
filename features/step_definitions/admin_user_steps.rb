Given /^I try the password "([^"]*)" (\d+) times in a row$/ do |password, number|
  number.times do
    steps %Q(
      And I fill in "Email" with "admin@example.com"
      And I fill in "Password" with "#{password}"
      And I press "Log in"
      Then I should see "Invalid email/password combination"
    )
  end
end

Given /^I try the password "([^"]*)" (\d+) times in a row for the email "([^"]*)"$/ do |password, number, email|
  number.times do
    steps %Q(
      And I fill in "Email" with "#{email}"
      And I fill in "Password" with "#{password}"
      And I press "Log in"
      Then I should see "Invalid email/password combination"
    )
  end
end
