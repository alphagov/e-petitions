@admin
Feature: Searching for signatures as Terry
  In order to easily find out if someone's signed a petition
  As Terry
  I would like to be able to enter an email address, and see all signatures associated with it

  Scenario: A user can search for signatures by email
    Given 2 petitions signed by "bob@example.com"
    And I am logged in as a moderator
    When I search for petitions signed by "bob@example.com"
    Then I should see 2 petitions associated with the email address

  Scenario: A user can search for signatures by email from the admin hub
    Given 2 petitions signed by "bob@example.com"
    And I am logged in as a moderator
    When I search for petitions signed by "bob@example.com" from the admin hub
    Then I should see 2 petitions associated with the email address

  Scenario: Validating a pending signature
    Given 1 petition with a pending signature by "bob@example.com"
    And I am logged in as a moderator
    When I search for petitions signed by "bob@example.com" from the admin hub
    Then I should see the email address is pending
    When I click the validate button
    Then I should see the email address is validated

  Scenario: Deleting a signature
    Given 1 petition signed by "bob@example.com"
    And I am logged in as a moderator
    When I search for petitions signed by "bob@example.com" from the admin hub
    Then I should see 1 petition associated with the email address
    When I click the delete button
    Then I should see 0 petitions associated with the email address

  Scenario: Deleting a signature when the person has signed more than one petition
    Given 2 petitions signed by "bob@example.com"
    And I am logged in as a moderator
    When I search for petitions signed by "bob@example.com" from the admin hub
    Then I should see 2 petitions associated with the email address
    When I click the first delete button
    Then I should see 1 petitions associated with the email address

  Scenario: The creator’s signature can’t be deleted
    Given an open petition "More money for charities" with some signatures
    And I am logged in as a moderator
    When I search for the petition creator from the admin hub
    Then I should see 1 petition associated with the email address
    And I should not see the delete button
