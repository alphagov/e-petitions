Feature: As Charlie
  In order to have an issue discussed in parliament
  I want to be able to create a petition and verify my email address.

Scenario: Charlie has to search for a petition before creating one
  Given the following petitions exist:
    | action                         | state    | signature_count | open_at    |
    | Rioters should loose benefits  | open     |             835 | 2011-08-11 |
    | Rioters must loose benefits    | rejected |               5 |            |
    | Do not remove rioters benefits | open     |            1023 | 2011-08-21 |
  And I am on the home page
  When I follow "Start a petition" within ".//main"
  Then I should be asked to search for a new petition
  When I check for similar petitions
  Then I should see the following similar petitions:
    | Do not remove rioters benefits | 1,023 signatures |
    | Rioters should loose benefits  | 835 signatures   |
  When I choose to create a petition anyway
  Then I should be on the new petition page
  And I should be asked to confirm my eligibility
  When I confirm that I am UK citizen or resident
  Then I should see my search query already filled in as the action of the petition

Scenario: Charlie starts to create a petition when parliament is not dissolving
  Given I am on the check for existing petitions page
  Then I should not see "Parliament is dissolving"

Scenario: Charlie starts to create a petition when parliament is dissolving
  Given Parliament is dissolving
  And I am on the check for existing petitions page
  Then I should see the Parliament dissolution warning message
  When I am on the home page
  Then I should see the Parliament dissolution warning message
  When I am on the help page
  Then I should see the Parliament dissolution warning message

Scenario: Charlie starts to create a petition when parliament is dissolved
  Given Parliament is dissolved
  And I am on the check for existing petitions page
  Then I should be on the home page
  And I should see the Parliament dissolved warning message
  When I am on the help page
  Then I should see the Parliament dissolved warning message

Scenario: Charlie cannot craft an xss attack when searching for petitions
  Given I am on the home page
  When I follow "Start a petition" within ".//main"
  Then I fill in "q" with "'onmouseover='alert(1)'"
  When I press "Continue"
  Then the markup should be valid

Scenario: Charlie creates a petition
  Given I start a new petition
  And I confirm that I am UK citizen or resident
  And I fill in the petition details
  And I press "Preview petition"
  And I press "This looks good"
  And I fill in my details
  When I press "Continue"
  Then the markup should be valid
  And I am asked to review my email address
  When I press "Yes – this is my email address"
  Then I should see "We’ve emailed you a link"
  And a petition should exist with action: "The wombats of wimbledon rock.", state: "pending"
  And there should be a "pending" signature with email "womboid@wimbledon.com" and name "Womboid Wibbledon"
  And "Womboid Wibbledon" wants to be notified about the petition’s progress
  And "womboid@wimbledon.com" should be emailed a link for gathering support from sponsors

Scenario: First person sponsors a petition
  When I have created a petition and told people to sponsor it
  And a sponsor supports my petition
  Then my petition should be validated
  And the petition creator signature should be validated

Scenario: Charlie creates a petition with invalid postcode SW14 9RQ
  Given I start a new petition
  And I confirm that I am UK citizen or resident
  And I fill in the petition details
  And I press "Preview petition"
  And I press "This looks good"
  And I fill in my details with postcode "SW14 9RQ"
  And I press "Continue"
  Then I should not see the text "Your constituency is"

@javascript
Scenario: Charlie tries to submit an invalid petition
  Given I am on the new petition page
  And I confirm that I am UK citizen or resident

  When I press "Preview petition"
  Then I should see "Action must be completed"
  And I should see "Background must be completed"

  When I am allowed to make the petition action too long
  And I fill in "What do you want us to do?" with text longer than 80 characters
  And I fill in "Tell us more about what you want the Government or Parliament to do" with text longer than 300 characters
  And I fill in "Tell us more about why you want the Government or Parliament to do it" with text longer than 800 characters
  And I press "Preview petition"

  Then I should see "Action is too long"
  And I should see "Background is too long"
  And I should see "Additional details is too long"

  When I fill in "What do you want us to do?" with "=cmd"
  And I fill in "Tell us more about what you want the Government or Parliament to do" with "@cmd"
  And I fill in "Tell us more about why you want the Government or Parliament to do it" with "+cmd"
  And I press "Preview petition"

  Then I should see "Action can’t start with a '=', '+', '-' or '@'"
  And I should see "Background can’t start with a '=', '+', '-' or '@'"
  And I should see "Additional details can’t start with a '=', '+', '-' or '@'"

  When I fill in "What do you want us to do?" with "The wombats of wimbledon rock."
  And I fill in "Tell us more about what you want the Government or Parliament to do" with "Give half of Wimbledon rock to wombats!"
  And I fill in "Tell us more about why you want the Government or Parliament to do it" with "The racial tensions between the wombles and the wombats are heating up. Racial attacks are a regular occurrence and the death count is already in 5 figures. The only resolution to this crisis is to give half of Wimbledon common to the Wombats and to recognise them as their own independent state."
  And I press "Preview petition"

  Then I should see a heading called "Check your petition"

  And I should see "The wombats of wimbledon rock."
  And I expand "More details"
  And I should see "The racial tensions between the wombles and the wombats are heating up. Racial attacks are a regular occurrence and the death count is already in 5 figures. The only resolution to this crisis is to give half of Wimbledon common to the Wombats and to recognise them as their own independent state."

  And I press "Go back and make changes"
  And the "What do you want us to do?" field should contain "The wombats of wimbledon rock."
  And the "Tell us more about what you want the Government or Parliament to do" field should contain "Give half of Wimbledon rock to wombats!"
  And the "Tell us more about why you want the Government or Parliament to do it" field should contain "The racial tensions between the wombles and the wombats are heating up. Racial attacks are a regular occurrence and the death count is already in 5 figures. The only resolution to this crisis is to give half of Wimbledon common to the Wombats and to recognise them as their own independent state."

  And I press "Preview petition"
  And I press "This looks good"

  Then I should see a heading called "Sign your petition"

  When I press "Continue"
  Then I should see "Name must be completed"
  And I should see "Email must be completed"
  And I should see "Postcode must be completed"

  When I fill in "Name" with "=cmd"
  And I press "Continue"

  Then I should see "Name can’t start with a '=', '+', '-' or '@'"

  When I am allowed to make the creator name too long
  When I fill in "Name" with text longer than 255 characters
  And I press "Continue"

  Then I should see "Name is too long"

  When I fill in my details
  And I press "Continue"

  Then I should see a heading called "Make sure this is right"

  And I press "Back"
  And I fill in "Name" with "Mr. Wibbledon"

  And I press "Continue"

  Then I should see a heading called "Make sure this is right"

  When I fill in "Email" with ""
  And I press "Yes – this is my email address"
  Then I should see "Email must be completed"
  When I fill in "Email" with "womboid@wimbledon.com"
  And I press "Yes – this is my email address"

  Then I should see "We’ve emailed you a link"
  And a petition should exist with action: "The wombats of wimbledon rock.", state: "pending"
  And there should be a "pending" signature with email "womboid@wimbledon.com" and name "Mr. Wibbledon"

Scenario: Charlie creates a petition with a typo in his email
  Given I start a new petition
  And I confirm that I am UK citizen or resident
  And I fill in the petition details
  And I press "Preview petition"
  And I press "This looks good"
  And I fill in my details with email "charlie@hotmial.com"
  And I press "Continue"
  Then my email is autocorrected to "charlie@hotmail.com"
  When I press "Yes – this is my email address"
  Then I should see "We’ve emailed you a link"
  And a petition should exist with action: "The wombats of wimbledon rock.", state: "pending"
  And a signature should exist with email: "charlie@hotmail.com", state: "pending"

Scenario: Charlie creates a petition when his email is autocorrected wrongly
  Given I start a new petition
  And I confirm that I am UK citizen or resident
  And I fill in the petition details
  And I press "Preview petition"
  And I press "This looks good"
  And I fill in my details with email "charlie@hotmial.com"
  And I press "Continue"
  Then my email is autocorrected to "charlie@hotmail.com"
  When I fill in "Email" with "charlie@hotmial.com"
  And I press "Yes – this is my email address"
  Then I should see "We’ve emailed you a link"
  And a petition should exist with action: "The wombats of wimbledon rock.", state: "pending"
  And a signature should exist with email: "charlie@hotmial.com", state: "pending"

Scenario: Charlie creates a petition when his IP address is blocked
  Given the IP address 127.0.0.1 is blocked
  And I start a new petition
  And I confirm that I am UK citizen or resident
  And I fill in the petition details
  And I press "Preview petition"
  And I press "This looks good"
  And I fill in my details
  When I press "Continue"
  Then the markup should be valid
  And I am asked to review my email address
  When I press "Yes – this is my email address"
  Then I should see "We’ve emailed you a link"
  And a petition should not exist with action: "The wombats of wimbledon rock.", state: "pending"
  And a signature should not exist with email: "womboid@wimbledon.com", state: "pending"

Scenario: Charlie creates a petition when his email address is blocked
  Given the email address "womboid@wimbledon.com" is blocked
  And I start a new petition
  And I confirm that I am UK citizen or resident
  And I fill in the petition details
  And I press "Preview petition"
  And I press "This looks good"
  And I fill in my details
  When I press "Continue"
  Then the markup should be valid
  And I am asked to review my email address
  When I press "Yes – this is my email address"
  Then I should see "We’ve emailed you a link"
  And a petition should not exist with action: "The wombats of wimbledon rock.", state: "pending"
  And a signature should not exist with email: "womboid@wimbledon.com", state: "pending"

Scenario: Charlie creates a petition when his IP address is rate limited
  Given the creator rate limit is 1 per hour
  And there are no allowed IPs
  And there are no blocked IPs
  And there are 2 petitions created from this IP address
  And I start a new petition
  And I confirm that I am UK citizen or resident
  And I fill in the petition details
  And I press "Preview petition"
  And I press "This looks good"
  And I fill in my details
  When I press "Continue"
  Then the markup should be valid
  And I am asked to review my email address
  When I press "Yes – this is my email address"
  Then I should see "We’ve emailed you a link"
  And a petition should not exist with action: "The wombats of wimbledon rock.", state: "pending"
  And a signature should not exist with email: "womboid@wimbledon.com", state: "pending"

@javascript
Scenario: Charlie creates a petition from overseas
  When I start a new petition
  And I confirm that I am UK citizen or resident
  And I fill in the petition details
  And I press "Preview petition"
  And I press "This looks good"
  Then I should see a "Postcode" text field
  When I select "United States" from "Location"
  Then I should not see a "Postcode" text field
  And I fill in "Name" with "Womboid Wibbledon"
  And I fill in "Email" with "womboid@wimbledon.com"
  And I press "Continue"
  Then I should see "Make sure this is right"
  When I press "Yes – this is my email address"
  Then I should see "We’ve emailed you a link"
  And a petition should exist with action: "The wombats of wimbledon rock.", state: "pending"
  And a signature should exist with email: "womboid@wimbledon.com", state: "pending", location_code: "US", postcode: ""
