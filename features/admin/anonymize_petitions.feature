@admin
Feature: An admin anonymizes petitions
  As an admin user
  I want to anonymize all petitions 6 months after parliament closes in accordance with our privacy policy

  Background:
    Given I am logged in as a sysadmin with the email "muddy@fox.com", first_name "Sys", last_name "Admin"

  @javascript
  Scenario: Admin anonymizes petitions 6 months after parliament closes
    Given Parliament is dissolved
    And 2 archived petitions exist
    When I go to the admin parliament page
    And I press "Anonymize petitions"
    And I accept the alert
    Then I should see "Anonymizing of petitions was successfully started"

  Scenario: An admin cannot anonymize petitions if there are none to anonymize
    When I go to the admin parliament page
    Then I should not see "Anonymize petitions"
