@admin
Feature: Sysadmin invalidates some signatures
  In order to improve the reputation of a petition
  As a sysadmin
  I want to invalidate fraudulent signatures

  Scenario: Sysadmin invalidates signatures by email
    Given 1 petition signed by "bob.jones@example.com"
    When I am logged in as a sysadmin
    And I am on the admin invalidations page
    And I follow "New Invalidation"
    Then I should see "Reasons for this invalidation"
    When I press "Save"
    Then I should see "Summary can't be blank"
    And I should see "Please select some conditions, otherwise all signatures will be invalidated"
    When I fill in "Summary" with "Bob Jones is a fraud"
    And I fill in "Email address" with "bob.jones@example.com"
    And I press "Save"
    Then I should see "Invalidation created successfully"
    When I press "Start"
    Then I should see "Enqueued the invalidation"
    When I search for petitions signed by "bob.jones@example.com" from the admin hub
    Then I should see the email address is invalidated
    When I am on the admin invalidations page
    Then I should see a matching signature count of 1
    And I should see a invalidated signature count of 1
    And I should see an invalidation status of "Completed"

  Scenario: Sysadmin counts matching signatures
    Given 3 petition signed by "bob.jones@example.com"
    When I am logged in as a sysadmin
    And I am on the admin invalidations page
    And I follow "New Invalidation"
    And I fill in "Summary" with "Bob Jones is a fraud"
    And I fill in "Email address" with "bob.jones@example.com"
    And I press "Save"
    Then I should see "Invalidation created successfully"
    When I press "Count"
    Then I should see "Counted the matching signatures for invalidation"
    And I should see a matching signature count of 3

  Scenario: Sysadmin deletes an invalidation
    When I am logged in as a sysadmin
    And I am on the admin invalidations page
    And I follow "New Invalidation"
    And I fill in "Summary" with "Bob Jones is a fraud"
    And I fill in "Email address" with "bob.jones@example.com"
    And I press "Save"
    Then I should see "Invalidation created successfully"
    When I press "Delete"
    Then I should see "Invalidation removed successfully"

  Scenario: Sysadmin cancels an invalidation
    When I am logged in as a sysadmin
    And I am on the admin invalidations page
    And I follow "New Invalidation"
    And I fill in "Summary" with "Bob Jones is a fraud"
    And I fill in "Email address" with "bob.jones@example.com"
    And I press "Save"
    Then I should see "Invalidation created successfully"
    When I press "Cancel"
    Then I should see "Invalidation cancelled successfully"
    And I should see an invalidation status of "Cancelled"
