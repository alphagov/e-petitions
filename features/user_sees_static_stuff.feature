Feature: User views static pages
  In order to let users know about the site
  I can navigate to how E-petitions works and help pages

  Scenario: I navigate to the home page
    When I go to the home page
    Then I should see "Petitions - Senedd" in the browser page title
    And the markup should be valid

  Scenario: I navigate to Help
    When I go to the home page
    And I follow "How petitions work"
    Then I should be on the help page
    And I should see "How petitions work" in the browser page title
    And the markup should be valid

  Scenario: I navigate to Privacy and cookies
    When I go to the home page
    And I follow "Privacy"
    Then I should be on the privacy page
    And I should see "Privacy and cookies" in the browser page title
    And the markup should be valid
