@admin
Feature: Sysadmin updates the rate limits
  In order to improve the reputation of a petition
  As a sysadmin
  I want to limit the number of signatures per IP address

  Scenario: Sysadmin updates the rate limits
    When I am logged in as a sysadmin
    And I am on the admin home page
    And I follow "Rate Limits"
    Then I should see "Edit Rate Limits"
    When I fill in "Length of short period in seconds" with ""
    And I press "Save"
    Then I should see "Burst period can’t be blank"
    When I fill in "Length of short period in seconds" with "120"
    And I fill in "Number of signatures created per short period" with "2"
    And I press "Save"
    Then I should see "Rate limits updated successfully"

  Scenario: Sysadmin updates the blocked emails list
    When I am logged in as a sysadmin
    And I am on the admin home page
    And I follow "Rate Limits"
    Then I should see "Edit Rate Limits"
    When I follow "Blocked Emails"
    Then I should see "normalize the email address according to the domain rules"
    When I fill in "rate_limit_blocked_emails" with "foo"
    And I press "Save"
    Then I should see "Blocked emails list is invalid"
    When I fill in "rate_limit_blocked_emails" with "user@example.com"
    And I press "Save"
    Then I should see "Rate limits updated successfully"

  Scenario: Sysadmin updates the allowed domains list
    When I am logged in as a sysadmin
    And I am on the admin home page
    And I follow "Rate Limits"
    Then I should see "Edit Rate Limits"
    When I follow "Allowed Domains"
    Then I should see "use *.example.com to match one subdomain and **.example.com to match nested subdomains"
    When I fill in "rate_limit_allowed_domains" with "foo("
    And I press "Save"
    Then I should see "Allowed domains list is invalid"
    When I fill in "rate_limit_allowed_domains" with "example.com"
    And I press "Save"
    Then I should see "Rate limits updated successfully"

  Scenario: Sysadmin updates the blocked domains list
    When I am logged in as a sysadmin
    And I am on the admin home page
    And I follow "Rate Limits"
    Then I should see "Edit Rate Limits"
    When I follow "Blocked Domains"
    Then I should see "use *.example.com to match one subdomain and **.example.com to match nested subdomains"
    When I fill in "rate_limit_blocked_domains" with "foo("
    And I press "Save"
    Then I should see "Blocked domains list is invalid"
    When I fill in "rate_limit_blocked_domains" with "example.com"
    And I press "Save"
    Then I should see "Rate limits updated successfully"

  Scenario: Sysadmin updates the allowed IPs list
    When I am logged in as a sysadmin
    And I am on the admin home page
    And I follow "Rate Limits"
    Then I should see "Edit Rate Limits"
    When I follow "Allowed IPs"
    Then I should see "use CIDR addressing to match ranges, e.g. 192.168.0.0/24"
    When I fill in "rate_limit_allowed_ips" with "127"
    And I press "Save"
    Then I should see "Allowed IPs list is invalid"
    When I fill in "rate_limit_allowed_ips" with "127.0.0.1/32"
    And I press "Save"
    Then I should see "Rate limits updated successfully"

  Scenario: Sysadmin updates the blocked IPs list
    When I am logged in as a sysadmin
    And I am on the admin home page
    And I follow "Rate Limits"
    Then I should see "Edit Rate Limits"
    When I follow "Blocked IPs"
    Then I should see "use CIDR addressing to match ranges, e.g. 192.168.0.0/24"
    When I fill in "rate_limit_blocked_ips" with "127"
    And I press "Save"
    Then I should see "Blocked IPs list is invalid"
    When I fill in "rate_limit_blocked_ips" with "127.0.0.1/32"

  Scenario: Sysadmin updates the countries
    When I am logged in as a sysadmin
    And I am on the admin home page
    And I follow "Rate Limits"
    Then I should see "Edit Rate Limits"
    When I follow "Countries"
    Then I should see "Add countries that are allowed to sign petitions, e.g. United Kingdom"
    When I fill in "rate_limit_countries" with "United Kingdom"
    And I press "Save"
    Then I should see "Rate limits updated successfully"
