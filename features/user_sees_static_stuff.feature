Feature: User views static pages
  In order to let users know about the site
  I can navigate to how E-petitions works and help pages

  Scenario: I navigate to the home page
    When I go to the home page
    Then I should see "e-petitions" in the browser page title
    And the markup should be valid
    # css is not entirely valid but useful to run to see any real no-nos
    # And the css files should be valid

  Scenario: I navigate to How e-petitions works
    When I go to the home page
    And I follow "How e-petitions work" within "//*[@id='page_content']"
    Then I should be on the how e-Petitions works page
    And I should see "How e-petitions works - e-petitions" in the browser page title
    And the markup should be valid

  Scenario: I navigate to Help
    When I go to the home page
    And I follow "Help"
    Then I should be on the help page
    And I should see "Help using the Petition Parliament service" in the browser page title
    And the markup should be valid
