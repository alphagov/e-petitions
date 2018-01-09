Then /^(?:I|they|"([^"]*?)") ha(?:ve|s) read all (?:their|my) email$/ do |address|
  unread_emails_for(address).each do |unread_email|
    read_emails_for(address) << unread_email
  end
end

Then (/^(\d+) emails? ha(?:ve|s) been sent with subject (.*?) and body (.*?)/) do |number, subject, body|
  expect(ActionMailer::Base.deliveries.length).to eq number

  ActionMail::Base.deliveries.each do |mail|
    expect(mail.subject).to eq subject
    expect(mail.body).to eq body
  end
end
