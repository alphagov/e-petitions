Feature: Charlie is notified to get an MP
  In order to ensure that Charlie has time to engage with an MP before the threshold is hit
  As Charlie
  I want to be emailed further instructions relating to getting an MP on board when my petition reaches a certain critical mass

  Scenario:
    Given I have created an e-petition
    When the e-petition recieves enough signatures to achieve 'critical mass'
    Then I should receive an email telling me how to get an MP on board
