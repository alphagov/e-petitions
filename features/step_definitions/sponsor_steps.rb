Given(/^I have been told about a petition that needs sponsoring$/) do
  @sponsor_petition = FactoryBot.create(:open_petition,
    action: 'Charles to be nominated for sublimation',
    closed_at: 1.day.from_now,
    state: Petition::VALIDATED_STATE)
end

Given(/^I have created a petition and told people to sponsor it$/) do
  @sponsor_petition = FactoryBot.create(:pending_petition,
    action: 'Charles to be nominated for sublimation',
    closed_at: 1.day.from_now,
    state: Petition::PENDING_STATE,
    creator_attributes: { email: 'charlie.the.creator@example.com' })
end

When(/^a sponsor supports my petition$/) do
  sponsor_email = FactoryBot.generate(:sponsor_email)
  steps %{
    When I visit the "sponsor this petition" url I was given
    And I fill in "Name" with "Anonymous Sponsor"
    And I fill in "Email" with "#{sponsor_email}"
    And I fill in my postcode with "SW1A 1AA"
    And I select "United Kingdom" from "Location"
    And I try to sign
    And I say I am happy with my email address
    And "#{sponsor_email}" opens the email with subject "Please confirm your email address"
    And they click the first link in the email
  }
  signature = @sponsor_petition.signatures.for_email(sponsor_email).first
  expect(signature).to be_present
  expect(signature).to be_sponsor
end

Given(/^I only need one more sponsor to support my petition$/) do
  before_threshold = Site.threshold_for_moderation - 1
  while (@sponsor_petition.sponsors.validated.count < before_threshold) do
    step %{a sponsor supports my petition}
  end
  step %{"charlie.the.creator@example.com" has read all their email}
end

Given(/^I have enough support from sponsors for my petition$/) do
  while (@sponsor_petition.sponsors.validated.count < Site.threshold_for_moderation) do
    step %{a sponsor supports my petition}
  end
  step %{"charlie.the.creator@example.com" has read all their email}
end

Given(/^the petition I want to sign is (validated|sponsored|open|hidden|rejected)$/) do |state|
  if state == "rejected"
    @sponsor_petition = FactoryBot.create(:rejected_petition, rejection_code: "irrelevant")
  else
    @sponsor_petition = FactoryBot.create(:open_petition, state: state)
  end
end

Given(/^the petition I want to sign has been closed$/) do
  @sponsor_petition = FactoryBot.create(:closed_petition, closed_at: 1.day.ago)
end

Then(/^I am redirected to the petition closed page$/) do
  expect(current_path).to eq(petition_path(@sponsor_petition))
end

Then(/^I am redirected to the petition view page$/) do
  expect(current_path).to eq(petition_path(@sponsor_petition))
end

Then(/^I will see 404 error page$/) do
  expect(page.status_code).to eq 404
end

Given(/^the petition I want to sign has enough sponsors?$/) do
  @sponsor_petition = FactoryBot.create(:sponsored_petition, sponsor_count: Site.maximum_number_of_sponsors, sponsors_signed: true)
end

Then(/^I am redirected to the petition moderation info page$/) do
  expect(current_path).to eq(moderation_info_petition_path(@sponsor_petition))
end

When(/^I visit the \"sponsor this petition\" url I was given$/) do
  visit new_petition_sponsor_url(@sponsor_petition, token: @sponsor_petition.sponsor_token)
end

When(/^I fill in my details as a sponsor(?: with email "(.*?)")?$/) do |email_address|
  email_address ||= 'laura.the.sponsor@example.com'
  steps %{
    When I fill in "Name" with "Laura The Sponsor"
    And I fill in "Email" with "#{email_address}"
    And I fill in my postcode with "AB10 1AA"
    And I select "United Kingdom" from "Location"
    And I check "Email me whenever there’s an update about this petition"
  }
end

When(/^I don't fill in my details correctly as a sponsor$/) do
  step %{I fill in "Name" with ""}
end

Then(/^I should have fully signed the petition as a sponsor$/) do
  sponsor = @sponsor_petition.sponsors.for_email('laura.the.sponsor@example.com').first
  expect(sponsor).to be_present
  expect(sponsor.petition).to eq @sponsor_petition
  expect(sponsor).to be_validated
end

Then(/^I should have a pending signature on the petition as a sponsor$/) do
  sponsor = @sponsor_petition.sponsors.for_email('laura.the.sponsor@example.com').first
  expect(sponsor).to be_present
  expect(sponsor.petition).to eq @sponsor_petition
  expect(sponsor).to be_pending
end

Then(/^I should not have signed the petition as a sponsor$/) do
  sponsor = @sponsor_petition.sponsors.for_email('laura.the.sponsor@example.com').first
  expect(sponsor).not_to be_present
end

Then(/^(?:I|"(.*?)") should receive an email explaining the petition I am sponsoring$/) do |address|
  address = address || 'laura.the.sponsor@example.com'
  expect(unread_emails_for(address).size).to eq 1
  open_last_email_for(address)
  steps %{
    Then they should see "Please confirm your email address" in the email subject
    And they should see "#{@sponsor_petition.action}" in the email body
    And they should see "#{@sponsor_petition.background}" in the email body
    And they should see "#{@sponsor_petition.additional_details}" in the email body
  }
end

Then(/^(?:I|"(.*?)") should not have received an email explaining the petition I am sponsoring$/) do |address|
  address = address.blank? ? address : "I"
  expect(unread_emails_for(address).select { |m| m.default_part_body.to_s =~ Regexp.new(@sponsor_petition.action) }.size).to eq 0
end

Then(/^(I|they|".*?") should be emailed a link for gathering support from sponsors$/) do |address|
  steps %{
    Then #{address} should receive an email with subject "Action required: Petition"
    When they open the email with subject "Action required: Petition"
    Then they should see /\/petitions\/\\d+\/sponsors\/[A-Za-z0-9]+/ in the email body
    Then they should see /\/deisebau\/\\d+\/noddwyr\/[A-Za-z0-9]+/ in the email body
  }
end

When(/^I have sponsored a petition$/) do
  steps %{
    When I visit the "sponsor this petition" url I was given
    And I should be connected to the server via an ssl connection
    When I fill in my details as a sponsor
    And I try to sign
    Then I should not have signed the petition as a sponsor
    And I am asked to review my email address
    When I say I am happy with my email address
    Then I should have a pending signature on the petition as a sponsor
    And I should receive an email explaining the petition I am sponsoring
  }
end
