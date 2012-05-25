Then /^I should see a recaptcha challenge$/ do
  xpath = "//script[contains(@src, 'https://image.captchas.net/')]"
  page.should have_xpath(xpath)
end

When /^I fill in a valid captcha$/ do
  captcha_string = find(:css, "#captcha_string").value
  user_input = Captcha.get_captcha_text captcha_string
  fill_in "captcha_response_field", :with => user_input
end

When /^I fill in an invalid captcha$/ do
  fill_in "captcha_response_field", :with => ""
end