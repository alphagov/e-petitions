Feature: As Laura, a sponsor of my friend Charlie’s petition
  In order to provide my support to the petition
  I want to be able to sign the petition by providing my details

  Background:
    Given I have been told about a petition that needs sponsoring

  Scenario: Laura signs the petition she is a sponsor of
    When I visit the "sponsor this petition" url I was given
    And I should be connected to the server via an ssl connection
    When I confirm that I am UK citizen or resident
    And I fill in my details as a sponsor
    And I try to sign
    Then I should not have signed the petition as a sponsor
    And I am asked to review my email address
    When I say I am happy with my email address
    Then I should have a pending signature on the petition as a sponsor
    And I should receive an email explaining the petition I am sponsoring
    When I confirm my email address as a sponsor
    Then I should see a heading called "Thanks"
    And I should have fully signed the petition as a sponsor

  Scenario: Laura cannot sign if she is not a UK citizen
    When I visit the "sponsor this petition" url I was given
    And I say that I am not UK citizen or resident
    Then I should see "Sorry, you can’t sign this petition"

  Scenario: Laura wants to sign the petition that is already published
    Given the petition I want to sign is open
    When I visit the "sponsor this petition" url I was given
    Then I should be connected to the server via an ssl connection
    And I am redirected to the petition view page

  Scenario: Laura wants to sign the petition that is in moderation state
    Given the petition I want to sign is sponsored
    When I visit the "sponsor this petition" url I was given
    Then I should be connected to the server via an ssl connection

  Scenario: Laura wants to sign the petition that is closed
    Given the petition I want to sign has been closed
    When I visit the "sponsor this petition" url I was given
    Then I should be connected to the server via an ssl connection
    And I am redirected to the petition closed page

  Scenario: Laura wants to sign the petition that is rejected
    Given the petition I want to sign is rejected
    When I visit the "sponsor this petition" url I was given
    Then I should be connected to the server via an ssl connection
    And I am redirected to the petition closed page

  @allow-rescue
  Scenario: Laura wants to sign the petition that is hidden from publishing
    Given the petition I want to sign is hidden
    When I visit the "sponsor this petition" url I was given
    And I will see a 404 error page

  Scenario: Laura is the 21st sponsor that wants to sign the petition
    Given the petition I want to sign has enough sponsors
    When I visit the "sponsor this petition" url I was given
    Then I should be connected to the server via an ssl connection
    And I am redirected to the petition moderation info page

  Scenario: Laura gets her email address wrong and changes it while sponsoring
    When I visit the "sponsor this petition" url I was given
    And I confirm that I am UK citizen or resident
    And I fill in my details as a sponsor with email "sponsor@example.com"
    And I try to sign
    And I change my email address to "laura.the.sponsor@example.com"
    And I say I am happy with my email address
    Then "laura.the.sponsor@example.com" should receive an email explaining the petition I am sponsoring
    But "sponsor@example.com" should not have received an email explaining the petition I am sponsoring

  Scenario: Laura makes mistakes signing the petition she is a sponsor of
    When I visit the "sponsor this petition" url I was given
    And I confirm that I am UK citizen or resident
    And I don’t fill in my details correctly as a sponsor
    And I try to sign
    Then I should see an error
    And I should not have signed the petition as a sponsor
    When I fill in my details as a sponsor with email "sponsor@example.com"
    And I try to sign
    And I change my email address to ""
    And I say I am happy with my email address
    Then I should see an error
    And I should not have signed the petition as a sponsor

  Scenario: Laura sees notice that she has already signed when she validates more than once
    When I have sponsored a petition
    When I confirm my email address as a sponsor
    Then I should see a heading called "Thanks"
    And I should see "Your signature has been added to this petition as a supporter"
    And I should have fully signed the petition as a sponsor
    When I confirm my email address as a sponsor again
    Then I should see a heading called "Thanks"
    And I should see "Your signature has been added to this petition as a supporter"
    And I should see /This petition needs [0-9]+ supporters to go live/

  Scenario: Laura does not get an email when IP address is rate limited
    Given the sponsor rate limit is 1 per hour
    And there are no allowed IPs
    And there are no allowed domains
    And there is a sponsor already from this IP address
    When I visit the "sponsor this petition" url I was given
    And I confirm that I am UK citizen or resident
    And I fill in my details as a sponsor
    And I try to sign
    Then I am asked to review my email address
    When I say I am happy with my email address
    Then I should have a fraudulent signature on the petition as a sponsor
    And "laura.the.sponsor@example.com" should not have received an email explaining the petition I am sponsoring
