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
    And I choose "yes"
    And I fill in "Address" with "Sponsor House, Sponsor Street"
    And I fill in "Town" with "Sponsorton-upon-Spon"
    And I fill in "Postcode" with "SW1A 1AA"
    And I select "United Kingdom" from "Country"
    And I accept the terms and conditions
    And I try to sign
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

When(/^I fill in my details as a sponsor$/) do
  expect(page).to have_no_field 'signature[email]'
  expect(page).to have_no_field 'signature[email_confirmation]'
  steps %Q(
    When I fill in "Name" with "Laura The Sponsor"
    And I choose "yes"
    And I fill in "Address" with "A House, On Street"
    And I fill in "Town" with "Townsville"
    And I fill in "Postcode" with "AB10 1AA"
    And I select "United Kingdom" from "Country"
  )
end

Then(/^I should have signed the petition as a sponsor$/) do
  sponsor = @sponsor_petition.sponsors.for_email('laura.the.sponsor@example.com').first
  expect(sponsor).to be_present
  expect(sponsor.signature).to be_present
  expect(sponsor.signature.petition).to eq @sponsor_petition
end

Then(/^I should not have signed the petition as a sponsor$/) do
  sponsor = @sponsor_petition.sponsors.for_email('laura.the.sponsor@example.com').first
  expect(sponsor).to be_present
  expect(sponsor.signature).not_to be_present
end
