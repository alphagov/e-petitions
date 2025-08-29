Then(/^I should see the cookie message$/) do
  expect(page).to have_text('We use cookies to make this service simpler')
end

Then(/^I should not see the cookie message$/) do
  expect(page).not_to have_text('We use cookies to make this service simpler')
end

Given(/^the site is disabled$/) do
  Site.update! enabled: false
end

Given(/^the site is protected$/) do
  Site.update! protected: true, username: "username", password: "password"
end

Given(/^signature counting is handled by an external process$/) do
  ENV["INLINE_UPDATES"] = "false"
end

Given(/^Parliament is dissolving$/) do
  Parliament.update! dissolution_at: 2.weeks.from_now,
    dissolution_heading: "Parliament is dissolving",
    dissolution_message: "This means all petitions will close in 2 weeks",
    dissolution_faq_url: "https://parliament.example.com/parliament-is-closing",
    show_dissolution_notification: true
end

Given(/^Parliament is dissolved$/) do
  Parliament.update! dissolution_at: 1.day.ago,
    dissolution_heading: "Parliament is dissolving",
    dissolution_message: "This means all petitions will close in 2 weeks",
    dissolved_heading: "Parliament has been dissolved",
    dissolved_message: "All petitions have been closed",
    dissolution_faq_url: "https://parliament.example.com/parliament-is-closing",
    show_dissolution_notification: true
end

Given(/^Parliament is pending$/) do
  Parliament.update!(opening_at: 1.month.from_now)
end

Given('{int} months has passed since parliament opened') do |number|
  Parliament.update!(opening_at: number.months.ago)
end

Given('{int} months has passed since the previous parliament dissolved') do |number|
  Parliament.instance.previous.update!(
    dissolution_at: number.months.ago,
    dissolution_heading: "Parliament is dissolving",
    dissolution_message: "This means all petitions will close in 2 weeks",
    dissolved_heading: "Parliament has been dissolved",
    dissolved_message: "All petitions have been closed"
  )
end

Given(/^the request is not local$/) do
  page.driver.options[:headers] = { "REMOTE_ADDR" => "192.168.1.128" }
end

Then(/^I am asked for a username and password$/) do
  expect(page.status_code).to eq 401
end

Then(/^I will see a 404 error page$/) do
  expect(page.status_code).to eq 404
end

Then(/^I will see a 503 error page$/) do
  expect(page.status_code).to eq 503
end

Then(/^I wait for (\d+) ((?:day|week|month|year|)s?)$/) do |duration, period|
  travel_to(Time.current + (duration.to_i.send(period) + 1.second))
end

When(/^I click the shared link$/) do
  expect(@shared_link).not_to be_blank
  visit @shared_link
end

Then(/^I should not index the page$/) do
  expect(page).to have_css('meta[name=robots]', visible: false)
end

Then(/^I should index the page$/) do
  expect(page).not_to have_css('meta[name=robots]', visible: false)
end

Then(/^I should see the Parliament dissolution warning message$/) do
  within(:css, ".notification") do
    expect(page).to have_content "Parliament is dissolving"
    expect(page).to have_content "This means all petitions will close in 2 weeks"
    expect(page).to have_link "Petitions Committee website", href: "https://parliament.example.com/parliament-is-closing"
  end
end

Then(/^I should see the Parliament dissolved warning message$/) do
  within(:css, ".notification") do
    expect(page).to have_content "Parliament has been dissolved"
    expect(page).to have_content "All petitions have been closed"
    expect(page).to have_link "Petitions Committee website", href: "https://parliament.example.com/parliament-is-closing"
  end
end

When(/^I accept the alert$/) do
  page.driver.browser.switch_to.alert.accept
end

Then('the page should have the title {string}') do |string|
  expect(page).to have_title(string)
end

Then('the page should have the meta description {string}') do |string|
  expect(page).to have_meta_tag('description', string)
end
