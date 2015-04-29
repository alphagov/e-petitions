def strip_onpaste_element_used_to_disable_pasting_emails(body)
  body.gsub!(/(onpaste=\".*?\")/, '')
end

Then /^the markup should be valid$/ do
  # If we could uniqueify each page that would speed up this test considerably. To do so we
  # need to make ids consistent and strip out the code after '?' on linked files
  body = page.source.dup

  body.gsub!(/(href=".*?)\?\d+/, '\1')
  body.gsub!(/(src=".*?)\?\d+/, '\1')
  strip_onpaste_element_used_to_disable_pasting_emails(body)

  expect(body).to be_valid_markup
end

Then /^the feed should be valid$/ do
  expect(page.body).to be_valid_feed
end

Then /^the css files should be valid$/ do
  stylesheets = page.all("//head/link[@type='text/css']").map { |c| c[:href] }

  # Not validating the external stylesheet files
  stylesheets.reject! do |s|
    s =~ /^http/
  end

  stylesheets.each do |stylesheet|
    css = File.read(File.join(Rails.root, 'public', /^[^\?]*/.match(stylesheet)[0]))
    expect(css).to be_valid_css
  end
end
