Feature: Suzie sees actioned petitions
  In order to make the site more engaging for browsing
  As Suzie the signer
  I want to see counts and links to petitions that have been actioned

  Scenario: There are no actioned petitions
    Given I am on the home page
    Then I should not see the actioned petitions section
    But I should see an empty government response threshold section
    And I should see an empty debate threshold section

  Scenario: There are petitions with a response from government
    Given there are 2 petitions with a government response
    And I am on the home page
    Then I should see there are 2 petitions with a government response
    And I should see the government response threshold section with a count of 2
    And I should see an empty debate threshold section

  Scenario: There are petitions debated in parliament
    Given there are 3 petitions debated in parliament
    And I am on the home page
    Then I should see there are 3 petitions debated in parliament
    And I should see an empty government response threshold section
    And I should see the debate threshold section with a count of 3

  Scenario: There are petitions with a response from government and petitions debated in parliament
    Given there are 5 petitions with a government response
    And there are 2 petitions debated in parliament
    And I am on the home page
    Then I should see there are 5 petitions with a government response
    Then I should see there are 2 petitions debated in parliament
    And I should see the government response threshold section with a count of 5
    And I should see the debate threshold section with a count of 2
