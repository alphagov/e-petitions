@admin
Feature: Moderator submits a paper petition
  In order to increase inclusion
  As a moderator user
  I want to submit a paper petition

  Background:
    Given I am logged in as a moderator

  Scenario: Submitting the petition
    When I go to the admin home page
    And I follow "Submit Paper Petition"
    Then I should see "Submit a paper petition"
    When I press "Save"
    Then I should see "Unable to submit paper petition - please check the form for errors"
    And I should see "Action must be completed"
    And I should see "Background must be completed"
    When I fill in the English petition details
    And I fill in the Welsh petition details
    And I press "Save"
    Then I should not see "Action must be completed"
    But I should see "Signature count must be completed"
    When I fill in "Signature count" with "25"
    And I press "Save"
    Then I should see "Signature count must meet the referral threshold"
    When I fill in "Signature count" with "500"
    And I press "Save"
    Then I should not see "Signature count must meet the referral threshold"
    But I should see "Submission date must be completed"
    When I fill in "Date petition was submitted" with "2020-04-30"
    And I press "Save"
    Then I should not see "Submission date must be completed"
    But I should see "Name must be completed"
    And I should see "Email must be completed"
    And I should see "Phone number must be completed"
    And I should see "Address must be completed"
    And I should see "Postcode must be completed"
    When I choose "Welsh"
    And I fill in "Name" with "Alice Smith"
    And I fill in "Email" with "alice@example.com"
    And I fill in "Phone number" with "0300 200 6565"
    And I fill in "Address" with "The Senedd\nPierhead St\nCardiff"
    And I fill in "Postcode" with "CF99 1NA"
    And I press "Save"
    Then I should see "Paper petition submitted successfully"
    And a petition exists with state: "closed", action_en: "Do stuff!", action_cy: "Gwnewch bethau!", closed_at: "2020-04-30T11:00:00Z"
    And a signature exists with state: "pending", name: "Alice Smith", email: "alice@example.com", postcode: "CF991NA"
    And a contact exists with address: "The Senedd\nPierhead St\nCardiff", phone_number: "03002006565"
