Then(/^I should receive a sponsor support notification email$/) do
  step %{"charlie.the.creator@example.com" should receive an email with subject "supported your petition"}
end

Then(/^I should not receive a sponsor support notification email$/) do
  step %{"charlie.the.creator@example.com" should receive no email with subject "supported your petition"}
end

Then(/^I should receive a sponsor threshold notification email$/) do
  step %{"charlie.the.creator@example.com" should receive an email with subject "We’re checking your petition"}
end

Then(/^I should not receive a sponsor threshold notification email$/) do
  step %{"charlie.the.creator@example.com" should receive no email with subject "We’re checking your petition"}
end

Then(/^the sponsor support notification email should include the countdown to the threshold$/) do
  signed = @sponsor_petition.sponsors.validated.count
  threshold = Site.threshold_for_moderation
  email = open_last_email_for("charlie.the.creator@example.com")
  expect(email.subject).to match /supported your petition/
  mail_body = email.default_part_body.to_s
  expect(mail_body).to include "You have #{signed} #{'supporter'.pluralize(signed)} so far"
end

Then(/^the sponsor threshold notification email should tell me about my petition going into moderation$/) do
  threshold = Site.threshold_for_moderation

  email = open_last_email_for("charlie.the.creator@example.com")
  expect(email.subject).to match /We’re checking your petition/
  mail_body = email.default_part_body.to_s
  expect(mail_body).to include "#{threshold} people have supported your petition"
  expect(mail_body).not_to match /support from \d+ of your nominated sponsors/
end
