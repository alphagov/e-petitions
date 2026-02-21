Feature: Suzie views a petition
  In order to read a petition and potentially sign it
  As Suzie the signer
  I want to view a petition of my choice from a list, seeing the vote count, closed and open dates, along with the reason for rejection if applicable

  Scenario: Suzie views a petition gathering sponsors
    Given a validated petition "Spend more money on Defence" with 2 supporters
    When I view the petition
    Then I should see "This petition is gathering support"
    And I should see "This petition needs 3 more supporters before we will check that it meets the petition standards"
    And I should see a link called "petition standards" linking to "/help#standards"
    And the page should have the title "This petition is gathering support - Petitions"
    And the page should have the meta description "Official online petitions in response to issues of the day"
    And the page should have the opengraph meta tag "title" with "This petition is gathering support - Petitions"
    And the page should not have the opengraph meta tag "description"
    And the page should have the twitter meta tag "title" with "This petition is gathering support - Petitions"
    And the page should have the twitter meta tag "description" with "Official online petitions in response to issues of the day"

  Scenario: Suzie views a petition gathering sponsors with 4 supporters
    Given a validated petition "Spend more money on Defence" with 4 supporters
    When I view the petition
    Then I should see "This petition is gathering support"
    And I should see "This petition needs 1 more supporter before we will check that it meets the petition standards"
    And I should see a link called "petition standards" linking to "/help#standards"
    And the page should have the title "This petition is gathering support - Petitions"
    And the page should have the meta description "Official online petitions in response to issues of the day"
    And the page should have the opengraph meta tag "title" with "This petition is gathering support - Petitions"
    And the page should not have the opengraph meta tag "description"
    And the page should have the twitter meta tag "title" with "This petition is gathering support - Petitions"
    And the page should have the twitter meta tag "description" with "Official online petitions in response to issues of the day"

  Scenario: Suzie views a petition waiting to be moderated
    Given a sponsored petition "Spend more money on Defence" with 5 supporters
    When I view the petition
    Then I should see "We’re checking this petition"
    And I should see "5 people have already supported this petition"
    And I should not see "No more people can sign this petition until it has been approved"
    And I should see a link called "petition standards" linking to "/help#standards"
    And the page should have the title "This petition has been sent to moderation - Petitions"
    And the page should have the meta description "Official online petitions in response to issues of the day"
    And the page should have the opengraph meta tag "title" with "This petition has been sent to moderation - Petitions"
    And the page should not have the opengraph meta tag "description"
    And the page should have the twitter meta tag "title" with "This petition has been sent to moderation - Petitions"
    And the page should have the twitter meta tag "description" with "Official online petitions in response to issues of the day"

  Scenario: Suzie views a petition waiting to be moderated with 1 supporter
    Given a sponsored petition "Spend more money on Defence" with 1 supporter
    When I view the petition
    Then I should see "We’re checking this petition"
    And I should see "1 person has already supported this petition"
    And I should not see "No more people can sign this petition until it has been approved"
    And I should see a link called "petition standards" linking to "/help#standards"
    And the page should have the title "This petition has been sent to moderation - Petitions"
    And the page should have the meta description "Official online petitions in response to issues of the day"
    And the page should have the opengraph meta tag "title" with "This petition has been sent to moderation - Petitions"
    And the page should not have the opengraph meta tag "description"
    And the page should have the twitter meta tag "title" with "This petition has been sent to moderation - Petitions"
    And the page should have the twitter meta tag "description" with "Official online petitions in response to issues of the day"

  Scenario: Suzie views a petition with the maximum number of supporters waiting to be moderated
    Given a sponsored petition "Spend more money on Defence" with 20 supporters
    When I view the petition
    Then I should see "We’re checking this petition"
    And I should see "20 people have already supported this petition"
    And I should see "No more people can sign this petition until it has been approved"
    And I should see a link called "petition standards" linking to "/help#standards"
    And the page should have the title "This petition has been sent to moderation - Petitions"
    And the page should have the meta description "Official online petitions in response to issues of the day"
    And the page should have the opengraph meta tag "title" with "This petition has been sent to moderation - Petitions"
    And the page should not have the opengraph meta tag "description"
    And the page should have the twitter meta tag "title" with "This petition has been sent to moderation - Petitions"
    And the page should have the twitter meta tag "description" with "Official online petitions in response to issues of the day"

  @allow-rescue
  Scenario: Suzie views a dormant petition
    Given a dormant petition "Spend more money on Defence"
    When I view the petition
    Then I will see a 404 error page

  Scenario: Suzie views an open petition
    Given an open petition "Spend more money on Defence" with background "Because of reasons"
    When I view the petition
    Then the page should have the title "Spend more money on Defence - Petitions"
    And the page should have the meta description "Because of reasons"
    And the page should have the opengraph meta tag "title" with "Petition: Spend more money on Defence"
    And the page should have the opengraph meta tag "description" with "Because of reasons"
    And the page should have the twitter meta tag "title" with "Petition: Spend more money on Defence"
    And the page should have the twitter meta tag "description" with "Because of reasons"
    And I should see the petition details
    And I should see the vote count, closed and open dates
    And I should not see "This petition is closed"
    And I can share it via Email
    And I can share it via Facebook
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

  @javascript
  Scenario: Suzie views an open petition that has received a response
    Given an open petition "Spend more money on Defence" with response "Defence is the best Offence" and response summary "Oh yes please"
    When I view the petition
    Then I should see "Oh yes please"
    And I should not see the response "Defence is the best Offence"
    When I expand "Read the response in full"
    Then I should see the response "Defence is the best Offence"

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

  Scenario: Suzie cannot sign closed petition
    Given a petition "Spend more money on Defence" has been closed
    When I view the petition
    Then I should see the petition details
    And I cannot sign the petition

  Scenario: Suzie sees a 'closed' message when viewing a closed petition
    Given a petition "Spend more money on Defence" has been closed
    When I view the petition
    Then I should see "This petition is closed"

  Scenario: Suzie sees a special 'closed' message when viewing a petition closed early due to parliament being dissolved
    Given a petition "Spend more money on Defence" has been closed early because of parliament dissolving
    When I view the petition
    Then I should see "This petition closed early because of a General Election"

  Scenario: Suzie sees a special message when viewing a petition closed early due to parliament being dissolved and awaiting a government response
    Given a petition "Spend more money on Defence" exists and passed the threshold for a response 14 days ago
    And the petition "Spend more money on Defence" has been closed early because of parliament dissolving
    When I view the petition
    Then I should see "Government will respond"
    Then I should see "Government responds to all petitions that get more than 10,000 signatures"
    Then I should see "Waiting for a new Petitions Committee after the General Election"

  Scenario: Suzie sees a special message when viewing a petition closed early due to parliament being dissolved and awaiting a debate
    Given a petition "Spend more money on Defence" passed the threshold for a debate 14 days ago and has no debate date set
    And the petition "Spend more money on Defence" has been closed early because of parliament dissolving
    When I view the petition
    Then I should see "This petition will be considered for debate"
    Then I should see "All petitions that have more than 100,000 signatures will be considered for debate in the new Parliament"
    Then I should see "Waiting for a new Petitions Committee after the General Election"

  Scenario: Suzie does not see the creator when viewing a closed petition
    Given a petition "Spend more money on Defence" has been closed
    When I view the petition
    Then I should not see the petition creator

  Scenario: Suzie does not see information about related activity when there is none
    Given an open petition "Ban Badger Baiting"
    When I view the petition
    Then I should not see "Related activity"

  Scenario: Suzie sees information about related activity when there is some
    Given a petition "Ban Badger Baiting" has related activity
    When I view the petition
    Then I should see the related activity

  Scenario: Suzie sees information about the outcomes when viewing a debated petition
    Given a petition "Ban Badger Baiting" has been debated 2 days ago
    When I view the petition
    Then I should see the date of the debate is 2 days ago
    And I should see links to the transcript, video and research
    And I should see a summary of the debate outcome

  Scenario: Suzie views a petition which has a scheduled debate date
    Given the date is the "01/08/2015"
    And an open petition "Spend more money on Defence" with scheduled debate date of "18/08/2015"
    When I view the petition
    Then I should see "Parliament will debate this petition on 18 August 2015. You’ll be able to watch online on the UK Parliament YouTube channel."

  Scenario: Suzie views a petition which will not be debated
    Given a petition "Spend more money on Defence" with a negative debate outcome
    When I view the petition
    Then I should see "The Petitions Committee decided not to debate this petition"

  Scenario: Suzie views a petition which was debated yesterday
    Given the date is the "27/10/2015"
    And a petition "Free the wombles" has been debated yesterday
    When I view the petition
    Then I should see "Parliament debated this petition on 26 October 2015"
    And I should see "Waiting for 1 day for Parliament to publish the debate outcome"

  Scenario: Suzie does not see information about future signature targets when viewing a closed petition
    Given a petition "Spend more money on Defence" has been closed
    When I view the petition
    Then I should not see "At 10,000 signatures..."
    Then I should not see "At 100,000 signatures..."

  Scenario: Suzie sees information about future signature targets when viewing an open petition which has not passed the threshold for response or debate
    Given an open petition "Spend more money on Defence"
    When I view the petition
    Then I should see "At 10,000 signatures..."
    Then I should see "At 100,000 signatures..."

  @javascript
  Scenario: Suzie sees information about a future signature target when viewing an open petition which has passed the threshold for response
    Given an open petition "Spend more money on Defence" with response "Defence is the best Offence" and response summary "Oh yes please"
    When I view the petition
    Then I should not see "At 10,000 signatures..."
    Then I should see "At 100,000 signatures..."
    Then I should see "Oh yes please"
    And I should not see the response "Defence is the best Offence"
    When I expand "Read the response in full"
    Then I should see the response "Defence is the best Offence"

  @javascript
  Scenario: Suzie does not see information about a future signature targets when viewing an open petition which has passed the threshold for response and debate
    Given a petition "Spend more money on Defence" exists with a debate outcome and with response threshold met
    When I view the petition
    Then I should not see "At 10,000 signatures..."
    Then I should not see "At 100,000 signatures..."
    And I should see a summary of the debate outcome

  Scenario: Suzie sees a message when viewing a petition and signature collection has been paused
    Given petitions are not collecting signatures
    And an open petition "Spend more money on Defence"
    When I view the petition
    Then I should see "This petition has stopped collecting signatures"
    And I cannot sign the petition

  Scenario: Suzie sees a message when viewing a petition and a message has been enabled
    Given a petition page message has been enabled
    And an open petition "Spend more money on Defence"
    When I view the petition
    Then I should see "We are experiencing delays when signing this petition"
    And I can sign the petition
