Given /^I am logged in as a sysadmin$/ do
  @user = FactoryBot.create(:sysadmin_user)
  step "the admin user is logged in"
end

Given /^I am logged in as a moderator$/ do
  @user = FactoryBot.create(:moderator_user)
  step "the admin user is logged in"
end

Given(/^I log out and login back in as a sysadmin$/) do
  @user = FactoryBot.create(:sysadmin_user)

  steps %q[
    the admin user is logged out
    the admin user is logged in
  ]
end

Given(/^I log out and login back in as a moderator$/) do
  @user = FactoryBot.create(:moderator_user)

  steps %q[
    the admin user is logged out
    the admin user is logged in
  ]
end

Given /^I am logged in as a moderator named "([^\"]*)"$/ do |name|
  first_name, last_name = name.split
  @user = FactoryBot.create(:moderator_user, first_name: first_name, last_name: last_name)
  step "the admin user is logged in"
end

Given /^I am logged in as a moderator named "([^\"]*)" with the password "([^\"]*)"$/ do |name, password|
  first_name, last_name = name.split
  @user = FactoryBot.create(:moderator_user, first_name: first_name, last_name: last_name, :password => password, :password_confirmation => password)
  step "the admin user is logged in"
end

Given /^I am logged in as a sysadmin named "([^\"]*)"$/ do |name|
  first_name, last_name = name.split
  @user = FactoryBot.create(:sysadmin_user, first_name: first_name, last_name: last_name)
  step "the admin user is logged in"
end

Given /^I am logged in as a sysadmin with the email "([^\"]*)", first_name "([^\"]*)", last_name "([^\"]*)"$/ do |email, first_name, last_name|
  @user = FactoryBot.create(:sysadmin_user, :email => email, :first_name => first_name, :last_name => last_name)
  step "the admin user is logged in"
end

Given /^the admin user is logged in$/ do
  visit admin_login_url
  click_button("Login with developer strategy")
  fill_in("Email", :with => @user.email)
  click_button("Sign In")
end

Given /^the admin user is logged out$/ do
  visit admin_logout_url
end
