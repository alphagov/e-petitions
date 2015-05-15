@search
Feature: Suzy Singer searches by free text
  In order to find interesting petitions to sign for a particular area of goverment
  As Suzy the signer
  I want to search against petition title, description and creator name

  Background:
    Given the date is the "21 April 2011 12:00"
    And a pending petition exists with title: "Wombles are great"
    And a validated petition exists with title: "The Wombles of Wimbledon"
    And an open petition exists with title: "Uncle Bulgaria", description: "The Wombles are here", closed_at: "1 minute from now"
    And a validated signature "creator" exists with name: "Mr Wombles"
    And an open petition exists with title: "Common People", creator_signature: signature "creator", closed_at: "11 days from now"
    And an open petition exists with title: "Overthrow the Wombles", closed_at: "1 year from now"
    And a closed petition exists with title: "The Wombles will rock Glasto", closed_at: "1 minute ago"
    And a rejected petition exists with title: "Eavis vs the Wombles"
    And a hidden petition exists with title: "The Wombles are profane"
    And an open petition exists with title: "Wombles", closed_at: "10 days from now"
    And sunspot is re-indexed
    And all petitions have had their signatures counted

  Scenario: Search for open petitions
    When I go to the home page
    And I fill in "search" with "Wombles"
    And I press "Search"
    Then I should be on the search results page
    And I should see "Search results - e-petitions" in the browser page title
    And I should see /For "Wombles"/
    And I should see "Listed below are any e-petitions that can be signed"
    And the "Open" tab should be active
    And I should not see "Wombles are great"
    And I should not see "The Wombles of Wimbledon"
    But I should see the following search results table:
      | Wombles View                            | 1                                       | 01/05/2011              |
      | Overthrow the Wombles View              | 1                                       | 21/04/2012              |
      | Uncle Bulgaria View                     | 1                                       | 21/04/2011              |
      | Common People View                      | 1                                       | 02/05/2011              |
    And the search results table should have the caption /Open e-petitions which match "Wombles"/
    And the markup should be valid

  Scenario: See search counts
    When I go to the home page
    And I fill in "search" with "Wombles"
    And I press "Search"
    Then I should see an "open" petition count of 4
    Then I should see a "closed" petition count of 1
    Then I should see a "rejected" petition count of 1

  Scenario: Search for open petitions using multiple search terms
    When I go to the home page
    And I fill in "search" with "overthrow the"
    And I press "Search"
    But I should see the following search results table:
      | Overthrow the Wombles View | 1          |

  Scenario: Search for special lucene characters to ensure they are escaped correctly
    When I go to the home page
    And I fill in "search" with "+ -|| ! && Common () { } [ ] ^ ~ * ? : \\"
    And I press "Search"
    Then I should see the following search results table:
      | Common People View | 1          |

  Scenario: Search for rejected petitions
    When I go to the search page
    And I search for "rejected" petitions with "WOMBLES"
    And I should see "Listed below are the e-petitions that failed to meet the terms and conditions"
    And the "Rejected" tab should be active
    Then I should see the following search results table:
      | Eavis vs the Wombles View |
    And the search results table should have the caption /Rejected e-petitions which match "WOMBLES"/


  Scenario: Search for closed petitions
    When I go to the search page
    And I search for "closed" petitions with "WOMBLES"
    Then I should see the following search results table:
      | The Wombles will rock Glasto View | 1          |

  Scenario: Search for open petitions and order by title
    When I go to the search page
    And I search for "open" petitions with "WOMBLES" ordered by "title"
    Then I should see the following search results table:
      | Common People View         |
      | Overthrow the Wombles View |
      | Uncle Bulgaria View        |
      | Wombles View               |

  Scenario: Search for open petitions and order by signature count
    Given the petition "Uncle Bulgaria" has 5 validated and 3 pending signatures
    And the petition "Wombles" has 2 validated and 20 pending signatures
    And the petition "Common People" has 10 validated and 10 pending signatures
    And the petition "Overthrow the Wombles" has 4 validated and 0 pending signatures
    And all petitions have had their signatures counted
    When I go to the search page
    And I search for "open" petitions with "WOMBLES" ordered by "count"
    Then I should see the following search results table:
      | Common People View         | 10         |
      | Uncle Bulgaria View        | 5          |
      | Overthrow the Wombles View | 4          |
      | Wombles View               | 2          |

  Scenario: Search for open petitions and order by signature count asc
    Given the petition "Uncle Bulgaria" has 5 validated and 3 pending signatures
    And the petition "Wombles" has 2 validated and 20 pending signatures
    And the petition "Common People" has 10 validated and 10 pending signatures
    And the petition "Overthrow the Wombles" has 4 validated and 0 pending signatures
    And all petitions have had their signatures counted
    When I go to the search page
    And I search for "open" petitions with "WOMBLES" ordered by "count asc"
    Then I should see the following search results table:
      | Wombles View               | 2          |
      | Overthrow the Wombles View | 4          |
      | Uncle Bulgaria View        | 5          |
      | Common People View         | 10         |

  Scenario: Search for open petitions and order by closing date
    When I go to the search page
    And I search for "open" petitions with "WOMBLES" ordered by "closing"
    Then I should see the following search results table:
      | Uncle Bulgaria View        | 21/04/2011 |
      | Wombles View               | 01/05/2011 |
      | Common People View         | 02/05/2011 |
      | Overthrow the Wombles View | 21/04/2012 |

  Scenario: Search for open petitions and order by closing date desc
    When I go to the search page
    And I search for "open" petitions with "WOMBLES" ordered by "closing desc"
    Then I should see the following search results table:
      | Overthrow the Wombles View | 21/04/2012 |
      | Common People View         | 02/05/2011 |
      | Wombles View               | 01/05/2011 |
      | Uncle Bulgaria View        | 21/04/2011 |

  Scenario: Paginate through open petitions
    Given 21 open petitions exist with title: "International development spending"
    When I go to the search page
    And I search for "open" petitions with "spending"
    And I follow "Next" within ".//*[contains(@class, 'title_pagination_row')]"
    Then I should see 1 petition
    And I follow "Previous" within ".//*[contains(@class, 'title_pagination_row')]"
    Then I should see 20 petitions

  Scenario: Searching for a profane search term
    When I go to the search page
    And I search for "hidden" petitions with "profane"
    Then I should see "No petitions could be found matching your search terms."

  Scenario: Searching and then reordering results
    Given the petition "Uncle Bulgaria" has 5 validated and 3 pending signatures
    And the petition "Wombles" has 2 validated and 20 pending signatures
    And the petition "Common People" has 10 validated and 10 pending signatures
    And the petition "Overthrow the Wombles" has 4 validated and 0 pending signatures
    And all petitions have had their signatures counted

    When I go to the search page
    And I search for "open" petitions with "WOMBLES"

    Then "e-petition name sort by e-petition name" should show as "search_normal"
    Then "Signatures sort by number of signatures" should show as "search_normal"
    Then "Closing sort by closing date" should show as "search_normal"

    And I follow "e-petition name"
    Then "e-petition name sort by e-petition name" should show as "active_search_normal"
    And I should see the following search results table:
      | Common People View         |
      | Overthrow the Wombles View |
      | Uncle Bulgaria View        |
      | Wombles View               |

    When I follow "e-petition name"
    Then "e-petition name sort by e-petition name" should show as "active_search_inverse"
    And I should see the following search results table:
      | Wombles View               |
      | Uncle Bulgaria View        |
      | Overthrow the Wombles View |
      | Common People View         |

    When I follow "Signatures"
    Then "Signatures sort by number of signatures" should show as "active_search_normal"
    And I should see the following search results table:
      | Common People View         | 10         |
      | Uncle Bulgaria View        | 5          |
      | Overthrow the Wombles View | 4          |
      | Wombles View               | 2          |

    When I follow "Signatures"
    Then "Signatures sort by number of signatures" should show as "active_search_inverse"
    And I should see the following search results table:
      | Wombles View               | 2          |
      | Overthrow the Wombles View | 4          |
      | Uncle Bulgaria View        | 5          |
      | Common People View         | 10         |

    When I follow "Closing"
    Then "Closing sort by closing date" should show as "active_search_normal"
    And I should see the following search results table:
      | Uncle Bulgaria View        | 21/04/2011 |
      | Wombles View               | 01/05/2011 |
      | Common People View         | 02/05/2011 |
      | Overthrow the Wombles View | 21/04/2012 |

    When I follow "Closing"
    Then "Closing sort by closing date" should show as "active_search_inverse"
    And I should see the following search results table:
      | Overthrow the Wombles View | 21/04/2012 |
      | Common People View         | 02/05/2011 |
      | Wombles View               | 01/05/2011 |
      | Uncle Bulgaria View        | 21/04/2011 |
