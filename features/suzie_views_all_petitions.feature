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
    Then I should see "3 petitions"
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
    Then I should see "3 petitions"
    Then I should see the following ordered list of petitions:
     | Make every monday bank holiday                      |
     | Force supermarkets to give unsold food to charities |
     | Free the wombles                                    |
    And the markup should be valid

  Scenario: Suzie browses petitions awaiting a goverment response
    Given a petition "Abolish bank holidays" exists and hasn't passed the threshold for a response
    Given a petition "Free the wombles" exists and passed the threshold for a response less than a day ago
    Given a petition "Force supermarkets to give unsold food to charities" exists and passed the threshold for a response 1 day ago
    Given a petition "Make every monday bank holiday" exists and passed the threshold for a response 10 days ago
    When I view all petitions from the home page
    And I follow "Awaiting government response"
    Then I should see "3 petitions"
    Then I should see the following ordered list of petitions:
     | Make every monday bank holiday                      |
     | Force supermarkets to give unsold food to charities |
     | Free the wombles                                    |
    And the markup should be valid

  Scenario: Suzie browses petitions with a goverment response
    Given a closed petition "Free the wombles" exists and has received a government response 100 days ago
    Given a petition "Force supermarkets to give unsold food to charities" exists and has received a government response 10 days ago
    Given a petition "Make every monday bank holiday" exists and has received a government response 1 days ago
    When I view all petitions from the home page
    And I follow "Government responses"
    Then I should see "3 petitions"
    Then I should see the following ordered list of petitions:
     | Make every monday bank holiday                      |
     | Force supermarkets to give unsold food to charities |
     | Free the wombles                                    |
    And the markup should be valid

  Scenario: Suzie browses petitions which have been debated
    Given a petition "Ban Badger Baiting" has been debated 2 days ago
    Given a petition "Spend more money on Defence" has been debated 18 days ago
    Given a petition "Force supermarkets to give unsold food to charities" has been debated 234 days ago
    Given a petition "Make every monday bank holiday" exists
    When I view all petitions from the home page
    And I follow "Petitions debated in Parliament"
    Then I should see "3 petitions"
    Then I should see the following ordered list of petitions:
     | Ban Badger Baiting                                  |
     | Spend more money on Defence                         |
     | Force supermarkets to give unsold food to charities |
    And the markup should be valid

  Scenario: Suzie browses petitions awaiting a debate in Parliament
    Given a petition "Save the planet" exists and hasn't passed the threshold for a debate
    Given a petition "Conquer the Moon" passed the threshold for a debate less than a day ago and has no debate date set
    Given a petition "Free the wombles" passed the threshold for a debate 10 days ago and has no debate date set
    When I view all petitions from the home page
    And I follow "Petitions waiting for a debate in Parliament"
    Then I should see the following ordered list of petitions:
      | Free the wombles |
      | Conquer the Moon |
    And the markup should be valid

