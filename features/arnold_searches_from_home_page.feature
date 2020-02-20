@search
Feature: Arnold searches from the home page
  In order to reduce the likelihood of a duplicate petition being made
  As a petition moderator
  I want to prominently show a petition search for the current parliament from the home page

Background:
    Given a pending petition exists with action: "Wombles are great"
    And a validated petition exists with action: "The Wombles of Wimbledon"
    And an open petition exists with action: "Uncle Bulgaria", additional_details: "The Wombles are here", closed_at: "1 minute from now"
    And an open petition exists with action: "Common People", background: "The Wombles belong to us all", closed_at: "11 days from now"
    And an open petition exists with action: "Overthrow the Wombles", closed_at: "1 year from now"
    And a closed petition exists with action: "The Wombles will rock Glasto", closed_at: "1 minute ago"
    And a rejected petition exists with action: "Eavis vs the Wombles"
    And a hidden petition exists with action: "The Wombles are profane"
    And an open petition exists with action: "Wombles", closed_at: "10 days from now"

Scenario: Arnold searches for petitions when parliament is opened
  Given I am on the home page
  When I search all petitions for "Wombles"
  Then I should be on the all petitions page
  And I should see my search term "Wombles" filled in the search field
  And I should see "6 results"
  And I should see the following search results:
    | Wombles                            | 1 signature             |
    | Overthrow the Wombles              | 1 signature             |
    | Uncle Bulgaria                     | 1 signature             |
    | Common People                      | 1 signature             |
    | The Wombles will rock Glasto       | 1 signature, now closed |
    | Eavis vs the Wombles               | Rejected                |
