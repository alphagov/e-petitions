Feature: Suzy Singer searches for petitions
  In order to find interesting petitions to sign for a particular area of goverment
  As Suzy the signer
  I want to search from any page within the site

  @search
  Scenario: Suzie can search by free text
    Given an open petition exists with title: "Uncle Bulgaria", description: "The Wombles are here"
    And all petitions have had their signatures counted
    And I am on the new petition page
    When I fill in "search_header" with "Wombles"
    And I press "search_button_header"
    Then I should be on the search results page
    And the "search_header" field should contain "Wombles" 
    And I should see the following search results table:
      | Uncle Bulgaria View        | 1          |

  Scenario: Suzie cannot see the search box if there are no visible petitions
    When I am on the new petition page
    Then I should not see a "search_header" text field

  Scenario: Suzie cannot see the search box in the header on the home page
    Given an open petition exists with title: "Uncle Bulgaria", description: "The Wombles are here"
    When I am on the home page
    Then I should not see a "search_header" text field
