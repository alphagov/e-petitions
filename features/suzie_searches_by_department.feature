@departments
Feature: Suzy Signer searches petitions by department
  In order to find interesting petitions to sign for a particular area of goverment
  As Suzy the signer
  I want to look through the petitions for each department

  Scenario:
    Given a set of petitions for the "Treasury"
    When I browse petitions by department
    Then I should see a list of all the departments
    And the markup should be valid
    And I should see "Search by department - e-petitions" in the browser page title
    When I view the open petitions for the "Treasury"
    And I should see "Treasury - e-petitions" in the browser page title
    And I should see the petitions belonging to the "Treasury"
    And the search results table should have the caption "Open e-petitions owned by the Treasury"
    And I should see an "open" petition count of 3
    And I should see a "closed" petition count of 0
    And I should see a "rejected" petition count of 0

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

  Scenario: Suzie doesn't know about the departments and browses the department info without javascript
    Given a department "Area 51" exists with name: "Area 51", description: "Department for the regulation of alien traffic."
    Given a department "Area 101" exists with name: "Area 101", description: "Things disappear here."
    When I go to the departments page
    Then I should see "Department for the regulation of alien traffic."
    And I should see "Things disappear here."


  @javascript
  Scenario: Suzie doesn't know about the departments and browses the department info with javascript
    Given a department "Area 51" exists with name: "Area 51", description: "Department for the regulation of alien traffic.", website_url: "http://www.example.com"
    Given a department "Area 101" exists with name: "Area 101", description: "Things disappear here."
    When I go to the departments page
    Then I should not see "Department for the regulation of alien traffic."
    And I should not see "Things disappear here."
    When I press the info button next to the department "Area 51"
    Then I should see "http://www.example.com"
    And I should see "Department for the regulation of alien traffic."
    # Capybara/envjs error stops this test going further.
    # When I press "Close" within "//*[class='lightbox']"
    # Then I should not see "Department for the regulation of alien traffic."
    # When I press the info button next to the department "Area 101"
    # Then I should see "Things disappear here."

  @search
  Scenario: Suzie searches by department free-text
    Given a set of petitions for the "Treasury"
    And a set of petitions for the "Cabinet Office"
    And sunspot is re-indexed
    When I search for "Treasury"
    Then I should see the petitions belonging to the "Treasury"
    And I should not see the petitions belonging to the "Cabinet Office"

