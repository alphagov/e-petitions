Feature: Maggie searches for petitions by tag
  In order to find petitions with tags in the notes field
  As Maggie
  I would like to be able to enter a structured tag and see all petitions that have that tag in their notes

  Background:
    Given I am logged in as a moderator

  Scenario: When searching for tag, it returns all petitions with keyword in action OR background OR additional_details
    Given a petition "Raise benefits" exists with notes "[DWP] [benefits] lorem ipsum"
    And a petition "Help the poor" exists with notes "[benefits] what about the home less"
    And a petition "Help the homeless" exists with notes "[home less]"
    And a petition "Petition about something else" exists with notes "this is not about benefits"
    When I search for petitions with tag "benefits"
    Then I should see the following list of petitions:
          | Raise benefits    |
          | Help the poor     |
    When I search for petitions with tag "home less"
    Then I should see the following list of petitions:
          | Help the homeless |

  Scenario: A user can search by tag from the admin hub
    Given a petition "Raise benefits" exists with notes "[DWP] [benefits] lorem ipsum"
    And a petition "Help the poor" exists with notes "[benefits] what about the home less"
    And a petition "Help the homeless" exists with notes "[home less]"
    And a petition "Petition about something else" exists with notes "this is not about benefits"
    When I search for petitions with tag "benefits" from the admin hub
    Then I should see the following list of petitions:
          | Raise benefits    |
          | Help the poor     |
