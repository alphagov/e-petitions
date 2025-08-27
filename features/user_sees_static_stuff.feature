Feature: User views static pages
  In order to let users know about the site
  I can navigate to how E-petitions works and help pages

  Scenario: I navigate to the home page
    When I go to the home page
    Then I should see "Petitions - UK Government and Parliament" in the browser page title
    And the markup should be valid

  Scenario: I navigate to Help
    When I go to the home page
    And I follow "How petitions work"
    Then I should be on the help page
    And I should see "How petitions work" in the browser page title
    And the markup should be valid

  Scenario: I navigate to Privacy notice
    When I go to the home page
    And I follow "Privacy"
    Then I should be on the privacy page
    And I should see "Privacy notice" in the browser page title
    And the markup should be valid

  Scenario: I navigate to the Cookies page
    When I go to the home page
    And I follow "Cookies"
    Then I should be on the cookies page
    And I should see "Cookies" in the browser page title
    And the markup should be valid

  Scenario: I navigate to Accessibility statement
    When I go to the home page
    And I follow "Accessibility statement"
    Then I should be on the accessibility page
    And I should see "Accessibility statement" in the browser page title
    And the markup should be valid

  @allow-rescue
  Scenario: I navigate to a disabled page
    Given the "cookies" page is disabled
    When I go to the home page
    And I follow "Cookies"
    Then I will see a 404 error page

  @javascript
  Scenario: I navigate to a redirected page
    Given the "cookies" page is redirected to "https://www.parliament.uk/site-information/privacy/"
    When I go to the home page
    And I press "Accept additional cookies"
    And I follow "Cookie policy"
    Then I should be redirected to "https://www.parliament.uk/site-information/privacy/"
