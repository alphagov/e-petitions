@admin
Feature: Moderator edits an archived petition
  As a moderator
  I want to edit an archived petition

  Scenario: Moderator edits archived petition
    Given I am logged in as a moderator named "Ben Macintosh"
    And I visit an archived petition with action: "We need to save our planet"
    Then I am on the admin archived petition edit details page for "We need to save our planet"
    And the markup should be valid
    And I check "Do not anonymize this petition"
    And I press "Save"
    Then I am on the admin archived petition page for "We need to save our planet"
    And I follow "Edit petition"
    Then the "Do not anonymize this petition" checkbox should be checked
