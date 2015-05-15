When /^I look at the next petition on my list$/ do
  @petition = FactoryGirl.create(:sponsored_petition, :title => "Petition 1", :description => "description")
  visit edit_admin_petition_path(@petition)
end

When /^I re\-assign it to a different department$/ do
  FactoryGirl.create(:department, :name => "Another department")
  visit edit_admin_petition_path(@petition)
  select "Another department"
  click_button "Re-assign"
end

Then /^the petition should be assigned to that department$/ do
  expect(@petition.reload.department.name).to eq "Another department"
end

When /^I reject the petition with a reason code "([^"]*)"$/ do |reason_code|
  select reason_code, :from => :petition_rejection_code
  click_button "Reject"
end

When /^I change the rejection status of the petition with a reason code "([^"]*)"$/ do |reason_code|
  select reason_code, :from => :petition_rejection_code
  click_button "Change rejection status"
end

When /^I reject the petition with a reason code "([^"]*)" and some explanatory text$/ do |reason_code|
  select reason_code, :from => :petition_rejection_code
  fill_in :petition_rejection_text, :with => "See guidelines at http://direct.gov.uk"
  click_button "Reject"
end

Then /^the petition is not available for signing$/ do
  visit petition_path(@petition)
  expect(page).not_to have_css("a", :text => "Sign")
end

When /^I publish the petition$/ do
  click_button "Publish this petition"
end

Then /^the petition is still available for searching or viewing$/ do
  step %{I view the rejected petitions for the "#{@petition.department.name}"}
  step %{I should see the petition "#{@petition.title}"}
  step %{I view the petition}
  step %{I should see the petition details}
end

Then /^the explanation is displayed on the petition for viewing by the public$/ do
  step %{I view the petition}
  step %{I should see the reason for rejection}
end

Then /^the petition is not available for searching or viewing$/ do
  step %{I view the rejected petitions for the "#{@petition.department.name}"}
  step %{I should not see the petition "#{@petition.title}"}
end

Then /^the petition will still show up in the back\-end reporting$/ do
  visit admin_petitions_path
  step %{I should see the petition "#{@petition.title}"}
end

Then /^the petition should be visible on the site for signing$/ do
  visit petition_path(@petition)
  expect(page).to have_css("a", :text => "Sign")
end

Then /^the creator should recieve a notification email$/ do
  steps %Q(
    Then "#{@petition.creator_signature.email}" should receive an email
    When they open the email
    Then they should see "published" in the email body
  )
end

Then /^the creator should recieve a (libel\/profanity )?rejection notification email$/ do |petition_is_libellous|
  @petition.reload
  steps %Q(
    Then "#{@petition.creator_signature.email}" should receive an email
    When they open the email
    Then they should see "hasn't been accepted" in the email body
    And they should see "#{@petition.rejection_description.gsub(/<.*?>/,' ').split.last}" in the email body
  )
  if petition_is_libellous
    step %{they should not see "#{petition_url(@petition)}" in the email body}
  else
    step %{they should see "#{petition_url(@petition)}" in the email body}
  end
end

When /^I view all petitions$/ do
  click_link "All petitions"
end

When /^I filter the list to show "([^"]*)" petitions$/ do |option|
  select option
  click_button "Go"
end

Then /^I should not see any "([^"]*)" petitions$/ do |state|
  expect(page).to have_no_css("td.state", :text => state)
end

Then /^I see relevant reason descriptions when I browse different reason codes$/ do
  select "Duplicate of an existing e-petition", :from => :petition_rejection_code
  expect(page).to have_content "already an e-petition"
  select "Confidential, libellous, false or defamatory statements", :from => :petition_rejection_code
  expect(page).to have_content "injunction or court order"
end
