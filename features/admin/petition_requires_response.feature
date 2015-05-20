Feature: An moderator user updates internal response and marks it for a public response
  In order to assign a petition to a moderator user
  As any moderator user
  I want to be able add an internal response and flag a petition as requiring a public response

  Background:
    Given I am logged in as a moderator
    And a department "Treasury" exists with name: "Treasury"
    And a department "Cabinet Office" exists with name: "Cabinet Office"
    And an open petition exists with title: "Solidarity with the Unions"

  Scenario: Viewing the update internal response page
    When I am on the admin all petitions page
    And I follow "Solidarity with the Unions"
    Then I should see a "Internal response" textarea field
    And I should see a "Public response required" checkbox field
    And the markup should be valid

  Scenario: Updating the internal response and response required
    When I am on the admin all petitions page
    And I follow "Solidarity with the Unions"
    And I fill in "Internal response" with "Lets debate this in parliament"
    And I check "Public response required"
    And I press "Save"
    Then I should be on the admin all petitions page
    And a petition should exist with title: "Solidarity with the Unions", internal_response: "Lets debate this in parliament", response_required: true
