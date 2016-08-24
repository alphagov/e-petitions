@admin
Feature: Sysadmin can see trending IP addresses
  In order to maintain the reputation of the service
  As a sysadmin
  I want to be able to see what IP addresses are trending

  Scenario: Moderators should not see trending IP addresses
    Given an open petition "Ban controversial thing" with some signatures
    And I am logged in as a moderator
    When I go to the admin home page
    Then I should not see "Trending IP addresses"

  Scenario: Sysadmins should see trending IP addresses
    Given an open petition "Ban controversial thing" with some signatures
    And I am logged in as a sysadmin
    When I go to the admin home page
    Then I should see "Trending IP addresses"
