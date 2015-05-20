Feature: Moderator respond to petition
  In order to allow or prevent the signing of petitions
  As a moderator
  I want to respond to a petition for my department, accepting, rejecting or re-assigning it

  Scenario: Accesing the petitions page
    Given a sponsored petition exists with title: "More money for charities"
    And I am logged in as a sysadmin
    When I go to the admin moderate petitions page for "More money for charities"
    Then I should be connected to the server via an ssl connection
    And the markup should be valid

  Scenario: Moderator publishes petition
    Given I am logged in as a moderator
    When I look at the next petition on my list
    And I publish the petition
    Then the petition should be visible on the site for signing
    And the creator should recieve a notification email

  Scenario: Moderator rejects petition with a suitable reason code
    Given I am logged in as a moderator
    When I look at the next petition on my list
    And I reject the petition with a reason code "Matters which are not the responsibility of HM Government"
    Then the petition is not available for signing
    But the petition is still available for searching or viewing

  @javascript
  Scenario: Moderator previews reason description
    Given I am logged in as a moderator
    When I look at the next petition on my list
    Then I see relevant reason descriptions when I browse different reason codes

  Scenario: Moderator rejects petition with a suitable reason code and text
    Given I am logged in as a moderator
    When I look at the next petition on my list
    And I reject the petition with a reason code "Duplicate of an existing e-petition" and some explanatory text
    Then the explanation is displayed on the petition for viewing by the public
    And the creator should recieve a rejection notification email

  Scenario: Moderator rejects petition with a reason code which precludes public searching or viewing
    Given I am logged in as a moderator
    When I look at the next petition on my list
    And I reject the petition with a reason code "Confidential, libellous, false or defamatory statements (will be hidden)"
    And the creator should recieve a libel/profanity rejection notification email
    And the petition is not available for searching or viewing
    But the petition will still show up in the back-end reporting

  Scenario: Moderator rejects petition but with no reason code
    Given I am logged in as a moderator
    And a sponsored petition exists with title: "Rupert Murdoch is on the run"
    When I go to the Admin moderate petitions page for "Rupert Murdoch is on the run"
    And I reject the petition with a reason code "-- Select a rejection code --"
    Then a petition should exist with title: "Rupert Murdoch is on the run", state: "sponsored"
    And I should see "can't be blank"

  Scenario: Moderator rejects and hides previously rejected (and public) petition
    And a petition "actually libellous" has been rejected by the "Treasury" with the reason "duplicate"
    And I am logged in as a moderator
    When I view the petition through the admin interface
    And I change the rejection status of the petition with a reason code "Confidential, libellous, false or defamatory statements (will be hidden)"
    And the petition is not available for searching or viewing
    But the petition will still show up in the back-end reporting
