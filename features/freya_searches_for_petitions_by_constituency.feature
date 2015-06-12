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
    And I should see a link to the MP for my constituency
    And I should see that my fellow constituents support "Save the monkeys"
    And I should see that my fellow constituents support "Build more quirky theme parks"
    But I should not see that my fellow constituents support "What about other primates?"
    And I should not see that my fellow constituents support "Restore vintage diggers"
    And the petitions I see should be ordered by my fellow constituents level of support

  Scenario: Searching for local petitions when the api is down
    Given the constituency api is down
    And I am on the home page
    When I search for petitions local to me in "BH20 6HH"
    Then the markup should be valid
    But I should see an explanation that my constituency couldn't be found
