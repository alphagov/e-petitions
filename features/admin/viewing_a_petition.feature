@admin
Feature: Maggie views a petition
  In order to moderate a petition
  As Maggie, a petition moderator
  I want to see information about the petition

  Scenario: Maggie views information about the petition creator
    Given a sponsored petition "Loose benefits!"
    And a creator with name: "Alice Smith", email: "alice@example.com", postcode: "SW1A 1AA", ip_address: "199.71.23.252"
    When I am logged in as a moderator
    And I am on the admin petition page for "Loose benefits!"
    Then I should see the creator’s name in the petition details
    And I should see a link called "alice@example.com" linking to "/admin/signatures?q=alice%40example.com"
    And I should see a link called "SW1A 1AA" linking to "/admin/signatures?q=SW1A+1AA"
    And I should see a link called "199.71.23.252" linking to "/admin/signatures?q=199.71.23.252"
    And I should see the creator’s constituency in the petition details
    And I should see the creator’s region in the petition details
