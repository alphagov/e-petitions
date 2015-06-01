Feature: Resending confirmation emails as Suzie
  In order to confirm a signature on a petition
  As Suzie
  I want to be able to have the confirmation email resent to me

  Background:
    Given a petition "Free the Wombles!"

  @javascript
  Scenario: Single Suzie has never even started signing the petition
    When I ask for my confirmation email to be resent
    Then I should see an ambiguous message telling me I'll receive an email
    Then I should receive an email telling me that I've not signed this petition

  @javascript
  Scenario: Single Suzie has a pending signature
    Given I have already signed the petition "Free the Wombles!" but not confirmed my email
    When I ask for my confirmation email to be resent
    Then I should see an ambiguous message telling me I'll receive an email
    Then I should receive an email with my confirmation link

  @javascript
  Scenario: Single Suzie has already validated her signature
    Given I have already signed the petition "Free the Wombles!"
    When I ask for my confirmation email to be resent
    Then I should see an ambiguous message telling me I'll receive an email
    Then I should receive an email telling me I've already confirmed

  @javascript
  Scenario: Suzie and Sam have two pending signatures
    Given I have already signed the petition "Free the Wombles!" but not confirmed my email
    And Sam has signed the petition "Free the Wombles!" but not confirmed by email
    When I ask for my confirmation email to be resent
    Then I should see an ambiguous message telling me I'll receive an email
    Then I should receive an email with two confirmation links

  @javascript
  Scenario: Suzie and Sam have one pending and one validated signature
    Given I have already signed the petition "Free the Wombles!"
    And Sam has signed the petition "Free the Wombles!" but not confirmed by email
    When I ask for my confirmation email to be resent
    Then I should see an ambiguous message telling me I'll receive an email
    Then I should receive an email telling me one has signed, with the second confirmation link

  @javascript
  Scenario: Suzie and Sam have two validated signatures
    Given I have already signed the petition "Free the Wombles!"
    And Sam has signed the petition "Free the Wombles!"
    When I ask for my confirmation email to be resent
    Then I should see an ambiguous message telling me I'll receive an email
    Then I should receive an email telling me we've already confirmed

  @javascript
  Scenario: Don't ever attempt to send email to an invalid address
    When I ask for my confirmation email to be resent with an invalid address
    Then I should see an ambiguous message telling me I'll receive an email
    But we don't send the resend email as the address is invalid

  Scenario: Petition has closed
