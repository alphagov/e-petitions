Then /^I cannot sign the petition$/ do
  expect(page).not_to have_css("a", :text => "Sign")
end

When /^I decide to sign the petition$/ do
  visit petition_path(@petition)
  click_link "Sign this petition"
end

When /^I try to sign$/ do
  click_button "Sign this e-petition"
end

Then /^I have not yet signed the petition$/ do
  expect(page).to have_title("Thank you")
  click_link("view")
  expect(page).to have_css("dd.signature_count", :text => "1")
end

When /^I accept the terms and conditions$/ do
  check "I agree"
end

When /^I confirm my email address$/ do
  steps %Q(
    And I open the email
    And I should see "Thank" in the email body
    When I click the first link in the email
    Then I should see "Thank you"
  )
end

def should_be_signature_count_of(count)
  Petition.update_all_signature_counts
  visit petition_path(@petition)
  expect(page).to have_css("dd.signature_count", :text => count.to_s)
end

Then /^I should have signed the petition$/ do
  should_be_signature_count_of(2)
end

When /^I fill in my non\-UK details$/ do
  step "I fill in my details"
  uncheck "Yes, I am a British citizen or UK resident"
end

When /^I fill in my details$/ do
  steps %Q(
    When I fill in "Name" with "Womboid Wibbledon"
    And I fill in "Email" with "womboid@wimbledon.com"
    And I fill in "Email confirmation" with "womboid@wimbledon.com"
    And I check "Yes, I am a British citizen or UK resident"
    And I fill in "Postcode" with "SW14 9RQ"
    And I select "United Kingdom" from "Country"
  )
end

When /^I fill in my details with email "([^"]*)" and confirmation "([^"]*)"$/ do |email, email_confirmation|
  step "I fill in my details"
  steps %Q(
    And I fill in "Email" with "#{email}"
    And I fill in "Email confirmation" with "#{email_confirmation}"
  )
end

And "I have already signed the petition with an uppercase email" do
  FactoryGirl.create(:signature, :petition => @petition, :email => "WOMBOID@WIMBLEDON.COM")
end

Given /^Suzie has already signed the petition$/ do
  FactoryGirl.create(:signature, :petition => @petition, :email => "womboid@wimbledon.com",
         :postcode => "SW14 9RQ", :name => "Womboid Wibbledon")
end

Given /^I have signed the petition with a second name$/ do
  FactoryGirl.create(:signature, :petition => @petition, :email => "womboid@wimbledon.com",
         :postcode => "SW14 9RQ", :name => "Sam Wibbledon")
end

When /^I try to sign the petition with the same email address and a different name$/ do
  step "I decide to sign the petition"
  step "I fill in my details"
  step %{I fill in "Name" with "Sam Wibbledon"}
  step "I accept the terms and conditions"
  step "I try to sign"
end

When /^I try to sign the petition with the same email address and the same name$/ do
  step "I decide to sign the petition"
  step "I fill in my details"
  step "I accept the terms and conditions"
  step "I try to sign"
end

When /^I try to sign the petition with the same email address, a different name, and a different postcode$/ do
  step "I decide to sign the petition"
  step "I fill in my details"
  step %{I fill in "Name" with "Sam Wibbledon"}
  step %{I fill in "Postcode" with "W1A 1AA"}
  step "I accept the terms and conditions"
  step "I try to sign"
end

When /^I try to sign the petition with the same email address and a third name$/ do
  step "I decide to sign the petition"
  step "I fill in my details"
  step %{I fill in "Name" with "Sarah Wibbledon"}
  step "I accept the terms and conditions"
  step "I try to sign"
end

Then /^I should have signed the petition after confirming my email address$/ do
  steps %Q(
    And "womboid@wimbledon.com" should receive 1 email
    When I confirm my email address
    And all petitions have had their signatures counted
  )
  should_be_signature_count_of(3)
end

Then /^there should be a "([^"]*)" signature with email "([^"]*)" and name "([^"]*)"$/ do |state, email, name|
  expect(Signature.for_email(email).find_by(name: name, state: state)).not_to be_nil
end

Then /^"([^"]*)" wants to be notified about the petition's progress$/ do |name|
  expect(Signature.find_by(name: name).notify_by_email?).to be_truthy
end

Given /^I have already signed the petition "([^"]*)" but not confirmed my email$/ do |petition_title|
  petition = Petition.find_by(title: petition_title)
  FactoryGirl.create(:pending_signature, :email => 'suzie@example.com', :petition => petition)
end

When /^I fill in "([^"]*)" with my email address$/ do |field_name|
  step "I fill in \"#{field_name}\" with \"suzie@example.com\""
end
