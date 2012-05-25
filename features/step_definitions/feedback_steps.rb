Then /^I should be able to submit feedback$/ do

  @feedback = Feedback.new(:name => "Joe Public", :email => "foo@example.com",
    :comment => "I can't submit a petition for some reason", :petition_link_or_title => 'link')

  fill_in "feedback[name]", :with => @feedback.name
  fill_in "feedback[email]", :with => @feedback.email
  fill_in "feedback[email_confirmation]", :with => @feedback.email
  check "feedback_response_required"
  fill_in "feedback[petition_link_or_title]", :with => @feedback.petition_link_or_title
  fill_in "feedback[comment]", :with => @feedback.comment

  click_button("Send feedback")
  page.should have_content("Thank")
end

Then /^the site owners should be notified$/ do
  steps %Q(
    Then "#{FeedbackMailer::TO}" should receive an email
    When they open the email
    Then they should see "#{@feedback.name}" in the email body
    Then they should see "#{@feedback.email}" in the email body
    Then they should see "#{@feedback.petition_link_or_title}" in the email body
    Then they should see "#{@feedback.comment}" in the email body
    Then they should see /Response required.* YES/ in the email body
  )
end

Then /^I cannot submit feedback without filling in the required fields$/ do
  click_button("Send feedback")
  page.should have_content("must be completed")
  step %{"#{FeedbackMailer::TO}" should have no emails}
end
