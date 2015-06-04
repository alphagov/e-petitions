Feature: Suzie signs a petition
  In order to have my say
  As Suzie
  I want to sign an existing petition

  Background:
    Given a petition "Do something!"
    And all petitions have had their signatures counted

  Scenario: Suzie signs a petition after validating her email
    When I decide to sign the petition
    And I fill in my details
    And I try to sign
    And I say I am happy with my email address
    Then I have not yet signed the petition
    And "womboid@wimbledon.com" should receive 1 email
    When I confirm my email address
    And all petitions have had their signatures counted
    Then I should have signed the petition

  Scenario: Suzie signs a petition after validating her email
    When I go to the new signature page for "Do something!"
    And I should see "Do something! - Sign this e-petition - e-petitions" in the browser page title
    And I should be connected to the server via an ssl connection
    And I fill in my details with email "womboid@wimbledon.com"
    And I fill in my postcode with "N1 1TY"
    And I try to sign
    Then I am asked to review my email address
    When I change my email address to "womboidian@wimbledon.com"
    And I say I am happy with my email address
    Then I have not yet signed the petition
    And "womboid@wimbledon.com" should receive no email
    And "womboidian@wimbledon.com" should receive 1 email
    When I confirm my email address
    Then I am taken to a landing page
    And I should see my constituency "Islington South and Finsbury"
    And I can click on a link to return to the petition
    And I should have signed the petition

  Scenario: Suzie signs a petition with invalid postcode SW14 9RQ
    When I go to the new signature page for "Do something!"
    And I fill in my details with email "womboid@wimbledon.com"
    And I fill in my postcode with "SW14 9RQ"
    And I try to sign
    Then I am asked to review my email address
    And I say I am happy with my email address
    Then I have not yet signed the petition
    And "womboid@wimbledon.com" should receive 1 email
    When I confirm my email address
    Then I am taken to a landing page
    And I should not see the text "Your constituency is"

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
    And I fill in my details with email "womboidian@wimbledon.com"
    And I try to sign
    When I change my email address to "womboid@wimbledon.com"
    And I say I am happy with my email address
    Then I should see an error

  Scenario: Suzie receives another email if she has already signed but not validated
    When I have already signed the petition but not validated my email
    And I decide to sign the petition
    And I fill in my details
    And I try to sign
    Then the signature count stays at 2
    And I have not yet signed the petition
    And "womboid@wimbledon.com" should receive 1 email

  Scenario: Suzie receives an email if her email has been used to sign the petition already
    When Eric has already signed the petition with Suzies email
    And I decide to sign the petition
    And I fill in my details
    And I try to sign
    And I say I am happy with my email address
    Then the signature count goes up to 3
    And I have not yet signed the petition
    And "womboid@wimbledon.com" should receive 1 email

  Scenario: Suzie cannot sign if she does not provide her details
    When I decide to sign the petition
    And I try to sign
    Then I should see an error

  Scenario: Suzie sees notice that she has already signed when she validates more than once
    When I fill in my details and sign a petition
    And I confirm my email address
    And I am taken to a landing page
    And I can click on a link to return to the petition
    And I should have signed the petition
    When I confirm my email address
    And I am taken to a landing page
    And I can click on a link to return to the petition
    Then I should see that I have already signed the petition
