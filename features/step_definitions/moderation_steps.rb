When /^I look at the next petition on my list$/ do
  @petition = Factory(:validated_petition, :title => "Petition 1", :description => "description", :department => AdminUser.first.departments.first)
  visit edit_admin_petition_path(@petition)
end

When /^I re\-assign it to a different department$/ do
  Factory(:department, :name => "Another department")
  visit edit_admin_petition_path(@petition)
  select "Another department"
  click_button "Re-assign"
end

Then /^the petition should be assigned to that department$/ do
  @petition.reload.department.name.should == "Another department"
end

When /^I reject the petition with a reason code "([^"]*)"$/ do |reason_code|
  select reason_code, :from => :petition_rejection_reason
  click_button "Reject"
end

When /^I change the rejection status of the petition with a reason code "([^"]*)"$/ do |reason_code|
  select reason_code, :from => :petition_rejection_reason
  click_button "Change rejection status"
end

When /^I reject the petition with a reason code "([^"]*)" and some explanatory text$/ do |reason_code|
  select reason_code, :from => :petition_rejection_reason
  fill_in :rejection_text, :with => "See guidelines at http://direct.gov.uk"
  click_button "Reject"
end

Then /^the petition is not available for signing$/ do
  visit petition_path(@petition)
  page.should_not have_css("a", :text => "Sign")
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
  # ensure we are in the right department to see the petition
  #AdminUser.first.departments << @petition.department
  visit admin_petitions_path
  step %{I should see the petition "#{@petition.title}"}
end

Then /^the petition should be visible on the site for signing$/ do
  visit petition_path(@petition)
  page.should have_css("a", :text => "Sign")
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
  page.should have_no_css("td.state", :text => state)
end

Then /^I see relevant reason descriptions when I browse different reason codes$/ do
  reason = RejectionReason.find_by_code("duplicate")
  page.should have_content "already an e-petition"
  reason = RejectionReason.find_by_code("libellous")
  page.should have_content "injunction or court order"
end
