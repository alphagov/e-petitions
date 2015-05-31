Feature: Joe searches for an archived petition
  In order to see what petitions were created in the past
  As Joe, a member of the general public
  I want to be able to search archived petitions

  Background:
    Given the following archived petitions exist:
      | title                    | state    | signature_count| opened_at  | closed_at  | created_at |
      | Wombles are great        | open     | 835            | 2012-01-01 | 2013-01-01 | 2012-01-01 |
      | The Wombles of Wimbledon | open     | 243            | 2011-04-01 | 2012-04-01 | 2011-04-01 |
      | Common People            | open     | 639            | 2014-10-01 | 2015-03-31 | 2014-10-01 |
      | Eavis vs the Wombles     | rejected |                |            |            | 2011-01-01 |

  Scenario: Searching for petitions
    When I go to the archived petitions page
    And I fill in "search" with "Wombles"
    And I press "Search"
    Then I should be on the archived petitions search results page
    And I should see "Search results - archived e-petitions" in the browser page title
    And I should see /for "Wombles"/
    But I should see the following search results table:
      | Eavis vs the Wombles (Rejected)   | –   | –          |
      | The Wombles of Wimbledon (Closed) | 243 | 01/04/2012 |
      | Wombles are great (Closed)        | 835 | 01/01/2013 |
    And the search results table should have the caption /Archived e-petitions/
    And the markup should be valid

  Scenario: Paging through archived petitions
    Given 21 archived petitions exist with title: "International development spending"
    When I go to the archived petitions page
    And I fill in "search" with "spending"
    And I press "Search"
    Then I should be on the archived petitions search results page
    And I should see 20 petitions
    Then I follow "Next" within ".//*[contains(@class, 'title_pagination_row')]"
    And I should see 1 petition
    Then I follow "Previous" within ".//*[contains(@class, 'title_pagination_row')]"
    And I should see 20 petitions
