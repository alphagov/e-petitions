Feature: Moderator updates petition scheduled debate date

  Scenario: Updating petition scheduled debate date
    Given a petition "More money for charities" exists with a signature count of 150000
    And I am logged in as a moderator
    When I view all petitions
    And I follow "More money for charities"
    And I follow "Publish Debate Schedule"
    And I fill in "Scheduled debate date" with "06/12/2015"
    And I press "Publish and Send Email"
    Then I should see "Scheduled debate date was successfully updated."
