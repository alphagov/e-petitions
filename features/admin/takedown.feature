@admin
Feature: Terry (or Sheila) takes down a petition
  In order to remove petitions that have been published by mistake
  As Terry or Sheila
  I want to reject a petition after it has been published, which sends the standard rejection email out to the creator and removes the petition from the site

  Background:
    Given a petition "Mistakenly published petition"

  Scenario: A sysadmin can take down a petition
    Given I am logged in as a sysadmin
    When I view all petitions
    And I follow "Mistakenly published petition"
    And I take down the petition with a reason code "Duplicate petition"
    Then the petition is not available for signing
    And I should not be able to take down the petition

  Scenario: A moderator can take down a petition
    Given I am logged in as a moderator
    When I view all petitions
    And I follow "Mistakenly published petition"
    And I take down the petition with a reason code "Duplicate petition"
    Then the petition is not available for signing
    And I should not be able to take down the petition

  Scenario: A moderator can take down a petition and hide it
    Given I am logged in as a moderator
    When I view all petitions
    And I follow "Mistakenly published petition"
    And I take down the petition with a reason code "Confidential, libellous, false, defamatory or references a court case"
    Then the petition is not available for searching or viewing
    And I should not be able to take down the petition

  Scenario: A moderator can take down a petition and hide it manually
    Given I am logged in as a moderator
    When I view all petitions
    And I follow "Mistakenly published petition"
    And I take down the petition with a reason code "Duplicate petition" and hide it
    Then the petition is not available for searching or viewing
    And I should not be able to take down the petition

  Scenario: A sysadmin can restore a petition that has been taken down
    Given I am logged in as a sysadmin
    And a published petition has been taken down
    When I visit the petition
    Then the petition can no longer be rejected
    And the petition can no longer be marked as dormant
    But it can still be approved
    And it can still be restored
    When I restore to a sponsored state
    Then the creator should not receive a notification email
    And the petition is not available for searching or viewing
    But the petition will still show up in the back-end reporting

  Scenario: A moderator can't restore a petition that has been taken down
    Given I am logged in as a moderator
    And a published petition has been taken down
    When I visit the petition
    Then there are no moderation options
