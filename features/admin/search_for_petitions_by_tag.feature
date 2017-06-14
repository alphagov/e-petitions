Feature: Maggie searches for petitions by tag
  In order to find petitions with tags
  As Maggie
  I would like to be able to enter a tag into the search box and see all petitions that have been assigned that tag

  Background:
    Given I am logged in as a moderator

  Scenario: When searching for tag, it returns all petitions tagged with tag
    Given allowed tags in site settings are "tag 1, tag 2, tag 3, tag 4, tag 5"
    And a petition "Raise benefits" exists with tags "tag 1, tag 2"
    And a petition "Help the poor" exists with tags "tag 2, tag 3"
    And a petition "Help the homeless" exists with tags "tag 3, tag 4"
    And a petition "Petition about something else" exists with tags "tag 4, tag 5"
    When I search for petitions with tag "tag 3"
    Then I should see the following list of petitions:
          | Help the homeless |
          | Help the poor     |
    When I search for petitions with tag "tag 4"
    Then I should see the following list of petitions:
          | Petition about something else |
          | Help the homeless             |

  Scenario: A user can search by tag from the admin hub
    Given allowed tags in site settings are "tag 1, tag 2, tag 3, tag 4, tag 5"
    Given a petition "Raise benefits" exists with tags "tag 1, tag 2"
    And a petition "Help the poor" exists with tags "tag 2, tag 3"
    And a petition "Help the homeless" exists with tags "tag 3, tag 4"
    And a petition "Petition about something else" exists with tags "tag 4, tag 5"
    When I search for petitions with tag "tag 1" from the admin hub
    Then I should see the following list of petitions:
          | Raise benefits |
    When I search for petitions with tag "tag 3" from the admin hub
    Then I should see the following list of petitions:
          | Help the homeless |
          | Help the poor |
