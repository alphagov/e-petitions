@admin
Feature: Administrate domain blocking
  As a sysadmin
  I can manage the blocking of domains

  Background:
    Given I am logged in as a sysadmin with the email "muddy@fox.com", first_name "Sys", last_name "Admin"

  Scenario: Accessing the domains index
    When I go to the admin home page
    And I follow "Domains"
    Then I should be on the admin domains index page
    And I should be connected to the server via an ssl connection

  Scenario: Viewing trending domains
    Given that a petition has been signed 10 times from "gmail.com" during the last 5 minutes
    When I go to the admin domains index page
    Then I should see the domain name "gmail.com"
    And I should see a current rate of 120 for the domain "gmail.com"
    And I should see a maximum rate of 120 for the domain "gmail.com"
    And I should see an allow button for the domain "gmail.com"
    And I should see a block button for the domain "gmail.com"

  Scenario: Allowing a trending domain
    Given that a petition has been signed 10 times from "gmail.com" during the last 5 minutes
    When I go to the admin domains index page
    Then I should see the domain name "gmail.com"
    When I click the allow button for the domain "gmail.com"
    Then I should be on the admin domains index page
    And I should see "Domain successfully whitelisted"

  Scenario: Blocking a trending domain
    Given that a petition has been signed 10 times from "gmail.com" during the last 5 minutes
    When I go to the admin domains index page
    Then I should see the domain name "gmail.com"
    When I click the block button for the domain "gmail.com"
    Then I should be on the admin domains index page
    And I should see "Domain successfully blocked"

  Scenario: Searching for a domain
    Given that a petition has been signed 10 times from "gmail.com" during the last 5 minutes
    When I go to the admin domains index page
    And I fill in "Search" with "gmail.com"
    And I press "Search"
    Then I should be on the admin domain search results page
    And I should see the domain name "gmail.com"

  Scenario: Blocking a whitelisted domain
    Given that the domain "gmail.com" has already been whitelisted
    When I go to the admin domains index page
    And I fill in "Search" with "gmail.com"
    And I press "Search"
    Then I should be on the admin domain search results page
    And I should see the domain name "gmail.com"
    And I should see a block button for the domain "gmail.com"
    And I should not see an allow button for the domain "gmail.com"
    When I click the block button for the domain "gmail.com"
    Then I should be on the admin domains index page
    And I should see "Domain successfully blocked"
    When I fill in "Search" with "gmail.com"
    And I press "Search"
    Then I should be on the admin domain search results page
    And I should see an allow button for the domain "gmail.com"
    And I should not see a block button for the domain "gmail.com"

  Scenario: Whitelisting a blocked domain
    Given that the domain "gmail.com" has already been blocked
    When I go to the admin domains index page
    And I fill in "Search" with "gmail.com"
    And I press "Search"
    Then I should be on the admin domain search results page
    And I should see the domain name "gmail.com"
    And I should see an allow button for the domain "gmail.com"
    And I should not see a block button for the domain "gmail.com"
    When I click the allow button for the domain "gmail.com"
    Then I should be on the admin domains index page
    And I should see "Domain successfully whitelisted"
    When I fill in "Search" with "gmail.com"
    And I press "Search"
    Then I should be on the admin domain search results page
    And I should see a block button for the domain "gmail.com"
    And I should not see an allow button for the domain "gmail.com"

  Scenario: Creating a domain
    When I go to the admin domains index page
    And I fill in "Search" with "gmail.com"
    And I press "Search"
    Then I should be on the admin domain search results page
    And I should not see the domain name "gmail.com"
    When I press "Create domain"
    Then I should be on the admin domains index page
    And I should see "Domain successfully created"

  Scenario: Creating an invalid domain
    When I go to the admin domains index page
    And I fill in "Search" with "gmail_com"
    And I press "Search"
    Then I should be on the admin domain search results page
    And I should not see the domain name "gmail_com.com"
    When I press "Create domain"
    Then I should be on the admin domains index page
    And I should see "Domain could not be created - please contact support"
