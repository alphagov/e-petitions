Feature: Suzie signs a petition
  In order to have my say
  As Suzie
  I want to sign an existing petition

  Background:
    Given a petition "Do something!"

  Scenario: Suzie signs a petition after validating her email
    When I decide to sign the petition
    And I fill in my details
    And I try to sign
    And I say I am happy with my email address
    Then I am told to check my inbox to complete signing
    And "womboid@wimbledon.com" should receive 1 email
    When I confirm my email address
    Then I should have signed the petition

  Scenario: Suzie signs a petition after validating her email
    When I go to the new signature page for "Do something!"
    And I should see "Do something! - Sign this petition - Petitions" in the browser page title
    And I should be connected to the server via an ssl connection
    And I fill in my details with email "womboid@wimbledon.com"
    And I fill in my postcode with "N1 1TY"
    And I try to sign
    Then I am asked to review my email address
    When I change my email address to "womboidian@wimbledon.com"
    And I say I am happy with my email address
    Then I am told to check my inbox to complete signing
    And "womboid@wimbledon.com" should receive no email
    And "womboidian@wimbledon.com" should receive 1 email
    When I confirm my email address
    Then I should see "2 signatures"
    And I should see my constituency "Islington South and Finsbury"
    And I should see my MP
    And I can click on a link to visit my MP
    And I can click on a link to return to the petition
    When I follow "Do something!"
    Then I should see "2 signatures"

  Scenario: Suzie signs a petition with an invalid name
    When I go to the new signature page for "Do something!"
    And I fill in "Name" with "=cmd"
    And I press "Continue"
    Then I should see "Name can't start with a '=', '+', '-' or '@'"

  Scenario: Suzie signs a petition with a link in their name
    When I go to the new signature page for "Do something!"
    And I fill in "Name" with "http://petition.parliament.uk"
    And I press "Continue"
    Then I should see "Name can't contain links"

  Scenario: Suzie signs a petition with invalid postcode SW14 9RQ
    When I go to the new signature page for "Do something!"
    And I fill in my details with email "womboid@wimbledon.com"
    And I fill in my postcode with "SW14 9RQ"
    And I try to sign
    Then I am asked to review my email address
    And I say I am happy with my email address
    Then I am told to check my inbox to complete signing
    And "womboid@wimbledon.com" should receive 1 email
    When I confirm my email address
    Then I should see "2 signatures"
    And I should not see the text "Your constituency is"
    And I should not see the text "Your MP is"

  Scenario: Suzie cannot sign if she is not a UK citizen
    When I decide to sign the petition
    And I fill in my non-UK details
    And I try to sign
    Then I should see an error

  Scenario: Suzie receives a duplicate signature email if she tries to sign but she has already signed and validated
    When I have already signed the petition with an uppercase email
    And I decide to sign the petition
    And I fill in my details
    And I try to sign
    And I say I am happy with my email address
    Then "WOMBOID@wimbledon.com" should receive 1 email with subject "You have tried to sign this petition twice"

  Scenario: Suzie receives a duplicate signature email if she changes to her original email but she has already signed and validated
    When I have already signed the petition with an uppercase email
    And I decide to sign the petition
    And I fill in my details with email "womboidian@wimbledon.com"
    And I try to sign
    When I change my email address to "womboid@wimbledon.com"
    And I say I am happy with my email address
    Then "WOMBOID@wimbledon.com" should receive 1 email with subject "You have tried to sign this petition twice"

  Scenario: Suzie receives a duplicate signature email if an alias has been used to sign the petition already
    Given "wimbledon.com" is configured to normalize email address
    And I have already signed the petition using an alias
    When I decide to sign the petition
    And I fill in my details with postcode "N1 1TY"
    And I try to sign
    And I say I am happy with my email address
    Then "wom.boid@wimbledon.com" should receive 1 email with subject "You have tried to sign this petition twice"

  Scenario: Suzie receives another email if she has already signed but not validated
    When I have already signed the petition but not validated my email
    And I decide to sign the petition
    And I fill in my details with postcode "N1 1TY"
    And I try to sign
    And I say I am happy with my email address
    Then the signature count stays at 2
    And I am told to check my inbox to complete signing
    And "womboid@wimbledon.com" should receive 1 email
    When I confirm my email address
    Then I should see "2 signatures"
    And I should see my constituency "Islington South and Finsbury"
    And I should see my MP
    And I can click on a link to visit my MP
    And I can click on a link to return to the petition
    When I follow "Do something!"
    Then I should see "2 signatures"

  Scenario: Suzie receives another email if she has already signed using an alias but not validated
    Given "wimbledon.com" is configured to normalize email address
    And I have already signed the petition using an alias but not validated my email
    When I decide to sign the petition
    And I fill in my details with postcode "N1 1TY"
    And I try to sign
    And I say I am happy with my email address
    Then the signature count stays at 2
    And I am told to check my inbox to complete signing
    And "wom.boid@wimbledon.com" should receive 1 email
    When I confirm my email address
    Then I should see "2 signatures"
    And I should see my constituency "Islington South and Finsbury"
    And I should see my MP
    And I can click on a link to visit my MP
    And I can click on a link to return to the petition
    When I follow "Do something!"
    Then I should see "2 signatures"

  Scenario: Suzie receives an email if her email has been used to sign the petition already
    When Eric has already signed the petition with Suzies email
    And I decide to sign the petition
    And I fill in my details
    And I try to sign
    And I say I am happy with my email address
    Then the signature count goes up to 3
    And I am told to check my inbox to complete signing
    And "womboid@wimbledon.com" should receive 1 email

  Scenario: Suzie cannot sign if she does not provide her details
    When I decide to sign the petition
    And I try to sign
    Then I should see an error

  Scenario: Suzie sees notice that she has already signed when she validates more than once
    When I fill in my details and sign a petition
    And I confirm my email address
    And I should see "2 signatures"
    And I should see "We've added your signature to the petition"
    And I can click on a link to return to the petition
    And I should have signed the petition
    When I confirm my email address again
    And I should see "2 signatures"
    And I should see "We've added your signature to the petition"
    And I can click on a link to return to the petition

  Scenario: Eric clicks the link shared to him by Suzie
    When Suzie has already signed the petition
    And Suzie shares the signatory confirmation link with Eric
    And I click the shared link
    Then I should see "Sign this petition"

  Scenario: Suzie cannot start a new signature when the petition has closed
    Given the petition has closed
    When I go to the new signature page
    Then I should be on the petition page
    And I should see "This petition is closed"

  Scenario: Suzie cannot create a new signature when the petition has closed
    Given I am on the new signature page
    And the petition has closed
    When I fill in my details
    And I try to sign
    Then I should be on the petition page
    And I should see "This petition is closed"

  Scenario: Suzie cannot confirm her email when the petition has closed
    Given I am on the new signature page
    When I fill in my details
    And I try to sign
    Then I should be on the new signature page
    When the petition has closed
    And I say I am happy with my email address
    Then I should be on the petition page
    And I should see "This petition is closed"

  Scenario: Suzie cannot validate her signature when the petition has closed
    Given I am on the new signature page
    When I fill in my details
    And I try to sign
    Then I should be on the new signature page
    When I say I am happy with my email address
    Then I am told to check my inbox to complete signing
    And "womboid@wimbledon.com" should receive 1 email
    When the petition has closed some time ago
    And I confirm my email address
    Then I should be on the petition page
    And I should see "This petition is closed"
    And I should see "1 signature"

  Scenario: Suzie can validate her signature when the petition has closed recently
    Given I am on the new signature page
    When I fill in my details
    And I try to sign
    Then I should be on the new signature page
    When I say I am happy with my email address
    Then I am told to check my inbox to complete signing
    And "womboid@wimbledon.com" should receive 1 email
    When the petition has closed
    And I confirm my email address
    Then I should see "We've added your signature to the petition"
    And I should see "2 signatures"
    When I follow "Do something!"
    Then I should be on the petition page
    And I should see "This petition is closed"
    And I should see "2 signatures"

  Scenario: Suzie cannot validate her signature when the domain is blocked
    Given the domain "wimbledon.com" is blocked
    When I am on the new signature page
    And I fill in my details
    And I try to sign
    Then I should be on the new signature page
    When I say I am happy with my email address
    Then I am told to check my inbox to complete signing
    And "womboid@wimbledon.com" should receive 1 email
    And I confirm my email address
    Then I should see "We've added your signature to the petition"
    And I should see "2 signatures"
    When I follow "Do something!"
    Then I should be on the petition page
    And I should see "1 signature"
    And the signature "womboid@wimbledon.com" is marked as fraudulent

  Scenario: Suzie cannot validate her signature when the email address is blocked
    Given the email address "womboid@wimbledon.com" is blocked
    When I am on the new signature page
    And I fill in my details
    And I try to sign
    Then I should be on the new signature page
    When I say I am happy with my email address
    Then I am told to check my inbox to complete signing
    And "womboid@wimbledon.com" should receive 1 email
    And I confirm my email address
    Then I should see "We've added your signature to the petition"
    And I should see "2 signatures"
    When I follow "Do something!"
    Then I should be on the petition page
    And I should see "1 signature"
    And the signature "womboid@wimbledon.com" is marked as fraudulent

  Scenario: Suzie can validate her signature when another email address on the same domain is blocked
    Given the email address "bulgaria@wimbledon.com" is blocked
    When I am on the new signature page
    And I fill in my details
    And I try to sign
    Then I should be on the new signature page
    When I say I am happy with my email address
    Then I am told to check my inbox to complete signing
    And "womboid@wimbledon.com" should receive 1 email
    And I confirm my email address
    Then I should see "We've added your signature to the petition"
    And I should see "2 signatures"
    When I follow "Do something!"
    Then I should be on the petition page
    And I should see "2 signatures"
    And the signature "womboid@wimbledon.com" is marked as validated

  Scenario: Suzie cannot validate her signature when IP address is rate limited
    Given the burst rate limit is 1 per minute
    And there are no allowed IPs
    And there is a signature already from this IP address
    When I am on the new signature page
    And I fill in my details
    And I try to sign
    Then I should be on the new signature page
    When I say I am happy with my email address
    Then I am told to check my inbox to complete signing
    And "womboid@wimbledon.com" should receive 1 email
    And I confirm my email address
    Then I should see "We've added your signature to the petition"
    And I should see "2 signatures"
    When I follow "Do something!"
    Then I should be on the petition page
    And I should see "1 signature"
    And the signature "womboid@wimbledon.com" is marked as fraudulent

  Scenario: Suzie can validate her signature when IP address is rate limited but the domain is allowed
    Given the burst rate limit is 1 per minute
    And there are no allowed IPs
    And the domain "wimbledon.com" is allowed
    And there is a signature already from this IP address
    When I am on the new signature page
    And I fill in my details
    And I try to sign
    Then I should be on the new signature page
    When I say I am happy with my email address
    Then I am told to check my inbox to complete signing
    And "womboid@wimbledon.com" should receive 1 email
    And I confirm my email address
    Then I should see "We've added your signature to the petition"
    And I should see "2 signatures"
    When I follow "Do something!"
    Then I should be on the petition page
    And I should see "2 signatures"
    And the signature "womboid@wimbledon.com" is marked as validated

  Scenario: Suzie signs a petition with a typo in her email
    Given I am on the new signature page
    When I fill in my details with email "suzie@gmial.com"
    And I try to sign
    Then my email is autocorrected to "suzie@gmail.com"
    When I say I am happy with my email address
    Then a signature should exist with email: "suzie@gmail.com", state: "pending"
    And "suzie@gmail.com" should receive 1 email
    When I confirm my email address
    Then I should see "We've added your signature to the petition"
    And a signature should exist with email: "suzie@gmail.com", state: "validated"

  Scenario: Suzie signs a petition when her email is autocorrected wrongly
    Given I am on the new signature page
    When I fill in my details with email "suzie@gmial.com"
    And I try to sign
    Then my email is autocorrected to "suzie@gmail.com"
    When I fill in "Email" with "suzie@gmial.com"
    And I say I am happy with my email address
    Then a signature should exist with email: "suzie@gmial.com", state: "pending"
    And "suzie@gmial.com" should receive 1 email
    When I confirm my email address
    Then I should see "We've added your signature to the petition"
    And a signature should exist with email: "suzie@gmial.com", state: "validated"

  @javascript
  Scenario: Suzie signs a petition from overseas
    Given I am on the new signature page
    Then I should see a "Postcode" text field
    When I select "United States" from "Location"
    Then I should not see a "Postcode" text field
    When I check "I am a British citizen or UK resident"
    And I fill in "Name" with "Womboid Wibbledon"
    And I fill in "Email" with "womboid@wimbledon.com"
    And I press "Continue"
    Then I should see "Make sure this is right"
    When I press "Yes – this is my email address"
    Then a signature should exist with email: "womboid@wimbledon.com", state: "pending", location_code: "US", postcode: ""
