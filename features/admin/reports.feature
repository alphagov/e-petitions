Feature: Viewing reports
  In order to gauge utilisation of the e-petitions site
  As Maggie or Terry
  I would like to be able to see summary of number of petitions in particular states

  Scenario:
    Given I am logged in as a threshold user
    And the "Transport" department has 1 pending, 1 validated, 2 open, 3 closed and 3 rejected petitions
    And the "DFID" department has 0 pending, 1 validated, 1 open, 1 closed and 2 rejected petitions
    When I follow "Reports" in the admin nav
    Then I should be on the admin reports page
    Then I see the following reports table:
      |                 | Pending | Validated | Open | Closed | Rejected | Total |
      | All Departments |       1 |         2 |    3 |      4 |        5 |    15 |
      | Transport       |       1 |         1 |    2 |      3 |        3 |    10 |
      | DFID            |       0 |         1 |    1 |      1 |        2 |     5 |

  Scenario: department moderator viewing trending petitions for their department
    Given I am logged in as a moderator for the "Transport" department
    And there has been activity on a number of petitions in the last 24 hours
    When I follow "Reports" in the admin nav
    Then I should be on the admin reports page
    And I should see trending petitions for all my departments for the last 24 hours
    And I should not see trending petitions for any other department

  @departments
  Scenario: Threshold user viewing trending petitions
    Given I am logged in as a threshold user
    And there has been activity on a number of petitions in the last 24 hours
    When I follow "Reports" in the admin nav
    Then I should be on the admin reports page
    And I should see trending petitions for all my departments for the last 24 hours

  @departments
  Scenario: Viewing trends for 7 days
    Given I am logged in as a threshold user
    And there has been activity on a number of petitions in the last 7 days
    When I follow "Reports" in the admin nav
    Then I choose to view 7 days of trends
    And I should see trending petitions for all my departments for the last 24 hours
