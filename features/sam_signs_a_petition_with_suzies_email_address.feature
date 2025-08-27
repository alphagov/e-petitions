Feature: Sam signs a petition
  In order to have my say as well as Suzie without needing a separate email address
  As Sam, Suzie’s partner
  I want to sign a petition that has already been signed by Suzie

  Background:
    Given a petition "Do something!"
    And Suzie has already signed the petition

  Scenario: Sam can sign the petition with a different name
    When I try to sign the petition with the same email address and a different name
    Then I should have signed the petition after confirming my email address

  Scenario: Sam cannot sign the petition again using Suzie’s name
    When I try to sign the petition with the same email address and the same name
    Then "womboid@wimbledon.com" should receive an email with subject "Duplicate signature of petition"

  Scenario: Sam cannot sign the petition with a different postcode
    When I try to sign the petition with the same email address, a different name, and a different postcode
    Then "womboid@wimbledon.com" should receive an email with subject "Duplicate signature of petition"

  Scenario: Sarah (Sam’s daughter) cannot sign the petition a third time with the same email address
    Given I have signed the petition with a second name
    When I try to sign the petition with the same email address and a third name
    Then "womboid@wimbledon.com" should receive an email with subject "Duplicate signature of petition"
