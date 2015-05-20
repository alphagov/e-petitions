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
    And I take down the petition with a reason code "Duplicate of an existing e-petition"
    Then the petition is not available for signing
    And I should not be able to take down the petition

  Scenario: A moderator can take down a petition
    Given I am logged in as a moderator
    When I view all petitions
    And I follow "Mistakenly published petition"
    And I take down the petition with a reason code "Duplicate of an existing e-petition"
    Then the petition is not available for signing
    And I should not be able to take down the petition
