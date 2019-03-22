Feature: Suzie sees trending petitions
  In order to make the site more engaging for browsing
  As Suzie the signer
  I want to see the most active petitions on the front page

  @skip
  Scenario: There are no trending petitions
    Given I am on the home page
    Then I should not see the trending petitions section

  @skip
  Scenario: Seeing a number of trending petitions
    Given there has been activity on a number of petitions in the last hour
    And I am on the home page
    Then I should see the most popular petitions listed on the front page
