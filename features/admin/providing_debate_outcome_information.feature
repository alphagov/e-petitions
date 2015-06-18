Feature: Providing debate outcome information
  In order to keep petition supporters up-to-date on what parliament said about their petition
  As an admin user
  I want to store information about debates on the petition

  Scenario: Adding debate outcome infromation
    Given an open petition "Ban Badger Baiting"
    And I am logged in as a sysadmin
    When I am on the admin all petitions page
    And I follow "Ban Badger Baiting"
    And I follow "Add details of a debate outcome"
    Then I should be on the admin debate outcomes form page for "Ban Badger Baiting"
    And the markup should be valid
    When I press "Publish"
    Then the petition should not have debate details
    And I should see an error
    When I fill in the debate outcome details
    And press "Publish"
    Then the petition should have the debate details I provided
