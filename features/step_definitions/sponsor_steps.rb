Given(/^I have been told about a petition that needs sponsoring$/) do
  @sponsor_petition = FactoryGirl.create(:open_petition,
    title: 'Charles to be nominated for sublimation',
    closed_at: 1.day.from_now,
    state: Petition::VALIDATED_STATE)
end

Given(/^I have created an e\-petition and told people to sponsor it$/) do
  @sponsor_petition = FactoryGirl.create(:open_petition,
    title: 'Charles to be nominated for sublimation',
    closed_at: 1.day.from_now,
    state: Petition::VALIDATED_STATE,
    creator_signature_attributes: {email: 'charlie.the.creator@example.com'} )
end

When(/^a sponsor supports my e\-petition$/) do
  sponsor_email = FactoryGirl.generate(:sponsor_email)
  steps %{
    When I visit the "sponsor this petition" url I was given
    And I fill in "Name" with "Anonymous Sponsor"
    And I fill in "Email" with "#{sponsor_email}"
    And I check "Yes, I am a British citizen or UK resident"
    And I fill in "Postcode" with "SW1A 1AA"
    And I select "United Kingdom" from "Country"
    And I try to sign
    And I say I am happy with my email address
    And "#{sponsor_email}" opens the email with text "confirm your email address"
    And they click the first link in the email
  }
  signature = @sponsor_petition.signatures.for_email(sponsor_email).first
  expect(signature).to be_present
  expect(signature).to be_sponsor
end

Given(/^I only need one more sponsor to support my e\-petition$/) do
  before_threshold = AppConfig.sponsor_moderation_threshold - 1
  while (@sponsor_petition.supporting_sponsors_count < before_threshold) do
    steps %Q{
      And a sponsor supports my e-petition
    }
  end
  steps %Q{
    And "charlie.the.creator@example.com" has read all their email
  }
end

Given(/^I have enough support from sponsors for my e\-petition$/) do
  while (@sponsor_petition.supporting_sponsors_count < AppConfig.sponsor_moderation_threshold) do
    steps %Q{
      And a sponsor supports my e-petition
    }
  end
  steps %Q{
    And "charlie.the.creator@example.com" has read all their email
  }
end

Given /^the petition I want to sign is (validated|sponsored|open|hidden|rejected)?$/ do |state|
  @sponsor_petition = FactoryGirl.create(:open_petition, state: state, :rejection_code => "irrelevant")
end

Given /^the petition I want to sign has been closed$/ do
  @sponsor_petition = FactoryGirl.create(:open_petition, closed_at: 1.day.ago)
end

Then(/^I am redirected to the petition closed page$/) do
  expect(current_path).to eq(petition_path(@sponsor_petition))
end

Then(/^I am redirected to the petition sign page$/) do
  expect(current_path).to eq(sign_petition_signatures_path(@sponsor_petition))
end

Then(/^I will see 404 error page$/) do
  expect(page.status_code).to eq 404
end

Given(/^the petition I want to sign has enough sponsors and is (validated|sponsored)?$/) do |state|
  @sponsor_petition = FactoryGirl.create(:open_petition, state: state, sponsor_count: AppConfig.sponsor_count_max)
end

Then(/^I am redirected to the petition moderation info page$/) do
  expect(current_path).to eq(moderation_info_petition_path(@sponsor_petition))
end

When(/^I visit the \"sponsor this petition\" url I was given$/) do
  visit petition_sponsor_path(@sponsor_petition, token: @sponsor_petition.sponsor_token)
end

When(/^I fill in my details as a sponsor(?: with email "(.*?)")?$/) do |email_address|
  email_address ||= 'laura.the.sponsor@example.com'
  steps %Q(
    When I fill in "Name" with "Laura The Sponsor"
    And I fill in "Email" with "#{email_address}"
    And I check "Yes, I am a British citizen or UK resident"
    And I fill in "Postcode" with "AB10 1AA"
    And I select "United Kingdom" from "Country"
  )
end

When(/^I don't fill in my details correctly as a sponsor$/) do
  steps %Q(
    When I fill in "Name" with ""
  )
end

Then(/^I should have fully signed the petition as a sponsor$/) do
  sponsor = @sponsor_petition.sponsors.for_email('laura.the.sponsor@example.com').first
  expect(sponsor).to be_present
  expect(sponsor.signature).to be_present
  expect(sponsor.signature.petition).to eq @sponsor_petition
  expect(sponsor.signature).to be_validated
end

Then(/^I should have a pending signature on the petition as a sponsor$/) do
  sponsor = @sponsor_petition.sponsors.for_email('laura.the.sponsor@example.com').first
  expect(sponsor).to be_present
  expect(sponsor.signature).to be_present
  expect(sponsor.signature.petition).to eq @sponsor_petition
  expect(sponsor.signature).to be_pending
end

Then(/^I should not have signed the petition as a sponsor$/) do
  sponsor = @sponsor_petition.sponsors.for_email('laura.the.sponsor@example.com').first
  expect(sponsor).not_to be_present
end

Then(/^(?:I|"(.*?)") should receive an email explaining the petition I am sponsoring$/) do |address|
  address = address || 'laura.the.sponsor@example.com'
  expect(unread_emails_for(address).size).to eq 1
  open_last_email_for(address)
  steps %Q{
    Then they should see "Parliament petitions - Validate your support for #{@sponsor_petition.creator_signature.name}'s petition #{@sponsor_petition.title}" in the email subject
    And they should see "#{@sponsor_petition.title}" in the email body
    And they should see "#{@sponsor_petition.action}" in the email body
    And they should see "#{@sponsor_petition.description}" in the email body
  }
end

Then(/^(?:I|"(.*?)") should not have received an email explaining the petition I am sponsoring$/) do |address|
  step %Q{#{address.blank? ? "\"#{address}\"" : "I"} should receive no email with subject "Parliament petitions - Validate your support for #{@sponsor_petition.creator_signature.name}'s petition #{@sponsor_petition.title}"}
end

Then(/^(I|they|".*?") should be emailed a link for gathering support from sponsors$/) do |address|
  steps %Q{
    Then #{address} should receive an email with subject "Parliament petitions - It's time to get sponsors to support your petition"
    When they open the email with subject "Parliament petitions - It's time to get sponsors to support your petition"
    Then they should see /\/petitions\/\\d+\/sponsors\/[A-Za-z0-9]+/ in the email body
  }
end
