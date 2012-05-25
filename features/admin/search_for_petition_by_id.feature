@departments
Feature: Maggie searches for a petition by id
  In order to quickly find a petition and view the contents
  As Maggie
  I want to enter an id and be taken to the petition for that id, or shown an error if it doesn't exist

  Scenario:
    Given a set of petitions for the "Treasury"
    And I am logged in as a moderator for the "Cabinet Office"
    When I search for a petition by id
    Then I should see the petition for viewing only

  Scenario: A user from the same department sees the edit page if the petition needs moderation
    Given a validated petition "Loose benefits!" belonging to the "Treasury"
    And I am logged in as a moderator for the "Treasury"
    When I search for a petition by id
    Then I should see the petition for editing

  Scenario: A user from the same department sees the edit internal page if the petition is visible
    Given a petition "Duplicate" has been rejected by the "Treasury"
    And I am logged in as a moderator for the "Treasury"
    When I search for a petition by id
    Then I should see the petition for editing the internal reponse and changing the status

  Scenario: A threshold user sees the edit page if the petition needs moderation
    Given a validated petition "Loose benefits!" belonging to the "Treasury"
    And I am logged in as a threshold user
    When I search for a petition by id
    Then I should see the petition for editing

  Scenario: A threshold user sees the edit response page if the petition is open
    Given a set of petitions for the "Treasury"
    And I am logged in as a threshold user
    When I search for a petition by id
    Then I should see the petition for editing the reponses

  Scenario:
    Given I am logged in as a threshold user
    When I search for a petition by id
    Then I should be taken back to the id search form with an error
