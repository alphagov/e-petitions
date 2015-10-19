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
    state "closed"
    description "Petition description"
    signature_count 0
    opened_at { 2.years.ago }
    closed_at { 1.year.ago }

    trait :response do
      response "Petition response"
    end

    trait :response_summary do
      response_summary "Petition summary"
    end

    trait :open do
      state "open"
      signature_count 100
      closed_at { 6.month.from_now }
    end

    trait :closed do
      state "closed"
      signature_count 100
      closed_at { 6.months.ago }
    end

    trait :rejected do
      reason_for_rejection "Petition rejection"
      state "rejected"
    end
  end

  factory :petition do
    transient do
      admin_notes { nil }
      creator_signature_attributes { {} }
      sponsors_signed false
      sponsor_count { Site.minimum_number_of_sponsors }
    end

    sequence(:action) {|n| "Petition #{n}" }
    background "Petition background"
    creator_signature  { |cs| cs.association(:signature, creator_signature_attributes.merge(:state => Signature::VALIDATED_STATE, :validated_at => Time.current)) }

    after(:build) do |petition, evaluator|
      evaluator.sponsor_count.times do
        sponsor = petition.sponsors.build(FactoryGirl.attributes_for(:sponsor))
      end

      if petition.signature_count.zero?
        petition.signature_count += 1 if petition.creator_signature.validated?
      end

      if evaluator.admin_notes
        petition.build_note details: evaluator.admin_notes
      end
    end

    trait :with_additional_details do
      additional_details "Petition additional details"
    end

    trait :scheduled_for_debate do
      scheduled_debate_date { 10.days.from_now }
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
    moderation_threshold_reached_at { Time.current }
    state  Petition::SPONSORED_STATE
  end

  factory :flagged_petition, :parent => :petition do
    state  Petition::FLAGGED_STATE
  end

  factory :open_petition, :parent => :sponsored_petition do
    state  Petition::OPEN_STATE
    open_at { Time.current }
  end

  factory :closed_petition, :parent => :petition do
    state      Petition::CLOSED_STATE
    open_at    { 10.days.ago }
    closed_at  { 1.day.ago }
  end

  factory :rejected_petition, :parent => :petition do
    state Petition::REJECTED_STATE

    transient do
      rejection_code { "duplicate" }
      rejection_details { nil }
    end

    after(:create) do |petition, evaluator|
      petition.create_rejection! do |r|
        r.code = evaluator.rejection_code
        r.details = evaluator.rejection_details
      end
    end
  end

  factory :hidden_petition, :parent => :petition do
    state Petition::HIDDEN_STATE
  end

  factory :awaiting_petition, :parent => :open_petition do
    response_threshold_reached_at { 1.week.ago }
  end

  factory :responded_petition, :parent => :awaiting_petition do
    government_response_at { 1.week.ago }

    transient do
      response_summary { "Response Summary" }
      response_details { "Response Details" }
    end

    after(:create) do |petition, evaluator|
      petition.create_government_response! do |r|
        r.summary = evaluator.response_summary
        r.details = evaluator.response_details
      end
    end
  end

  factory :awaiting_debate_petition, :parent => :open_petition do
    debate_threshold_reached_at { 1.week.ago }
    debate_state 'awaiting'
  end

  factory :debated_petition, :parent => :open_petition do
    transient do
      debated_on { 1.day.ago }
      overview { nil }
      transcript_url { nil }
      video_url { nil }
    end
    debate_state 'debated'
    after(:build) do |petition, evaluator|
      debate_outcome_attributes = {petition: petition}
      debate_outcome_attributes[:debated_on] = evaluator.debated_on if evaluator.debated_on.present?
      debate_outcome_attributes[:overview] = evaluator.overview if evaluator.overview.present?
      debate_outcome_attributes[:transcript_url] = evaluator.transcript_url if evaluator.transcript_url.present?
      debate_outcome_attributes[:video_url] = evaluator.video_url if evaluator.video_url.present?
      petition.create_debate_outcome(debate_outcome_attributes)
    end
  end

  factory :not_debated_petition, :parent => :open_petition do
    after(:create) do |petition, evaluator|
      petition.create_debate_outcome(debated: false)
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
      if signature.petition && signature.validated?
        signature.petition.increment!(:signature_count)
        signature.increment!(:number)
      end
    end
  end

  factory :pending_signature, :parent => :signature do
    state      Signature::PENDING_STATE
  end

  factory :validated_signature, :parent => :signature do
    state                         Signature::VALIDATED_STATE
    validated_at                  { Time.current }
    seen_signed_confirmation_page true
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
  sequence(:ons_code) { |n| '%08d' % n }

  factory :constituency do
    trait(:england) do
      ons_code{ "E#{generate(:ons_code)}" }
    end

    trait(:scotland) do
      ons_code{ "S#{generate(:ons_code)}" }
    end

    trait(:wales) do
      ons_code{ "W#{generate(:ons_code)}" }
    end

    trait(:northern_ireland) do
      ons_code{ "N#{generate(:ons_code)}" }
    end

    england

    name { Faker::Address.county }
    external_id { generate(:constituency_id) }
    mp_name { "#{Faker::Name.name} MP" }
    mp_id { generate(:mp_id) }
  end

  factory :constituency_petition_journal do
    constituency_id { generate(:constituency_id) }
    association :petition
  end

  factory :country_petition_journal do
    country { Faker::Address.country }
    association :petition
  end

  factory :debate_outcome do
    association :petition, factory: :open_petition
    debated_on { 1.month.from_now.to_date }
    debated true

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

  factory :government_response do
    association :petition, factory: :awaiting_petition
    details "Government Response Details"
    summary "Government Response Summary"
  end

  factory :note do
    association :petition, factory: :petition
    details "Petition notes"
  end

  factory :petition_email, class: "Petition::Email" do
    association :petition, factory: :petition
    subject "Message Subject"
    body "Message body"
    sent_by "Admin User"
  end

  factory :rejection do
    association :petition, factory: :validated_petition
    code "duplicate"
  end

  factory :email_requested_receipt do
    association :petition, factory: :open_petition
  end

  factory :email_sent_receipt do
    association :signature, factory: :validated_signature
  end
end
