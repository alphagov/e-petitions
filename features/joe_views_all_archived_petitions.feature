Feature: Joe views all archived petition
  In order to see what petitions were created in the past
  As Joe, a member of the general public
  I want to be able to view all archived petitions

  Background:
    Given the following archived petitions exist:
      | title                    | state    | signature_count |  created_at |
      | Wombles are great        | open     | 835             |  2012-01-01 |
      | Common People            | open     | 639             |  2014-01-01 |
      | Save the planet          | open     | 243             |  2014-01-01 |
      | Wombles to Parliament    | open     | 243             |  2013-01-01 |
      | Free gig tickets         | rejected |                 |  2013-01-01 |

  Scenario:
    When I view all petitions from the home page
    And I follow "Closed petitions"
    And I follow "2010-2015 Conservative - Liberal Democrat coalition government"
    Then I should see the following list of archived petitions:
      | Wombles are great         | 835 signatures |
      | Common People             | 639 signatures |
      | Save the planet           | 243 signatures |
      | Wombles to Parliament     | 243 signatures |
      | Free gig tickets          | Rejected       |
    And the markup should be valid
