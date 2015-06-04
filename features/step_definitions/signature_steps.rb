Then /^I cannot sign the petition$/ do
  expect(page).not_to have_css("a", :text => "Sign")
end

When /^I decide to sign the petition$/ do
  visit petition_path(@petition)
  click_link "Sign this petition"
end

When /^I try to sign$/ do
  click_button "Sign this petition"
end

Then /^I have not yet signed the petition$/ do
  expect(page).to have_title("Thank you")
  click_link("view")
  expect(page).to have_css("p.signature-count", :text => "1 signatures")
end

Then(/^(?:I|they|"(.*?)") should be asked to confirm their email address$/) do |address|
  expect(find_email(address, with_text: "confirm your email address")).to be_present
end

When /^I confirm my email address$/ do
  steps %Q(
    And I open the email with text "confirm your email address"
    When I click the first link in the email
    Then I should see "Thank you"
  )
end

def should_be_signature_count_of(count)
  Petition.update_all_signature_counts
  visit petition_path(@petition)
  expect(page).to have_css("p.signature-count", :text => count.to_s + " signatures")
end

Then /^I should have signed the petition$/ do
  should_be_signature_count_of(2)
end

When /^I fill in my non\-UK details$/ do
  step "I fill in my details"
  uncheck "Yes, I am a British citizen or UK resident"
end

When(/^I fill in my details(?: with email "([^"]+)")?$/) do |email_address|
  email_address ||= "womboid@wimbledon.com"
  steps %Q(
    When I fill in "Name" with "Womboid Wibbledon"
    And I fill in "Email" with "#{email_address}"
    And I check "Yes, I am a British citizen or UK resident"
    And I fill in my postcode with "SW14 9RQ"
    And I select "United Kingdom" from "Country"
  )
end

When(/^I fill in my details with postcode "(.*?)"?$/) do |postcode|
  steps %Q(
    When I fill in "Name" with "Womboid Wibbledon"
    And I fill in "Email" with "womboid@wimbledon.com"
    And I check "Yes, I am a British citizen or UK resident"
    And I fill in my postcode with "#{postcode}"
    And I select "United Kingdom" from "Country"
  )
end

When(/^I fill in my postcode with "(.*?)"$/) do |postcode|
  step %{I fill in "Postcode" with "#{postcode}"}

  api_url = ConstituencyApi::Client::URL
  body = "<Constituencies/>"
  if postcode == "N1 1TY"
    body = "<Constituencies>
              <Constituency><Name>Islington South and Finsbury</Name></Constituency>
            </Constituencies>"
  end
  stub_request(:get, "#{ api_url }/#{postcode.gsub(/\s+/, '')}/").to_return(status: 200, body: body)
end


When /^I fill in my details and sign a petition$/ do
  steps %Q(
    When I go to the new signature page for "Do something!"
    And I should see "Do something! - Sign this e-petition - e-petitions" in the browser page title
    And I should be connected to the server via an ssl connection
    And I fill in my details
    And I try to sign
    And I say I am happy with my email address
    Then I have not yet signed the petition
    And "womboid@wimbledon.com" should receive 1 email
  )
end

Then /^I should see that I have already signed the petition$/ do
  expect(page).to have_text("Thank you. Your signature has already been added to the e-petition.")
end

Then(/^I am asked to review my email address$/) do
  expect(page).to have_content 'Make sure this is right'
  expect(page).to have_field('Email')
end

When(/^I change my email address to "(.*?)"$/) do |email_address|
  fill_in 'Email', with: email_address
end

When(/^I say I am happy with my email address$/) do
  click_on "Yes - this is my email address"
end

And "I have already signed the petition with an uppercase email" do
  FactoryGirl.create(:signature, name: "Womboid Wibbledon", :petition => @petition,
                     :email => "WOMBOID@WIMBLEDON.COM")
end

And "I have already signed the petition but not validated my email" do
  FactoryGirl.create(:pending_signature, name: "Womboid Wibbledon", :petition => @petition,
                     :email => "womboid@wimbledon.com")
end

Given /^Suzie has already signed the petition$/ do
  @suzies_signature = FactoryGirl.create(:signature, :petition => @petition, :email => "womboid@wimbledon.com",
         :postcode => "SW14 9RQ", :name => "Womboid Wibbledon")
end

Given /^Eric has already signed the petition with Suzies email$/ do
  FactoryGirl.create(:signature, :petition => @petition, :email => "womboid@wimbledon.com",
         :postcode => "SW14 9RQ", :name => "Eric Wibbledon")
end

Given /^I have signed the petition with a second name$/ do
  FactoryGirl.create(:signature, :petition => @petition, :email => "womboid@wimbledon.com",
         :postcode => "SW14 9RQ", :name => "Sam Wibbledon")
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
end

When /^I try to sign the petition with the same email address, a different name, and a different postcode$/ do
  step "I decide to sign the petition"
  step "I fill in my details"
  step %{I fill in "Name" with "Sam Wibbledon"}
  step %{I fill in "Postcode" with "W1A 1AA"}
  step "I try to sign"
end

When /^I try to sign the petition with the same email address and a third name$/ do
  step "I decide to sign the petition"
  step "I fill in my details"
  step %{I fill in "Name" with "Sarah Wibbledon"}
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

Then /^the signature count (?:stays at|goes up to) (\d+)$/ do |number|
  signatures = @petition.signatures
  expect(signatures.count).to eq number
end

