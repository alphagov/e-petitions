Then /^I can sign the petition$/ do
  expect(page).to have_css("a", :text => "Sign")
end

Then /^I cannot sign the petition$/ do
  expect(page).not_to have_css("a", :text => "Sign")
end

When /^I decide to sign the petition$/ do
  visit petition_url(@petition)
  click_link "Sign this petition"
end

When /^I try to sign$/ do
  click_button "Continue"
end

Then /^I am told to check my inbox to complete signing$/ do
  expect(page).to have_title("Thank you")
  expect(page).to have_content("We’ve sent you an email")
end

Then(/^(?:I|they|"(.*?)") should be asked to confirm their email address$/) do |address|
  expect(find_email(address, with_subject: "Please confirm your signature")).to be_present
end

When(/^I confirm my email address(?: again)?$/) do
  steps %Q(
    And I open the email with subject "Please confirm your signature"
    When I click the first link in the email
  )
end

def should_be_signature_count_of(count)
  expect(Petition.find(@petition.id).signature_count).to eq(count)
end

Then /^I should have signed the petition$/ do
  should_be_signature_count_of(2)
end

When(/^I fill in my details(?: with email "([^"]+)")?$/) do |email_address|
  email_address ||= "womboid@wimbledon.com"

  if I18n.locale == :"en-GB"
    steps %Q(
      When I fill in "Name" with "Womboid Wibbledon"
      And I fill in "Email" with "#{email_address}"
      And I fill in my postcode with "SW14 9RQ"
      And I select "Wales" from "Location"
      And I check "Email me whenever there’s an update about this petition"
    )
  else
    steps %Q(
      When I fill in "Enw" with "Womboid Wibbledon"
      And I fill in "Cyfeiriad e-bost" with "#{email_address}"
      And I fill in my postcode with "SW14 9RQ"
      And I select "Cymru" from "Lleoliad"
      And I check "Anfonwch neges e-bost ataf pryd bynnag y bydd diweddariad ynghylch y ddeiseb hon"
    )
  end
end

When(/^I fill in my details as a creator(?: with email "([^"]+)")?$/) do |email_address|
  email_address ||= "womboid@wimbledon.com"

  if I18n.locale == :"en-GB"
    steps %Q(
      When I fill in "Name" with "Womboid Wibbledon"
      And I fill in "Email" with "#{email_address}"
      And I fill in my postcode with "SW14 9RQ"
      And I select "Wales" from "Location"
    )
  else
    steps %Q(
      When I fill in "Enw" with "Womboid Wibbledon"
      And I fill in "Cyfeiriad e-bost" with "#{email_address}"
      And I fill in my postcode with "SW14 9RQ"
      And I select "Cymru" from "Lleoliad"
    )
  end
end

When(/^I fill in my details with postcode "(.*?)"?$/) do |postcode|
  steps %Q(
    When I fill in "Name" with "Womboid Wibbledon"
    And I fill in "Email" with "womboid@wimbledon.com"
    And I fill in my postcode with "#{postcode}"
    And I select "Wales" from "Location"
    And I check "Email me whenever there’s an update about this petition"
  )
end

When(/^I fill in my details as a creator with postcode "(.*?)"?$/) do |postcode|
  steps %Q(
    When I fill in "Name" with "Womboid Wibbledon"
    And I fill in "Email" with "womboid@wimbledon.com"
    And I fill in my postcode with "#{postcode}"
    And I select "Wales" from "Location"
  )
end

When(/^I fill in my creator contact details$/) do
  if I18n.locale == :"en-GB"
    steps %Q(
      And I fill in "Phone number" with "0300 200 6565"
      And I fill in "Address" with "Pierhead St, Cardiff"
    )
  else
    steps %Q(
      And I fill in "Rhif ffôn" with "0300 200 6565"
      And I fill in "Cyfeiriad" with "Pierhead St, Cardiff"
    )
  end
end

When(/^I fill in my postcode with "(.*?)"$/) do |postcode|
  if I18n.locale == :"en-GB"
    step %{I fill in "Postcode" with "#{postcode}"}
  else
    step %{I fill in "Cod post" with "#{postcode}"}
  end
end

When /^I fill in my details and sign a petition$/ do
  steps %Q(
    When I go to the new signature page for "Do something!"
    And I should see "Do something! - Sign this petition - Petitions" in the browser page title
    And I should be connected to the server via an ssl connection
    And I fill in my details
    And I try to sign
    And I say I am happy with my email address
    Then I am told to check my inbox to complete signing
    And "womboid@wimbledon.com" should receive 1 email
  )
end

Then /^I should see that I have already signed the petition$/ do
  expect(page).to have_text("You’ve already signed this petition")
end

Then(/^I am asked to review my email address$/) do
  if I18n.locale == :"en-GB"
    expect(page).to have_content 'Make sure this is right'
    expect(page).to have_field('Email')
  else
    expect(page).to have_content 'Gwnewch yn siŵr fod hyn yn gywir'
    expect(page).to have_field('Cyfeiriad e-bost')
  end
end

Then(/^my email is autocorrected to "([^"]+)"/) do |email|
  expect(page).to have_field('Email', with: email)
end

When(/^I change my email address to "(.*?)"$/) do |email_address|
  fill_in 'Email', with: email_address
end

When(/^I say I am happy with my email address$/) do
  click_on "Yes – this is my email address"
end

And "I have already signed the petition with an uppercase email" do
  FactoryBot.create(:signature, petition: @petition,
    name: "Womboid Wibbledon", email: "WOMBOID@WIMBLEDON.COM"
  )
end

And "I have already signed the petition but not validated my email" do
  FactoryBot.create(:pending_signature, petition: @petition,
    name: "Womboid Wibbledon", email: "womboid@wimbledon.com", postcode: "CF991NA"
  )
end

And "I have already signed the petition using an alias" do
  FactoryBot.create(:validated_signature, petition: @petition,
    name: "Womboid Wibbledon", email: "wom.boid@wimbledon.com", postcode: "CF991NA"
  )
end

And "I have already signed the petition using an alias but not validated my email" do
  FactoryBot.create(:pending_signature, petition: @petition,
    name: "Womboid Wibbledon", email: "wom.boid@wimbledon.com", postcode: "CF991NA"
  )
end

Given /^Suzie has already signed the petition$/ do
  @suzies_signature = FactoryBot.create(:validated_signature, petition: @petition,
    name: "Womboid Wibbledon", email: "womboid@wimbledon.com", postcode: "SW14 9RQ"
  )
end

Given /^Eric has already signed the petition with Suzies email$/ do
  FactoryBot.create(:validated_signature, petition: @petition,
    name: "Eric Wibbledon", email: "womboid@wimbledon.com", postcode: "SW14 9RQ"
  )
end

Given(/^"([^"]*)" is configured to normalize email address$/) do |domain|
  FactoryBot.create(:domain, name: domain)
end

Given /^I have signed the petition with a second name$/ do
  FactoryBot.create(:validated_signature, petition: @petition,
    name: "Sam Wibbledon", email: "womboid@wimbledon.com", postcode: "SW14 9RQ"
  )
end

When(/^Suzie shares the signatory confirmation link with Eric$/) do
  @shared_link = signed_signature_url(@suzies_signature, token: @suzies_signature.perishable_token)
end

When /^I try to sign the petition with the same email address and a different name$/ do
  steps %Q{
    When I decide to sign the petition
    And I fill in my details
    And I fill in "Name" with "Sam Wibbledon"
    And I try to sign
    And I say I am happy with my email address
  }
end

When /^I try to sign the petition with the same email address and the same name$/ do
  step "I decide to sign the petition"
  step "I fill in my details"
  step "I try to sign"
  step "I say I am happy with my email address"
end

When /^I try to sign the petition with the same email address, a different name, and a different postcode$/ do
  step "I decide to sign the petition"
  step "I fill in my details"
  step %{I fill in "Name" with "Sam Wibbledon"}
  step %{I fill in my postcode with "W1A 1AA"}
  step "I try to sign"
  step "I say I am happy with my email address"
end

When /^I try to sign the petition with the same email address and a third name$/ do
  step "I decide to sign the petition"
  step "I fill in my details"
  step %{I fill in "Name" with "Sarah Wibbledon"}
  step "I try to sign"
  step "I say I am happy with my email address"
end

Then /^I should have signed the petition after confirming my email address$/ do
  steps %Q(
    And "womboid@wimbledon.com" should receive 1 email
    When I confirm my email address
  )
  should_be_signature_count_of(3)
end

Then /^there should be a "([^"]*)" signature with email "([^"]*)" and name "([^"]*)"$/ do |state, email, name|
  expect(Signature.for_email(email).find_by(name: name, state: state)).not_to be_nil
end

Then /^"([^"]*)" wants to be notified about the petition's progress$/ do |name|
  expect(Signature.find_by(name: name).notify_by_email?).to be_truthy
end

Given /^I have already signed the petition "([^"]*)" but not confirmed my email$/ do |petition_action|
  petition = Petition.find_by(action: petition_action)
  FactoryBot.create(:pending_signature, :email => 'suzie@example.com', :petition => petition)
end

When /^I fill in "([^"]*)" with my email address$/ do |field_name|
  step "I fill in \"#{field_name}\" with \"suzie@example.com\""
end

Then /^the signature count (?:stays at|goes up to) (\d+)$/ do |number|
  signatures = @petition.signatures
  expect(signatures.count).to eq number
end
