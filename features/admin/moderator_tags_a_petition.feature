@admin
Feature: A moderator user updates records notes
  In order to tag a petition to a particular department
  As any moderator user
  I want to be able add tags to any petition

  Background:
    Given I am logged in as a moderator

  Scenario: Adding tags to an open petition
    Given an open petition exists with action: "Solidarity with the Unions"
    And a tag exists with name: "DWP"
    When I am on the admin all petitions page
    And I follow "Solidarity with the Unions"
    And I follow "Tags"
    Then the "DWP" checkbox should not be checked
    When I check "DWP"
    And I press "Save tags"
    Then I should be on the admin petition page for "Solidarity with the Unions"
    And I should see "Petition has been successfully updated"
    When I follow "Tags"
    Then the "DWP" checkbox should be checked

  Scenario: Adding tags to a sponsored petition
    Given an sponsored petition exists with action: "Solidarity with the Unions"
    And a tag exists with name: "DWP"
    When I am on the admin all petitions page
    And I follow "Solidarity with the Unions"
    And I follow "Tags"
    Then the "DWP" checkbox should not be checked
    When I check "DWP"
    And I press "Save tags"
    Then I should be on the admin petition page for "Solidarity with the Unions"
    And I should see "Petition has been successfully updated"
    When I follow "Tags"
    Then the "DWP" checkbox should be checked

  Scenario: Removing tags from a petition
    Given an open petition exists with action: "Solidarity with the Unions"
    And a tag exists with name: "DWP"
    When I am on the admin all petitions page
    And I follow "Solidarity with the Unions"
    And I follow "Tags"
    Then the "DWP" checkbox should not be checked
    When I check "DWP"
    And I press "Save tags"
    Then I should be on the admin petition page for "Solidarity with the Unions"
    And I should see "Petition has been successfully updated"
    When I follow "Tags"
    Then the "DWP" checkbox should be checked
    When I uncheck "DWP"
    And I press "Save tags"
    Then I should be on the admin petition page for "Solidarity with the Unions"
    And I should see "Petition has been successfully updated"
    When I follow "Tags"
    Then the "DWP" checkbox should not be checked
