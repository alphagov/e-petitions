Feature: Searching for signatures as Terry
  In order to easily find out if someone's signed a petition
  As Terry
  I would like to be able to enter an email address, and see all signatures associated with it

  @departments
  Scenario:
    Given 2 petitions signed by "bob@example.com"
    And I am logged in as a threshold user
    When I search for petitions signed by "bob@example.com" in the admin section
    Then I should see 2 petitions associated with the email address
