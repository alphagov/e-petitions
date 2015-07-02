Given(/^I try the password "([^"]*)" (\d+) times in a row$/) do |password, number|
  number.times do
    steps %Q(
      And I fill in "Email" with "admin@example.com"
      And I fill in "Password" with "#{password}"
      And I press "Log in"
      Then I should see "Invalid email/password combination"
    )
  end
end

Given(/^I try the password "([^"]*)" (\d+) times in a row for the email "([^"]*)"$/) do |password, number, email|
  number.times do
    steps %Q(
      And I fill in "Email" with "#{email}"
      And I fill in "Password" with "#{password}"
      And I press "Log in"
      Then I should see "Invalid email/password combination"
    )
  end
end

Then(/^I should see the following admin user table:$/) do |values_table|
  actual_table = find(:css, 'table.user-list').all(:css, 'tr').map { |row| row.all(:css, 'th, td').map { |cell| cell.text.strip } }
  values_table.diff!(actual_table)
end

Then(/^I should see (\d+) rows? in the admin user table$/) do |number|
  expect(page).to have_xpath( "//table#{XPathHelpers.class_matching('user-list')}[count(tr#{XPathHelpers.class_matching('user-list-user')})=#{number.to_i}]" )
end
