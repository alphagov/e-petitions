Feature: User views static pages
  In order to let users know about the site
  I can navigate to how E-petitions works, terms and conditions, privacy, crown copyright and accessibility pages

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

  Scenario: I navigate to Terms and conditions
    When I go to the home page
    And I follow "Terms and conditions"
    Then I should be on the terms and conditions page
    And I should see "Terms and conditions - e-petitions" in the browser page title
    And the markup should be valid

  Scenario: I navigate to Privacy
    When I go to the home page
    And I follow "Privacy"
    Then I should be on the privacy policy page
    And I should see "Privacy policy - e-petitions" in the browser page title
    And the markup should be valid

  Scenario: I navigate to Crown Copyright
    When I go to the home page
    And I follow "Crown copyright"
    Then I should be on the crown copyright page
    And I should see "Crown copyright - e-petitions" in the browser page title
    And the markup should be valid

  Scenario: I navigate to Accessbility page
    When I go to the home page
    And I follow "Accessibility"
    Then I should be on the accessibility page
    And I should see "Accessibility - e-petitions" in the browser page title
    And the markup should be valid

