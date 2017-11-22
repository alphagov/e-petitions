Then /^the markup should be valid$/ do
  tags = %w[header nav main details summary section footer]
  pattern = /\A\d+:\d+: ERROR: Tag (?:#{tags.join('|')}) invalid\z/
  filter = -> (error){ error.message =~ pattern }

  document = Nokogiri::HTML(page.source)
  expect(document.errors.reject(&filter)).to be_empty
end
