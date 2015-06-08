Feature: Joe sees cookie message
  In order to be informed about privacy issues
  As Joe, a member of the general public
  I want to see a message about cookie usage

  Scenario: On the first visit
    Given I am on the home page
    Then I should see the cookie message

  Scenario: On subsequent visits
    Given I am on the home page
    And I go to the home page
    Then I should not see the cookie message

  Scenario: On revisiting after a year
    Given I am on the home page
    And I wait for 1 year
    And I go to the home page
    Then I should see the cookie message
