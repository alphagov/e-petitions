@admin
Feature: Moderator manually adds a signature to a petition

  Scenario: Adding a signature to a petition
    Given an open petition "More money for charities" with some signatures
    And I am logged in as a moderator
    When I view all petitions
    And I follow "More money for charities"
    And I follow "Add a signature"
    And I press "Create signature"
    Then I should see "Name must be completed"
    And I should see "Postcode must be completed"
    When I fill in "Name" with "Suzie Signer"
    And I select "England" from "Location"
    And I fill in "Postcode" with "SW1A 1AA"
    And I press "Create signature"
    Then I should see "Signature added to the petition successfully"
    And a validated signature should exist with name: "Suzie Signer", location_code: "GB-ENG", postcode: "SW1A1AA"
