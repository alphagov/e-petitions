When /^I ask for my confirmation email to be resent$/ do
  visit petition_path(@petition)
  click_link "Not received your confirmation email?"
  fill_in "confirmation_email", :with => 'suzie@example.com'
  click_button "Resend"
end

Then /^I should see an ambiguous message telling me I'll receive an email$/ do
  page.should have_content("If you signed")
end

Then /^I should receive an email telling me that I've not signed this petition$/ do
  open_email("suzie@example.com", :with_text => "This email address has not been used to sign this e-petition")
end

Then /^I should receive an email with my confirmation link$/ do
  open_email("suzie@example.com", :with_text => "confirm your email address")
end

Given /^I have already signed the petition "([^"]*)"$/ do |petition_title|
  petition = Petition.find_by_title(petition_title)
  Factory(:validated_signature, :petition => petition, :email => 'suzie@example.com')
end

Then /^I should receive an email telling me (?:I|we)'ve already confirmed$/ do
  open_email("suzie@example.com", :with_text => "already been added")
end

Given /^Sam has signed the petition "([^"]*)" but not confirmed by email$/ do |petition_title|
  petition = Petition.find_by_title(petition_title)
  Factory(:pending_signature, :petition => petition, :email => 'suzie@example.com')
end

Given /^Sam has signed the petition "([^"]*)"$/ do |petition_title|
  petition = Petition.find_by_title(petition_title)
  Factory(:validated_signature, :petition => petition, :email => 'suzie@example.com')
end

Then /^I should receive an email with two confirmation links$/ do
  signatures = Signature.find_all_by_email("suzie@example.com")
  signatures.count.should == 2
  open_email("suzie@example.com")
  current_email.default_part_body.to_s.should match(signatures.first.perishable_token)
  current_email.default_part_body.to_s.should match(signatures.second.perishable_token)
end

Then /^I should receive an email telling me one has signed, with the second confirmation link$/ do
  signatures = Signature.find_all_by_email("suzie@example.com")
  signatures.count.should == 2
  open_email("suzie@example.com", :with_text => 'already been confirmed')
  current_email.default_part_body.to_s.should match(signatures.second.perishable_token)
end

When /^I ask for my confirmation email to be resent with an invalid address$/ do
  visit petition_path(@petition)
  click_link "Not received your confirmation email?"
  fill_in "confirmation_email", :with => 'garbage email address'
  click_button "Resend"
end

Then /^we don't send the resend email as the address is invalid$/ do
  all_emails.count.should == 0
end
