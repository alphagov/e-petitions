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
    transient do
      creator_signature_attributes { {} }
      sponsors_signed false
      sponsor_count { AppConfig.sponsor_count_min }
    end
    sequence(:title) {|n| "Petition #{n}" }
    action "Petition action"
    description "Petition description"
    sponsor_emails { (1..sponsor_count).map { |i| "sponsor#{i}@example.com" } }
    creator_signature  { |cs| cs.association(:signature, creator_signature_attributes.merge(:state => Signature::VALIDATED_STATE)) }
  end

  factory :pending_petition, :parent => :petition do
    state  Petition::PENDING_STATE
    creator_signature  { |cs| cs.association(:signature, creator_signature_attributes.merge(:state => Signature::PENDING_STATE)) }
  end

  factory :validated_petition, :parent => :petition do
    state  Petition::VALIDATED_STATE

    after(:create) do |petition, evaluator|
      petition.sponsors.each do |sp|
        sp.create_signature!(FactoryGirl.attributes_for(:validated_signature)) if evaluator.sponsors_signed
      end
    end
  end

  factory :sponsored_petition, :parent => :petition do
    state  Petition::SPONSORED_STATE
  end

  factory :open_petition, :parent => :petition do
    state      Petition::OPEN_STATE
    open_at    { Time.current }
    closed_at  { open_at + 1.day }
  end

  factory :closed_petition, :parent => :petition do
    state      Petition::OPEN_STATE
    open_at    { 10.days.ago }
    closed_at  { 1.day.ago }
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
    postcode            "SW1A 1AA"
    country             "United Kingdom"
    uk_citizenship       '1'
    notify_by_email      '1'
    state                Signature::VALIDATED_STATE
  end

  factory :pending_signature, :parent => :signature do
    state      Signature::PENDING_STATE
  end

  factory :validated_signature, :parent => :signature do
    state      Signature::VALIDATED_STATE
  end

  factory :sponsor do
    sequence(:email) {|n| "sponsor#{n}@public.com" }
    association :petition

    trait :with_signature do
      signature  { |s| s.association(:signature, petition: s.petition, email: s.email, state: Signature::VALIDATED_STATE) }
    end
  end

  factory :system_setting do
    sequence(:key)  {|n| "key#{n}"}
  end
end
