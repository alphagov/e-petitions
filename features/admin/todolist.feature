Feature: Dashboard todo list
  In order to see the priority items as well as petitions that are still collecting sponsors
  I can see a list of sponsored petitions that need moderation as a default list on my todo list page
  And I can filter to see a list of petitions that are collecting sponsors

  Background:
    Given I am logged in as a moderator
    And a petition "p1" exists with action: "Petition 1", state: "sponsored", created_at: "2009-02-10"
    And an open petition "p2" exists with action: "Petition 2", created_at: "2008-10-09"
    And a petition "p3" exists with action: "Petition 3", state: "sponsored", created_at: "2010-11-11"
    And a petition "p4" exists with action: "Petition 4", state: "sponsored", created_at: "2010-01-01"
    And a rejected petition "p5" exists with action: "Petition 5", created_at: "2007-01-01"
    And a validated petition "p6" exists with action: "Petition 6", created_at: "2015-01-01"
    And the petition "Petition 6" has 4 validated signatures
    And the petition "Petition 6" has reached maximum amount of sponsors
    And a validated petition "p7" exists with action: "Petition 7", created_at: "2015-02-01"
    And the petition "Petition 7" has 4 validated signatures
    And the petition "Petition 7" has 10 pending sponsors
    And a pending petition "p8" exists with action: "Petition 8", created_at: "2015-03-01"
    And the petition "Petition 8" has 0 validated signatures
    And the petition "Petition 8" has reached maximum amount of sponsors

  Scenario: I can see all petitions that need moderation
    When I go to the admin todolist page
    Then I should see the following admin index table:
      | Action     | Date       |
      | Petition 1 | 10-02-2009 |
      | Petition 4 | 01-01-2010 |
      | Petition 3 | 11-11-2010 |
  And I should be connected to the server via an ssl connection
  And the markup should be valid

  Scenario: Petitions waiting for moderation are paginated
    Given 50 petitions exist with state: "sponsored"
    When I go to the admin todolist page
    And I follow "Next"
    Then I should see 3 rows in the admin index table
    And I follow "Previous"
    And I should see 50 rows in the admin index table

  Scenario: Filter list by state
    When I go to the admin todolist page
    And I select the option to view "collecting sponsors" petitions
    Then I should see the following admin index table:
      | Action     | Date       |
      | Petition 6 | 01-01-2015 |
      | Petition 7 | 01-02-2015 |
      | Petition 8 | 01-03-2015 |
    And I should be connected to the server via an ssl connection
    And the markup should be valid
