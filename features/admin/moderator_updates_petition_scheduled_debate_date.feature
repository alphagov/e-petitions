@admin
Feature: Moderator updates petition scheduled debate date

  Scenario: Updating petition scheduled debate date
    Given an open petition "More money for charities" with some signatures
    And I am logged in as a moderator
    When I view all petitions
    And I follow "More money for charities"
    And I follow "Scheduled debate date"
    Then I should not see "Email 6 petitioners"
    When I fill in "Scheduled debate date" with "06/12/2015"
    And I press "Save"
    Then I should see "Updated the scheduled debate date successfully"
    And no emails have been sent
