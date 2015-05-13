Feature: Charlie is notified to get an MP
  As Charlie, creator of a petition with some sponsors
  In order to ensure that I am up to date with how many of my sponsors have signed
  I want to be emailed when they sign with a countdown to the threshold

  Background:
    Given I have created an e-petition with sponsors

  Scenario: Charlie is emailed about sponsor support before passing the threshold
    When a sponsor supports my e-petition
    Then I should receive a sponsor support notification email
    And the sponsor support notification email should include the countdown to the threshold

  Scenario: Charlie is emailed about moderation upon hitting the sponsor support threshold
    Given I only need one more sponsor to support my e-petition
    When a sponsor supports my e-petition
    Then I should receive a sponsor support notification email
    And the sponsor support notification email should tell me about my e-petition going into moderation

  Scenario: Charlie is no longer emailed about sponsor support after passing the threshold
    Given I have enough support from sponsors for my e-petition
    When a sponsor supports my e-petition
    Then I should not receive a sponsor support notification email
