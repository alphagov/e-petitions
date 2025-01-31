Then /^the markup should be valid$/ do
  document = Nokogiri::HTML5(page.source)
  expect(document.errors).to be_empty
end
