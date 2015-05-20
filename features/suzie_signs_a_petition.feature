@departments
Feature: Suzie signs a petition
  In order to have my say
  As Suzie
  I want to sign an existing petition

  Background:
    Given a petition "Do something!" belonging to the "Treasury"
    And all petitions have had their signatures counted

  Scenario: Suzie signs a petition after validating her email
    When I go to the new signature page for "Do something!"
    And I should see "Do something! - Sign this e-petition - e-petitions" in the browser page title
    And the markup should be valid
    And I should be connected to the server via an ssl connection
    And I fill in my details
    And I try to sign
    Then I have not yet signed the petition
    And "womboid@wimbledon.com" should receive 1 email
    When I confirm my email address
    Then I am taken to a landing page
    And I can click on a link to return to the petition
    And I should have signed the petition

  @javascript
  Scenario: Suzie signs a petition after validating her email (javascript run-through)
    When I decide to sign the petition
    And I fill in my details
    And I try to sign
    Then I have not yet signed the petition
    And "womboid@wimbledon.com" should receive 1 email
    When I confirm my email address
    And all petitions have had their signatures counted
    Then I should have signed the petition

  Scenario: Suzie cannot sign if she is not a UK citizen
    When I decide to sign the petition
    And I fill in my non-UK details
    And I try to sign
    Then I should see an error

  Scenario: Suzie cannot sign if she has already signed and validated
    When I have already signed the petition with an uppercase email
    And I decide to sign the petition
    And I fill in my details
    And I try to sign
    Then I should see an error

  Scenario: Suzie receives another email if she has already signed but not validated
    When I have already signed the petition but not validated my email
    And I decide to sign the petition
    And I fill in my details
    And I try to sign
    Then "womboid@wimbledon.com" should receive 1 email

  Scenario: Suzie receives an email if her email has been used to sign the petition already
    When Eric has already signed the petition with Suzies email
    And I decide to sign the petition
    And I fill in my details
    And I try to sign
    Then "womboid@wimbledon.com" should receive 1 email

  Scenario: Suzie cannot sign if she does not provide her details
    When I decide to sign the petition
    And I try to sign
    Then I should see an error
    