Feature: Freya searches petitions by constituency
  In order to see what petitions are relevant to other people in my constituency
  As Freya, a member of the general public
  I want to use my postcode to find my constituency and see petitions with signatures from people who also live in it

  Background:
    Given a constituency "South Dorset" with MP "Emma Pee MP" is found by postcode "BH20 6HH"
    And a constituency "Rochester and Strood" is found by postcode "ME2 2NU"
    And an open petition "Save the monkeys" with some signatures
    And an open petition "Restore vintage diggers" with some signatures
    And an open petition "Build more quirky theme parks" with some signatures
    And a closed petition "What about other primates?" with some signatures
    And a constituent in "Rochester and Strood" supports "Restore vintage diggers"
    And few constituents in "South Dorset" support "Save the monkeys"
    And some constituents in "South Dorset" support "Build more quirky theme parks"
    And many constituents in "Rochester and Strood" support "Build more quirky theme parks"
    And a constituent in "South Dorset" supports "What about other primates?"

  Scenario: Searching for local petitions
    Given I am on the home page
    When I search for petitions local to me in "BH20 6HH"
    Then I should be on the local petitions results page
    And the markup should be valid
    And I should see "Petitions in South Dorset" in the browser page title
    And I should see "Popular open petitions in the constituency of South Dorset"
    And I should see a link to view all local petitions
    And I should see a link to the MP for my constituency
    And I should see that my fellow constituents support "Save the monkeys"
    And I should see that my fellow constituents support "Build more quirky theme parks"
    But I should not see that my fellow constituents support "What about other primates?"
    And I should not see that my fellow constituents support "Restore vintage diggers"
    And the petitions I see should be ordered by my fellow constituents level of support
    When I click the view all local petitions
    Then I should be on the all local petitions results page
    And the markup should be valid
    And I should see "Popular petitions in the constituency of South Dorset"
    And I should see a link to view open local petitions
    And I should see that my fellow constituents support "What about other primates?"
    And I should see that closed petitions are identified
    And the petitions I see should be ordered by my fellow constituents level of support

  Scenario: Downloading the JSON data for open local petitions
    Given I am on the home page
    When I search for petitions local to me in "BH20 6HH"
    Then I should be on the local petitions results page
    And the markup should be valid
    When I click the JSON link
    Then I should be on the local petitions JSON page
    And the JSON should be valid

  Scenario: Downloading the JSON data for all local petitions
    Given I am on the home page
    When I search for petitions local to me in "BH20 6HH"
    Then I should be on the local petitions results page
    And the markup should be valid
    When I click the view all local petitions
    Then I should be on the all local petitions results page
    And the markup should be valid
    When I click the JSON link
    Then I should be on the all local petitions JSON page
    And the JSON should be valid

  Scenario: Downloading the CSV data for open local petitions
    Given I am on the home page
    When I search for petitions local to me in "BH20 6HH"
    Then I should be on the local petitions results page
    And the markup should be valid
    When I click the CSV link
    Then I should get a download with the filename "open-popular-petitions-in-south-dorset.csv"

  Scenario: Downloading the CSV data for all local petitions
    Given I am on the home page
    When I search for petitions local to me in "BH20 6HH"
    Then I should be on the local petitions results page
    And the markup should be valid
    When I click the view all local petitions
    Then I should be on the all local petitions results page
    And the markup should be valid
    When I click the CSV link
    Then I should get a download with the filename "all-popular-petitions-in-south-dorset.csv"

  Scenario: Searching for local petitions when the api is down
    Given the constituency api is down
    And I am on the home page
    When I search for petitions local to me in "BH20 6HH"
    Then the markup should be valid
    But I should see an explanation that my constituency couldn’t be found

  Scenario: Searching for local petitions when the no-one in my constituency is engaged
    Given a constituency "South Northamptonshire" is found by postcode "NN13 5QD"
    And I am on the home page
    When I search for petitions local to me in "NN13 5QD"
    Then the markup should be valid
    But I should see an explanation that there are no petitions popular in my constituency

  Scenario: Searching for local petitions when the mp has passed away
    Given a constituency "Sheffield, Brightside and Hillsborough" with MP "Harry Harpham" is found by postcode "S4 8AA"
    And the MP has passed away
    When I am on the home page
    And I search for petitions local to me in "S4 8AA"
    Then the markup should be valid
    And I should not see a link to the MP for my constituency

  Scenario: Downloading the JSON data for open local petitions when the mp has passed away
    Given a constituency "Sheffield, Brightside and Hillsborough" with MP "Harry Harpham" is found by postcode "S4 8AA"
    And the MP has passed away
    When I am on the home page
    And I search for petitions local to me in "S4 8AA"
    Then the markup should be valid
    When I click the JSON link
    Then I should be on the local petitions JSON page
    And the JSON should be valid

  Scenario: Downloading the JSON data for all local petitions when the mp has passed away
    Given a constituency "Sheffield, Brightside and Hillsborough" with MP "Harry Harpham" is found by postcode "S4 8AA"
    And the MP has passed away
    When I am on the home page
    And I search for petitions local to me in "S4 8AA"
    Then the markup should be valid
    When I click the view all local petitions
    Then I should be on the all local petitions results page
    And the markup should be valid
    When I click the JSON link
    Then I should be on the all local petitions JSON page
    And the JSON should be valid

  Scenario: Downloading the CSV data for local petitions when the mp has passed away
    Given a constituency "Sheffield, Brightside and Hillsborough" with MP "Harry Harpham" is found by postcode "S4 8AA"
    And the MP has passed away
    When I am on the home page
    And I search for petitions local to me in "S4 8AA"
    Then the markup should be valid
    When I click the CSV link
    Then I should get a download with the filename "open-popular-petitions-in-sheffield-brightside-and-hillsborough.csv"

  Scenario: Downloading the CSV data for local petitions when the mp has passed away
    Given a constituency "Sheffield, Brightside and Hillsborough" with MP "Harry Harpham" is found by postcode "S4 8AA"
    And the MP has passed away
    When I am on the home page
    And I search for petitions local to me in "S4 8AA"
    Then the markup should be valid
    When I click the view all local petitions
    Then I should be on the all local petitions results page
    And the markup should be valid
    When I click the CSV link
    Then I should get a download with the filename "all-popular-petitions-in-sheffield-brightside-and-hillsborough.csv"
