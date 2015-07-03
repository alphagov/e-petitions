Given /^I am logged in as a sysadmin$/ do
  @user = FactoryGirl.create(:sysadmin_user)
  step "the admin user is logged in"
end

Given /^I am logged in as a moderator$/ do
  @user = FactoryGirl.create(:moderator_user)
  step "the admin user is logged in"
end

Given /^I am logged in as a moderator with the password "([^\"]*)"$/ do |password|
  @user = FactoryGirl.create(:moderator_user, :password => password, :password_confirmation => password)
  step "the admin user is logged in"
end

Given /^I am logged in as a moderator named "([^\"]*)" with the password "([^\"]*)"$/ do |name, password|
  first_name, last_name = name.split
  @user = FactoryGirl.create(:moderator_user, first_name: first_name, last_name: last_name, :password => password, :password_confirmation => password)
  step "the admin user is logged in"
end

Given /^I am logged in as a sysadmin with the email "([^\"]*)", first_name "([^\"]*)", last_name "([^\"]*)"$/ do |email, first_name, last_name|
  @user = FactoryGirl.create(:sysadmin_user, :email => email, :first_name => first_name, :last_name => last_name)
  step "the admin user is logged in"
end

Given /^the admin user is logged in$/ do
  visit admin_login_url
  fill_in("Email", :with => @user.email)
  fill_in("Password", :with => "Letmein1!")
  click_button("Log in")
end
