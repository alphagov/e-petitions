Feature: Suzie views front page without moderated petitions
  In order to avoid confusing users
  As the site owner
  I want to replace the search box with some explanatory text if no petitions exist to be searched for yet

  Scenario:
    When I go to the home page
    Then I should not be able to search via free text
