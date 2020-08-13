Feature: As Charlie
  In order to have an issue discussed in the Senedd
  I want to be able to create a petition and verify my email address.

Scenario: Charlie has to search for a petition before creating one
  Given a petition "Rioters should loose benefits"
  And a rejected petition "Rioters must loose benefits"
  Given I am on the home page
  When I follow "Start a petition" within ".//main"
  Then I should be asked to search for a new petition
  When I check for similar petitions
  Then I should see "Rioters should loose benefits"
  Then I should not see "Rioters must loose benefits"
  When I choose to create a petition anyway
  Then I should be on the new petition page
  And I should see my search query already filled in as the action of the petition

Scenario: Charlie cannot craft an xss attack when searching for petitions
  Given I am on the home page
  When I follow "Start a petition" within ".//main"
  Then I fill in "q" with "'onmouseover='alert(1)'"
  When I press "Continue"
  Then the markup should be valid

Scenario: Charlie creates a petition
  Given I start a new petition
  And I fill in the petition details
  And I press "Preview petition"
  And I press "This looks good"
  And I choose the default closing date
  And I fill in my details as a creator
  And I fill in my creator contact details
  When I press "Continue"
  Then the markup should be valid
  And I am asked to review my email address
  When I press "Yes – this is my email address"
  Then a petition should exist with action_en: "The wombats of wimbledon rock.", action_cy: nil, state: "pending", locale: "en-GB"
  And there should be a "pending" signature with email "womboid@wimbledon.com" and name "Womboid Wibbledon"
  And "Womboid Wibbledon" wants to be notified about the petition's progress
  And "womboid@wimbledon.com" should be emailed a link for gathering support from sponsors

Scenario: Charlie creates a petition with a custom closing date
  Given the date is the "20 April, 2020"
  And I start a new petition
  And I fill in the petition details
  And I press "Preview petition"
  And I press "This looks good"
  And I choose "I want to stop collecting signatures on a specific date"
  And I fill in the closing date with "2020-08-31"
  And I press "Check closing date"
  Then I should see "31 August 2020"
  When I press "This looks good"
  And I fill in my details as a creator
  And I fill in my creator contact details
  And I press "Continue"
  Then I am asked to review my email address
  When I press "Yes – this is my email address"
  Then the petition "The wombats of wimbledon rock." should exist with a closing date of "2020-08-31"

@welsh
Scenario: Charlie creates a petition in Welsh
  Given I start a new petition
  And I fill in the petition details
  And I press "Gweld rhagolwg o’r ddeiseb"
  And I press "Mae’n edrych yn iawn"
  And I choose the default closing date
  And I fill in my details as a creator
  And I fill in my creator contact details
  When I press "Parhau"
  Then the markup should be valid
  And I am asked to review my email address
  When I press "Ie – dyma fy nghyfeiriad e-bost i"
  Then a petition should exist with action_cy: "The wombats of wimbledon rock.", action_en: nil, state: "pending", locale: "cy-GB"
  And there should be a "pending" signature with email "womboid@wimbledon.com" and name "Womboid Wibbledon"
  And "Womboid Wibbledon" wants to be notified about the petition's progress
  And "womboid@wimbledon.com" should be emailed a link for gathering support from sponsors

Scenario: First person sponsors a petition
  When I have created a petition and told people to sponsor it
  And a sponsor supports my petition
  Then my petition should be validated
  And the petition creator signature should be validated

Scenario: Charlie creates a petition with invalid postcode SW14 9RQ
  Given I start a new petition
  And I fill in the petition details
  And I press "Preview petition"
  And I press "This looks good"
  And I choose the default closing date
  And I fill in my details as a creator with postcode "SW14 9RQ"
  And I fill in my creator contact details
  And I press "Continue"
  Then I should not see the text "Your constituency is"

@javascript
Scenario: Charlie tries to submit an invalid petition
  Given I am on the new petition page

  When I press "Preview petition"
  Then I should see "Action must be completed"
  And I should see "Background must be completed"

  When I am allowed to make the petition action too long
  When I fill in "What do you want us to do?" with text longer than 100 characters
  And I fill in "Background" with text longer than 500 characters
  And I fill in "Additional details" with text longer than 1100 characters
  And I press "Preview petition"

  Then I should see "Action is too long"
  And I should see "Background is too long"
  And I should see "Additional details is too long"

  When I fill in "What do you want us to do?" with "=cmd"
  And I fill in "Background" with "@cmd"
  And I fill in "Additional details" with "+cmd"
  And I press "Preview petition"

  Then I should see "Action can’t start with a ‘=’, ‘+’, ‘-’ or ‘@’"
  And I should see "Background can’t start with a ‘=’, ‘+’, ‘-’ or ‘@’"
  And I should see "Additional details can’t start with a ‘=’, ‘+’, ‘-’ or ‘@’"

  When I fill in "What do you want us to do?" with "The wombats of wimbledon rock."
  And I fill in "Background" with "Give half of Wimbledon rock to wombats!"
  And I fill in "Additional details" with "The racial tensions between the wombles and the wombats are heating up. Racial attacks are a regular occurrence and the death count is already in 5 figures. The only resolution to this crisis is to give half of Wimbledon common to the Wombats and to recognise them as their own independent state."
  And I press "Preview petition"

  Then I should see a heading called "Check your petition"

  And I should see "The wombats of wimbledon rock."
  And I expand "More details"
  And I should see "The racial tensions between the wombles and the wombats are heating up. Racial attacks are a regular occurrence and the death count is already in 5 figures. The only resolution to this crisis is to give half of Wimbledon common to the Wombats and to recognise them as their own independent state."

  And I press "Go back and make changes"
  And the "What do you want us to do?" field should contain "The wombats of wimbledon rock."
  And the "Background" field should contain "Give half of Wimbledon rock to wombats!"
  And the "Additional details" field should contain "The racial tensions between the wombles and the wombats are heating up. Racial attacks are a regular occurrence and the death count is already in 5 figures. The only resolution to this crisis is to give half of Wimbledon common to the Wombats and to recognise them as their own independent state."

  And I press "Preview petition"
  And I press "This looks good"

  Then I should see a heading called "How long would you like to collect signatures for?"

  When I choose "I want to stop collecting signatures on a specific date"
  And I press "Check closing date"

  Then I should see "Closing date must be completed"

  When I fill in "Day" with "0"
  And I fill in "Month" with "0"
  And I fill in "Year" with "0"
  And I press "Check closing date"

  Then I should see "Closing date not recognised"

  When I fill in "Day" with "31"
  And I fill in "Month" with "10"
  And I fill in "Year" with "1968"
  And I press "Check closing date"

  Then I should see "Closing date is in the past"

  When I fill in the closing date with a date 20 days from today
  And I press "Check closing date"

  Then I should see "Closing date must be at least 30 days from today"

  When I fill in the closing date with a date 9 months from today
  And I press "Check closing date"

  Then I should see "Closing date must be no more than 6 months from today"

  When I fill in the closing date with a date 3 months from today
  And I press "Check closing date"

  Then I should see a heading called "Check your closing date"

  When I press "This looks good"
  Then I should see a heading called "Sign your petition"

  When I press "Continue"
  Then I should see "Name must be completed"
  And I should see "Email must be completed"
  And I should see "Postcode must be completed"
  And I should see "Phone number must be completed"
  And I should see "Address must be completed"

  When I fill in "Address" with text longer than 500 characters
  And I fill in "Phone number" with "32000000000000000000000000000000"
  And I press "Continue"
  Then I should see "Phone number is too long"
  And I should see "Address is too long"

  When I fill in "Name" with "=cmd"
  And I press "Continue"

  Then I should see "Name can’t start with a ‘=’, ‘+’, ‘-’ or ‘@’"

  When I am allowed to make the creator name too long
  When I fill in "Name" with text longer than 255 characters
  And I press "Continue"

  Then I should see "Name is too long"

  When I fill in my details as a creator
  And I fill in my creator contact details
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

  Then a petition should exist with action: "The wombats of wimbledon rock.", state: "pending"
  Then there should be a "pending" signature with email "womboid@wimbledon.com" and name "Mr. Wibbledon"

Scenario: Charlie creates a petition with a typo in his email
  Given I start a new petition
  And I fill in the petition details
  And I press "Preview petition"
  And I press "This looks good"
  And I choose the default closing date
  And I fill in my details as a creator with email "charlie@hotmial.com"
  And I fill in my creator contact details
  And I press "Continue"
  Then my email is autocorrected to "charlie@hotmail.com"
  When I press "Yes – this is my email address"
  Then a petition should exist with action: "The wombats of wimbledon rock.", state: "pending"
  And a signature should exist with email: "charlie@hotmail.com", state: "pending"

Scenario: Charlie creates a petition when his email is autocorrected wrongly
  Given I start a new petition
  And I fill in the petition details
  And I press "Preview petition"
  And I press "This looks good"
  And I choose the default closing date
  And I fill in my details as a creator with email "charlie@hotmial.com"
  And I fill in my creator contact details
  And I press "Continue"
  Then my email is autocorrected to "charlie@hotmail.com"
  When I fill in "Email" with "charlie@hotmial.com"
  And I press "Yes – this is my email address"
  Then a petition should exist with action: "The wombats of wimbledon rock.", state: "pending"
  And a signature should exist with email: "charlie@hotmial.com", state: "pending"

Scenario: Charlie creates a petition when blocked
  Given the IP address 127.0.0.1 is blocked
  And I start a new petition
  And I fill in the petition details
  And I press "Preview petition"
  And I press "This looks good"
  And I choose the default closing date
  And I fill in my details as a creator
  And I fill in my creator contact details
  When I press "Continue"
  Then the markup should be valid
  And I am asked to review my email address
  When I press "Yes – this is my email address"
  Then a petition should not exist with action: "The wombats of wimbledon rock.", state: "pending"
  And a signature should not exist with email: "womboid@wimbledon.com", state: "pending"

Scenario: Charlie creates a petition when his IP address is rate limited
  Given the burst rate limit is 1 per minute
  And there are no allowed IPs
  And there are no blocked IPs
  And there are 2 petitions created from this IP address
  And I start a new petition
  And I fill in the petition details
  And I press "Preview petition"
  And I press "This looks good"
  And I choose the default closing date
  And I fill in my details as a creator
  And I fill in my creator contact details
  When I press "Continue"
  Then the markup should be valid
  And I am asked to review my email address
  When I press "Yes – this is my email address"
  Then a petition should not exist with action: "The wombats of wimbledon rock.", state: "pending"
  And a signature should not exist with email: "womboid@wimbledon.com", state: "pending"
