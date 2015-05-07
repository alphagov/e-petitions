Feature: As Laura, a sponsor of my friend Charlie's petition
  In order to provide my support to the petition
  I want to be able to sign the petition by providing my details

  Background:
    Given I have been listed as a sponsor of a petition

  Scenario: Laura signs the petition she is a sponsor of
    When I follow the link to the petition in my sponsor email
    Then the markup should be valid
    And I should be connected to the server via an ssl connection
    When I fill in my details as a sponsor
    And I accept the terms and conditions
    And I try to sign
    Then I should have signed the petition as a sponsor

