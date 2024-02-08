@admin
Feature: A moderator user updates records notes
  In order to record thoughts about a petition that are not for public consumption
  As any moderator user
  I want to be able add notes to any petition

  Background:
    Given I am logged in as a moderator

  Scenario: Adding notes to an open petition
    Given an open petition exists with action: "Solidarity with the Unions"
    When I am on the admin all petitions page
    And I follow "Solidarity with the Unions"
    And I follow "Notes"
    Then I should see a "Notes" textarea field
    And the markup should be valid
    When I fill in "Notes" with "I think we can debate this, will check with unions select committee first"
    And I press "Save"
    Then I should be on the admin petition page for "Solidarity with the Unions"
    And I follow "Notes"
    Then I should see "I think we can debate this, will check with unions select committee first"

  @javascript
  Scenario: Adding notes to an open petition as you type
    Given an open petition exists with action: "Solidarity with the Unions"
    When I am on the admin all petitions page
    And I follow "Solidarity with the Unions"
    And I follow "Notes"
    Then I should see a "Notes" textarea field
    And the markup should be valid
    When I fill in "Notes" with "I am just mulling this over"
    And I stop typing for 1000ms
    And I wait for the petition notes to save
    Then I reload the page
    Then I should see "I am just mulling this over"

  Scenario: Adding notes to an in moderation petition
    Given an sponsored petition exists with action: "Solidarity with the Unions"
    When I am on the admin all petitions page
    And I follow "Solidarity with the Unions"
    And I follow "Notes"

    Then I should see a "Notes" textarea field
    And the markup should be valid
    When I fill in "Notes" with "I think we can debate this, will check with unions select committee first"
    And I press "Save"
    Then I should be on the admin petition page for "Solidarity with the Unions"
    And I follow "Notes"
    Then I should see "I think we can debate this, will check with unions select committee first"

  Scenario: Removing notes
    Given an open petition exists with action: "Solidarity with the Unions"
    When I am on the admin all petitions page
    And I follow "Solidarity with the Unions"
    And I follow "Notes"
    Then I should see a "Notes" textarea field
    And the markup should be valid
    When I fill in "Notes" with "I think we can debate this, will check with unions select committee first"
    And I press "Save"
    Then I should be on the admin petition page for "Solidarity with the Unions"
    And I follow "Notes"
    Then I should see "I think we can debate this, will check with unions select committee first"
    When I fill in "Notes" with ""
    And I press "Save"
    Then I should be on the admin petition page for "Solidarity with the Unions"
