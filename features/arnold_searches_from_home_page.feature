@search
Feature: Arnold searches from the home page
  In order to reduce the likelihood of a duplicate petition being made
  As a petition moderator
  I want to prominently show a petition search for the current parliament from the home page

Background:
    Given a pending petition exists with action_en: "Wombles are great", action_cy: "Mae Wombles yn wych"
    And a validated petition exists with action_en: "The Wombles of Wimbledon", action_cy: "Wombles Wimbledon"
    And an open petition exists with action_en: "Uncle Bulgaria", additional_details: "The Wombles are here", action_cy: "Yncl Bwlgaria", additional_details_cy: "Mae'r Wombles yma", closed_at: "1 minute from now"
    And an open petition exists with action_en: "Common People", background: "The Wombles belong to us all", action_cy: "Pobl Gyffredin", background_cy: "Mae'r Wombles yn perthyn i ni i gyd", closed_at: "11 days from now"
    And an open petition exists with action_en: "Overthrow the Wombles", action_cy: "Goresgyn y Wombles", closed_at: "1 year from now"
    And a closed petition exists with action_en: "The Wombles will rock Glasto", action_cy: "Bydd y Wombles yn siglo Glasto", closed_at: "1 minute ago"
    And a rejected petition exists with action_en: "Eavis vs the Wombles", action_cy: "Eavis vs y Wombles"
    And a hidden petition exists with action_en: "The Wombles are profane", action_cy: "Mae'r Wombles yn halogedig"
    And an open petition exists with action_en: "Wombles", action_cy: "Wombles", closed_at: "10 days from now"

Scenario: Arnold searches for petitions
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

@welsh
Scenario: Arnold searches for petitions in Welsh
  Given I am on the home page
  When I search all petitions for "Wombles"
  Then I should see my search term "Wombles" filled in the search field
  And I should see "6 results"
  And I should see the following search results:
    | Wombles                            | 1 signature             |
    | Goresgyn y Wombles                 | 1 signature             |
    | Yncl Bwlgaria                      | 1 signature             |
    | Pobl Gyffredin                     | 1 signature             |
    | Bydd y Wombles yn siglo Glasto     | 1 signature, now closed |
    | Eavis vs y Wombles                 | Rejected                |
  And the markup should be valid
