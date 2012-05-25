Feature: Log of Department Changes on a Petition
  In order to determine whether a petition is being bounced around between departments
  As a moderator
  I want to see a history of the departmental assignment for a particular petition

  @departments
  Scenario: A petition has been bounced between two departments
  Given I am logged in as an admin
  And there is a petition "Rioters should loose benefits" that has been assigned between two departments several times
  When I view the "Rioters should loose benefits" admin edit page
  Then I should see the following admin index table:
    | Department     | Assigned On      |
    | Cabinet Office | 10-03-2012 10:15 |
    | Treasury       | 14-03-2012 11:30 |
    | Cabinet Office | 17-03-2012 12:45 |
