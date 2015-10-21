Given(/^(\d+) petitions? signed by "([^"]*)"$/) do |petition_count, email|
  petition_count.times do
    FactoryGirl.create(:signature, :petition => FactoryGirl.create(:open_petition), :email => email)
  end
end

Given(/^(\d+) petitions? with a pending signature by "([^"]*)"$/) do |petition_count, email|
  petition_count.times do
    FactoryGirl.create(:pending_signature, :petition => FactoryGirl.create(:open_petition), :email => email)
  end
end

When(/^I search for petitions signed by "([^"]*)"( from the admin hub)?$/) do |email, from_the_hub|
  if from_the_hub.blank?
    visit admin_petitions_url
  else
    visit admin_root_url
  end
  fill_in "Search", :with => email
  click_button 'Search'
end

When(/^I search for a petition by id( from the admin hub)?$/) do |from_the_hub|
  non_existent_petition_id = 123123
  if from_the_hub.blank?
    visit admin_petitions_url
  else
    visit admin_root_url
  end
  fill_in "Search", :with => @petition ? @petition.id : non_existent_petition_id
  click_button 'Search'
end

When(/^I search for petitions with keyword "([^"]*)"( from the admin hub)?$/) do |keyword, from_the_hub|
  if from_the_hub.blank?
    visit admin_petitions_url
  else
    visit admin_root_url
  end
  fill_in "Search", :with => keyword
  click_button 'Search'
end

When(/^I search for petitions with tag "([^"]*)"( from the admin hub)?$/) do |tag, from_the_hub|
  if from_the_hub.blank?
    visit admin_petitions_url
  else
    visit admin_root_url
  end
  fill_in "Search", :with => "[#{tag}]"
  click_button 'Search'
end

When(/^I search for the petition creator from the admin hub$/) do
  visit admin_petitions_url
  fill_in "Search", :with => @petition.creator_signature.email
  click_button 'Search'
end

When(/^I view the petition through the admin interface$/) do
  visit admin_petitions_url
  fill_in "Search", :with => @petition.id
  click_button 'Search'
end

Then(/^I should see (\d+) petitions? associated with the email address$/) do |petition_count|
  expect(page).to have_css("tbody tr", :count => petition_count)
end

Then(/^I should be taken back to the id search form with an error$/) do
  expect(page).to have_css(".flash-alert")
  expect(page).to have_css("form")
end

Then(/^I should see the email address is pending$/) do
  expect(page).to have_button "Validate"
end

When(/^I click the validate button$/) do
  click_button "Validate"
end

Then(/^I should see the email address is validated$/) do
  expect(page).not_to have_button "Validate"
  expect(page).to have_button "Delete"
end

When(/^I click the delete button$/) do
  click_button "Delete"
end

When(/^I click the first delete button$/) do
  within :css, "tbody tr:first" do
    click_button "Delete"
  end
end

Then(/^I should not see the delete button$/) do
  expect(page).not_to have_button "Delete"
end
