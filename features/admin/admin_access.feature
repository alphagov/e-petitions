Feature: Restricted access to the admin console
  In order to prevent unauthorised people accessing the admin area
  I can only access the admin area if I have logged on and my password does not need resetting

  Scenario: Accessing admin when not logged in
    When I go to the Admin home page
    Then I should be on the admin login page
    And I should be connected to the server via an ssl connection
    And the markup should be valid
    
  Scenario: Login and logout to the admin console as a sysadmin
    Given a sysadmin user exists with email: "admin@example.com", password: "Letmein1!", password_confirmation: "Letmein1!"
    When I go to the admin login page
    And I fill in "Email" with "admin@example.com"
    And I fill in "Password" with "Letmein1!"
    And I press "Log in"
    Then I should be on the admin todolist page
    And I should be connected to the server via an ssl connection
    And the markup should be valid
    And I should see "To do list"
    And I should see "Threshold"
    And I should see "Users"
    And I should see "Profile"
    And I follow "Logout"
    And I should be on the admin login page
    
  Scenario: Login and logout to the admin console as a moderator user
    Given a moderator user exists with email: "admin@example.com", password: "Letmein1!", password_confirmation: "Letmein1!"
    When I go to the admin login page
    And I fill in "Email" with "admin@example.com"
    And I fill in "Password" with "Letmein1!"
    And I press "Log in"
    Then I should be on the admin threshold page
    And I should see "To do list"
    And I should see "Threshold"
    And I should not see "Users"
    And I should see "Profile"
    And I follow "Logout"
    And I should be on the admin login page

  Scenario: Invalid login 
    Given I go to the admin login page
    And I fill in "Email" with "admin@example.com"
    And I fill in "Password" with "letmein1"
    And I press "Log in"
    Then I should see "Invalid email/password combination"
    And should not see "Logout"
    
  Scenario: 5 failed logins disables an account
    Given an admin user exists with email: "admin@example.com", password: "Letmein1!", password_confirmation: "Letmein1!"
    And I go to the admin login page
    And I try the password "wrong trousers" 5 times in a row
    And I fill in "Email" with "admin@example.com"
    And I fill in "Password" with "wrong trousers"
    And I press "Log in"
    Then I should see "Consecutive failed logins limit exceeded, account has been temporarily disabled."
    And should not see "Logout"

  Scenario: 5 failed logins with an email address containing a wildcard does not disable an account
    Given an admin user exists with email: "admin@example.com", password: "Letmein1!", password_confirmation: "Letmein1!"
    And I go to the admin login page
    And I try the password "wrong trousers" 5 times in a row for the email "admin%"
    And I fill in "Email" with "admin@example.com"
    And I fill in "Password" with "Letmein1!"
    And I press "Log in"
    Then I should be on the admin threshold page

  Scenario: Login as a user who hasn't changed their password for over 9 months
    Given an admin user exists with email: "admin@example.com", password: "Letmein1!", password_confirmation: "Letmein1!", password_changed_at: "10 months ago"
    When I go to the admin login page
    And I fill in "Email" with "admin@example.com"
    And I fill in "Password" with "Letmein1!"
    And I press "Log in"
    Then I should be on the admin edit profile page for "admin@example.com"
    And I should be connected to the server via an ssl connection
    And I fill in "Current password" with "Letmein1!"
    And I fill in "New password" with "Letmeout1!"
    And I fill in "Password confirmation" with "Letmeout1!"
    And I press "Save"
    Then I should be on the admin home page
    
  Scenario: Login as a user who is logging in for the first time
    Given an admin user exists with email: "admin@example.com", password: "Letmein1!", password_confirmation: "Letmein1!", force_password_reset: true
    When I go to the admin login page
    And I fill in "Email" with "admin@example.com"
    And I fill in "Password" with "Letmein1!"
    And I press "Log in"
    Then I should be on the admin edit profile page for "admin@example.com"
    And I fill in "Current password" with "Letmein1!"
    And I fill in "New password" with "Letmeout1!"
    And I fill in "Password confirmation" with "Letmeout1!"
    And I press "Save"
    Then I should be on the admin home page
