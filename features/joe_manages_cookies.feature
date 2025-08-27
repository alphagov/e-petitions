@javascript
Feature: Joe manages cookies
  In order to control what information is shared
  As Joe, a member of the general public
  I want to manage my cookie preferences

  Scenario: On the first visit
    Given I am on the home page
    Then I should see the cookie banner
    And the analytics cookie preference should not be set

  Scenario: Accepting additional cookies
    Given I am on the home page
    Then I should see the cookie banner
    When I press "Accept additional cookies"
    Then I should not see the cookie banner
    And the analytics cookie preference should be set to true

  Scenario: Rejecting additional cookies
    Given I am on the home page
    Then I should see the cookie banner
    When I press "Reject additional cookies"
    Then I should not see the cookie banner
    And the analytics cookie preference should be set to false

  Scenario: Rejecting additional cookies
    Given I am on the home page
    Then I should see the cookie banner
    When I press "Reject additional cookies"
    Then I should not see the cookie banner
    And the analytics cookie preference should be set to false

  Scenario: Analytics cookie preference defaults to off
    Given I am on the home page
    Then I should see the cookie banner
    When I press "Cookie settings"
    Then I should see the cookie settings
    And "Do not use cookies that measure my website use" is chosen
    When I press "Close cookie settings"
    Then I should not see the cookie settings
    And I should see the cookie banner
    And the analytics cookie preference should not be set

  Scenario: Managing cookie preferences
    Given I am on the home page
    Then I should see the cookie banner
    When I press "Reject additional cookies"
    Then I should not see the cookie banner
    And the analytics cookie preference should be set to false
    When I follow "Cookie settings"
    Then I should see the cookie settings
    And "Do not use cookies that measure my website use" is chosen
    When I choose "Use cookies that measure my website use"
    And I press "Save cookie settings"
    Then I should not see the cookie settings
    And I should not see the cookie banner
    And the analytics cookie preference should be set to true
