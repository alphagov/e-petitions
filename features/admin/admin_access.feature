@admin
Feature: Restricted access to the admin console
  In order to prevent unauthorised people accessing the admin area
  I can only access the admin area if I have logged on and my password does not need resetting

  Scenario: Accessing admin when not logged in
    When I go to the admin home page
    Then I should be on the admin login page
    And I should be connected to the server via an ssl connection
    And the markup should be valid

  Scenario: Accessing the job admin when not logged in
    When I go to the admin delayed job page
    Then I should be on the admin login page
    And I should be connected to the server via an ssl connection
    And the markup should be valid

  Scenario: Login and logout to the admin console as a sysadmin
    Given a sysadmin user exists with first_name: "John", last_name: "Admin", email: "admin@example.com", password: "Letmein1!", password_confirmation: "Letmein1!"
    When I go to the admin login page
    And I fill in "Email" with "admin@example.com"
    And I fill in "Password" with "Letmein1!"
    And I press "Sign in"
    Then I should be on the admin home page
    And I should be connected to the server via an ssl connection
    And the markup should be valid
    And I should see "Users"
    And I should see "John Admin"
    And I follow "Logout"
    And I should be on the admin login page

  Scenario: Login and logout to the admin console as a moderator user
    Given a moderator user exists with first_name: "John", last_name: "Moderator", email: "admin@example.com", password: "Letmein1!", password_confirmation: "Letmein1!"
    When I go to the admin login page
    And I fill in "Email" with "admin@example.com"
    And I fill in "Password" with "Letmein1!"
    And I press "Sign in"
    Then I should be on the admin home page
    And I should see "John Moderator"
    And I should not see "Users"
    And I follow "Logout"
    And I should be on the admin login page

  Scenario: Invalid login
    Given I go to the admin login page
    And I fill in "Email" with "admin@example.com"
    And I fill in "Password" with "letmein1"
    And I press "Sign in"
    Then I should see "Invalid email/password combination"
    And should not see "Logout"

  Scenario: 5 failed logins disables an account
    Given a moderator user exists with email: "admin@example.com", password: "Letmein1!", password_confirmation: "Letmein1!"
    And I go to the admin login page
    And I try the password "wrong trousers" 3 times in a row
    And I fill in "Email" with "admin@example.com"
    And I fill in "Password" with "wrong trousers"
    And I press "Sign in"
    Then I should see "You have one more attempt before your account is temporarily disabled"
    And should not see "Logout"
    And I fill in "Email" with "admin@example.com"
    And I fill in "Password" with "wrong trousers"
    And I press "Sign in"
    Then I should see "Failed login limit exceeded, your account has been temporarily disabled"
    And should not see "Logout"

  Scenario: 5 failed logins with an email address containing a wildcard does not disable an account
    Given a moderator user exists with email: "admin@example.com", password: "Letmein1!", password_confirmation: "Letmein1!"
    And I go to the admin login page
    And I try the password "wrong trousers" 5 times in a row for the email "admin%"
    And I fill in "Email" with "admin@example.com"
    And I fill in "Password" with "Letmein1!"
    And I press "Sign in"
    Then I should be on the admin home page
