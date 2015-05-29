Given(/^I have been listed as a sponsor of a petition$/) do
  @sponsor_petition = FactoryGirl.create(:open_petition,
    title: 'Charles to be nominated for sublimation',
    closed_at: 1.day.from_now,
    state: Petition::VALIDATED_STATE)
  @sponsor_petition.sponsors.create(email: 'laura.the.sponsor@example.com')
  @sponsor_petition.notify_sponsors
end

Given(/^I have created an e\-petition with sponsors$/) do
  @petition = FactoryGirl.create(:open_petition,
    title: 'Charles to be nominated for sublimation',
    closed_at: 1.day.from_now,
    state: Petition::VALIDATED_STATE,
    sponsor_emails: (1..AppConfig.sponsor_count_max).map { |n| "sponsor#{n}@example.com" },
    creator_signature_attributes: {email: 'charlie.the.creator@example.com'} )
  @petition.notify_sponsors
end

When(/^a sponsor supports my e\-petition$/) do
  sponsor = @petition.sponsors.where(signature_id: nil).first
  expect(sponsor).to be_present
  steps %{
    When "#{sponsor.email}" opens the email with subject "Parliament petitions - #{@petition.creator_signature.name} would like your support"
    And they click the first link in the email
    And I fill in "Name" with "Anonymous Sponsor"
    And I fill in "Email" with "#{sponsor.email}"
    And I check "Yes, I am a British citizen or UK resident"
    And I fill in "Postcode" with "SW1A 1AA"
    And I select "United Kingdom" from "Country"
    And I try to sign
    And I say I am happy with my email address
    And "#{sponsor.email}" opens the email with text "confirm your email address"
    And they click the first link in the email
  }
  expect(sponsor.reload.signature).to be_present
end

Given(/^I only need one more sponsor to support my e\-petition$/) do
  before_threshold = AppConfig.sponsor_moderation_threshold - 1
  while (@petition.supporting_sponsors_count < before_threshold) do
    steps %Q{
      And a sponsor supports my e-petition
    }
  end
  steps %Q{
    And "charlie.the.creator@example.com" has read all their email
  }
end

Given(/^I have enough support from sponsors for my e\-petition$/) do
  while (@petition.supporting_sponsors_count < AppConfig.sponsor_moderation_threshold) do
    steps %Q{
      And a sponsor supports my e-petition
    }
  end
  steps %Q{
    And "charlie.the.creator@example.com" has read all their email
  }
end

When(/^I follow the link to the petition in my sponsor email$/) do
  steps %Q{
    When "laura.the.sponsor@example.com" opens the email with subject "Parliament petitions - #{@sponsor_petition.creator_signature.name} would like your support"
    And they click the first link in the email
  }
  sponsor = @sponsor_petition.sponsors.for_email('laura.the.sponsor@example.com').first
  expect(current_path).to eq petition_sponsor_path(@sponsor_petition, token: sponsor.perishable_token)
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
  expect(sponsor).to be_present
  expect(sponsor.signature).not_to be_present
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
