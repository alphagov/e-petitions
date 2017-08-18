Given(/^the burst rate limit is (\d+) per minute$/) do |rate|
  RateLimit.first_or_create!.update!(burst_rate: rate, burst_period: 60)
end

Given(/^there are no allowed IPs$/) do
  RateLimit.first_or_create!.update!(allowed_ips: "")
end

Given(/^the domain "(.*?)" is allowed$/) do |domain|
  RateLimit.first_or_create!.update!(allowed_domains: domain)
end

Given(/^there is a signature already from this IP address$/) do
  steps %Q(
    When I go to the new signature page for "Do something!"
    And I fill in "Name" with "Existing Signer"
    And I fill in "Email" with "existing@example.com"
    And I check "I am a British citizen or UK resident"
    And I fill in my postcode with "SW14 9RQ"
    And I select "United Kingdom" from "Location"
    And I try to sign
    And I say I am happy with my email address
    Then I am told to check my inbox to complete signing
    And "existing@example.com" should receive 1 email
  )
end
