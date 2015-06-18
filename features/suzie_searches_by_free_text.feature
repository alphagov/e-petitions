@search
Feature: Suzy Singer searches by free text
  In order to find interesting petitions to sign for a particular area of goverment
  As Suzy the signer
  I want to search against petition title, action, description

  Background:
    Given the date is the "21 April 2011 12:00"
    And a pending petition exists with title: "Wombles are great"
    And a validated petition exists with title: "The Wombles of Wimbledon"
    And an open petition exists with title: "Uncle Bulgaria", additional_details: "The Wombles are here", closed_at: "1 minute from now"
    And an open petition exists with title: "Common People", action: "The Wombles belong to us all", closed_at: "11 days from now"
    And an open petition exists with title: "Overthrow the Wombles", closed_at: "1 year from now"
    And a closed petition exists with title: "The Wombles will rock Glasto", closed_at: "1 minute ago"
    And a rejected petition exists with title: "Eavis vs the Wombles"
    And a hidden petition exists with title: "The Wombles are profane"
    And an open petition exists with title: "Wombles", closed_at: "10 days from now"
    And all petitions have had their signatures counted

  Scenario: Search for open petitions
    When I search for "Wombles"
    Then I should be on the search results page
    And I should see "Search results - Petitions" in the browser page title
    And I should see /For "Wombles"/
    And I should not see "Wombles are great"
    And I should not see "The Wombles of Wimbledon"
    But I should see the following search results:
      | Wombles                            | 1 signature |
      | Overthrow the Wombles              | 1 signature |
      | Uncle Bulgaria                     | 1 signature |
      | Common People                      | 1 signature |
    And the markup should be valid

  Scenario: See search counts
    When I search for "Wombles"
    Then I should see an "open" petition count of 4
    Then I should see a "closed" petition count of 1
    Then I should see a "rejected" petition count of 1

  Scenario: Search for open petitions using multiple search terms
    When I search for "overthrow the"
    Then I should see the following search results:
      | Overthrow the Wombles | 1 signature |

  Scenario: Search for special lucene characters to ensure they are escaped correctly
    When I search for "+ -|| ! && Common () { } [ ] ^ ~ * ? : \\"
    Then I should see the following search results:
      | Common People | 1 signature |

  Scenario: Search for rejected petitions
    When I go to the search page
    And I search for "rejected" petitions with "WOMBLES"
    Then I should see the following search results:
      | Eavis vs the Wombles |

  Scenario: Search for closed petitions
    When I go to the search page
    And I search for "closed" petitions with "WOMBLES"
    Then I should see the following search results:
      | The Wombles will rock Glasto | 1 signature          |

  Scenario: Search for open petitions and order by title
    When I go to the search page
    And I search for "open" petitions with "WOMBLES" ordered by "title"
    Then I should see the following search results:
      | Common People         |
      | Overthrow the Wombles |
      | Uncle Bulgaria        |
      | Wombles               |

  Scenario: Search for open petitions and order by signature count
    Given the petition "Uncle Bulgaria" has 5 validated and 3 pending signatures
    And the petition "Wombles" has 2 validated and 20 pending signatures
    And the petition "Common People" has 10 validated and 10 pending signatures
    And the petition "Overthrow the Wombles" has 4 validated and 0 pending signatures
    And all petitions have had their signatures counted
    When I go to the search page
    And I search for "open" petitions with "WOMBLES" ordered by "count"
    Then I should see the following search results:
      | Common People         | 10 signatures         |
      | Uncle Bulgaria        | 5 signatures          |
      | Overthrow the Wombles | 4 signatures          |
      | Wombles               | 2 signatures          |

  Scenario: Search for open petitions and order by signature count asc
    Given the petition "Uncle Bulgaria" has 5 validated and 3 pending signatures
    And the petition "Wombles" has 2 validated and 20 pending signatures
    And the petition "Common People" has 10 validated and 10 pending signatures
    And the petition "Overthrow the Wombles" has 4 validated and 0 pending signatures
    And all petitions have had their signatures counted
    When I go to the search page
    And I search for "open" petitions with "WOMBLES" ordered by "count asc"
    Then I should see the following search results:
      | Wombles               | 2 signatures          |
      | Overthrow the Wombles | 4 signatures          |
      | Uncle Bulgaria        | 5 signatures          |
      | Common People         | 10 signatures         |

  Scenario: Search for open petitions and order by closing date
    When I go to the search page
    And I search for "open" petitions with "WOMBLES" ordered by "closing"
    Then I should see the following search results:
      | Uncle Bulgaria        |
      | Wombles               |
      | Common People         |
      | Overthrow the Wombles |

  Scenario: Search for open petitions and order by closing date desc
    When I go to the search page
    And I search for "open" petitions with "WOMBLES" ordered by "closing desc"
    Then I should see the following search results:
      | Overthrow the Wombles |
      | Common People         |
      | Wombles               |
      | Uncle Bulgaria        |

  Scenario: Paginate through open petitions
    Given 51 open petitions exist with title: "International development spending"
    When I go to the search page
    And I search for "open" petitions with "spending"
    And I follow "Next"
    Then I should see 1 petition
    And I follow "Previous"
    Then I should see 50 petitions

  Scenario: Searching for a profane search term
    When I go to the search page
    And I search for "hidden" petitions with "profane"
    Then I should see "No petitions could be found matching your search terms."
