When(/^I stop typing for (\d+)ms$/) do |ms|
  page.find('//body').click
  sleep(ms.to_f / 1000)
end

Then(/^I should wait for the petition to save$/) do
  Timeout.timeout(Capybara.default_max_wait_time) do
    loop until finished_ajax_requests?
  end
end

Then(/^I should reload$/) do
  visit current_url
end

Then(/^the notes field should contain "([^"]*)"$/) do |expected_text|
  expect(page.find("//textarea").value).to eq expected_text
end

def finished_ajax_requests?
  !page.has_css?('body.ajax-active')
end
