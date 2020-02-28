@admin
Feature: A moderator user views all petitions
  In order to see a full list of all the petitions
  As any moderator user
  I want to view a paginated list of Open, Rejected and Closed petitions, sorted by signature count (descending), then most recent. I want to be able to filter this list by state and follow links to change petition details.

  Background:
    Given I am logged in as a moderator

  Scenario: Viewing all petitions
    Given a set of petitions
    When I view all petitions
    And the markup should be valid

  Scenario: Follow links to change details
    Given a petition "My petition"
    When I view all petitions
    And I view the petition
    Then I should see the petition details

  @javascript
  Scenario: Filter list by state
    Given a pending petition "My pending petition"
    And a validated petition "My validated petition"
    And a sponsored petition "My sponsored petition" reached threshold 2 days ago
    And a sponsored petition "My other sponsored petition" reached threshold 1 day ago
    And a flagged petition "My flagged petition" reached threshold 3 days ago

    And an open petition exists with action: "My open petition"
    And a referred petition exists with action: "My referred petition"
    And a rejected petition exists with action: "My rejected petition"
    And a hidden petition exists with action: "My hidden petition"

    And a petition "My referred petition with debate outcome" exists with a debate outcome
    And a petition "My referred petition awaiting debate date" exists awaiting debate date
    And a petition "My referred petition with scheduled debate date" with a scheduled debate date of "23/10/2010"

    When I view all petitions
    Then I should see the following list of petitions:
     | My referred petition with scheduled debate date |
     | My referred petition awaiting debate date       |
     | My referred petition with debate outcome        |
     | My hidden petition                              |
     | My rejected petition                            |
     | My referred petition                            |
     | My open petition                                |
     | My flagged petition                             |
     | My other sponsored petition                     |
     | My sponsored petition                           |
     | My validated petition                           |
     | My pending petition                             |

    And I filter the list to show "Collecting sponsors" petitions
    Then I should see the following list of petitions:
     | My validated petition                         |
     | My pending petition                           |

    And I filter the list to show "Awaiting moderation (3)" petitions
    Then I should see the following list of petitions:
     | My other sponsored petition |
     | My sponsored petition       |
     | My flagged petition         |

    And I filter the list to show "Open" petitions
    Then I should see the following list of petitions:
     | My open petition                              |

    And I filter the list to show "Referred" petitions
    Then I should see the following list of petitions:
     | My referred petition with scheduled debate date |
     | My referred petition awaiting debate date       |
     | My referred petition with debate outcome        |
     | My referred petition                            |

    And I filter the list to show "Rejected" petitions
    Then I should see the following list of petitions:
     | My rejected petition |

    And I filter the list to show "Hidden" petitions
    Then I should see the following list of petitions:
     | My hidden petition |

    And I filter the list to show "Awaiting a debate in the Senedd" petitions
    Then I should see the following list of petitions:
     | My referred petition awaiting debate date |

    And I filter the list to show "Has been debated in the Senedd" petitions
    Then I should see the following list of petitions:
     | My referred petition with debate outcome |

    And I filter the list to show "In debate queue" petitions
    Then I should see the following list of petitions:
     | My referred petition awaiting debate date       |
     | My referred petition with scheduled debate date |

  Scenario: A sysadmin can view all petitions
    Given I am logged in as a sysadmin
    And an open petition exists with action: "Simply the best"
    When I view all petitions
    Then I should see "Simply the best"

  Scenario: A moderator user can view all petitions
    Given I am logged in as a moderator
    And an open petition exists with action: "Simply the best"
    When I view all petitions
    Then I should see "Simply the best"

  Scenario: A moderator can download petitions as CSV
    Given I am logged in as a moderator
    And the time is "2015-08-21 06:00:00"
    When I view all petitions
    And I follow "Download CSV"
    Then I should get a download with the filename "all-petitions-20150821060000.csv"
