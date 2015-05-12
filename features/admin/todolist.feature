Feature: Dashboard todo list
  In order to see priority items
  I can see a list of validated petitions on my todo list that need moderation
  
  Background:
    Given a department "DFID" exists with name: "DFID"
    And a department "Treasury" exists with name: "Treasury"
    And a department "Home Office" exists with name: "Home Office"
    And a petition "p1" exists with title: "Petition 1", department: department "DFID", state: "sponsored", created_at: "2009-02-10"
    And an open petition "p2" exists with title: "Petition 2", department: department "DFID", created_at: "2008-10-09"
    And a petition "p3" exists with title: "Petition 3", department: department "Treasury", state: "sponsored", created_at: "2010-11-11"
    And a petition "p4" exists with title: "Petition 4", department: department "Treasury", state: "sponsored", created_at: "2010-01-01"
    And a rejected petition "p5" exists with title: "Petition 5", department: department "Home Office", created_at: "2007-01-01"
    And a petition "p6" exists with title: "Petition 6", department: department "Treasury", state: "validated", created_at: "2010-01-01"	

  Scenario: A sysadmin sees all pending petitions
    Given I am logged in as a sysadmin
    When I go to the admin todolist page
    Then I should see the following admin index table:
      | Title      | Date       |
      | Petition 1 | 10-02-2009 |
      | Petition 4 | 01-01-2010 |
      | Petition 3 | 11-11-2010 |
  And I should be connected to the server via an ssl connection
  And the markup should be valid

  Scenario: An admin sees pending petitions for their department
    Given I am logged in as an admin
    And I am associated with the department "Treasury"
    And I am associated with the department "Home Office"
    When I go to the admin todolist page
    Then I should see the following admin index table:
      | Title      | Date       |
      | Petition 4 | 01-01-2010 |
      | Petition 3 | 11-11-2010 |

  Scenario: Pending petitions are paginated
    Given I am logged in as a sysadmin
    And 20 petitions exist with state: "sponsored"
    When I go to the admin todolist page
    And I follow "Next"
    Then I should see 3 rows in the admin index table
    And I follow "Previous"
    And I should see 20 rows in the admin index table
