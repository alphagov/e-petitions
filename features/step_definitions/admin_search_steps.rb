Given(/^(\d+) petitions? signed by "([^"]*)"$/) do |petition_count, name_or_email|
  petition_count.times do
    if name_or_email =~ /\A[^@]+@[^@]+\z/
      attrs = { email: name_or_email }
    else
      attrs = { name: name_or_email }
    end

    attrs[:petition] = FactoryBot.create(:open_petition)
    FactoryBot.create(:signature, attrs)
  end
end

Given(/^a petition "(.*?)" signed by "([^"]*)"$/) do |action, name_or_email|
  if name_or_email =~ /\A[^@]+@[^@]+\z/
    attrs = { email: name_or_email }
  else
    attrs = { name: name_or_email }
  end

  @petition = FactoryBot.create(:open_petition, action: action)
  @signature = FactoryBot.create(:validated_signature, attrs.merge(petition: @petition))
end

Given(/^(\d+) petitions? signed from "([^"]*)"$/) do |petition_count, ip_address|
  petition_count.times do
    petition = FactoryBot.create(:open_petition)
    FactoryBot.create(:signature, ip_address: ip_address, petition: petition)
  end
end

Given(/^(\d+) petitions? signed in "([^"]*)"$/) do |petition_count, postcode|
  petition_count.times do
    petition = FactoryBot.create(:open_petition)
    FactoryBot.create(:signature, postcode: PostcodeSanitizer.call(postcode), petition: petition)
  end
end

Given(/^(\d+) petitions? with a (pending|validated) signature by "([^"]*)"$/) do |petition_count, state, email|
  petition_count.times do
    FactoryBot.create(:"#{state}_signature", :petition => FactoryBot.create(:open_petition), :email => email)
  end
end

When(/^I search for signatures from "([^"]*)"$/) do |name_or_email|
  fill_in "Search", with: name_or_email
  click_button 'Search'
end

Then(/^I should see (\d+) signatures? associated with that (?:name|email address)$/) do |count|
  expect(page).to have_css("tbody tr", count: count)
end

When(/^I search for petitions signed by "([^"]*)"( from the admin hub)?$/) do |name_or_email, from_the_hub|
  if from_the_hub.blank?
    visit admin_signatures_url
  else
    visit admin_root_url
    choose "signatures"
  end

  fill_in "Search", :with => name_or_email
  click_button 'Search'
end

When(/^I search for petitions signed from "([^"]*)"( from the admin hub)?$/) do |ip_address, from_the_hub|
  if from_the_hub.blank?
    visit admin_signatures_url
  else
    visit admin_root_url
    choose "signatures"
  end

  fill_in "Search", with: ip_address
  click_button 'Search'
end

When(/^I search for petitions signed in "([^"]*)"( from the admin hub)?$/) do |postcode, from_the_hub|
  if from_the_hub.blank?
    visit admin_signatures_url
  else
    visit admin_root_url
    choose "signatures"
  end

  fill_in "Search", with: postcode
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

  click_details "Tags"

  check tag
  click_button 'Search'
end

When(/^I search for the petition creator from the admin hub$/) do
  visit admin_root_url
  choose "signatures"
  fill_in "Search", :with => @petition.creator.email
  click_button 'Search'
end

When(/^I view the petition through the admin interface$/) do
  visit admin_petitions_url
  fill_in "Search", :with => @petition.id
  click_button 'Search'
end

Then(/^I should see (\d+) petitions? associated with the (?:name|email address|IP address|postcode|sector)$/) do |petition_count|
  expect(page).to have_css("tbody tr", :count => petition_count)
end

Then(/^I should be taken back to the id search form with an error$/) do
  expect(page).to have_css(".flash-alert")
  expect(page).to have_css("form")
end

Then(/^I should see the email address is pending$/) do
  expect(page).to have_button "Validate"
end

When(/^I click the (validate|invalidate) button$/) do |button|
  click_button button.titleize
end

Then(/^I should see the email address is validated$/) do
  expect(page).not_to have_button "Validate"
  expect(page).to have_button "Invalidate"
  expect(page).to have_button "Delete"
end

Then(/^I should see the email address is invalidated$/) do
  expect(page).not_to have_button "Invalidate"
  expect(page).to have_button "Validate"
  expect(page).to have_button "Delete"
end

Then(/^I should see the email address is unsubscribed$/) do
  expect(page).not_to have_button "Unsubscribe"
end

When(/^I click the unsubscribe button$/) do
  click_button "Unsubscribe"
end

When(/^I click the delete button$/) do
  click_button "Delete"
end

When(/^I click the first delete button$/) do
  within :css, "tbody tr:first" do
    click_button "Delete"
  end
end

Then(/^I should not see the unsubscribe button$/) do
  expect(page).not_to have_button "Unsubscribe"
end

Then(/^I should not see the delete button$/) do
  expect(page).not_to have_button "Delete"
end
