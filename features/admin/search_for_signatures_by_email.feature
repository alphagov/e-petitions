Feature: Searching for signatures as Terry
  In order to easily find out if someone's signed a petition
  As Terry
  I would like to be able to enter an email address, and see all signatures associated with it

  Scenario: A user can search for signatures by email
    Given 2 petitions signed by "bob@example.com"
    And I am logged in as a moderator
    When I search for petitions signed by "bob@example.com"
    Then I should see 2 petitions associated with the email address

  Scenario: A user can search for signatures by email from the admin hub
    Given 2 petitions signed by "bob@example.com"
    And I am logged in as a moderator
    When I search for petitions signed by "bob@example.com" from the admin hub
    Then I should see 2 petitions associated with the email address
