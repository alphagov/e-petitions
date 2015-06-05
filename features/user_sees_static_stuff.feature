Feature: User views static pages
  In order to let users know about the site
  I can navigate to how E-petitions works and help pages

  Scenario: I navigate to the home page
    When I go to the home page
    Then I should see "Petition parliament" in the browser page title
    And the markup should be valid
    # css is not entirely valid but useful to run to see any real no-nos
    # And the css files should be valid

  Scenario: I navigate to Help
    When I go to the home page
    And I follow "Help"
    Then I should be on the help page
    And I should see "Help" in the browser page title
    And the markup should be valid
