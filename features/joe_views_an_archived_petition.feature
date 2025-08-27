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
    And I should see "This petition was submitted during the 2010-2015 parliament"

  Scenario: Joe views an archived petition at the old url and is redirected
    Given an archived petition "Spend more money on Defence"
    When I view the petition at the old url
    Then I should be redirected to the archived url
    And I should see "Spend more money on Defence - Petitions" in the browser page title
    And I should see the vote count, closed and open dates
    And I should see "This petition was submitted during the 2010-2015 parliament"

  Scenario: Joe views an archived petition containing urls, email addresses and html tags
    Given an archived petition exists with action: "Defence review", background: "<i>We<i> like http://www.google.com and bambi@gmail.com"
    When I go to the archived petition page for "Defence review"
    Then I should see "<i>We<i>"
    And I should see a link called "http://www.google.com" linking to "http://www.google.com"
    And I should see a link called "bambi@gmail.com" linking to "mailto:bambi@gmail.com"

  Scenario: Joe views an archived petition with a Petitions Committee note
    Given an archived petition exists with action: "Defence review", committee_note: "This petition was found to be misleading"
    When I go to the archived petition page for "Defence review"
    Then I should see "This petition was found to be misleading"

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
    Then I should see "This petition was submitted during the 2010-2015 parliament"

  Scenario: Joe sees information about the outcomes when viewing a debated archived petition
    Given an archived petition "Ban Badger Baiting" has been debated 2 days ago
    When I view the petition
    Then I should see the date of the debate is 2 days ago
    And I should see links to the transcript, video and research
    And I should see a summary of the debate outcome

  Scenario: Joe views an archived petition which has a scheduled debate date
    Given the date is the "01/08/2015"
    And an archived petition "Spend more money on Defence" with scheduled debate date of "18/08/2015"
    When I view the petition
    Then I should see "Parliament will debate this petition on 18 August 2015. You’ll be able to watch online on the UK Parliament YouTube channel."

  Scenario: Joe views an archived petition which will not be debated
    Given an archived petition "Spend more money on Defence" with a negative debate outcome
    When I view the petition
    Then I should see "The Petitions Committee decided not to debate this petition"

  Scenario: Joe views a petition which was debated yesterday
    Given the date is the "27/10/2015"
    And an archived petition "Free the wombles" has been debated yesterday
    When I view the petition
    Then I should see "Parliament debated this petition on 26 October 2015"
    And I should see "Waiting for 1 day for Parliament to publish the debate outcome"

  Scenario: Joe does not see information about related activity when there is none
    Given an archived petition "Ban Badger Baiting"
    When I view the petition
    Then I should not see "Related activity"

  Scenario: Joe sees information about related activity when there is some
    Given an archived petition "Ban Badger Baiting" has related activity
    When I view the petition
    Then I should see the related activity

  @allow-rescue
  Scenario: Joe tries to see a stopped archived petition
    Given a stopped archived petition exists with action: "Spend more money on Defence"
    When I view the petition
    Then I will see a 404 error page

  @allow-rescue
  Scenario: Joe tries to see a hidden archived petition
    Given a hidden archived petition exists with action: "Spend more money on Defence"
    When I view the petition
    Then I will see a 404 error page
