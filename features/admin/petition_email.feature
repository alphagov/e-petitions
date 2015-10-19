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
    And I follow "Add an item of parliamentary business"
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
