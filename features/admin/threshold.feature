Feature: Threshold list
  In order to see and action petitions that require a response
  As a moderator or sysadmin user I can see a list of petitions that have exceeded the signature threshold count
  Or have been marked as requiring a response

  Background:
    Given I am logged in as a moderator
    And the date is the "21 April 2011 12:00"
    And the threshold for a parliamentary debate is "5"
    And an open petition "p1" exists with action: "Petition 1", closed_at: "1 January 2012"
    And the petition "Petition 1" has 25 validated signatures
    And an open petition "p2" exists with action: "Petition 2", closed_at: "20 August 2011"
    And the petition "Petition 2" has 4 validated signatures
    And an open petition "p3" exists with action: "Petition 3", closed_at: "20 September 2011"
    And the petition "Petition 3" has 5 validated signatures
    And a closed petition "p4" exists with action: "Petition 4", closed_at: "20 April 2011"
    And the petition "Petition 4" has 10 validated signatures
    And an open petition "p5" exists with action: "Petition 5", response_required: false
    And a closed petition "p6" exists with action: "Petition 6", response_required: true, closed_at: "21 April 2011"

  Scenario: A moderator user sees all petitions above the threshold signature count
    When I go to the admin threshold page
    Then I should see the following admin index table:
      | Action     | Count | Closing date |
      | Petition 6 | 1     | 21-04-2011   |
      | Petition 3 | 5     | 20-09-2011   |
      | Petition 4 | 10    | 20-04-2011   |
      | Petition 1 | 25    | 01-01-2012   |
    And I should be connected to the server via an ssl connection
    And the markup should be valid

  Scenario: Threshold petitions are paginated
    Given I am logged in as a sysadmin
    And 20 petitions exist with a signature count of 6
    When I go to the admin threshold page
    And I follow "Next"
    Then I should see 4 rows in the admin index table
    And I follow "Previous"
    And I should see 20 rows in the admin index table

  Scenario: A moderator user can view the details of a petition and form fields
    When I go to the admin threshold page
    And I follow "Petition 1"
    And I should see "01-01-2012"
    And I should see a "Public response summary" textarea field
    And I should see a "Public response" textarea field
    And I should see a "Email signees" checkbox field

  Scenario: A moderator user updates the public response to a petition
    Given the time is "3 Dec 2010 01:00"
    When I go to the admin threshold page
    And I follow "Petition 1"
    And I fill in "Public response summary" with "Ready yourselves"
    And I fill in "Public response" with "Parliament here it comes. This is a long text."
    And I check "Email signees"
    And I press "Save"
    Then I should be on the admin all petitions page
    And the petition with action: "Petition 1" should have requested a government response email after "2010-12-03 01:00:00"
    And the response summary to "Petition 1" should be publicly viewable on the petition page
    And the response to "Petition 1" should be publicly viewable on the petition page
    And the petition signatories of "Petition 1" should receive a response notification email

  Scenario: A moderator user unsuccessfully tries to update the public response to a petition
    Given the time is "3 Dec 2010 01:00"
    When I go to the admin threshold page
    And I follow "Petition 1"
    And I check "Email signees"
    And I press "Save"
    Then I should see "must be completed when email signees is checked"
    And the petition with action: "Petition 1" should not have requested a government response email
    And the petition signatories of "Petition 1" should not receive a response notification email
