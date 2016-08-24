@admin
Feature: Sysadmin can see fraudulent domains for a petition
  In order to maintain the reputation of the service
  As a sysadmin
  I want to be able to see what domains have had fraudulent signatures

  Scenario: Moderators should not see fraudulent domains
    Given an open petition "Ban controversial thing" with some fraudulent signatures
    And I am logged in as a moderator
    When I view all petitions
    And I follow "Ban controversial thing"
    Then I should not see "Fraudulent domains"

  Scenario: Sysadmins should see fraudulent domains
    Given an open petition "Ban controversial thing" with some fraudulent signatures
    And I am logged in as a sysadmin
    When I view all petitions
    And I follow "Ban controversial thing"
    Then I should see "Fraudulent domains"
