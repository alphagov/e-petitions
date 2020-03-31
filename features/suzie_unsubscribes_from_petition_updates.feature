Feature: Unsubscribing from petition updates as Suzie
  In order to not receive any more emails regarding the petition
  As Suzie
  I want to be able to unsubscribe from petition updates

  Background:
    Given a petition "Wombles of Wimbledon"
    And the petition "Wombles of Wimbledon" has 5 validated signatures
    And Suzie has already signed the petition
    And the threshold for a Senedd debate is "5"
    And a moderator updates the petition activity

  Scenario: Suzie receives an email containing an unsubscription link
    Then Suzie should have received a petition response email with an unsubscription link
    When Suzie follows the unsubscription link
    Then Suzie should see a confirmation page stating that her subscription was successful
    And Suzie should no longer receive any emails regarding this petition
