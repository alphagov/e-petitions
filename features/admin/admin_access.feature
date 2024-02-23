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

  @javascript
  Scenario: Login and logout to the admin console as a sysadmin
    Given a sysadmin SSO user exists
    When I go to the admin login page
    And I fill in "Email" with "sysadmin@example.com"
    And I press "Sign in"
    Then I should be on the admin home page
    And I should be connected to the server via an ssl connection
    And the markup should be valid
    And I should see "Users"
    And I should see "John Admin"
    And I follow "Logout"
    And I should be on the admin login page

  @javascript
  Scenario: Login and logout to the admin console as a moderator
    Given a moderator SSO user exists
    When I go to the admin login page
    And I fill in "Email" with "moderator@example.com"
    And I press "Sign in"
    Then I should be on the admin home page
    And I should be connected to the server via an ssl connection
    And the markup should be valid
    And I should not see "Users"
    And I should see "John Moderator"
    And I follow "Logout"
    And I should be on the admin login page

  @javascript
  Scenario: Login and logout to the admin console as a reviewer
    Given a reviewer SSO user exists
    When I go to the admin login page
    And I fill in "Email" with "reviewer@example.com"
    And I press "Sign in"
    Then I should be on the admin home page
    And I should be connected to the server via an ssl connection
    And the markup should be valid
    And I should not see "Users"
    And I should see "John Reviewer"
    And I follow "Logout"
    And I should be on the admin login page

  Scenario: Invalid domain
    When I go to the admin login page
    And I fill in "Email" with "admin@example.org"
    And I press "Sign in"
    Then I should see "Invalid login details"
    And should not see "Logout"

  Scenario: Invalid login
    Given an invalid SSO login
    When I go to the admin login page
    And I fill in "Email" with "admin@example.com"
    And I press "Sign in"
    Then I should see "There was a problem logging in - please contact support"
    And should not see "Logout"

  Scenario: Valid login but no role
    Given a valid SSO login with no roles
    When I go to the admin login page
    And I fill in "Email" with "norole@example.com"
    And I press "Sign in"
    Then I should see "Invalid login details"
    And should not see "Logout"

