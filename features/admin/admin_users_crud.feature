@admin
Feature: Admin users index and crud
  As a sysadmin
  I can see the admin users index and crud admin users

  Background:
    Given I am logged in as a sysadmin with the email "muddy@fox.com", first_name "Sys", last_name "Admin"
    And a moderator user exists with email: "naomi@example.com", first_name: "Naomi", last_name: "Campbell"

  Scenario: Accessing the admin users index
    When I go to the admin home page
    And I follow "Users"
    Then I should be on the admin users index page
    And I should be connected to the server via an ssl connection

  Scenario: Ordering of the users index
    Given a moderator user exists with email: "derek@example.com", first_name: "Derek", last_name: "Jacobi"
    And a moderator user exists with email: "helen@example.com", first_name: "Helen", last_name: "Hunt", failed_attempts: 5
    When I go to the admin users index page
    Then I should see the following admin user table:
      | Name            | Email             | Role      | Disabled |
      | Admin, Sys      | muddy@fox.com     | sysadmin  |          |
      | Campbell, Naomi | naomi@example.com | moderator |          |
      | Hunt, Helen     | helen@example.com | moderator | Yes      |
      | Jacobi, Derek   | derek@example.com | moderator |          |
    And the markup should be valid

  Scenario: Pagination of the users index
    Given 50 moderator users exist
    When I go to the admin users index page
    And I follow "Next"
    Then I should see 2 rows in the admin user table
    And I follow "Previous"
    Then I should see 50 rows in the admin user table

  Scenario: Inspecting the new user form
    When I go to the admin users index page
    And I follow "New user"
    Then I should be on the admin new user page
    And I should be connected to the server via an ssl connection
    And I should see a "First name" text field
    And I should see a "Last name" text field
    And I should see a "Email" email field
    And I should see a "sysadmin" radio field
    And I should see a "moderator" radio field
    And I should see a "Force password reset" checkbox field
    And I should see a "Account disabled" checkbox field
    And I should see a "Password" password field
    And I should see a "Password confirmation" password field

  Scenario: Creating a new user
    When I go to the admin users index page
    And I follow "New user"
    And I fill in "First name" with "Derek"
    And I fill in "Last name" with "Jacobi"
    And I fill in "Email" with "derek@example.com"
    And I choose "sysadmin"
    And I fill in "Password" with "Letmein1!"
    And I fill in "Password confirmation" with "Letmein1!"
    And I press "Save"
    Then I should be on the admin users index page
    And I should see "derek@example.com"
    When I follow "Jacobi, Derek"
    Then the "sysadmin" radio button should be chosen
    And the "Account disabled" checkbox should not be checked

  Scenario: Updating a user
    When I go to the admin users index page
    And I follow "Campbell, Naomi"
    And I fill in "First name" with "Nolene"
    And I fill in "Email" with "helen@example.com"
    And I check "Account disabled"
    And I press "Save"
    Then I should be on the admin users index page
    And I should see "helen@example.com"
    When I follow "Campbell, Nolene"
    And the "Email" field should contain "helen@example.com"
    And the "Account disabled" checkbox should be checked
    And a moderator user should exist with email: "helen@example.com", failed_attempts: "5"
    And I should be connected to the server via an ssl connection

  Scenario: Enabling a user's disabled account
    Given a moderator user exists with email: "derek@example.com", first_name: "Derek", last_name: "Jacobi", failed_attempts: "5"
    When I go to the admin users index page
    And I follow "Jacobi, Derek"
    And the "Account disabled" checkbox should be checked
    And I uncheck "Account disabled"
    And I press "Save"
    Then I should be on the admin users index page
    When I follow "Jacobi, Derek"
    And the "Account disabled" checkbox should not be checked
    And a moderator user should exist with email: "derek@example.com", failed_attempts: "0"

  Scenario: Deleting a user
    When I go to the admin users index page
    And I follow "Delete" for "naomi@example.com"
    Then a admin user should not exist with email: "naomi@example.com"
    And the row with the name "naomi@example.com" is not listed
