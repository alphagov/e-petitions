Feature: Maggie fitlers her searches wth tags
  In order to filter petitions by tags
  As Maggie
  I would like to be able to select tags from the tag fitler box and see all petitions that have those tags

  Background:
    Given I am logged in as a moderator

  Scenario: When searching for petitions by keyword, it returns all petitions tagged with selected tags
    Given allowed tags in site settings are "tag 1, tag 2, tag 3, tag 4, tag 5"
    And a petition "Raise benefits" exists with tags "tag 1, tag 2"
    And a petition "Help the poor" exists with tags "tag 2, tag 3"
    And a petition "Help the homeless" exists with tags "tag 3, tag 4"
    And a petition "Petition about something else" exists with tags "tag 4, tag 5"
    When I search for petitions with keyword "Help"
    And I filter the results by tags "tag 2, tag 3"
    Then I should see the following list of petitions:
          | Help the poor |
    When I search for petitions with keyword "something"
    And I filter the results by tags "tag 1, tag 2"
    Then I should not see any petitions
    When I search for petitions with keyword "Raise"
    And I filter the results by tags "tag 2"
    Then I should see the following list of petitions:
          | Raise benefits |

  Scenario: When searching for petitions in the admin hub by keyword, it returns all petitions tagged with selected tags
    Given allowed tags in site settings are "tag 1, tag 2, tag 3, tag 4, tag 5"
    And a petition "Raise benefits" exists with tags "tag 1, tag 2"
    And a petition "Help the poor" exists with tags "tag 2, tag 3"
    And a petition "Help the homeless" exists with tags "tag 3, tag 4"
    And a petition "Petition about something else" exists with tags "tag 4, tag 5"
    When I search for petitions with keyword "Help" from the admin hub
    And I filter the results by tags "tag 2, tag 3"
    Then I should see the following list of petitions:
          | Help the poor |
    When I search for petitions with keyword "something" from the admin hub
    And I filter the results by tags "tag 1, tag 2"
    Then I should not see any petitions
    When I search for petitions with keyword "Raise" from the admin hub
    And I filter the results by tags "tag 2"
    Then I should see the following list of petitions:
          | Raise benefits |

  Scenario: When searching for petitions by tag, it returns all petitions also tagged with selected tags
    Given allowed tags in site settings are "tag 1, tag 2, tag 3, tag 4, tag 5"
    And a petition "Raise benefits" exists with tags "tag 1, tag 2"
    And a petition "Help the poor" exists with tags "tag 2, tag 3"
    And a petition "Help the homeless" exists with tags "tag 3, tag 4"
    And a petition "Petition about something else" exists with tags "tag 4, tag 5"
    When I search for petitions with tag "tag 3"
    And I filter the results by tags "tag 2"
    Then I should see the following list of petitions:
          | Help the poor |
    When I search for petitions with tag "tag 2"
    And I filter the results by tags "tag 1, tag 2, tag 3"
    Then I should not see any petitions
    When I search for petitions with tag "tag 4"
    And I filter the results by tags "tag 4"
    Then I should see the following list of petitions:
          | Petition about something else |
          | Help the homeless             |

  Scenario: When searching for petitions by tag, it returns all petitions also tagged with selected tags
    Given allowed tags in site settings are "tag 1, tag 2, tag 3, tag 4, tag 5"
    And a petition "Raise benefits" exists with tags "tag 1, tag 2"
    And a petition "Help the poor" exists with tags "tag 2, tag 3"
    And a petition "Help the homeless" exists with tags "tag 3, tag 4"
    And a petition "Petition about something else" exists with tags "tag 4, tag 5"
    When I search for petitions with tag "tag 3" from the admin hub
    And I filter the results by tags "tag 2"
    Then I should see the following list of petitions:
          | Help the poor |
    When I search for petitions with tag "tag 2" from the admin hub
    And I filter the results by tags "tag 1, tag 2, tag 3"
    Then I should not see any petitions
    When I search for petitions with tag "tag 4" from the admin hub
    And I filter the results by tags "tag 4"
    Then I should see the following list of petitions:
          | Petition about something else |
          | Help the homeless             |
