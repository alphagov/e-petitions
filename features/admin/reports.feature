Feature: Viewing reports
  In order to gauge utilisation of the e-petitions site
  As Maggie or Terry
  I would like to be able to see summary of number of petitions in particular states

  Scenario: moderator user viewing trending petitions
    Given I am logged in as a moderator
    And there has been activity on a number of petitions in the last 24 hours
    When I follow "Reports" in the admin nav
    Then I should be on the admin reports page
    And I should see trending petitions for the last 24 hours

  Scenario: moderator user viewing trending petitions
    Given I am logged in as a moderator
    And there has been activity on a number of petitions in the last 24 hours
    When I follow "Reports" in the admin nav
    Then I should be on the admin reports page
    And I should see trending petitions for the last 24 hours

  Scenario: Viewing trends for 7 days
    Given I am logged in as a moderator
    And there has been activity on a number of petitions in the last 7 days
    When I follow "Reports" in the admin nav
    Then I choose to view 7 days of trends
    And I should see trending petitions for the last 24 hours
