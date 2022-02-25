@admin
Feature: Moderator respond to petition
  In order to allow or prevent the signing of petitions
  As a moderator
  I want to respond to a petition, editing, accepting, rejecting or re-assigning it

  @javascript
  Scenario: Accessing the petitions page
    Given a sponsored petition "More money for charities"
    And I am logged in as a sysadmin
    When I go to the admin petition page for "More money for charities"
    Then I should be connected to the server via an ssl connection
    And the markup should be valid
    And I should see the petition details
    And I should not see "Rejection reason"

  Scenario: Moderator edits petition before publishing
    Given I am logged in as a moderator named "Ben Macintosh"
    And I visit a sponsored petition with action: "wee need to save our plaanet", that has background: "Reduce polootion" and additional details: "Enforce Kyotoe protocol in more countries"
    And I follow "Edit petition"
    Then I am on the admin petition edit details page for "wee need to save our plaanet"
    And the markup should be valid
    And the "Action" field should contain "wee need to save our plaanet"
    And the "Background" field should contain "Reduce polootion"
    And the "Additional details" field should contain "Enforce Kyotoe protocol in more countries"
    Then I fill in "Action" with "We need to save our planet"
    And I fill in "Background" with "Reduce pollution"
    And I fill in "Additional details" with "Enforce Kyoto Protocol in more countries"
    And I check "Do not anonymize this petition"
    And I press "Save"
    Then I am on the admin petition page for "We need to save our planet"
    And I should see "We need to save our planet"
    And I should see "Reduce pollution"
    And I should see "Enforce Kyoto Protocol in more countries"
    And I follow "Edit petition"
    Then the "Do not anonymize this petition" checkbox should be checked

  Scenario: Moderator edits and tries to save an invalid petition
    Given I am logged in as a moderator named "Ben Macintosh"
    And I visit a sponsored petition with action: "wee need to save our plaanet", that has background: "Reduce polootion" and additional details: "Enforce Kyotoe protocol in more countries"
    And I follow "Edit petition"
    Then I fill in "Action" with ""
    And I fill in "Background" with ""
    And I fill in "Additional details" with ""
    And I press "Save"
    Then I should see "Action must be completed"
    And I should see "Background must be completed"

  Scenario: Moderator cancel editing petition
    Given I am logged in as a moderator named "Ben Macintosh"
    And I visit a sponsored petition with action: "Blah", that has background: "Blah" and additional details: "Blah"
    And I follow "Edit petition"
    Then I am on the admin petition edit details page for "Blah"
    When I follow "Cancel"
    Then I am on the admin petition page for "Blah"

  Scenario: Moderator publishes petition
    Given I am logged in as a moderator named "Ben Macintosh"
    When I look at the next petition on my list
    And I publish the petition
    Then I should see "Published by Ben Macintosh"
    Then the petition should be visible on the site for signing
    And the creator should receive a notification email

  Scenario: Moderator tries to publish a petition before the creator has validated their email address
    Given I am logged in as a moderator named "Ben Macintosh"
    And a pending petition "Remove trolls on the bridge" exists
    When I go to the admin petition page for "Remove trolls on the bridge"
    And I publish the petition
    Then the petition should still be unmoderated
    And the creator should not receive a notification email
    And I should see "You can't publish a petition before the creator has validated their email address"

  Scenario: Moderator rejects petition with a suitable reason code
    Given I am logged in as a moderator named "Ben Macintosh"
    When I look at the next petition on my list
    And I reject the petition with a reason code "Not the Government/Parliament’s responsibility"
    Then I should see "Rejected by Ben Macintosh"
    And the petition is not available for signing
    But the petition is still available for searching or viewing

  @javascript
  Scenario: Moderator previews reason description
    Given I am logged in as a moderator named "Ben Macintosh"
    When I look at the next petition on my list
    Then I see relevant reason descriptions when I browse different reason codes
    And I go to the Admin home page

  Scenario: Moderator rejects petition with a suitable reason code and text
    Given I am logged in as a moderator named "Ben Macintosh"
    When I look at the next petition on my list
    And I reject the petition with a reason code "Duplicate petition" and some explanatory text
    Then I should see "Rejected by Ben Macintosh"
    And the explanation is displayed on the petition for viewing by the public
    And the creator should receive a rejection notification email

  Scenario: Moderator rejects petition with a reason code which precludes public searching or viewing
    Given I am logged in as a moderator named "Ben Macintosh"
    When I look at the next petition on my list
    And I reject the petition with a reason code "Confidential, libellous, false, defamatory or references a court case"
    Then I should see "Hidden by Ben Macintosh"
    And the creator should receive a libel/profanity rejection notification email
    And the petition is not available for searching or viewing
    But the petition will still show up in the back-end reporting

  Scenario: Moderator rejects petition but with no reason code
    Given I am logged in as a moderator named "Ben Macintosh"
    And a sponsored petition exists with action: "Rupert Murdoch is on the run"
    When I go to the admin petition page for "Rupert Murdoch is on the run"
    And I reject the petition with a reason code "-- Select a rejection code --"
    Then a petition should exist with action: "Rupert Murdoch is on the run", state: "sponsored"
    And I should see "can't be blank"

  Scenario: Moderator rejects and hides previously rejected (and public) petition
    Given I am logged in as a moderator named "Ben Macintosh"
    And a petition "actually libellous" has been rejected with the reason "duplicate"
    When I go to the admin petition page for "actually libellous"
    And I change the rejection status of the petition with a reason code "Confidential, libellous, false, defamatory or references a court case"
    Then I should see "Hidden by Ben Macintosh"
    And the petition is not available for searching or viewing
    But the petition will still show up in the back-end reporting

  @javascript
  Scenario: Moderator flags petition
    Given I am logged in as a moderator named "Ben Macintosh"
    When I look at the next petition on my list
    And I flag the petition
    Then the petition is not available for searching or viewing
    And the creator should not receive a notification email
    And the creator should not receive a rejection notification email
    But the petition will still show up in the back-end reporting
    When I revisit the petition
    Then the petition can no longer be flagged
    And the petition can no longer be marked as dormant
    But it can still be approved
    And it can still be rejected
    And it can be restored to a sponsored state

  @javascript
  Scenario: Moderator marks a petition as dormant
    Given I am logged in as a moderator named "Ben Macintosh"
    When I look at the next petition on my list
    And I mark the petition as dormant
    Then the petition is not available for searching or viewing
    And the creator should not receive a notification email
    And the creator should not receive a rejection notification email
    But the petition will still show up in the back-end reporting
    When I revisit the petition
    Then the petition can no longer be flagged
    And the petition can no longer be marked as dormant
    But it can still be approved
    And it can still be rejected
    And it can be restored to a sponsored state

  @javascript
  Scenario: Moderator publishes a rejected petition
    Given I am logged in as a sysadmin named "Ben Macintosh"
    When I look at the next petition on my list
    And I reject the petition
    Then the creator should receive a rejection notification email
    And the petition is not available for signing
    But the petition is still available for searching or viewing
    Given no emails have been sent
    When I revisit the petition
    Then the petition can no longer be rejected
    And the petition can no longer be marked as dormant
    But it can still be approved
    And it can still be restored
    When I publish the petition
    Then I should see "Published by Ben Macintosh"
    And the petition should be visible on the site for signing
    And the creator should receive a notification email

  @javascript
  Scenario: Moderator restores a rejected petition
    Given I am logged in as a sysadmin named "Ben Macintosh"
    When I look at the next petition on my list
    And I reject the petition
    Then the creator should receive a rejection notification email
    And the petition is not available for signing
    But the petition is still available for searching or viewing
    Given no emails have been sent
    When I revisit the petition
    Then the petition can no longer be rejected
    And the petition can no longer be marked as dormant
    But it can still be approved
    And it can still be restored
    When I restore to a sponsored state
    Then the creator should not receive a notification email
    And the petition is not available for searching or viewing
    But the petition will still show up in the back-end reporting
