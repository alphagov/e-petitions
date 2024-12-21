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

  Scenario: User is blocked by ip address
    Given the IP address 127.0.0.1 is blocked
    And I am on the feedback page
    When I fill in "Comments" with "I must protest"
    And I press "Send feedback"
    Then I should see "Your feedback has been sent"
    Then the markup should be valid
    And the site owners should not be notified
    And a feedback should not exist with comment: "I must protest"

  Scenario: User is blocked by domain
    Given the domain "example.com" is blocked
    And I am on the feedback page
    When I fill in "Comments" with "I must protest"
    And I fill in "Email address" with "bob@example.com"
    And I press "Send feedback"
    Then I should see "Your feedback has been sent"
    Then the markup should be valid
    And the site owners should not be notified
    And a feedback should not exist with comment: "I must protest"

  Scenario: User is blocked by email address
    Given the email address "bob@example.com" is blocked
    And I am on the feedback page
    When I fill in "Comments" with "I must protest"
    And I fill in "Email address" with "bob@example.com"
    And I press "Send feedback"
    Then I should see "Your feedback has been sent"
    Then the markup should be valid
    And the site owners should not be notified
    And a feedback should not exist with comment: "I must protest"

  Scenario: User is blocked by IP address rate limiting
    Given the feedback rate limit is 1 per hour
    And there are no allowed IPs
    And there are no allowed domains
    And there are 2 feedbacks created from this IP address
    And I am on the feedback page
    When I fill in "Comments" with "I must protest"
    And I fill in "Email address" with "bob@example.com"
    And I press "Send feedback"
    Then I should see "Your feedback has been sent"
    Then the markup should be valid
    And the site owners should not be notified
    And a feedback should not exist with comment: "I must protest"
