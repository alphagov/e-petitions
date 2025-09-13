Given(/^the burst rate limit is (\d+) per minute$/) do |rate|
  RateLimit.first_or_create!.update!(burst_rate: rate, burst_period: 60)
end

Given(/^the creator rate limit is (\d+) per hour$/) do |rate|
  RateLimit.first_or_create!.update!(creator_rate: rate, sustained_period: 3600)
end

Given(/^the sponsor rate limit is (\d+) per hour$/) do |rate|
  RateLimit.first_or_create!.update!(sponsor_rate: rate, sustained_period: 3600)
end

Given(/^the feedback rate limit is (\d+) per hour$/) do |rate|
  RateLimit.first_or_create!.update!(feedback_rate: rate, sustained_period: 3600)
end

Given(/^there are no allowed IPs$/) do
  RateLimit.first_or_create!.update!(allowed_ips: "")
end

Given(/^there are no blocked IPs$/) do
  RateLimit.first_or_create!.update!(blocked_ips: "")
end

Given(/^there are no allowed domains$/) do
  RateLimit.first_or_create!.update!(allowed_domains: "")
end

Given(/^the IP address (\d+\.\d+\.\d+\.\d+) is blocked$/) do |ip_address|
  RateLimit.first_or_create!.update!(blocked_ips: ip_address)
end

Given(/^the domain "(.*?)" is blocked$/) do |domain|
  RateLimit.first_or_create!.update!(blocked_domains: domain)
end

Given(/^the domain "(.*?)" is allowed$/) do |domain|
  RateLimit.first_or_create!.update!(allowed_domains: domain)
end

Given(/^the email address "(.*?)" is blocked$/) do |email|
  RateLimit.first_or_create!.update!(blocked_emails: email)
end

Given(/^there is a signature already from this IP address$/) do
  steps %Q(
    When I go to the new signature page for "Do something!"
    And I confirm that I am UK citizen or resident
    And I fill in "Full name" with "Existing Signer"
    And I fill in "Email" with "existing@example.com"
    And I fill in "Confirm email" with "existing@example.com"
    And I fill in my postcode with "SW14 9RQ"
    And I select "United Kingdom" from "Location"
    And I try to sign
    And I say I am happy with my details
    Then I am told to check my inbox to complete signing
    And "existing@example.com" should receive 1 email
  )
end

Given(/^there (?:are|is) (\d+) petitions? created from this IP address$/) do |count|
  count.times do
    FactoryBot.create(:pending_petition, creator_attributes: { ip_address: "127.0.0.1" })
  end
end

Then(/^the signature "([^"]*)" is marked as fraudulent$/) do |email|
  expect(Signature.for_email(email).last).to be_fraudulent
end

Then(/^the signature "([^"]*)" is marked as validated$/) do |email|
  expect(Signature.for_email(email).last).to be_validated
end
