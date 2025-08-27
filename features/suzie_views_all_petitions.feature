Feature: Suzy Signer views all petitions
  In order to find interesting petitions to sign for a particular area of government
  As Suzy the signer
  I want to look through all the petitions

  Scenario:
    Given a set of petitions
    When I view all petitions from the home page
    Then I should see all petitions
    And the markup should be valid

  Scenario: Suzie browses open petitions
    Given a petition "Free the wombles" exists with a signature count of 500
    And a petition "Force supermarkets to give unsold food to charities" exists with a signature count of 500000
    And a petition "Make every monday bank holiday" exists with a signature count of 1000
    When I browse to see only "Open" petitions
    Then I should see "3 petitions"
    And I should see the following ordered list of petitions:
     | Force supermarkets to give unsold food to charities |
     | Make every monday bank holiday                      |
     | Free the wombles                                    |
    And the markup should be valid

  Scenario: Suzie browses rejected petitions
    Given a petition "Free the wombles" has been rejected
    And a petition "Force supermarkets to give unsold food to charities" has been rejected
    And a petition "Make every monday bank holiday" has been rejected
    When I browse to see only "Rejected" petitions
    Then I should see "3 petitions"
    And I should see the following ordered list of petitions:
     | Make every monday bank holiday                      |
     | Force supermarkets to give unsold food to charities |
     | Free the wombles                                    |
    And the markup should be valid

  Scenario: Suzie browses petitions awaiting a government response
    Given a petition "Abolish bank holidays" exists and hasn’t passed the threshold for a response
    And a petition "Free the wombles" exists and passed the threshold for a response less than a day ago
    And a petition "Force supermarkets to give unsold food to charities" exists and passed the threshold for a response 1 day ago
    And a petition "Make every monday bank holiday" exists and passed the threshold for a response 10 days ago
    When I browse to see only "Awaiting government response" petitions
    Then I should see "3 petitions"
    And I should see the following ordered list of petitions:
     | Make every monday bank holiday                      |
     | Force supermarkets to give unsold food to charities |
     | Free the wombles                                    |
    And the markup should be valid

  Scenario: Suzie browses petitions with a government response
    Given a closed petition "Free the wombles" exists and has received a government response 100 days ago
    And a petition "Force supermarkets to give unsold food to charities" exists and has received a government response 10 days ago
    And a petition "Make every monday bank holiday" exists and has received a government response 1 days ago
    When I browse to see only "Government responses" petitions
    Then I should see "3 petitions"
    And I should see the following ordered list of petitions:
     | Make every monday bank holiday                      |
     | Force supermarkets to give unsold food to charities |
     | Free the wombles                                    |
    And the markup should be valid

  Scenario: Suzie browses petitions which have been debated
    Given a petition "Free the wombles" has been debated yesterday
    And a petition "Ban Badger Baiting" has been debated 2 days ago
    And a petition "Spend more money on Defence" has been debated 18 days ago
    And a petition "Force supermarkets to give unsold food to charities" has been debated 234 days ago
    And a petition "Make every monday bank holiday" exists
    When I browse to see only "Debated in Parliament" petitions
    Then I should see "4 petitions"
    Then I should see the following ordered list of petitions:
     | Free the wombles                                    |
     | Ban Badger Baiting                                  |
     | Spend more money on Defence                         |
     | Force supermarkets to give unsold food to charities |
    And the markup should be valid

  Scenario: Suzie browses petitions awaiting a debate in Parliament
    Given a petition "Save the planet" exists and hasn’t passed the threshold for a debate
    And a petition "Conquer the Moon" passed the threshold for a debate less than a day ago and has no debate date set
    And a petition "Free the wombles" passed the threshold for a debate 10 days ago and has no debate date set
    And a petition "Travel to the stars" passed the threshold for a debate 2 days ago and has a debate in 2 days
    When I browse to see only "Awaiting a debate in Parliament" petitions
    Then I should see the following ordered list of petitions:
      | Travel to the stars |
      | Free the wombles    |
      | Conquer the Moon    |
    And the markup should be valid

  Scenario: Suzie browses open petitions and can see numbering in the list view
    Given a set of 101 petitions
    When I view all petitions from the home page
    Then I should see "2 of 3"
    And I navigate to the next page of petitions
    Then I should see "1 of 3"
    And I should see "3 of 3"
    And I navigate to the next page of petitions
    Then I should see "2 of 3"

  Scenario: Downloading the JSON data for petitions
    Given a set of petitions
    And I am on the all petitions page
    Then I should see all petitions
    And the markup should be valid
    When I click the JSON link
    Then I should be on the all petitions JSON page
    And the JSON should be valid

  Scenario: Downloading the CSV data for petitions
    Given a set of petitions
    And I am on the all petitions page
    Then I should see all petitions
    And the markup should be valid
    When I click the CSV link
    Then I should get a download with the filename "all-petitions.csv"
