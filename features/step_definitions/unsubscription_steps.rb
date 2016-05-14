Then /^Suzie should have received a petition response email with an unsubscription link$/ do
  expect(unread_emails_for(@suzies_signature.email).size).to eq 1
  open_email(@suzies_signature.email)
  unsubscription_url = unsubscribe_signature_url(@suzies_signature, token: @suzies_signature.unsubscribe_token)
  expect(current_email.default_part_body.to_s).to include(unsubscription_url)
end

When(/^Suzie follows the unsubscription link$/) do
  open_email(@suzies_signature.email)
  visit_in_email("unsubscribe")
end

Then(/^Suzie should see a confirmation page stating that her subscription was successful$/) do
  expect(page).to have_content("Successfully unsubscribed")
end

Then(/^Suzie should no longer receive any emails regarding this petition$/) do
  @suzies_signature.reload
  expect(@suzies_signature.notify_by_email).to be_falsey
end
