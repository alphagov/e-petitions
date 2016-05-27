@admin
Feature: Searching for signatures as Terry
  In order to easily find out if someone's signed a petition
  As Terry
  I would like to be able to enter a name, and see all signatures associated with it

  Scenario: A user can search for signatures by name
    Given 2 petitions signed by "Bob Jones"
    And I am logged in as a moderator
    When I search for petitions signed by "Bob Jones"
    Then I should see 2 petitions associated with the name

  Scenario: A user can search for signatures by name from the admin hub
    Given 2 petitions signed by "Bob Jones"
    And I am logged in as a moderator
    When I search for petitions signed by "Bob Jones" from the admin hub
    Then I should see 2 petitions associated with the name

  Scenario: A user can search for signatures by name case insensitively
    Given 2 petitions signed by "Bob Jones"
    And I am logged in as a moderator
    When I search for petitions signed by "BOB JONES"
    Then I should see 2 petitions associated with the name
