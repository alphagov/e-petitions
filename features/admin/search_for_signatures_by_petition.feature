@admin
Feature: Searching for signatures as Terry
  In order to easily find out if someone's signed a petition
  As Terry
  I would like to be able to enter a name, and see all signatures on a petition associated with it

  Scenario: Searching for signatures on a petition by name
    Given a petition "Fun times!" signed by "Bob Jones"
    And I am logged in as a moderator
    When I search for a petition by id
    Then I am on the admin petition page for "Fun times!"
    When I follow "Signatures 2"
    Then I should see "Signatures"
    When I search for signatures from "Bob Jones"
    Then I should see 1 signature associated with that name

  Scenario: Searching for signatures on a petition by email
    Given a petition "Fun times!" signed by "bob@example.com"
    And I am logged in as a moderator
    When I search for a petition by id
    Then I am on the admin petition page for "Fun times!"
    When I follow "Signatures 2"
    Then I should see "Signatures"
    When I search for signatures from "bob@example.com"
    Then I should see 1 signature associated with that email address
