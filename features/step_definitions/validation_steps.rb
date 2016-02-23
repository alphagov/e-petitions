Then /^the markup should be valid$/ do
  document = Nokogiri::XML(page.source)
  expect(document.errors).to be_empty
end
