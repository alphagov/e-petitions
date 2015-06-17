Feature: Pete protects the website
  In order to be protect the site from exposure
  As Pete, the product owner
  I want to be able to control access to the website

  @allow-rescue
  Scenario: Taking the website down
    Given the site is disabled
    And I am on the home page
    Then I will see a 503 error page

  @allow-rescue
  Scenario: Password protecting the website
    Given the site is protected
    And the request is not local
    And I am on the home page
    Then I am asked for a username and password
