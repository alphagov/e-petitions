require 'factory_girl'

FactoryGirl.define do
  factory :admin_user do
    sequence(:email) {|n| "admin#{n}@example.com" }
    password              "Letmein1!"
    password_confirmation "Letmein1!"
    sequence(:first_name) {|n| "AdminUser#{n}" }
    sequence(:last_name) {|n| "AdminUser#{n}" }
    force_password_reset  false
  end

  factory :sysadmin_user, :parent => :admin_user do
    role "sysadmin"
  end

  factory :moderator_user, :parent => :admin_user do
    role "moderator"
  end

  factory :archived_petition do
    sequence(:title) { |n| "Petition #{n}" }
    description "Petition description"
    signature_count 0
    opened_at { 2.years.ago }

    trait :response do
      response "Petition response"
    end

    trait :response_summary do
      response_summary "Petition summary"
    end

    trait :open do
      state "open"
      signature_count 100
    end

    trait :closed do
      state "open"
      signature_count 100
      closed_at { 1.year.ago }
    end

    trait :rejected do
      reason_for_rejection "Petition rejection"
      state "rejected"
    end
  end

  factory :petition do
    transient do
      creator_signature_attributes { {} }
      sponsors_signed false
      sponsor_count { Site.minimum_number_of_sponsors }
    end
    sequence(:action) {|n| "Petition #{n}" }
    background "Petition background"
    creator_signature  { |cs| cs.association(:signature, creator_signature_attributes.merge(:state => Signature::VALIDATED_STATE)) }
    after(:build) do |petition, evaluator|
      evaluator.sponsor_count.times do
        petition.sponsors.build(FactoryGirl.attributes_for(:sponsor))
      end

      if petition.signature_count.zero?
        petition.signature_count += 1 if petition.creator_signature.validated?
      end
    end

    trait :with_additional_details do
      additional_details "Petition additional details"
    end
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
    rejection_code "duplicate"
  end

  factory :hidden_petition, :parent => :petition do
    state      Petition::HIDDEN_STATE
  end

  factory :awaiting_petition, :parent => :open_petition do
    response_threshold_reached_at { 1.week.ago }
  end

  factory :responded_petition, :parent => :awaiting_petition do
    response "Government Response"
  end

  factory :debated_petition, :parent => :open_petition do
    transient do
      debated_on { nil }
      overview { nil }
      transcript_url { nil }
      video_url { nil }
    end
    debate_outcome do |p|
      debate_outcome_attributes = {}
      debate_outcome_attributes[:debated_on] = debated_on if debated_on.present?
      debate_outcome_attributes[:overview] = overview if overview.present?
      debate_outcome_attributes[:transcript_url] = transcript_url if transcript_url.present?
      debate_outcome_attributes[:video_url] = video_url if video_url.present?
      p.association(:debate_outcome, :fully_specified, debate_outcome_attributes)
    end
  end

  factory :signature do
    sequence(:name) {|n| "Jo Public #{n}" }
    sequence(:email) {|n| "jo#{n}@public.com" }
    postcode            "SW1A 1AA"
    country             "United Kingdom"
    uk_citizenship       '1'
    notify_by_email      '1'
    state                Signature::VALIDATED_STATE

    after(:create) do |signature, evaluator|
      if signature.petition
        signature.petition.increment!(:signature_count) if signature.validated?
      end
    end
  end

  factory :pending_signature, :parent => :signature do
    state      Signature::PENDING_STATE
  end

  factory :validated_signature, :parent => :signature do
    state          Signature::VALIDATED_STATE
    validated_at { Time.current }
  end

  sequence(:sponsor_email) { |n| "sponsor#{n}@example.com" }

  factory :sponsor do
    transient do
      email { generate(:sponsor_email) }
    end

    association :petition

    trait :pending do
      signature  { |s| s.association(:pending_signature, petition: s.petition, email: s.email) }
    end

    trait :validated do
      signature  { |s| s.association(:validated_signature, petition: s.petition, email: s.email) }
    end
  end

  sequence(:constituency_id) { |n| (1234 + n).to_s }
  sequence(:mp_id) { |n| (4321 + n).to_s }

  factory :constituency_petition_journal do
    constituency_id { generate(:constituency_id) }
    association :petition
  end

  factory :debate_outcome do
    association :petition, factory: :open_petition
    debated_on { 1.month.from_now.to_date }

    trait :fully_specified do
      overview { 'Discussion of the 2014 Christmas Adjournment - has the house considered everything it needs to before it closes for the festive period?' }
      sequence(:transcript_url) { |n|
        "http://www.publications.parliament.uk/pa/cm#{debated_on.strftime('%Y%m')}/cmhansrd/cm#{debated_on.strftime('%y%m%d')}/debtext/#{debated_on.strftime('%y%m%d')}-0003.htm##{debated_on.strftime('%y%m%d')}49#{ '%06d' % n }"
      }
      video_url {
        "http://parliamentlive.tv/event/index/#{SecureRandom.uuid}"
      }

    end
  end
end
