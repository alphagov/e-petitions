Then(/^I should be able to submit feedback$/) do
  page.driver.browser.header('User-Agent', 'Chrome')

  @feedback = Feedback.new(:name => "Joe Public", :email => "foo@example.com",
    :comment => "I can't submit a petition for some reason", :petition_link_or_title => 'link')

  fill_in "feedback[email]", :with => @feedback.email
  fill_in "feedback[petition_link_or_title]", :with => @feedback.petition_link_or_title
  fill_in "feedback[comment]", :with => @feedback.comment

  click_button("Send feedback")
  expect(page).to have_content("Thank")
end

Then(/^the site owners should be notified$/) do
  steps %Q(
    Then "#{Mail::Address.new(Site.feedback_email).address}" should receive an email
    When they open the email
    Then they should see "#{@feedback.email}" in the email body
    Then they should see "#{@feedback.petition_link_or_title}" in the email body
    Then they should see "#{@feedback.comment}" in the email body
    Then they should see "Browser: Chrome" in the email body
  )
end

Then(/^I cannot submit feedback without filling in the required fields$/) do
  click_button("Send feedback")
  expect(page).to have_content("must be completed")
  step %{"#{Mail::Address.new(Site.feedback_email).address}" should have no emails}
end
