Feature: Suzie sees actioned petitions
  In order to make the site more engaging for browsing
  As Suzie the signer
  I want to see counts and links to petitions that have been actioned

  Scenario: There are no actioned petitions
    Given I am on the home page
    Then I should not see the actioned petitions section

  Scenario: There are petitions with a response from government
    Given There are 2 petitions with a government response
    And I am on the home page
    Then I should see there are 2 petitions with a government response

  Scenario: There are petitions debated in parliament
    Given There are 123 petitions debated in parliament
    And I am on the home page
    Then I should see there are 123 petitions debated in parliament

  Scenario: There are petitions with a response from government and petitions debated in parliament
    Given There are 57 petitions with a government response
    Given There are 12 petitions debated in parliament
    And I am on the home page
    Then I should see there are 57 petitions with a government response
    Then I should see there are 12 petitions debated in parliament
