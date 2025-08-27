@admin
Feature: Maggie searches for a petition by id
  In order to quickly find a petition and view the contents
  As Maggie, a petition moderator
  I want to enter an id and be taken to the petition for that id, or shown an error if it doesn’t exist

  Scenario: A user sees the show page if the petition needs moderation
    Given a sponsored petition "Loose benefits!"
    And I am logged in as a moderator
    When I search for a petition by id
    Then I am on the admin petition page for "Loose benefits!"

  Scenario: A user sees the show page if the petition is visible
    Given a petition "Duplicate" has been rejected
    And I am logged in as a moderator
    When I search for a petition by id
    Then I am on the admin petition page for "Duplicate"

  Scenario: A moderator user show page if the petition needs moderation
    Given a sponsored petition "Loose benefits!"
    And I am logged in as a moderator
    When I search for a petition by id
    Then I am on the admin petition page for "Loose benefits!"

  Scenario: A moderator user show response page if the petition is open
    Given an open petition "Fun times!"
    And I am logged in as a moderator
    When I search for a petition by id
    Then I am on the admin petition page for "Fun times!"

  Scenario: A user doing a search for a petition id that doesn’t exist gets an error
    Given I am logged in as a moderator
    When I search for a petition by id
    Then I should be taken back to the id search form with an error

  Scenario: A user can search by id from the main admin hub
    Given a sponsored petition "Loose benefits!"
    And I am logged in as a moderator
    When I search for a petition by id from the admin hub
    Then I am on the admin petition page for "Loose benefits!"
