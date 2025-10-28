Feature: Arnold searches from the home page
  In order to reduce the likelihood of a duplicate petition being made
  As a petition moderator
  I want to prominently show a petition search for the current parliament from the home page

Background:
    Given a pending petition exists with action: "Wombles are great"
    And a validated petition exists with action: "The Wombles of Wimbledon"
    And an open petition exists with action: "Uncle Bulgaria", additional_details: "The Wombles are here", closed_at: "1 minute from now", signature_count: 23
    And an open petition exists with action: "Common People", background: "The Wombles belong to us all", closed_at: "11 days from now", signature_count: 19
    And an open petition exists with action: "Overthrow the Wombles", closed_at: "3 months from now", signature_count: 17
    And a closed petition exists with action: "The Wombles will rock Glasto", closed_at: "1 minute ago", signature_count: 9
    And a rejected petition exists with action: "Eavis vs the Wombles"
    And a hidden petition exists with action: "The Wombles are profane"
    And an open petition exists with action: "Wombles", closed_at: "10 days from now", signature_count: 13
    And the following archived petitions exist:
      | action                   | state    | signature_count | opened_at  | closed_at  | created_at |
      | Rivers are great         | closed   | 835             | 2012-01-01 | 2013-01-01 | 2012-01-01 |
      | More rivers please       | closed   | 243             | 2011-04-01 | 2012-04-01 | 2011-04-01 |
      | Cry me a river           | closed   | 639             | 2014-10-01 | 2015-03-31 | 2014-10-01 |
      | Also Rivers              | rejected | 6               |            |            | 2011-01-01 |
      | River Island             | hidden   |                 |            |            | 2011-01-01 |

Scenario: Arnold searches for petitions when parliament is opened
  Given I am on the home page
  When I search all petitions for "Wombles"
  Then I should be on the all petitions page
  And I should have the following query string:
    | state | open    |
    | query | Wombles |
  And I should see my search term "Wombles" filled in the search field
  And I should see "We’ve found 4 petitions"
  And I should see the following search results:
    | Uncle Bulgaria               | Total signatures 23 |
    | Common People                | Total signatures 19 |
    | Overthrow the Wombles        | Total signatures 17 |
    | Wombles                      | Total signatures 13 |

Scenario: Arnold searches for petitions by id
  Given I am on the home page
  When I search all petitions using the id of the petition "Uncle Bulgaria"
  Then I should be on the petition page for "Uncle Bulgaria"

Scenario: Arnold searches for petitions when parliament is dissolving
  Given Parliament is dissolving
  When I am on the home page
  And I search all petitions for "Wombles"
  Then I should be on the all petitions page
  And I should have the following query string:
    | state | open    |
    | query | Wombles |
  And I should see my search term "Wombles" filled in the search field
  And I should see "We’ve found 4 petitions"
  And I should see the following search results:
    | Uncle Bulgaria               | Total signatures 23 |
    | Common People                | Total signatures 19 |
    | Overthrow the Wombles        | Total signatures 17 |
    | Wombles                      | Total signatures 13 |

Scenario: Arnold searches for petitions when parliament is dissolved
  Given Parliament is dissolved
  And all the open petitions have been closed
  When I am on the home page
  And I search all petitions for "Wombles"
  Then I should be on the all petitions page
  And I should have the following query string:
    | state | closed  |
    | query | Wombles |
  And I should see my search term "Wombles" filled in the search field
  And I should see "We’ve found 5 petitions"
  And I should see the following search results:
    | Uncle Bulgaria               | Total signatures 23 |
    | Common People                | Total signatures 19 |
    | Overthrow the Wombles        | Total signatures 17 |
    | Wombles                      | Total signatures 13 |
    | The Wombles will rock Glasto | Total signatures 9  |

Scenario: Arnold searches for petitions when parliament is pending
  Given Parliament is pending
  When I am on the home page
  And I search all petitions for "Rivers"
  Then I should be on the archived petitions page
  And I should have the following query string:
    | state | published |
    | query | Rivers    |
  And I should see my search term "Rivers" filled in the search field
  And I should see "We’ve found 3 petitions"
  And I should see the following search results:
    | Rivers are great         | Total signatures 835 |
    | Cry me a river           | Total signatures 639 |
    | More rivers please       | Total signatures 243 |
