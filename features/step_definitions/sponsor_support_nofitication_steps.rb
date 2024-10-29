Then(/^I should receive a sponsor support notification email$/) do
  step %{"charlie.the.creator@example.com" should receive an email with subject "Someone supported: “#{@sponsor_petition.action}”"}
end

Then(/^I should not receive a sponsor support notification email$/) do
  step %{"charlie.the.creator@example.com" should receive no email with subject "Someone supported: “#{@sponsor_petition.action}”"}
end

Then(/^I should receive a sponsor threshold notification email$/) do
  step %{"charlie.the.creator@example.com" should receive an email with subject "Your petition has five supporters: “#{@sponsor_petition.action}”"}
end

Then(/^I should not receive a sponsor threshold notification email$/) do
  step %{"charlie.the.creator@example.com" should receive no email with subject "Your petition has five supporters: “#{@sponsor_petition.action}”"}
end

Then(/^the sponsor support notification email should include the countdown to the threshold$/) do
  signed = @sponsor_petition.sponsors.validated.count
  threshold = Site.threshold_for_moderation
  email = open_last_email_for("charlie.the.creator@example.com")
  expect(email.subject).to match /Someone supported/
  mail_body = email.default_part_body.to_s
  expect(mail_body).to include "You have #{signed} #{'supporter'.pluralize(signed)} so far"
end

Then(/^the sponsor threshold notification email should tell me about my petition going into moderation$/) do
  threshold = Site.threshold_for_moderation

  email = open_last_email_for("charlie.the.creator@example.com")
  expect(email.subject).to match /Your petition has five supporters/
  mail_body = email.default_part_body.to_s
  expect(mail_body).to include "#{threshold} people have supported your petition"
end
