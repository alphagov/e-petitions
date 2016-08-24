@admin
Feature: Searching for signatures as Terry
  In order to easily find signatures from an IP address
  As Terry
  I would like to be able to enter an IP address, and see all signatures associated with it

  Scenario: A user can search for signatures by IP address
    Given 2 petitions signed from "192.168.1.1"
    And I am logged in as a moderator
    When I search for petitions signed from "192.168.1.1"
    Then I should see 2 petitions associated with the IP address

  Scenario: A user can search for signatures by IP address from the admin hub
    Given 2 petitions signed from "192.168.1.1"
    And I am logged in as a moderator
    When I search for petitions signed from "192.168.1.1" from the admin hub
    Then I should see 2 petitions associated with the IP address
