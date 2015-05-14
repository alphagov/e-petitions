Feature: As Charlie
  In order to have an issue discussed in parliament
  I want to be able to create a petition and verify my email address.

Background:
  Given a department exists with name: "Cabinet Office", description: "Where cabinets do their paperwork"
  And a department exists with name: "Department for International Development", description: "A large portion of the UK population cannot intonate their words properly. This department is responsible for developing this."

@search
Scenario: Charlie has to search for a petition before creating one
  Given a petition "Rioters should loose benefits" belonging to the "Cabinet Office"
  Given I am on the home page
  When I follow "Create a new e-petition"
  Then I should be asked to search for a new petition
  When I check my petition title
  Then I should see a list of existing petitions I can sign
  When I choose to create a petition anyway
  Then I should be on the new petition page
  And I should see my search query already filled in as the title of the petition

@search
Scenario: Charlie cannot craft an xss attack when searching for petitions
  Given I am on the home page
  When I follow "Create a new e-petition"
  Then I fill in "search" with "'onmouseover='alert(1)'"
  When I press "Search"
  Then the markup should be valid

Scenario: Charlie creates our petition
  Given I am on the new petition page
  Then I should see "Create a new e-petition - e-petitions" in the browser page title
  And I should be connected to the server via an ssl connection
  When I fill in "Title" with "The wombats of wimbledon rock."
  And I fill in "Action" with "Give half of Wimbledon rock to wombats!"
  And I fill in "Description" with "The racial tensions between the wombles and the wombats are heating up. Racial attacks are a regular occurrence and the death count is already in 5 figures. The only resolution to this crisis is to give half of Wimbledon common to the Wombats and to recognise them as their own independent state."
  And I select "3 months" from "Time to collect signatures"
  And I press "Next"
  And I fill in my details
  And I press "Next"
  And I fill in sponsor emails
  And I press "Next"
  And I check "I agree to the Terms & Conditions"
  Then the markup should be valid
  When I press "Submit"
  Then a petition should exist with title: "The wombats of wimbledon rock.", state: "pending", duration: "3"
  And there should be a "pending" signature with email "womboid@wimbledon.com" and name "Womboid Wibbledon"
  And "Womboid Wibbledon" wants to be notified about the petition's progress
  And "womboid@wimbledon.com" should receive 1 email

  When I confirm my email address
  Then a petition should exist with title: "The wombats of wimbledon rock.", state: "validated"
  And there should be a "validated" signature with email "womboid@wimbledon.com" and name "Womboid Wibbledon"

@javascript
Scenario: Charlie tries to submit an invalid petition
  Given I am on the new petition page

  Then I should see a fieldset called "Petition Details"

  When I press "Next"
  Then I should see "Title must be completed"
  And I should see "Action must be completed"
  And I should see "Description must be completed"

  When I am allowed to make the petition title too long
  When I fill in "Title" with "012345678911234567892123456789312345678941234567895123456789012345678911234567892123456789312345678941234567895123456789012345678911234567892123456789Blah"
  And I fill in "Action" with "This text is longer than 200 characters. 012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789"
  And I fill in "Description" with "This text is longer than 1000 characters. 012345678911234567892123456789312345678941234567895123456789012345678911234567892123456789312345678941234567895123456789012345678911234567892123456789312345678941234567895123456789012345678911234567892123456789312345678941234567895123456789012345678911234567892123456789312345678941234567895123456789012345678911234567892123456789312345678941234567895123456789012345678911234567892123456789312345678941234567895123456789012345678911234567892123456789312345678941234567895123456789012345678911234567892123456789312345678941234567895123456789012345678911234567892123456789312345678941234567895123456789012345678911234567892123456789312345678941234567895123456789012345678911234567892123456789312345678941234567895123456789012345678911234567892123456789312345678941234567895123456789012345678911234567892123456789312345678941234567895123456789012345678911234567892123456789312345678941234567895123456789012345678911234567892123456789312345678941234567895123456789"
  And I press "Next"

  Then I should see "Title is too long."
  And I should see "Description is too long."
  And I should see "Action is too long."

  When I fill in "Title" with "The wombats of wimbledon rock."
  And I fill in "Action" with "Give half of Wimbledon rock to wombats!"
  And I fill in "Description" with "The racial tensions between the wombles and the wombats are heating up.  Racial attacks are a regular occurrence and the death count is already in 5 figures.  The only resolution to this crisis is to give half of Wimbledon common to the Wombats and to recognise them as their own independent state."
  And I press "Next"

  Then I should see a fieldset called "Your Details"

  When I press "Next"
  Then I should see "Name must be completed"
  And I should see "Email must be completed"
  And I should see "You must be a British citizen"
  And I should see "Address must be completed"
  And I should see "Town must be completed"
  And I should see "Postcode must be completed"

  When I fill in my details with email "wimbledon@womble.com" and confirmation "uncleb@wimbledon.com"
  And I press "Next"
  And I should see "Email should match confirmation"

  When I fill in my details

  And I press "Next"
  Then I should see a fieldset called "Sponsor email addresses"

  And I fill in sponsor emails

  And I press "Next"
  Then I should see a fieldset called "Submit Petition"

  #Seems there's an envjs bug here
  # And I should see "The wombats of wimbledon rock."
  # And I should see "Department for International Development"
  # And I should see "The racial tensions between the wombles and the wombats are heating up.  Racial attacks are a regular occurrence and the death count is already in 5 figures.  The only resolution to this crisis is to give half of Wimbledon common to the Wombats and to recognise them as their own independent state."

  And I press "Submit"
  Then I should see "You must accept the terms and conditions."
  When I check "I agree to the Terms & Conditions"
  And I press "Back"
  And I press "Back"
  And I fill in "Name" with "Mr. Wibbledon"
  And I press "Next"
  And I press "Next"

  And I press "Submit"

  Then a petition should exist with title: "The wombats of wimbledon rock.", state: "pending"
  Then there should be a "pending" signature with email "womboid@wimbledon.com" and name "Mr. Wibbledon"


Scenario: Charlie looks up information about departments
  Given I am on the department information page
  And I should see "Cabinet Office"
  And I should see "Where cabinets do their paperwork"
  And I should see "Department for International Development"
  And I should see "A large portion of the UK population cannot intonate their words properly. This department is responsible for developing this."
