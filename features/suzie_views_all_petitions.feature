Feature: Suzy Signer views all petitions
  In order to find interesting petitions to sign for a particular area of goverment
  As Suzy the signer
  I want to look through all the petitions

  Scenario:
    Given a set of petitions
    When I view all petitions from the home page
    Then I should see all petitions
    And the markup should be valid

  Scenario: Suzie browses open petitions
    Given a petition "Free the wombles" exists with a signature count of 500
    Given a petition "Force supermarkets to give unsold food to charities" exists with a signature count of 500000
    Given a petition "Make every monday bank holiday" exists with a signature count of 1000
    When I view all petitions from the home page
    Then I should see the following ordered list of petitions:
     | Force supermarkets to give unsold food to charities |
     | Make every monday bank holiday                      |
     | Free the wombles                                    |
    And the markup should be valid

  Scenario: Suzie browses rejected petitions
    Given a petition "Free the wombles" has been rejected
    Given a petition "Force supermarkets to give unsold food to charities" has been rejected
    Given a petition "Make every monday bank holiday" has been rejected
    When I view all petitions from the home page
    And I follow "Rejected"
    Then I should see the following ordered list of petitions:
     | Free the wombles                                    |
     | Force supermarkets to give unsold food to charities |
     | Make every monday bank holiday                      |
    And the markup should be valid
