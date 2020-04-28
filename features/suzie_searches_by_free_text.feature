Feature: Suzy Singer searches by free text
  In order to find interesting petitions to sign for a particular area of government
  As Suzy the signer
  I want to search against petition action, background, supporting details

  Background:
    Given the date is the "21 April 2011 12:00"
    And a pending petition exists with action_en: "Wombles are great", action_cy: "Mae Wombles yn wych"
    And a validated petition exists with action_en: "The Wombles of Wimbledon", action_cy: "Wombles Wimbledon"
    And an open petition exists with action_en: "Uncle Bulgaria", additional_details: "The Wombles are here", action_cy: "Yncl Bwlgaria", additional_details_cy: "Mae'r Wombles yma", closed_at: "1 minute from now"
    And an open petition exists with action_en: "Common People", background: "The Wombles belong to us all", action_cy: "Pobl Gyffredin", background_cy: "Mae'r Wombles yn perthyn i ni i gyd", closed_at: "11 days from now"
    And an open petition exists with action_en: "Overthrow the Wombles", action_cy: "Goresgyn y Wombles", closed_at: "1 year from now"
    And a referred petition exists with action_en: "The Wombles will rock Glasto", action_cy: "Bydd y Wombles yn siglo Glasto", closed_at: "1 minute ago"
    And a rejected petition exists with action_en: "Eavis vs the Wombles", action_cy: "Eavis vs y Wombles"
    And a hidden petition exists with action_en: "The Wombles are profane", action_cy: "Mae'r Wombles yn halogedig"
    And an open petition exists with action_en: "Wombles", action_cy: "Wombles", closed_at: "10 days from now"

    # debated
    Given a petition "Ban Badger Baiting" has been debated 2 days ago
    Given a petition "Leave EU" has been debated 18 days ago

  Scenario: Search for all visible petitions
    When I search for "All petitions" with "Wombles"
    Then I should see my search term "Wombles" filled in the search field
    And I should see "6 petitions"
    And I should see the following search results:
      | Wombles                            | 1 signature                                      |
      | Overthrow the Wombles              | 1 signature                                      |
      | Uncle Bulgaria                     | 1 signature                                      |
      | Common People                      | 1 signature                                      |
      | The Wombles will rock Glasto       | 1 signature Referred to the Petitions Committee  |
      | Eavis vs the Wombles               | Rejected                                         |
    And the markup should be valid

  @welsh
  Scenario: Search for all visible petitions in Welsh
    When I search for "Pob deiseb" with "Wombles"
    Then I should see my search term "Wombles" filled in the search field
    And I should see "6 deiseb"
    And I should see the following search results:
      | Wombles                            | 1 llofnod                                    |
      | Goresgyn y Wombles                 | 1 llofnod                                    |
      | Yncl Bwlgaria                      | 1 llofnod                                    |
      | Pobl Gyffredin                     | 1 llofnod                                    |
      | Bydd y Wombles yn siglo Glasto     | 1 llofnod Cyfeiriwyd at y Pwyllgor Deisebau  |
      | Eavis vs y Wombles                 | Gwrthodwyd                                   |
    And the markup should be valid

  Scenario: Search for open petitions
    When I search for "Open petitions" with "Wombles"
    Then I should see my search term "Wombles" filled in the search field
    And I should see "4 petitions"
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
    Then I should see an "open" petition count of 4
    Then I should see a "referred" petition count of 3
    Then I should see a "rejected" petition count of 1

  Scenario: Search for open petitions using multiple search terms
    When I search for "Open petitions" with "overthrow the"
    Then I should see the following search results:
      | Overthrow the Wombles | 1 signature |

  @welsh
  Scenario: Search for open petitions using multiple search terms in Welsh
    When I search for "Pob deiseb" with "goresgyn y"
    Then I should see the following search results:
      | Goresgyn y Wombles    | 1 llofnod |

  Scenario: Search for rejected petitions
    When I search for "Rejected petitions" with "WOMBLES"
    Then I should see the following search results:
      | Eavis vs the Wombles |

  Scenario: Search for referred petitions
    When I search for "Referred to the Committee" with "WOMBLES"
    Then I should see the following search results:
      | The Wombles will rock Glasto | 1 signature          |

  Scenario: Search for petitions debated by the Senedd
    When I search for "Debated by the Senedd" with "EU"
    Then I should see the following search results:
      | Leave EU                        | 1 signature |

  Scenario: Paginate through open petitions
    Given 51 open petitions exist with action: "International development spending"
    When I search for "Open petitions" with "International"
    And I follow "Next"
    Then I should see 1 petition
    And I follow "Previous"
    Then I should see 50 petitions
