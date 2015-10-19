Feature: Suzie views a petition
  In order to read a petition and potentially sign it
  As Suzie the signer
  I want to view a petition of my choice from a list, seeing the vote count, closed and open dates, along with the reason for rejection if applicable

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
    # Cannot test for validity due to iframe attribute required for IE7
    # Then the markup should be valid
    And I should see "<i>We<i>"
    And I should see a link called "http://www.google.com" linking to "http://www.google.com"
    And I should see a link called "bambi@gmail.com" linking to "mailto:bambi@gmail.com"

  @javascript
  Scenario: Suzie views an open petition that has received a response
    Given an open petition "Spend more money on Defence" with response "Defence is the best Offence" and response summary "Oh yes please"
    When I view the petition
    Then I should see "Oh yes please"
    And I should not see "Defence is the best Offence"
    When I expand "Read the response in full"
    Then I should see "Defence is the best Offence"

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

  Scenario: Suzie does not see the creator when viewing a closed petition
    Given a petition "Spend more money on Defence" has been closed
    When I view the petition
    Then I should not see the petition creator

  Scenario: Suzie does not see information about other parliamentary business when there is none
    Given an open petition "Ban Badger Baiting"
    When I view the petition
    Then I should not see "Other parliamentary business"

  Scenario: Suzie sees information about other parliamentary business when there is some
    Given a petition "Ban Badger Baiting" has other parliamentary business
    When I view the petition
    Then I should see the other business items

  Scenario: Suzie sees information about the outcomes when viewing a debated petition
    Given a petition "Ban Badger Baiting" has been debated 2 days ago
    When I view the petition
    Then I should see the date of the debate is 2 days ago
    And I should see links to transcript and video
    And I should see a summary of the debate outcome

  Scenario: Suzie views a petition which has a scheduled debate date
    Given the date is the "01/08/2015"
    And an open petition "Spend more money on Defence" with scheduled debate date of "18/08/2015"
    When I view the petition
    Then I should see "Parliament will debate this petition on 18 August 2015. You'll be able to watch online at parliamentlive.tv"

  Scenario: Suzie views a petition which will not be debated
    Given a petition "Spend more money on Defence" with a negative debate outcome
    When I view the petition
    Then I should see "The Petitions Committee decided not to debate this petition"
