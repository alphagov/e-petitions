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

    # waiting for govts response
    And a petition "Force supermarkets to give unsold food to charities" exists and passed the threshold for a response 1 day ago
    And a petition "Make every monday bank holiday" exists and passed the threshold for a response 10 days ago

    # having a govt response
    Given a petition "Spend more money on defence" exists and has received a government response 10 days ago
    Given a petition "Save the city foxes" exists and has received a government response 1 days ago

    # debated
    Given a petition "Ban Badger Baiting" has been debated 2 days ago
    Given a petition "Leave EU" has been debated 18 days ago

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
    When I go to the petitions page
    And I fill in "Wombles" as my search term
    And I press "Search"
    Then I should see an "open" petition count of 12
    Then I should see a "closed" petition count of 1
    Then I should see a "rejected" petition count of 1

  Scenario: Search for open petitions using multiple search terms
    When I search for "Open petitions" with "overthrow the"
    Then I should see the following search results:
      | Overthrow the Wombles | 1 signature |

  Scenario: Search for rejected petitions
    When I search for "Rejected petitions" with "WOMBLES"
    Then I should see the following search results:
      | Eavis vs the Wombles |

  Scenario: Search for closed petitions
    When I search for "Closed petitions" with "WOMBLES"
    Then I should see the following search results:
      | The Wombles will rock Glasto | 1 signature          |

  Scenario: Search for petitions awaiting a goverment response
    When I search for "Awaiting a government response" with "Monday"
    Then I should see the following search results:
      | Make every monday bank holiday | 1 signature |

  Scenario: Search for petitions having a goverment response
    When I search for "Government responses" with "foxes"
    Then I should see the following search results:
      | Save the city foxes            | 1 signature |

  Scenario: Search for petitions debated in Parliament
    When I search for "Petitions debated in Parliament" with "EU"
    Then I should see the following search results:
      | Leave EU                        | 1 signature |

  Scenario: Paginate through open petitions
    Given 51 open petitions exist with action: "International development spending"
    When I search for "Open petitions" with "International"
    And I follow "Next"
    Then I should see 1 petition
    And I follow "Previous"
    Then I should see 50 petitions
