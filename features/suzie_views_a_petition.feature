Feature: Suzie views a petition
  In order to read a petition and potentially sign it
  As Suzie the signer
  I want to view a petition of my choice from a list, seeing the vote count, closed and open dates, along with the reason for rejection if applicable

  Scenario: Suzie views a petition gathering sponsors
    Given a validated petition "Spend more money on Defence"
    When I view the petition
    Then I should see "This petition is gathering support"
    And I should see a link called "petition standards" linking to "/help#standards"

  Scenario: Suzie views a petition waiting to be moderated
    Given a sponsored petition "Spend more money on Defence"
    When I view the petition
    Then I should see "We’re checking this petition"
    And I should see a link called "petition standards" linking to "/help#standards"

  Scenario: Suzie views an open petition
    Given an open petition "Spend more money on Defence"
    When I view the petition
    Then I should see the petition details
    And I should see "Spend more money on Defence - Petitions" in the browser page title
    And I should see the vote count, closed and open dates
    And I should not see "This petition is closed"
    And I can share it via Email
    And I can share it via Facebook
    And I can share it via Twitter
    And I can share it via Whatsapp

  Scenario: Suzie views a petition containing urls, email addresses and html tags
    Given an open petition exists with action: "Defence review", additional_details: "<i>We<i> like http://www.google.com and bambi@gmail.com"
    When I go to the petition page for "Defence review"
    Then the markup should be valid
    When I click to see more details
    Then I should see "<i>We<i>"
    And I should see a link called "http://www.google.com" linking to "http://www.google.com"
    And I should see a link called "bambi@gmail.com" linking to "mailto:bambi@gmail.com"

  Scenario: Suzie views a petition with a Petitions Committee note
    Given an open petition exists with action: "Defence review", committee_note: "This petition was found to be misleading"
    When I go to the petition page for "Defence review"
    Then the markup should be valid
    And I should see "This petition was found to be misleading"

  Scenario: Suzie sees reason for rejection if appropriate
    Given a petition "Please bring back Eldorado" has been rejected with the reason "We like http://www.google.com and bambi@gmail.com"
    When I view the petition
    Then I should see the petition details
    And I should see the reason for rejection
    And I should see "We like http://www.google.com and bambi@gmail.com"
    And I should see a link called "http://www.google.com" linking to "http://www.google.com"
    And I should see a link called "bambi@gmail.com" linking to "mailto:bambi@gmail.com"
    And I should not see the vote count
    And I should see submitted date
    And I cannot sign the petition

  Scenario: Suzie cannot sign a closed petition
    Given a petition "Spend more money on Defence" has been closed
    When I view the petition
    Then I should see the petition details
    And I cannot sign the petition

  Scenario: Suzie sees a 'closed' message when viewing a closed petition
    Given a petition "Spend more money on Defence" has been closed
    When I view the petition
    Then I should see "This petition is closed"

  Scenario: Suzie does not see the creator when viewing a closed petition
    Given a petition "Spend more money on Defence" has been closed
    When I view the petition
    Then I should not see the petition creator

  Scenario: Suzie cannot sign a completed petition
    Given a petition "Spend more money on Defence" has been completed
    When I view the petition
    Then I should see the petition details
    And I cannot sign the petition

  Scenario: Suzie sees a 'closed' message when viewing a completed petition
    Given a petition "Spend more money on Defence" has been completed
    When I view the petition
    Then I should see "This petition is closed"

  Scenario: Suzie does not see the creator when viewing a completed petition
    Given a petition "Spend more money on Defence" has been completed
    When I view the petition
    Then I should not see the petition creator

  Scenario: Suzie does not see information about other Senedd business when there is none
    Given an open petition "Ban Badger Baiting"
    When I view the petition
    Then I should not see "Other Senedd business"

  Scenario: Suzie sees information about other Senedd business when there is some
    Given a petition "Ban Badger Baiting" has other Senedd business
    When I view the petition
    Then I should see the other Senedd business items

  Scenario: Suzie sees information about the outcomes when viewing a debated petition
    Given a petition "Ban Badger Baiting" has been debated 2 days ago
    When I view the petition
    Then I should see the date of the debate is 2 days ago
    And I should see links to the transcript, video and research
    And I should see a summary of the debate outcome

  Scenario: Suzie views a petition which has a scheduled debate date
    Given the date is the "01/08/2015"
    And a petition "Spend more money on Defence" with a scheduled debate date of "18/08/2015"
    When I view the petition
    Then I should see "Senedd will debate this petition on 18 August 2015. You'll be able to watch online on the Senedd YouTube channel."

  Scenario: Suzie views a petition which will not be debated
    Given a petition "Spend more money on Defence" with a negative debate outcome
    When I view the petition
    Then I should see "The Petitions Committee decided not to refer this petition for a debate"

  Scenario: Suzie views a petition which was debated yesterday
    Given the date is the "27/10/2015"
    And a petition "Free the wombles" has been debated yesterday
    When I view the petition
    Then I should see "Senedd debated this petition on 26 October 2015"
    And I should see "Waiting 1 day for the Senedd to publish the debate outcome"

  Scenario: Suzie does not see information about future signature targets when viewing a closed petition
    Given a petition "Spend more money on Defence" has been closed
    When I view the petition
    Then I should not see "At 50 signatures..."
    Then I should not see "At 5,000 signatures..."

  Scenario: Suzie does not see information about future signature targets when viewing a completed petition
    Given a petition "Spend more money on Defence" has been completed
    When I view the petition
    Then I should not see "At 50 signatures..."
    Then I should not see "At 5,000 signatures..."

  Scenario: Suzie sees information about future signature targets when viewing an open petition which has not passed the threshold for response or debate
    Given an open petition "Spend more money on Defence"
    When I view the petition
    Then I should see "At 50 signatures..."
    Then I should see "At 5,000 signatures..."

  @javascript
  Scenario: Suzie does not see information about a future signature targets when viewing an open petition which has passed the threshold for referral and debate
    Given a petition "Spend more money on Defence" exists with a debate outcome and with referral threshold met
    When I view the petition
    Then I should not see "At 50 signatures..."
    Then I should not see "At 5,000 signatures..."
    And I should see a summary of the debate outcome
