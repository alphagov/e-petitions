Feature: Unsubscribing from petiton updates as Suzie
  In order to not receive any more emails regarding the petition
  As Suzie
  I want to be able to unsubscribe from petition updates

  Background:
    Given a petition "Wombles of Wimbledon"
    And Suzie has already signed the petition
    And a moderator responds to the petition

  Scenario: Suzie receives and email containing an unsubscription link
    Then Suzie should have received a petition response email with an unsubscription link
    When Suzie follows the unsubscription link
    Then Suzie should see a confirmation page stating that her subscription was successful
    And Suzie should no longer receive any emails regarding this petition
