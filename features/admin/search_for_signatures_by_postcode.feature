@admin
Feature: Searching for signatures as Terry
  In order to easily find out if someone’s signed a petition
  As Terry
  I would like to be able to enter a postcode, and see all signatures associated with it

  Scenario: A user can search for signatures by postcode
    Given 2 petitions signed in "RG1 9ZZ"
    And I am logged in as a moderator
    When I search for petitions signed in "RG1 9ZZ"
    Then I should see 2 petitions associated with the postcode

  Scenario: A user can search for signatures by postcode from the admin hub
    Given 2 petitions signed in "RG1 9ZZ"
    And I am logged in as a moderator
    When I search for petitions signed in "RG1 9ZZ" from the admin hub
    Then I should see 2 petitions associated with the postcode

  Scenario: A user can search for signatures by sector
    Given 1 petition signed in "RG1 1AA"
    And 1 petition signed in "RG1 9ZZ"
    And I am logged in as a moderator
    When I search for petitions signed in "RG1 XXX"
    Then I should see 2 petitions associated with the sector

  Scenario: A user can search for signatures by postcode from the admin hub
    Given 1 petition signed in "RG1 1AA"
    And 1 petition signed in "RG1 9ZZ"
    And I am logged in as a moderator
    When I search for petitions signed in "RG1 XXX" from the admin hub
    Then I should see 2 petitions associated with the sector
