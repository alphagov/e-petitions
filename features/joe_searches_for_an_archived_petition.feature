Feature: Joe searches for an archived petition
  In order to see what petitions were created in the past
  As Joe, a member of the general public
  I want to be able to search archived petitions
  And I want to see the results ordered by the oldest petitions

  Background:
    Given the following archived petitions exist:
      | action                   | state    | signature_count | opened_at  | closed_at  | created_at |
      | Wombles are great        | closed   | 835             | 2012-01-01 | 2013-01-01 | 2012-01-01 |
      | The Wombles of Wimbledon | closed   | 243             | 2011-04-01 | 2012-04-01 | 2011-04-01 |
      | Common People            | closed   | 639             | 2014-10-01 | 2015-03-31 | 2014-10-01 |
      | Eavis vs the Wombles     | rejected |                 |            |            | 2011-01-01 |

  Scenario: Searching for petitions
    When I go to the archived petitions page
    And I fill in "search" with "Wombles"
    And I press "Search"
    Then I should be on the archived petitions page
    But I should see the following search results:
      | Eavis vs the Wombles           | Rejected       |
      | Wombles are great              | 835 signatures |
      | The Wombles of Wimbledon       | 243 signatures |
    And the markup should be valid

  Scenario: Paging through archived petitions
    Given 51 archived petitions exist with action: "International development spending"
    When I go to the archived petitions page
    And I fill in "search" with "spending"
    And I press "Search"
    Then I should be on the archived petitions page
    And I should see 50 petitions
    Then I follow "Next"
    And I should see 1 petition
    Then I follow "Previous"
    And I should see 50 petitions
