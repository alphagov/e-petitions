Feature: Joe views an archived petition
  In order to see what petitions were created in the past
  As Joe, a member of the general public
  I want to be able to view archived petitions

  Scenario: Joe views an archived petition
    Given an archived petition "Spend more money on Defence"
    When I view the petition
    Then I should see the petition details
    And I should see "Spend more money on Defence - Petitions" in the browser page title
    And I should see the vote count, closed and open dates
    And I should see "This petition was submitted during the 2010–2015 Conservative - Liberal Democrat coalition government"

  Scenario: Joe views an archived petition at the old url and is redirected
    Given an archived petition "Spend more money on Defence"
    When I view the petition at the old url
    Then I should be redirected to the archived url
    And I should see "Spend more money on Defence - Petitions" in the browser page title
    And I should see the vote count, closed and open dates
    And I should see "This petition was submitted during the 2010–2015 Conservative - Liberal Democrat coalition government"

  Scenario: Joe views an archived petition containing urls, email addresses and html tags
    Given an archived petition exists with title: "Defence review", description: "<i>We<i> like http://www.google.com and bambi@gmail.com"
    When I go to the archived petition page for "Defence review"
    And I should see "<i>We<i>"
    And I should see a link called "http://www.google.com" linking to "http://www.google.com"
    And I should see a link called "bambi@gmail.com" linking to "mailto:bambi@gmail.com"

  Scenario: Joe sees reason for rejection if appropriate
    Given an archived petition "Please bring back Eldorado" has been rejected with the reason "<i>We<i> like http://www.google.com and bambi@gmail.com"
    When I view the petition
    Then I should see the petition details
    And I should see the reason for rejection
    And I should see "<i>We<i>"
    And I should see a link called "http://www.google.com" linking to "http://www.google.com"
    And I should see a link called "bambi@gmail.com" linking to "mailto:bambi@gmail.com"
    And I should not see "0 signatures"
    And I should not see "Deadline"
    And I cannot sign the petition

  Scenario: Joe cannot sign an archived petition
    Given an archived petition "Spend more money on Defence"
    When I view the petition
    Then I should see the petition details
    And I cannot sign the petition

  Scenario: Joe sees a 'closed' message when viewing an archived petition
    Given an archived petition "Spend more money on Defence"
    When I view the petition
    Then I should see "This petition was submitted during the 2010–2015 Conservative - Liberal Democrat coalition government"
