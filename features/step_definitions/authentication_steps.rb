Given /^I am logged in as a sysadmin$/ do
  @user = FactoryGirl.create(:sysadmin_user)
  step "the admin user is logged in"
end

Given /^I am logged in as a threshold user$/ do
  @user = FactoryGirl.create(:threshold_user)
  step "the admin user is logged in"
end

Given /^I am logged in as an admin with the password "([^\"]*)"$/ do |password|
  @user = FactoryGirl.create(:admin_user, :password => password, :password_confirmation => password)
  step "the admin user is logged in"
end


Given /^I am logged in as a sysadmin with the email "([^\"]*)", first_name "([^\"]*)", last_name "([^\"]*)"$/ do |email, first_name, last_name|
  @user = FactoryGirl.create(:sysadmin_user, :email => email, :first_name => first_name, :last_name => last_name)
  step "the admin user is logged in"
end

Given /^I am logged in as an admin$/ do
  @user = FactoryGirl.create(:admin_user)
  @user.departments <<  FactoryGirl.create(:department)
  step "the admin user is logged in"
end

Given /^I am logged in as a moderator for the "([^"]*)"$/ do |department_name|
  step "I am logged in as an admin"
  @user.departments << Department.find_by(name: department_name)
end

Given /^the admin user is logged in$/ do
  visit admin_login_path
  fill_in("Email", :with => @user.email)
  fill_in("Password", :with => "Letmein1!")
  click_button("Log in")
end
