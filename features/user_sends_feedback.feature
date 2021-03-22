Feature: User sends feedback
  In order to see the site improved with my suggestions
  As a user of the site
  I want to be able to easily send feedback to the site owners

  Scenario:
    Given I am on the feedback page
    Then I should be able to submit feedback
    And the site owners should be notified

  Scenario: User must supply fields
    Given I am on the feedback page
    Then I cannot submit feedback without filling in the required fields

  Scenario: User sees a message when submitting feedback and a message has been enabled
    Given a feedback page message has been enabled
    When I am on the feedback page
    Then I should see "Petition moderation is experiencing delays"
