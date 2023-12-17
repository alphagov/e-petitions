@admin
Feature: Admin users index and crud
  As a sysadmin
  I can see the admin users index and crud admin users

  Background:
    Given the time is "Sun, 17 Dec 2023 08:28:41 +0000"
    And I am logged in as a sysadmin with the email "muddy@fox.com", first_name "Sys", last_name "Admin"
    And a moderator user exists with email: "naomi@example.com", first_name: "Naomi", last_name: "Campbell"

  Scenario: Accessing the admin users index
    When I go to the admin home page
    And I follow "Users"
    Then I should be on the admin users index page
    And I should be connected to the server via an ssl connection

  Scenario: Ordering of the users index
    Given a moderator user exists with email: "derek@example.com", first_name: "Derek", last_name: "Jacobi", current_sign_in_at: "2023-12-11 14:27:14"
    And a moderator user exists with email: "helen@example.com", first_name: "Helen", last_name: "Hunt", current_sign_in_at: "2023-12-15 10:09:31"
    When I go to the admin users index page
    Then I should see the following admin user table:
      | Name            | Email             | Role      | Last login                  |
      | Admin, Sys      | muddy@fox.com     | sysadmin  | 08:28am on 17 December 2023 |
      | Campbell, Naomi | naomi@example.com | moderator |                             |
      | Hunt, Helen     | helen@example.com | moderator | 10:09am on 15 December 2023 |
      | Jacobi, Derek   | derek@example.com | moderator | 14:27pm on 11 December 2023 |
    And the markup should be valid

  Scenario: Pagination of the users index
    Given 50 moderator users exist
    When I go to the admin users index page
    And I follow "Next"
    Then I should see 2 rows in the admin user table
    And I follow "Previous"
    Then I should see 50 rows in the admin user table
