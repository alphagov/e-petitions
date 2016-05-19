@admin
Feature: Moderator updates petition scheduled debate date

  Scenario: Updating petition scheduled debate date
    Given an open petition "More money for charities" with some signatures
    And I am logged in as a moderator
    When I view all petitions
    And I follow "More money for charities"
    And I follow "Scheduled debate date"
    And I fill in "Scheduled debate date" with "06/12/2015"
    And I press "Email 6 petitioners"
    Then I should see "Email will be sent overnight"
    And the petition creator should have been emailed about the scheduled debate
    And all the signatories of the petition should have been emailed about the scheduled debate
