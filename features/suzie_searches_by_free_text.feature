@search
Feature: Suzy Singer searches by free text
  In order to find interesting petitions to sign for a particular area of goverment
  As Suzy the signer
  I want to search against petition action, background, supporting details

  Background:
    Given the date is the "21 April 2011 12:00"
    And a pending petition exists with action: "Wombles are great"
    And a validated petition exists with action: "The Wombles of Wimbledon"
    And an open petition exists with action: "Uncle Bulgaria", additional_details: "The Wombles are here", closed_at: "1 minute from now"
    And an open petition exists with action: "Common People", background: "The Wombles belong to us all", closed_at: "11 days from now"
    And an open petition exists with action: "Overthrow the Wombles", closed_at: "1 year from now"
    And a closed petition exists with action: "The Wombles will rock Glasto", closed_at: "1 minute ago"
    And a rejected petition exists with action: "Eavis vs the Wombles"
    And a hidden petition exists with action: "The Wombles are profane"
    And an open petition exists with action: "Wombles", closed_at: "10 days from now"

  Scenario: Search for open petitions
    When I go to the petitions page
    And I follow "Open petitions"
    And I fill in "Wombles" as my search term
    And I press "Search"
    Then I should see my search term "Wombles" filled in the search field
    And I should see "4 results"
    And I should not see "Wombles are great"
    And I should not see "The Wombles of Wimbledon"
    But I should see the following search results:
      | Wombles                            | 1 signature |
      | Overthrow the Wombles              | 1 signature |
      | Uncle Bulgaria                     | 1 signature |
      | Common People                      | 1 signature |
    And the markup should be valid

  Scenario: See search counts
    When I search for "all" petitions with "Wombles"
    Then I should see an "open" petition count of 4
    Then I should see a "closed" petition count of 1
    Then I should see a "rejected" petition count of 1

  Scenario: Search for open petitions using multiple search terms
    When I search for "open" petitions with "overthrow the"
    Then I should see the following search results:
      | Overthrow the Wombles | 1 signature |

  Scenario: Search for rejected petitions
    When I search for "rejected" petitions with "WOMBLES"
    Then I should see the following search results:
      | Eavis vs the Wombles |

  Scenario: Search for closed petitions
    When I search for "closed" petitions with "WOMBLES"
    Then I should see the following search results:
      | The Wombles will rock Glasto | 1 signature          |

  Scenario: Paginate through open petitions
    Given 51 open petitions exist with action: "International development spending"
    When I search for "open" petitions with "spending"
    And I follow "Next"
    Then I should see 1 petition
    And I follow "Previous"
    Then I should see 50 petitions

  Scenario: Searching for a profane search term
    When I search for "hidden" petitions with "profane"
    Then I should see "No petitions could be found matching your search terms."
