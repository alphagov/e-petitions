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
    And I try to sign
    Then I should not have signed the petition as a sponsor
    And I am asked to review my email address
    When I say I am happy with my email address
    Then I should have a pending signature on the petition as a sponsor
    And I should receive an email explaining the petition I am sponsoring
    When I confirm my email address
    Then I am taken to a landing page
    And I should have fully signed the petition as a sponsor

  Scenario: Laura gets her email address wrong and changes it while sponsoring
    When I follow the link to the petition in my sponsor email
    And I fill in my details as a sponsor with email "sponsor@example.com"
    And I try to sign
    And I change my email address to "laura.the.sponsor@example.com"
    And I say I am happy with my email address
    Then "laura.the.sponsor@example.com" should receive an email explaining the petition I am sponsoring
    But "sponsor@example.com" should not have received an email explaining the petition I am sponsoring

  Scenario: Laura makes mistakes signing the petition she is a sponsor of
    When I follow the link to the petition in my sponsor email
    And I don't fill in my details correctly as a sponsor
    And I try to sign
    Then I should see an error
    And I should not have signed the petition as a sponsor
    When I fill in my details as a sponsor with email "sponsor@example.com"
    And I try to sign
    And I change my email address to ""
    And I say I am happy with my email address
    Then I should see an error
    And I should not have signed the petition as a sponsor
