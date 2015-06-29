Feature: Admin hub page
  In order to help administrators see the next actions they need to take
  As any moderator user
  I want to view a page which lists totals for actionable list and links to them

  Background:
    Given I am logged in as a moderator

  Scenario: I can see a total of petitions needing moderation and link to them
    Given 20 petitions exist with state: "sponsored"
    And there are 12 petitions awaiting a government response
    And there are 5 petitions with a scheduled debate date
    And there are 3 petitions with enough signatures to require a debate
    When I go to the Admin home page
    Then I should see "20 Moderation queue"
    And I should see "12 Government response queue"
    And I should see "8 Debate queue"
    And I should see "40 All petitions"
    And I should be connected to the server via an ssl connection
    And the markup should be valid


  Scenario: I can click through to see lists of matching petitions
    Given 12 petitions exist with state: "sponsored"
    When I go to the Admin home page
    And I follow "12 Moderation queue"
    Then I should be on the Admin all petitions page
