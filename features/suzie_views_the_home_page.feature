Feature: Suzy Signer views the home page
  In order to explore the Petitions website
  As Suzy the signer
  I visit the home page

  Scenario: I navigate to the home page when petitions are collecting signatures
    Given petitions are collecting signatures
    When I go to the home page
    Then I should not see "Petitions have stopped collecting signatures"

  Scenario: I navigate to the home page when petitions are not collecting signatures
    Given petitions are not collecting signatures
    When I go to the home page
    Then I should see "Petitions have stopped collecting signatures"

  Scenario: I navigate to the home page when a message is configured
    Given a home page message has been enabled
    When I go to the home page
    Then I should see "Petition moderation is experiencing delays"
