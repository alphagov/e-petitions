Given /^(\d+) petitions signed by "([^"]*)"$/ do |petition_count, email|
  petition_count.times do
    FactoryGirl.create(:signature, :petition => FactoryGirl.create(:open_petition), :email => email)
  end
end

When /^I search for petitions signed by "([^"]*)" in the admin section$/ do |email|
  visit new_admin_search_path
  fill_in "Search", :with => email
  click_button 'Search'
end

When /^I search for a petition by id$/ do
  non_existent_petition_id = 123123
  visit new_admin_search_path
  fill_in "Search", :with => @petition ? @petition.id : non_existent_petition_id
  click_button 'Search'
end

When /^I search for petitions with keyword "([^"]*)" in the admin section$/ do |keyword|
  visit new_admin_search_path
  fill_in "Search", :with => keyword
  click_button 'Search'
end

When /^I view the petition through the admin interface$/ do
  visit new_admin_search_path
  fill_in "Search", :with => @petition.id
  click_button 'Search'
end

Then /^I should see the petition for viewing only$/ do
  expect(page).to have_css('.petition')
end

Then /^I should see the petition for editing$/ do
  expect(page).to have_css('form.edit_petition')
end

Then /^I should see the petition for editing the internal reponse and changing the status$/ do
  expect(page).to have_css('form textarea#petition_internal_response')
  expect(page).to have_css('form select#petition_rejection_code')
end

Then /^I should see the petition for editing the reponses$/ do
  expect(page).to have_css('form textarea#petition_response')
end

Then /^I should see (\d+) petitions associated with the email address$/ do |petition_count|
  expect(page).to have_css("tbody tr", :count => petition_count)
end

Then /^I should be taken back to the id search form with an error$/ do
  expect(page).to have_css(".flash_error")
  expect(page).to have_css("form")
end
