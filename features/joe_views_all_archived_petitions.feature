Feature: Joe views all archived petition
  In order to see what petitions were created in the past
  As Joe, a member of the general public
  I want to be able to view all archived petitions

  Background:
    Given these archived petitions exist:
      | action                   | state    | signature_count | created_at | rejected_at | opened_at  |
      | Wombles are great        | closed   | 835             | 2012-01-01 |             | 2012-01-10 |
      | Common People            | closed   | 639             | 2014-01-01 |             | 2014-01-10 |
      | Save the planet          | closed   | 243             | 2014-01-01 |             | 2014-01-11 |
      | Wombles to Parliament    | closed   | 243             | 2013-01-01 |             | 2013-01-10 |
      | Free gig tickets         | rejected |                 | 2013-01-01 | 2013-01-08  |            |
      | Wombles are &*!%         | hidden   |                 | 2013-02-01 | 2013-02-08  |            |
      | Bring back the Wombles   | stopped  |                 | 2013-03-01 |             | 2013-03-10 |

  Scenario:
    When I am on the petitions page
    And I follow "View archived petitions"
    Then I should see "Search archived petitions"
    And I should see "We’ve found 4 petitions"
    And I should see the following list of archived petitions:
      | Wombles are great         | Total signatures 835 |
      | Common People             | Total signatures 639 |
      | Save the planet           | Total signatures 243 |
      | Wombles to Parliament     | Total signatures 243 |
    And the markup should be valid
    When I search for "Rejected petitions"
    Then I should see "We’ve found 1 petition"
    And I should see the following list of archived petitions:
      | Free gig tickets          | Rejected on 8 January 2013 |
    And the markup should be valid
    When I search for "All petitions"
    Then I should see "We’ve found 5 petitions"
    And I should see the following list of archived petitions:
      | Wombles are great         | Total signatures 835       |
      | Common People             | Total signatures 639       |
      | Save the planet           | Total signatures 243       |
      | Wombles to Parliament     | Total signatures 243       |
      | Free gig tickets          | Rejected on 8 January 2013 |
    And I should not see "Wombles are &*!%"
    And I should not see "Bring back the Wombles"
    And the markup should be valid

  Scenario: Joe browses petitions which have been debated
    Given an archived petition "Free the wombles" has been debated yesterday
    And an archived petition "Ban Badger Baiting" has been debated 2 days ago
    And an archived petition "Spend more money on Defence" has been debated 18 days ago
    And an archived petition "Force supermarkets to give unsold food to charities" has been debated 234 days ago
    And an archived petition "Make every monday bank holiday" exists
    When I browse to see only "Debated in Parliament" archived petitions
    And I should see "We’ve found 4 petitions"
    Then I should see the following ordered list of petitions:
     | Free the wombles                                    |
     | Ban Badger Baiting                                  |
     | Spend more money on Defence                         |
     | Force supermarkets to give unsold food to charities |
    And the markup should be valid

  Scenario: Downloading the JSON data for archived petitions
    Given I am on the archived petitions page
    Then I should see the following list of archived petitions:
      | Wombles are great         | Total signatures 835       |
      | Common People             | Total signatures 639       |
      | Save the planet           | Total signatures 243       |
      | Wombles to Parliament     | Total signatures 243       |
      | Free gig tickets          | Rejected on 8 January 2013 |
    And the markup should be valid
    When I click the JSON link
    Then I should be on the archived petitions JSON page
    And the JSON should be valid

  Scenario: Downloading the CSV data for archived petitions
    Given I am on the archived petitions page
    Then I should see the following list of archived petitions:
      | Wombles are great         | Total signatures 835       |
      | Common People             | Total signatures 639       |
      | Save the planet           | Total signatures 243       |
      | Wombles to Parliament     | Total signatures 243       |
      | Free gig tickets          | Rejected on 8 January 2013 |
    And the markup should be valid
    When I click the CSV link
    Then I should get a download with the filename "filtered-archived-petitions.csv"
