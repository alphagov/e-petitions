Feature: Admin users password change
  As a an admin
  I can change my password

  Background:
    Given I am logged in as an admin with the password "Letmein1!"
    
  Scenario: Accessing the Profile page
    When I go to the admin home page
    And I follow "Profile" in the admin nav
    Then I should be on the admin edit profile page
    And I should see a "Current password" text field
    And I should see a "New password" text field
    And I should see a "Password confirmation" text field
    And I should be connected to the server via an ssl connection
    And the markup should be valid
    
  Scenario: Changing password successfully
    When I go to the admin edit profile page
    And I fill in "Current password" with "Letmein1!"
    And I fill in "New password" with "Letmeout1!"
    And I fill in "Password confirmation" with "Letmeout1!"
    And I press "Save"
    Then I should be on the admin home page
    And I should see "Password was successfully updated"
    
  Scenario: Incorrect current password
    When I go to the admin edit profile page
    And I fill in "Current password" with "wrong password"
    And I fill in "New password" with "Letmeout1!"
    And I fill in "Password confirmation" with "Letmeout1!"
    And I press "Save"
    Then I should see "Current password is incorrect"

  Scenario: Invalid new password
    When I go to the admin edit profile page
    And I fill in "Current password" with "Letmein1!"
    And I fill in "New password" with "12345678"
    And I fill in "Password confirmation" with "12345678"
    And I press "Save"
    Then I should see "Password must contain at least one digit, a lower and upper case letter and a special character"
