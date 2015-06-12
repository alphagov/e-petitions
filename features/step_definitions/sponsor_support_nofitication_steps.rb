Then(/^I should receive a sponsor support notification email$/) do
  steps %Q{
    Then "charlie.the.creator@example.com" should receive an email with subject "Parliament Petitions - #{@sponsor_petition.title} has received support from a sponsor"
  }
end

Then(/^I should not receive a sponsor support notification email$/) do
  steps %Q{
    Then "charlie.the.creator@example.com" should receive no email with subject "Parliament Petitions - #{@sponsor_petition.title} has received support from a sponsor"
  }
end

Then(/^the sponsor support notification email should include the countdown to the threshold$/) do
  signed = @sponsor_petition.sponsors.where.not(signature_id: nil).count
  threshold = Site.threshold_for_moderation
  email = open_last_email_for("charlie.the.creator@example.com")
  expect(email.subject).to eq "Parliament Petitions - #{@sponsor_petition.title} has received support from a sponsor"
  mail_body = email.default_part_body.to_s
  expect(mail_body).to include "support from #{signed} of your nominated sponsors"
  expect(mail_body).to include "still need #{threshold - signed} more before"
end

Then(/^the sponsor support notification email should tell me about my e\-petition going into moderation$/) do
  threshold = Site.threshold_for_moderation

  email = open_last_email_for("charlie.the.creator@example.com")
  expect(email.subject).to eq "Parliament Petitions - #{@sponsor_petition.title} has received support from a sponsor"
  mail_body = email.default_part_body.to_s
  expect(mail_body).to include "Congratulations, you have support from #{threshold} sponsors, enough to send your petition for moderation review"
  expect(mail_body).not_to match /support from \d+ of your nominated sponsors/
  expect(mail_body).not_to match /still need \d+ more before/
end
