Given /^I am logged in as a sysadmin$/ do
  @user = FactoryBot.build(:sysadmin_sso_user)
  step "the admin user is logged in"
end

Given /^I am logged in as a moderator$/ do
  @user = FactoryBot.build(:moderator_sso_user)
  step "the admin user is logged in"
end

Given(/^I log out and login back in as a sysadmin$/) do
  @user = FactoryBot.build(:sysadmin_sso_user)
  steps "the admin user is logged in"
end

Given(/^I log out and login back in as a moderator$/) do
  @user = FactoryBot.build(:moderator_sso_user)
  steps "the admin user is logged in"
end

Given /^I am logged in as a moderator named "([^\"]*)"$/ do |name|
  first_name, last_name = name.split
  @user = FactoryBot.build(:moderator_sso_user, first_name: first_name, last_name: last_name)
  step "the admin user is logged in"
end

Given /^I am logged in as a sysadmin named "([^\"]*)"$/ do |name|
  first_name, last_name = name.split
  @user = FactoryBot.build(:sysadmin_sso_user, first_name: first_name, last_name: last_name)
  step "the admin user is logged in"
end

Given /^I am logged in as a sysadmin with the email "([^\"]*)", first_name "([^\"]*)", last_name "([^\"]*)"$/ do |email, first_name, last_name|
  @user = FactoryBot.build(:sysadmin_sso_user, email: email, first_name: first_name, last_name: last_name)
  step "the admin user is logged in"
end

Given /^the admin user is logged in$/ do
  visit admin_logout_url

  expect(page).to have_current_path("/admin/login")
  expect(page).to have_content("You have been logged out")

  OmniAuth.config.mock_auth[:example] = @user

  visit admin_login_url
  fill_in("Email", with: @user.uid)
  click_button("Sign in")

  if Capybara.current_driver == :chrome_headless
    expect(page).to have_current_path("/admin")
  else
    expect(page).to have_current_path("/admin/auth/example/callback")
  end

  expect(page).to have_content("Logged in successfully")
end

Given /^a sysadmin SSO user exists$/ do
  OmniAuth.config.mock_auth[:example] = FactoryBot.build(:sysadmin_sso_user)
end

Given /^a moderator SSO user exists$/ do
  OmniAuth.config.mock_auth[:example] = FactoryBot.build(:moderator_sso_user)
end

Given /^a reviewer SSO user exists$/ do
  OmniAuth.config.mock_auth[:example] = FactoryBot.build(:reviewer_sso_user)
end

Given(/^a valid SSO login with no roles$/) do
  OmniAuth.config.mock_auth[:example] = FactoryBot.build(:norole_sso_user)
end

Given /^an invalid SSO login$/ do
  OmniAuth.config.mock_auth[:example] = :invalid_credentials
end
