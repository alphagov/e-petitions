When(/^I leave the form alone for (\d+)ms$/) do |ms|
  page.find('//body').click
  sleep(ms.to_f / 1000)
end

Then(/^I wait for the petition tags to save$/) do
  Timeout.timeout(Capybara.default_max_wait_time) do
    loop until finished_ajax_requests?
  end
end

def finished_ajax_requests?
  !page.find('//body')[:class].include?('ajax-active')
end
