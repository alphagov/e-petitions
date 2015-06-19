Then /^the response to "([^"]*)" should be publicly viewable on the petition page$/ do |petition_action|
  petition = Petition.find_by(action: petition_action)
  visit petition_path(petition)
  expect(page).to have_content(petition.response)
end

Then /^the response summary to "([^"]*)" should be publicly viewable on the petition page$/ do |petition_action|
  petition = Petition.find_by(action: petition_action)
  visit petition_path(petition)
  expect(page).to have_content(petition.response_summary)
end

Then(/^the petition signatories of "([^"]*)" should not receive a response notification email$/) do |petition_action|
  petition = Petition.find_by(action: petition_action)
  petition.signatures.validated.each do |signatory|
    step %{"#{signatory.email}" should receive no email}
  end
end

Then(/^the petition signatories of "([^"]*)" should receive a response notification email$/) do |petition_action|
  petition = Petition.find_by(action: petition_action)
  petition.signatures.notify_by_email.validated.each do |signatory|
    steps %{
      Then "#{signatory.email}" should receive an email
      When they open the email
      Then they should see "a response has been made to it." in the email body
      And they should see "#{petition.response}" in the email body
      When they follow "View the response to the petition" in the email
      Then I should be on the petition page for "#{petition.action}"
    }
  end
end
