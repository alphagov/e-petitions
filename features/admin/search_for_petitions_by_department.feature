Feature: Maggie searches for petitions by department
  In order to find petitions with departments
  As Maggie
  I would like to be able to select a department and see all the petitions tagged with that department

  Background:
    Given I am logged in as a moderator

  Scenario: When searching for department, it returns all petitions tagged with that department
    Given a petition "Raise benefits" exists with departments "DWP, DIFD"
    And a petition "Help the poor" exists with departments "DIFD"
    And a petition "Help the homeless" exists with departments "DCLG"
    And a petition "Petition about something else" exists with departments ""
    When I search for petitions with department "DIFD"
    Then I should see the following list of petitions:
          | Help the poor     |
          | Raise benefits    |
    When I search for petitions with department "DCLG"
    Then I should see the following list of petitions:
          | Help the homeless |

  Scenario: A user can search by department from the admin hub
    Given a petition "Raise benefits" exists with departments "DWP, DIFD"
    And a petition "Help the poor" exists with departments "DIFD"
    And a petition "Help the homeless" exists with departments "DCLG"
    And a petition "Petition about something else" exists with departments ""
    When I search for petitions with department "DIFD" from the admin hub
    Then I should see the following list of petitions:
          | Help the poor     |
          | Raise benefits    |
