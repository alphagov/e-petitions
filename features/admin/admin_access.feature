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
    Given a sysadmin user exists with email: "admin@example.com", first_name: "John", last_name: "Admin"
    When I go to the admin login page
    And I press "Login with developer strategy"
    And I fill in "Email" with "admin@example.com"
    And I press "Sign In"
    Then I should be on the admin home page
    And I should be connected to the server via an ssl connection
    And the markup should be valid
    And I should see "Users"
    And I should see "John Admin"
    And I follow "Logout"
    And I should be on the admin login page

  Scenario: Login and logout to the admin console as a moderator user
    Given a moderator user exists with email: "admin@example.com", first_name: "John", last_name: "Moderator"
    When I go to the admin login page
    And I press "Login with developer strategy"
    And I fill in "Email" with "admin@example.com"
    And I press "Sign In"
    Then I should be on the admin home page
    And I should see "John Moderator"
    And I should not see "Users"
    And I follow "Logout"
    And I should be on the admin login page

  Scenario: Invalid login
    Given I go to the admin login page
    And I press "Login with developer strategy"
    And I fill in "Email" with "admin@example.com"
    And I press "Sign In"
    Then I should see "Invalid login details"
    And should not see "Logout"
