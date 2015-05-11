Then /^(?:I|they|"([^"]*?)") ha(?:ve|s) read all (?:their|my) email$/ do |address|
  unread_emails_for(address).each do |unread_email|
    read_emails_for(address) << unread_email
  end
end
