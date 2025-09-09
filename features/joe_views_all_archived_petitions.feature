Feature: Joe views all archived petition
  In order to see what petitions were created in the past
  As Joe, a member of the general public
  I want to be able to view all archived petitions

  Background:
    Given these archived petitions exist:
      | action                   | state    | signature_count |  created_at |
      | Wombles are great        | closed   | 835             |  2012-01-01 |
      | Common People            | closed   | 639             |  2014-01-01 |
      | Save the planet          | closed   | 243             |  2014-01-01 |
      | Wombles to Parliament    | closed   | 243             |  2013-01-01 |
      | Free gig tickets         | rejected |                 |  2013-01-01 |
      | Wombles are &*!%         | hidden   |                 |  2013-02-01 |
      | Bring back the Wombles   | stopped  |                 |  2013-03-01 |

  Scenario:
    When I am on the petitions page
    And I follow "View archived petition"
    Then I should see "Published petitions" within ".//h1"
    And I should see the following list of archived petitions:
      | Wombles are great         | 835 signatures |
      | Common People             | 639 signatures |
      | Save the planet           | 243 signatures |
      | Wombles to Parliament     | 243 signatures |
    And the markup should be valid
    When I follow "Rejected petitions" within ".//div[@id='list-navigation']"
    Then I should see "Rejected petitions" within ".//h1"
    And I should see the following list of archived petitions:
      | Free gig tickets          | Rejected       |
    And the markup should be valid
    When I follow "All petitions" within ".//div[@id='list-navigation']"
    Then I should see "All petitions" within ".//h1"
    And I should see the following list of archived petitions:
      | Wombles are great         | 835 signatures |
      | Common People             | 639 signatures |
      | Save the planet           | 243 signatures |
      | Wombles to Parliament     | 243 signatures |
      | Free gig tickets          | Rejected       |
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
    Then I should see "4 petitions"
    Then I should see the following ordered list of petitions:
     | Free the wombles                                    |
     | Ban Badger Baiting                                  |
     | Spend more money on Defence                         |
     | Force supermarkets to give unsold food to charities |
    And the markup should be valid

  Scenario: Downloading the JSON data for archived petitions
    Given I am on the archived petitions page
    Then I should see the following list of archived petitions:
      | Wombles are great         | 835 signatures |
      | Common People             | 639 signatures |
      | Save the planet           | 243 signatures |
      | Wombles to Parliament     | 243 signatures |
      | Free gig tickets          | Rejected       |
    And the markup should be valid
    When I click the JSON link
    Then I should be on the archived petitions JSON page
    And the JSON should be valid

  Scenario: Downloading the CSV data for archived petitions
    Given I am on the archived petitions page
    Then I should see the following list of archived petitions:
      | Wombles are great         | 835 signatures |
      | Common People             | 639 signatures |
      | Save the planet           | 243 signatures |
      | Wombles to Parliament     | 243 signatures |
      | Free gig tickets          | Rejected       |
    And the markup should be valid
    When I click the CSV link
    Then I should get a download with the filename "all-petitions-2010-2015.csv"
