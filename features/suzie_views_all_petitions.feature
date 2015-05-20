Feature: Suzy Signer views all petitions
  In order to find interesting petitions to sign for a particular area of goverment
  As Suzy the signer
  I want to look through all the petitions

  Scenario:
    Given a set of petitions
    When I view all petitions from the home page
    Then I should see all petitions
    And the markup should be valid
