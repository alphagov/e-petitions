Feature: Maggie searches for a petition by id
  In order to quickly find a petition and view the contents
  As Maggie
  I want to enter an id and be taken to the petition for that id, or shown an error if it doesn't exist

  Scenario: A user sees the edit page if the petition needs moderation
    Given a sponsored petition "Loose benefits!"
    And I am logged in as a moderator
    When I search for a petition by id
    Then I should see the petition for editing

  Scenario: A user sees the edit internal page if the petition is visible
    Given a petition "Duplicate" has been rejected
    And I am logged in as a moderator
    When I search for a petition by id
    Then I should see the petition for editing the internal reponse and changing the status

  Scenario: A moderator user sees the edit page if the petition needs moderation
    Given a sponsored petition "Loose benefits!"
    And I am logged in as a moderator
    When I search for a petition by id
    Then I should see the petition for editing

  Scenario: A moderator user sees the edit response page if the petition is open
    Given a set of petitions
    And I am logged in as a moderator
    When I search for a petition by id
    Then I should see the petition for editing the reponses

  Scenario: A user doing a search for a petition id that doesn't exist gets an error
    Given I am logged in as a moderator
    When I search for a petition by id
    Then I should be taken back to the id search form with an error
