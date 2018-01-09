@admin
Feature: Surveying petitioners by email
  Moderators should be able to email a subset of petitioners

  Background:
    Given an open petition "Build more theme parks"
    And a constituency "Rochester and Strood" is found by postcode "ME2 2NU"
    And a constituency "Brighton (Pavilion)" is found by postcode "BN1 1AD"
    And a constituent with email "bob@example.com" in "Rochester and Strood" supports "Build more theme parks"
    And a constituent with email "sarah@example.com" in "Rochester and Strood" supports "Build more theme parks"
    And 3 constituents in "Brighton (Pavilion)" support "Build more theme parks"

  Scenario:
    When I am logged in as a moderator
    And I am on the admin surveys page
    And I follow "New Survey"
    And I fill in "Petition", with "Build more theme parks"
    And I fill in "Constituency" with "Rochester and Strood"
    And I fill in "Percentage of Petitioners" with 100
    And I fill in "Subject", with "Exporatory Survey"
    And I fill in "Body" with "https://www.example.com/a_survey_path"
    And I press "Email petitioners"
    Then I should see the following survey table:
      | Petition                    | Constituency          | Percentage Petitioners | Subject              |
      | Build more theme parks      | Rochester and Strood  | 100                    | Exploratory Survey   |
    And 2 emails have been sent with subject "Exploratory Survey" and body "https://www.example.com/a_survey_path"
    And "bob@example.com" should receive an email with subject "Exploratory Survey"
    And "sarah@example.com" should receive an email with subject "Exploratory Survey"

  Scenario:
    When I am logged in as a moderator
    And I am on the admin surveys page
    And I follow "New Survey"
    And I fill in "Petition", with "Build more theme parks"
    And I fill in "Percentage of Petitioners" with 10
    And I fill in "Subject", with "Exporatory Survey"
    And I fill in "Body" with "https://www.example.com/a_survey_path"
    And I press "Email petitioners"
    Then I should see the following survey table:
      | Petition                    | Constituency          | Percentage Petitioners | Subject              |
      | Build more theme parks      | All                   | 10                     | Exploratory Survey   |
    And 1 email has been sent with subject "Exploratory Survey" and body "https://www.example.com/a_survey_path"

  Scenario:
    When I am logged in as a moderator
    And I am on the admin surveys page
    And I follow "New Survey"
    And I press "Email petitioners"
    Then I should see "Subject can't be blank"
    And I should see "Body can't be blank"
    And I should see "Percentage petitioners can't be blank"
    And I should see "Petition can't be blank"

  Scenario:
    When I am logged in as a moderator
    And I am on the admin surveys page
    And I follow "New Survey"
    And I fill in "Percentage of Petitioners" with 101
    And I press "Email petitioners"
    Then I should see "Percentage petitioners must be between 1 and 100"
