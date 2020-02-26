When(/^I look at the next petition on my list$/) do
  @petition = FactoryBot.create(:sponsored_petition, :with_additional_details, :action => "Petition 1")
  visit admin_petition_url(@petition)
end

When(/^I visit a sponsored petition with action: "([^"]*)", that has background: "([^"]*)" and additional details: "([^"]*)"$/) do |petition_action, background, additional_details|
  @sponsored_petition = FactoryBot.create(:sponsored_petition, action: petition_action, background: background, additional_details: additional_details)
  visit admin_petition_url(@sponsored_petition)
end

When(/^I reject the petition with a reason code "([^"]*)"$/) do |reason_code|
  choose "Reject"
  select reason_code, :from => :petition_rejection_code
  click_button "Email petition creator"
end

When(/^I change the rejection status of the petition with a reason code "([^"]*)"$/) do |reason_code|
  click_on 'Change rejection reason'
  select reason_code, :from => :petition_rejection_code
  click_button "Email petition creator"
end

When(/^I reject the petition with a reason code "([^"]*)" and some explanatory text$/) do |reason_code|
  choose "Reject"
  select reason_code, :from => :petition_rejection_code
  fill_in :petition_rejection_details_en, :with => "See guidelines at http://direct.gov.uk"
  fill_in :petition_rejection_details_cy, :with => "Gweler y canllawiau yn http://direct.gov.uk"
  click_button "Email petition creator"
end

Then /^the petition is not available for signing$/ do
  visit petition_url(@petition)
  expect(page).not_to have_css("a", :text => "Sign")
end

When(/^I publish the petition$/) do
  choose "Approve"
  click_button "Email petition creator"
end

When(/^I flag the petition$/) do
  choose "Flag"
  click_button "Save without emailing"
end

Then /^the petition is still available for searching or viewing$/ do
  step %{I search for "Rejected petitions" with "#{@petition.action}"}
  step %{I should see the petition "#{@petition.action}"}
  step %{I view the petition}
  step %{I should see the petition details}
end

Then /^the explanation is displayed on the petition for viewing by the public$/ do
  step %{I view the petition}
  step %{I should see the reason for rejection}
end

Then /^the petition is not available for searching or viewing$/ do
  step %{I search for "Rejected petitions" with "#{@petition.action}"}
  step %{I should not see the petition "#{@petition.action}"}
end

Then /^the petition will still show up in the back\-end reporting$/ do
  visit admin_petitions_url
  step %{I should see the petition "#{@petition.action}"}
end

Then /^the petition should be visible on the site for signing$/ do
  visit petition_url(@petition)
  expect(page).to have_css("a", :text => "Sign")
end

Then(/^the petition can no longer be flagged$/) do
  expect(page).to have_no_field('Flag', visible: false)
end

Then(/^the creator should receive a notification email$/) do
  steps %Q(
    Then "#{@petition.creator.email}" should receive an email
    When they open the email
    Then they should see "published" in the email body
    And they should see /We published your petition/ in the email subject
  )
end

Then(/^the creator should not receive a notification email$/) do
  step %{"#{@petition.creator.email}" should receive no email with subject "We published your petition"}
end

Then(/^the creator should receive a (libel\/profanity )?rejection notification email$/) do |petition_is_libellous|
  @petition.reload
  steps %Q(
    Then "#{@petition.creator.email}" should receive an email
    When they open the email
    Then they should see "We rejected the petition you created" in the email body
    And they should see "#{I18n.t(@petition.rejection.code, scope: :"rejections.descriptions")}" in the email body
    And they should see /We rejected your petition/ in the email subject
  )
  if petition_is_libellous
    step %{they should not see "#{petition_url(@petition)}" in the email body}
  else
    step %{they should see "#{petition_url(@petition)}" in the email body}
  end
end

Then(/^the creator should not receive a rejection notification email$/) do
  step %{"#{@petition.creator.email}" should receive no email with subject "We rejected your petition"}
end

When(/^I view all petitions$/) do
  click_on 'Petitions Admin'
  find("//a", :text => /^All Petitions/).click
end

Then /^I should see the petition "([^"]*)"$/ do |petition_action|
  expect(page).to have_link(petition_action)
end

Then /^I should not see the petition "([^"]*)"$/ do |petition_action|
  expect(page).not_to have_link(petition_action)
end

When(/^I filter the list to show "([^"]*)" petitions$/) do |option|
  select option
end

Then /^I should not see any "([^"]*)" petitions$/ do |state|
  expect(page).to have_no_css("td.state", :text => state)
end

Then /^I see relevant reason descriptions when I browse different reason codes$/ do
  choose "Reject"
  select "Duplicate petition", :from => :petition_rejection_code
  expect(page).to have_content "already a petition"
  select "Confidential, libellous, false, defamatory or references a court case", :from => :petition_rejection_code
  expect(page).to have_content I18n.t(:"rejections.descriptions.libellous")
end

Given(/^a moderator updates the petition activity$/) do
  steps %Q(
    Given I am logged in as a moderator
    And I view all petitions
    And I follow "#{@petition.action}"
    And I follow "Other Senedd business"
    And I fill in "Subject" with "Get ready"
    And I fill in "Body" with "Senedd here it comes"
    And I press "Email #{NumberHelpers.number_with_delimiter(@petition.signature_count)} petitioners"
  )
end

Given /^the petition is translated$/ do
  (@sponsored_petition || @petition).tap do |petition|
    if petition.english?
      petition.update!(
        action_cy: petition.action_en,
        background_cy: petition.background_en,
        additional_details_cy: petition.additional_details_en
      )
    else
      petition.update!(
        action_en: petition.action_cy,
        background_en: petition.background_cy,
        additional_details_en: petition.additional_details_cy
      )
    end
  end
end

Given /^the petition "([^"]*)" is translated$/ do |action|
  (Petition.find_by!(action: action)).tap do |petition|
    if petition.english?
      petition.update!(
        action_cy: petition.action_en,
        background_cy: petition.background_en,
        additional_details_cy: petition.additional_details_en
      )
    else
      petition.update!(
        action_en: petition.action_cy,
        background_en: petition.background_cy,
        additional_details_en: petition.additional_details_cy
      )
    end
  end
end

When /^I revisit the petition$/ do
  visit admin_petition_url(@petition)
end

Then /^it can still be approved$/ do
  expect(page).to have_field('Approve', visible: false)
end

Then /^it can still be rejected$/ do
  expect(page).to have_field('Reject', visible: false)
end

Then /^it can be restored to a sponsored state$/ do
  choose "Unflag"
  click_button "Save without emailing"
  expect(page).to have_content("Petition has been successfully updated")
  expect(page).to have_content("Status Sponsored")
end

Then /^the petition should still be unmoderated$/ do
  expect(@petition).not_to be_visible
end
