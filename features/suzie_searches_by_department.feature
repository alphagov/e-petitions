@departments
Feature: Suzy Signer searches petitions by department
  In order to find interesting petitions to sign for a particular area of goverment
  As Suzy the signer
  I want to look through the petitions for each department

  Scenario: Suzie sees closed petitions
    Given a petition "Spend more money on Defence" belonging to the "Treasury" has been closed
    When I view the closed petitions for the "Treasury"
    Then I should see the petition "Spend more money on Defence"

  Scenario: Suzie see rejected (non-libelous) petitions
    Given a petition "Please bring back Eldorado" has been rejected by the "Treasury"
    When I view the rejected petitions for the "Treasury"
    Then I should see the petition "Please bring back Eldorado"
    And I should see the creation date of the petition
    And I should not see the signature count or the closing date

  Scenario: Suzie does not see libelous and other hidden petitions
    Given a libelous petition "You stink!" has been rejected by the "Treasury"
    When I view the rejected petitions for the "Treasury"
    Then I should not see the petition "You stink!"

  Scenario: Suzie sees comma delimited signature count
    Given a department "DFID" exists with name: "DFID"
    And an open petition exists with title: "Spend more money on Defence", department: department "DFID"
    And the petition "Spend more money on Defence" has 1020 validated signatures
    And all petitions have had their signatures counted
    When I view the open petitions for the "DFID"
    Then I should see the following search results table:
      | Spend more money on Defence View        | 1,020 |

  @search
  Scenario: Suzie searches by department free-text
    Given a set of petitions for the "Treasury"
    And a set of petitions for the "Cabinet Office"
    And sunspot is re-indexed
    When I search for "Treasury"
    Then I should see the petitions belonging to the "Treasury"
    And I should not see the petitions belonging to the "Cabinet Office"

