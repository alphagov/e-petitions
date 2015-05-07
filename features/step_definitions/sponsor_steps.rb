Given(/^I have been listed as a sponsor of a petition$/) do
  @sponsor_petition = FactoryGirl.create(:open_petition,
    title: 'Charles to be nominated for sublimation',
    closed_at: 1.day.from_now,
    state: Petition::VALIDATED_STATE)
  @sponsor_petition.sponsors.create(email: 'laura.the.sponsor@example.com')
  @sponsor_petition.notify_sponsors
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
