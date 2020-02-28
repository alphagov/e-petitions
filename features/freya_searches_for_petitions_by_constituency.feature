Feature: Freya searches petitions by constituency
  In order to see what petitions are relevant to other people in my constituency
  As Freya, a member of the general public
  I want to use my postcode to find my constituency and see petitions with signatures from people who also live in it

  Background:
    Given a constituency "Monmouth" with Member "Nick Ramsay AM" is found by postcode "NP6 5YE"
    And a constituency "Pontypridd" is found by postcode "CF15 7QE"
    And an open petition "Save the monkeys" with some signatures
    And an open petition "Restore vintage diggers" with some signatures
    And an open petition "Build more quirky theme parks" with some signatures
    And a closed petition "What about other primates?" with some signatures
    And a constituent in "Pontypridd" supports "Restore vintage diggers"
    And few constituents in "Monmouth" support "Save the monkeys"
    And some constituents in "Monmouth" support "Build more quirky theme parks"
    And many constituents in "Pontypridd" support "Build more quirky theme parks"
    And a constituent in "Monmouth" supports "What about other primates?"

  Scenario: Searching for local petitions
    Given I am on the home page
    When I search for petitions local to me in "NP6 5YE"
    Then I should be on the local petitions results page
    And the markup should be valid
    And I should see "Petitions in Monmouth" in the browser page title
    And I should see "Popular open petitions in the constituency of Monmouth"
    And I should see a link to view all local petitions
    And I should see a link to the Member for my constituency
    And I should see that my fellow constituents support "Save the monkeys"
    And I should see that my fellow constituents support "Build more quirky theme parks"
    But I should not see that my fellow constituents support "What about other primates?"
    And I should not see that my fellow constituents support "Restore vintage diggers"
    And the petitions I see should be ordered by my fellow constituents level of support
    When I click the view all local petitions
    Then I should be on the all local petitions results page
    And the markup should be valid
    And I should see "Popular petitions in the constituency of Monmouth"
    And I should see a link to view open local petitions
    And I should see that my fellow constituents support "What about other primates?"
    And I should see that closed petitions are identified
    And the petitions I see should be ordered by my fellow constituents level of support

  Scenario: Downloading the JSON data for open local petitions
    Given I am on the home page
    When I search for petitions local to me in "NP6 5YE"
    Then I should be on the local petitions results page
    And the markup should be valid
    When I click the JSON link
    Then I should be on the local petitions JSON page
    And the JSON should be valid

  Scenario: Downloading the JSON data for all local petitions
    Given I am on the home page
    When I search for petitions local to me in "NP6 5YE"
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
    When I search for petitions local to me in "NP6 5YE"
    Then I should be on the local petitions results page
    And the markup should be valid
    When I click the CSV link
    Then I should get a download with the filename "open-popular-petitions-in-monmouth.csv"

  Scenario: Downloading the CSV data for all local petitions
    Given I am on the home page
    When I search for petitions local to me in "NP6 5YE"
    Then I should be on the local petitions results page
    And the markup should be valid
    When I click the view all local petitions
    Then I should be on the all local petitions results page
    And the markup should be valid
    When I click the CSV link
    Then I should get a download with the filename "all-popular-petitions-in-monmouth.csv"

  Scenario: Searching for local petitions when the no-one in my constituency is engaged
    Given a constituency "Llanelli" is found by postcode "CF478YN"
    And I am on the home page
    When I search for petitions local to me in "CF478YN"
    Then the markup should be valid
    But I should see an explanation that there are no petitions popular in my constituency

  Scenario: Searching for local petitions when the member has passed away
    Given a constituency "Rhondda" with Member "Harry Harpham" is found by postcode "CF40 2YN"
    And the Member has passed away
    When I am on the home page
    And I search for petitions local to me in "CF40 2YN"
    Then the markup should be valid
    And I should not see a link to the Member for my constituency

  Scenario: Downloading the JSON data for open local petitions when the member has passed away
    Given a constituency "Rhondda" with Member "Harry Harpham" is found by postcode "CF40 2YN"
    And the Member has passed away
    When I am on the home page
    And I search for petitions local to me in "CF40 2YN"
    Then the markup should be valid
    When I click the JSON link
    Then I should be on the local petitions JSON page
    And the JSON should be valid

  Scenario: Downloading the JSON data for all local petitions when the member has passed away
    Given a constituency "Rhondda" with Member "Harry Harpham" is found by postcode "CF40 2YN"
    And the Member has passed away
    When I am on the home page
    And I search for petitions local to me in "CF40 2YN"
    Then the markup should be valid
    When I click the view all local petitions
    Then I should be on the all local petitions results page
    And the markup should be valid
    When I click the JSON link
    Then I should be on the all local petitions JSON page
    And the JSON should be valid

  Scenario: Downloading the CSV data for local petitions when the member has passed away
    Given a constituency "Rhondda" with Member "Harry Harpham" is found by postcode "CF40 2YN"
    And the Member has passed away
    When I am on the home page
    And I search for petitions local to me in "CF40 2YN"
    Then the markup should be valid
    When I click the CSV link
    Then I should get a download with the filename "open-popular-petitions-in-rhondda.csv"

  Scenario: Downloading the CSV data for local petitions when the member has passed away
    Given a constituency "Rhondda" with Member "Harry Harpham" is found by postcode "CF40 2YN"
    And the Member has passed away
    When I am on the home page
    And I search for petitions local to me in "CF40 2YN"
    Then the markup should be valid
    When I click the view all local petitions
    Then I should be on the all local petitions results page
    And the markup should be valid
    When I click the CSV link
    Then I should get a download with the filename "all-popular-petitions-in-rhondda.csv"
