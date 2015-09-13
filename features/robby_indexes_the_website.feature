Feature: Robby indexes the website
  In order to provide relevant links
  As Robby, a search engine webcrawler
  I want to be able to index the correct pages

  @admin
  Scenario: Fetching an admin page
    When I go to the Admin home page
    Then I should not index the page

  Scenario: Fetching a petition page
    Given an open petition "Do something!"
    When I view the petition
    Then I should index the page

  Scenario: Fetching the new signature page
    Given an open petition "Do something!"
    When I go to the new signature page for "Do something!"
    Then I should not index the page
