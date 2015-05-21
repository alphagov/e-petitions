Feature: A moderator user views all petitions
  In order to see a full list of all the petitions
  As any moderator user
  I want to view a paginated list of Open, Rejected and Closed petitions, sorted by signature count (descending), then most recent. I want to be able to filter this list by state and follow links to change petition details.

  Background:
    Given I am logged in as a moderator

  Scenario: Viewing all petitions
    Given a set of petitions
    When I view all petitions
    And the markup should be valid

  Scenario: Follow links to change details
    Given a petition "My petition"
    When I view all petitions
    And I view the petition
    Then I should see the petition details

  Scenario: Can see hidden petitions
    Given a libelous petition "You suck!" has been rejected
    When I view all petitions
    Then I should see the petition "You suck!"

  Scenario: Cannot see pending or validated petitions
    Given a pending petition "My pending petition"
    And a validated petition "My validated petition"
    When I view all petitions
    Then I should not see the petition "My pending petition"
    Then I should not see the petition "My validation petition"

  Scenario: Filter list by state
    Given a petition "My open petition"
    And a libelous petition "You suck!" has been rejected
    When I view all petitions
    And I filter the list to show "open" petitions
    Then I should not see any "rejected" petitions
    When I filter the list to show "rejected" petitions
    Then I should not see any "open" petitions

  @javascript
  Scenario: Change number per page
    Given I am logged in as a sysadmin
    And 25 petitions exist with a signature count of 5
    When I view all petitions
    Then I should see a list of 20 petitions
    When I change the number viewed per page to 50
    And I press "Go"
    Then I should see a list of 25 petitions

  Scenario: A sysadmin can view all petitions
    Given I am logged in as a sysadmin
    And an open petition exists with title: "Simply the best"
    When I view all petitions
    Then I should see "Simply the best"

  Scenario: A moderator user can view all petitions
    Given I am logged in as a moderator
    And an open petition exists with title: "Simply the best"
    When I view all petitions
    Then I should see "Simply the best"
