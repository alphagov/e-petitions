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
  Then I should see "Start your petition"
  When I follow "Start a petition" within ".//main"
  Then I should be asked to confirm my eligibility
  When I confirm that I am UK citizen or resident
  Then I should see "What do you want us to do?"
  When I fill in "What do you want us to do?" with "Rioters benefits"
  And I press "Continue"
  Then I should see the following similar petitions:
    | Do not remove rioters benefits | 1,023 signatures |
    | Rioters should loose benefits  | 835 signatures   |
  When I press "Continue with my petition"
  Then I should see "Tell us more about what you want the Government or Parliament to do"

Scenario: Charlie cannot create a petition if he is not a UK citizen
  Given I am on the start a new petition page
  And I follow "Start a petition" within ".//main"
  Then I should see "Are you a British citizen or UK resident?"
  When I choose "No"
  And press "Continue"
  Then I should see "Sorry, you can’t create a petition"

Scenario: Charlie starts to create a petition when parliament is not dissolving
  Given I am on the start a new petition page
  Then I should not see "Parliament is dissolving"

Scenario: Charlie starts to create a petition when parliament is dissolving
  Given Parliament is dissolving
  And I am on the start a new petition page
  Then I should see the Parliament dissolution warning message
  When I am on the home page
  Then I should see the Parliament dissolution warning message
  When I am on the help page
  Then I should see the Parliament dissolution warning message

Scenario: Charlie starts to create a petition when parliament is dissolved
  Given Parliament is dissolved
  And I am on the start a new petition page
  Then I should be on the home page
  And I should see the Parliament dissolved warning message
  When I am on the help page
  Then I should see the Parliament dissolved warning message

Scenario: Charlie cannot craft an xss attack when searching for petitions
  Given I am on the start a new petition page
  When I follow "Start a petition" within ".//main"
  Then I should be asked to confirm my eligibility
  When I confirm that I am UK citizen or resident
  Then I should see "What do you want us to do?"
  When I fill in "What do you want us to do?" with "'onmouseover='alert(1)'"
  When I press "Continue"
  Then the markup should be valid

Scenario: Charlie creates a petition
  Given I am on the start a new petition page
  And I follow "Start a petition" within ".//main"
  And I confirm that I am UK citizen or resident
  And I fill in the petition details
  And I fill in my details
  When I press "Continue"
  Then I should see "Check and submit your petition"
  When I press "Submit your petition"
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

@javascript
Scenario: Charlie tries to submit an invalid petition
  Given I am on the new petition page
  And I confirm that I am UK citizen or resident

  When I press "Continue"
  Then I should see "Action must be completed"

  When I fill in "What do you want us to do?" with text longer than 80 characters
  And I press "Continue"
  Then I should see "Action is too long"

  When I fill in "What do you want us to do?" with "=cmd"
  And I press "Continue"
  Then I should see "Action can’t start with a '=', '+', '-' or '@'"

  When I fill in "What do you want us to do?" with "The wombats of wimbledon rock."
  And I press "Continue"
  Then I should see "We checked for similar petitions"

  When I press "Continue with my petition"
  Then I should see "Say what you want the UK Government or Parliament to do"

  When I press "Continue"
  Then I should see "Background must be completed"

  When I fill in "Tell us more about what you want the Government or Parliament to do" with text longer than 300 characters
  And I press "Continue"
  Then I should see "Background is too long"

  When I fill in "Tell us more about what you want the Government or Parliament to do" with "@cmd"
  And I press "Continue"
  Then I should see "Background can’t start with a '=', '+', '-' or '@'"

  When I fill in "Tell us more about what you want the Government or Parliament to do" with "Give half of Wimbledon rock to wombats!"
  And I press "Continue"
  Then I should see "Add more information to your petition"

  When I fill in "Tell us more about why you want the Government or Parliament to do it" with text longer than 800 characters
  And I press "Continue"
  Then I should see "Additional details is too long"

  When I fill in "Tell us more about why you want the Government or Parliament to do it" with "+cmd"
  And I press "Continue"
  Then I should see "Additional details can’t start with a '=', '+', '-' or '@'"

  When I fill in "Tell us more about why you want the Government or Parliament to do it" with "The racial tensions between the wombles and the wombats are heating up. Racial attacks are a regular occurrence and the death count is already in 5 figures. The only resolution to this crisis is to give half of Wimbledon common to the Wombats and to recognise them as their own independent state."
  And I press "Continue"
  Then I should see "Confirm your details"

  When I press "Continue"
  Then I should see "Full name must be completed"
  And I should see "Email must be completed"
  And I should see "Email confirmation must be completed"
  And I should see "Postcode must be completed"

  When I fill in "Full name" with "=cmd"
  And I press "Continue"
  Then I should see "Full name can’t start with a '=', '+', '-' or '@'"

  When I am allowed to make the creator name too long
  And I fill in "Full name" with text longer than 255 characters
  And I press "Continue"

  Then I should see "Full name is too long"

  When I fill in my details
  And I press "Continue"
  Then I should see a heading called "Check and submit your petition"

  When I press "Change my details"
  And I fill in "Full name" with "Mr. Wibbledon"
  And I press "Continue"
  Then I should see a heading called "Check and submit your petition"

  When I press "Submit your petition"
  Then I should see "We’ve emailed you a link"
  And a petition should exist with action: "The wombats of wimbledon rock.", state: "pending"
  And there should be a "pending" signature with email "womboid@wimbledon.com" and name "Mr. Wibbledon"

Scenario: Charlie creates a petition when his IP address is blocked
  Given the IP address 127.0.0.1 is blocked
  And I start a new petition
  And I confirm that I am UK citizen or resident
  And I fill in the petition details
  And I fill in my details
  When I press "Continue"
  Then I should see "Check and submit your petition"
  When I press "Submit your petition"
  Then I should see "We’ve emailed you a link"
  And a petition should not exist with action: "The wombats of wimbledon rock.", state: "pending"
  And a signature should not exist with email: "womboid@wimbledon.com", state: "pending"

Scenario: Charlie creates a petition when his email address is blocked
  Given the email address "womboid@wimbledon.com" is blocked
  And I start a new petition
  And I confirm that I am UK citizen or resident
  And I fill in the petition details
  And I fill in my details
  When I press "Continue"
  Then I should see "Check and submit your petition"
  When I press "Submit your petition"
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
  And I fill in my details
  When I press "Continue"
  Then I should see "Check and submit your petition"
  When I press "Submit your petition"
  Then I should see "We’ve emailed you a link"
  And a petition should not exist with action: "The wombats of wimbledon rock.", state: "pending"
  And a signature should not exist with email: "womboid@wimbledon.com", state: "pending"

@javascript
Scenario: Charlie creates a petition from overseas
  When I start a new petition
  And I confirm that I am UK citizen or resident
  And I fill in the petition details
  Then I should see a "Postcode" text field
  When I select "United States" from "Location"
  Then I should not see a "Postcode" text field
  When I fill in "Full name" with "Womboid Wibbledon"
  And I fill in "Email address" with "womboid@wimbledon.com"
  And I fill in "Confirm email address" with "womboid@wimbledon.com"
  And I press "Continue"
  Then I should see "Check and submit your petition"
  When I press "Submit your petition"
  Then I should see "We’ve emailed you a link"
  And a petition should exist with action: "The wombats of wimbledon rock.", state: "pending"
  And a signature should exist with email: "womboid@wimbledon.com", state: "pending", location_code: "US", postcode: ""
