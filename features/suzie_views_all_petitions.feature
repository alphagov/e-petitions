Feature: Suzy Signer views all petitions
  In order to find interesting petitions to sign for a particular area of goverment
  As Suzy the signer
  I want to look through all the petitions

  @departments
  Scenario:
    Given a set of petitions for the "Treasury"
    And a set of petitions for the "Cabinet Office"
    When I view all petitions from the home page
    Then I should see petitions for all departments
    And the markup should be valid
