@admin
Feature: Emailing petitioner supporters
  In order to keep petition supporters up-to-date on their petition
  As an admin user
  I want to send an email to all petition supporters

  Scenario: Sending an email to all petitioners
    Given an open petition "Ban Badger Baiting" with some signatures
    And I am logged in as a sysadmin with the email "admin@example.com", first_name "Admin", last_name "User"
    When I am on the admin all petitions page
    And I follow "Ban Badger Baiting"
    And I follow "Other parliamentary business"
    Then I should be on the admin email petitioners form page for "Ban Badger Baiting"
    And the markup should be valid
    When I press "Email 6 petitioners"
    Then the petition should not have any emails
    And I should see an error
    When I fill in the email details
    And press "Email 6 petitioners"
    Then the petition should have the email details I provided
    And the petition creator should have been emailed with the update
    And all the signatories of the petition should have been emailed with the update
    And the feedback email address should have been emailed a copy

  Scenario: Previewing an email to all petitioners
    Given an open petition "Ban Badger Baiting" with some signatures
    And I am logged in as a sysadmin with the email "admin@example.com", first_name "Admin", last_name "User"
    When I am on the admin all petitions page
    And I follow "Ban Badger Baiting"
    And I follow "Other parliamentary business"
    Then I should be on the admin email petitioners form page for "Ban Badger Baiting"
    And the markup should be valid
    When I press "Save"
    Then the petition should not have any emails
    And I should see an error
    When I fill in the email details
    And press "Save and preview"
    Then the petition should have the email details I provided
    And the petition creator should not have been emailed with the update
    And all the signatories of the petition should not have been emailed with the update
    And the feedback email address should have been emailed a copy

  Scenario: Saving an email to all petitioners
    Given an open petition "Ban Badger Baiting" with some signatures
    And I am logged in as a sysadmin with the email "admin@example.com", first_name "Admin", last_name "User"
    When I am on the admin all petitions page
    And I follow "Ban Badger Baiting"
    And I follow "Other parliamentary business"
    Then I should be on the admin email petitioners form page for "Ban Badger Baiting"
    And the markup should be valid
    When I press "Save"
    Then the petition should not have any emails
    And I should see an error
    When I fill in the email details
    And press "Save"
    Then the petition should have the email details I provided
    And the petition creator should not have been emailed with the update
    And all the signatories of the petition should not have been emailed with the update
    And the feedback email address should not have been emailed a copy

  Scenario: Updating an email to all petitioners
    Given an open petition "Ban Badger Baiting" with some signatures
    And it has an existing petition email "This will be debated"
    And I am logged in as a sysadmin with the email "admin@example.com", first_name "Admin", last_name "User"
    When I am on the admin all petitions page
    And I follow "Ban Badger Baiting"
    And I follow "Other parliamentary business"
    Then I should be on the admin email petitioners form page for "Ban Badger Baiting"
    And the markup should be valid
    And I should see "This will be debated"
    When I press "Edit"
    Then I should see "Edit other parliamentary business"
    When I fill in "Subject" with "This will not be debated"
    And I press "Save"
    Then I should see "Updated other parliamentary business successfully"
    When I follow "Other parliamentary business"
    Then I should see "This will not be debated"

  Scenario: Deleting an email to all petitioners
    Given an open petition "Ban Badger Baiting" with some signatures
    And it has an existing petition email "This will be debated"
    And I am logged in as a sysadmin with the email "admin@example.com", first_name "Admin", last_name "User"
    When I am on the admin all petitions page
    And I follow "Ban Badger Baiting"
    And I follow "Other parliamentary business"
    Then I should be on the admin email petitioners form page for "Ban Badger Baiting"
    And the markup should be valid
    And I should see "This will be debated"
    When I press "Delete"
    Then I should see "Deleted other parliamentary business successfully"
    When I follow "Other parliamentary business"
    Then I should not see "This will be debated"
