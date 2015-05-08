require 'factory_girl'

FactoryGirl.define do
  factory :admin_user do
    sequence(:email) {|n| "admin#{n}@example.com" }
    password              "Letmein1!"
    password_confirmation "Letmein1!"
    sequence(:first_name) {|n| "AdminUser#{n}" }
    sequence(:last_name) {|n| "AdminUser#{n}" }
    role "admin"
    force_password_reset  false
  end

  factory :sysadmin_user, :parent => :admin_user do
    role "sysadmin"
  end

  factory :threshold_user, :parent => :admin_user do
    role "threshold"
  end

  factory :department do
    sequence(:name) {|n| "Department #{n}" }
    website_url "http://department.gov.uk"
  end

  factory :petition do
    sequence(:title) {|n| "Petition #{n}" }
    description "Petition description"
    association :department
    sponsor_emails { (1..AppConfig.sponsor_count_min).map { |i| "sponsor#{i}@example.com" } }
    creator_signature  { |cs| cs.association(:signature, :state => Signature::VALIDATED_STATE) }
  end

  factory :pending_petition, :parent => :petition do
    state  Petition::PENDING_STATE
    creator_signature  { |cs| cs.association(:signature, :state => Signature::PENDING_STATE) }
  end

  factory :validated_petition, :parent => :petition do
    state  Petition::VALIDATED_STATE
  end

  factory :open_petition, :parent => :petition do
    state      Petition::OPEN_STATE
    open_at    Time.zone.now
    closed_at  1.day.from_now
  end

  factory :closed_petition, :parent => :petition do
    state      Petition::OPEN_STATE
    open_at    10.days.ago
    closed_at  1.day.ago
  end

  factory :rejected_petition, :parent => :petition do
    state  Petition::REJECTED_STATE
    rejection_code "Just do not like"
  end

  factory :hidden_petition, :parent => :petition do
    state      Petition::HIDDEN_STATE
  end

  factory :signature do
    sequence(:name) {|n| "Jo Public #{n}" }
    sequence(:email) {|n| "jo#{n}@public.com" }
    email_confirmation  {|sig| sig.email }
    address             "10 Downing St"
    town                "London"
    postcode            "SW1A 2"
    country             "United Kingdom"
    uk_citizenship       '1'
    notify_by_email      '1'
    terms_and_conditions '1'
    state                Signature::VALIDATED_STATE
  end

  factory :pending_signature, :parent => :signature do
    state      Signature::PENDING_STATE
  end

  factory :validated_signature, :parent => :signature do
    state      Signature::VALIDATED_STATE
  end

  factory :sponsor do
    sequence(:email) {|n| "jo#{n}@public.com" }
    association :petition
  end

  factory :system_setting do
    sequence(:key)  {|n| "key#{n}"}
  end
end
