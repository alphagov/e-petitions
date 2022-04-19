require 'factory_bot'
require 'faker'
require 'active_support/core_ext/digest/uuid'

FactoryBot.define do
  factory :admin_user do
    sequence(:email) { |n| "admin#{n}@example.com" }
    password { "Letmein1!" }
    password_confirmation { "Letmein1!" }
    sequence(:first_name) { |n| "AdminUser#{n}" }
    sequence(:last_name) { |n| "AdminUser#{n}" }
    force_password_reset { false }
  end

  factory :sysadmin_user, :parent => :admin_user do
    role { "sysadmin" }
  end

  factory :moderator_user, :parent => :admin_user do
    role { "moderator" }
  end

  factory :petition do
    transient do
      admin_notes { nil }
      creator { nil }
      creator_name { nil }
      creator_email { nil }
      creator_attributes { {} }
      sponsors_signed { nil }
      sponsor_count { Site.minimum_number_of_sponsors }
      increment { true }
    end

    sequence(:action) { |n| "Petition #{n}" }
    background { "Petition background" }

    trait :english do
      locale { "en-GB" }
    end

    trait :welsh do
      locale { "cy-GB" }
    end

    after(:build) do |petition, evaluator|
      unless petition.creator
        petition.creator = evaluator.creator

        if petition.pending?
          petition.creator ||= build(:pending_signature, petition: petition, creator: true)
        else
          petition.creator ||= build(:validated_signature, petition: petition, creator: true)
        end
      end

      petition.creator.assign_attributes(evaluator.creator_attributes)

      if evaluator.creator_name
        petition.creator.name = evaluator.creator_name
      end

      if evaluator.creator_email
        petition.creator.email = evaluator.creator_email
      end

      if petition.last_signed_at?
        petition.creator.validated_at = petition.last_signed_at
      end

      if evaluator.admin_notes
        petition.build_note details: evaluator.admin_notes
      end
    end

    after(:create) do |petition, evaluator|
      if petition.signature_count.zero? && evaluator.increment
        if petition.creator.validated?
          petition.last_signed_at = nil
          petition.increment_signature_count!(petition.creator.validated_at)
        end
      end

      unless evaluator.sponsors_signed.nil?
        evaluator.sponsor_count.times do
          if evaluator.sponsors_signed
            FactoryBot.create(:sponsor, :validated, petition: petition, validated_at: 10.seconds.ago)
          else
            FactoryBot.create(:sponsor, :pending, petition: petition)
          end
        end

        petition.update_signature_count!
      end
    end

    trait :translated do
      after(:build) do |petition, evaluator|
        if petition.english?
          petition.action_cy ||= petition.action_en
          petition.background_cy ||= petition.background_en
          petition.additional_details_cy ||= petition.additional_details_en
        else
          petition.action_en ||= petition.action_cy
          petition.background_en ||= petition.background_cy
          petition.additional_details_en ||= petition.additional_details_cy
        end
      end
    end

    trait :with_additional_details do
      additional_details { "Petition additional details" }
    end

    trait :scheduled_for_debate do
      scheduled_debate_date { 10.days.from_now }
    end

    trait :email_requested do
      transient do
        email_requested_for_debate_scheduled_at { nil }
        email_requested_for_debate_outcome_at { nil }
        email_requested_for_petition_email_at { nil }
      end

      after(:build) do |petition, evaluator|
        petition.build_email_requested_receipt do |r|
          r.debate_scheduled = evaluator.email_requested_for_debate_scheduled_at
          r.debate_outcome = evaluator.email_requested_for_debate_outcome_at
          r.petition_email = evaluator.email_requested_for_petition_email_at
        end
      end
    end

    trait :tagged do
      transient do
        tag_name { nil }
      end

      after(:build) do |petition, evaluator|
        if evaluator.tag_name
          tag = create(:tag, name: evaluator.tag_name)
        else
          tag = create(:tag)
        end

        petition.tags = [tag.id]
      end
    end
  end

  factory :pending_petition, :parent => :petition do
    state { Petition::PENDING_STATE }

    after(:build) do |petition, evaluator|
      petition.creator.state = Signature::PENDING_STATE
      petition.creator.validated_at = nil
    end
  end

  factory :validated_petition, :parent => :petition do
    state { Petition::VALIDATED_STATE }
  end

  factory :sponsored_petition, :parent => :petition do
    moderation_threshold_reached_at { Time.current }
    state { Petition::SPONSORED_STATE }

    trait :overdue do
      moderation_threshold_reached_at { Site.moderation_overdue_in_days.ago - 5.minutes }
    end

    trait :nearly_overdue do
      moderation_threshold_reached_at { Site.moderation_overdue_in_days.ago + 5.minutes }
    end

    trait :recent do
      moderation_threshold_reached_at { Time.current }
    end
  end

  factory :flagged_petition, :parent => :petition do
    state { Petition::FLAGGED_STATE }
  end

  factory :open_petition, :parent => :sponsored_petition do
    state { Petition::OPEN_STATE }
    open_at { Time.current }

    translated

    transient do
      referred { false }
    end

    after(:build) do |petition, evaluator|
      if evaluator.referred
        petition.referral_threshold_reached_at = petition.open_at + 2.months
      end

      petition.closed_at ||= Site.closed_at_for_opening(petition.open_at)
    end
  end

  factory :closed_petition, :parent => :open_petition do
    state { Petition::CLOSED_STATE }
    open_at { 10.days.ago }
    closed_at { 1.day.ago }
  end

  factory :paper_petition, :parent => :closed_petition do
    submitted_on_paper { true }
    submitted_on { Date.current }
  end

  factory :rejected_petition, :parent => :petition do
    state { Petition::REJECTED_STATE }

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
    state { Petition::HIDDEN_STATE }

    transient do
      rejection_code { "offensive" }
      rejection_details { nil }
    end

    after(:create) do |petition, evaluator|
      petition.create_rejection! do |r|
        r.code = evaluator.rejection_code
        r.details = evaluator.rejection_details
      end
    end
  end

  factory :referred_petition, :parent => :closed_petition do
    referral_threshold_reached_at { 1.week.ago }
    referred_at { 1.day.ago }
  end

  factory :awaiting_debate_petition, :parent => :referred_petition do
    debate_threshold_reached_at { 1.week.ago }
    debate_state { 'awaiting' }
  end

  factory :scheduled_debate_petition, :parent => :referred_petition do
    debate_threshold_reached_at { 1.week.ago }
    scheduled_debate_date { 1.week.from_now }
    debate_state { 'scheduled' }
  end

  factory :debated_petition, :parent => :referred_petition do
    transient do
      debated_on { 1.day.ago }
      overview { nil }
      overview_en { nil }
      overview_cy { nil }
      transcript_url { nil }
      transcript_url_en { nil }
      transcript_url_cy { nil }
      video_url { nil }
      video_url_en { nil }
      video_url_cy { nil }
      debate_pack_url { nil }
      debate_pack_url_en { nil }
      debate_pack_url_cy { nil }
      debate_image { nil }
    end

    debate_state { 'debated' }

    after(:build) do |petition, evaluator|
      debate_outcome_attributes = { debated: true }

      if evaluator.debated_on.present?
        debate_outcome_attributes[:debated_on] = evaluator.debated_on
      end

      if evaluator.overview.present?
        debate_outcome_attributes[:overview_en] = evaluator.overview
        debate_outcome_attributes[:overview_cy] = evaluator.overview
      end

      if evaluator.overview_en.present?
        debate_outcome_attributes[:overview_en] = evaluator.overview_en
      end

      if evaluator.overview_cy.present?
        debate_outcome_attributes[:overview_cy] = evaluator.overview_cy
      end

      if evaluator.transcript_url.present?
        debate_outcome_attributes[:transcript_url_en] = evaluator.transcript_url
        debate_outcome_attributes[:transcript_url_cy] = evaluator.transcript_url
      end

      if evaluator.transcript_url_en.present?
        debate_outcome_attributes[:transcript_url_en] = evaluator.transcript_url_en
      end

      if evaluator.transcript_url_cy.present?
        debate_outcome_attributes[:transcript_url_cy] = evaluator.transcript_url_cy
      end

      if evaluator.video_url.present?
        debate_outcome_attributes[:video_url_en] = evaluator.video_url
        debate_outcome_attributes[:video_url_cy] = evaluator.video_url
      end

      if evaluator.video_url_en.present?
        debate_outcome_attributes[:video_url_en] = evaluator.video_url_en
      end

      if evaluator.video_url_cy.present?
        debate_outcome_attributes[:video_url_cy] = evaluator.video_url_cy
      end

      if evaluator.debate_pack_url.present?
        debate_outcome_attributes[:debate_pack_url_en] = evaluator.debate_pack_url
        debate_outcome_attributes[:debate_pack_url_cy] = evaluator.debate_pack_url
      end

      if evaluator.debate_pack_url_en.present?
        debate_outcome_attributes[:debate_pack_url_en] = evaluator.debate_pack_url_en
      end

      if evaluator.debate_pack_url_cy.present?
        debate_outcome_attributes[:debate_pack_url_cy] = evaluator.debate_pack_url_cy
      end

      if evaluator.debate_image.present?
        debate_outcome_attributes[:image] = evaluator.debate_image
      end

      petition.build_debate_outcome(debate_outcome_attributes)
    end
  end

  factory :not_debated_petition, :parent => :referred_petition do
    transient do
      overview { nil }
      overview_en { nil }
      overview_cy { nil }
    end

    debate_state { 'not_debated' }

    after(:build) do |petition, evaluator|
      debate_outcome_attributes = { debated: false }

      if evaluator.overview.present?
        debate_outcome_attributes[:overview_en] = evaluator.overview
        debate_outcome_attributes[:overview_cy] = evaluator.overview
      end

      if evaluator.overview_en.present?
        debate_outcome_attributes[:overview_en] = evaluator.overview_en
      end

      if evaluator.overview_cy.present?
        debate_outcome_attributes[:overview_cy] = evaluator.overview_cy
      end

      petition.build_debate_outcome(debate_outcome_attributes)
    end
  end

  factory :completed_petition, :parent => :referred_petition do
    state { "completed" }
    completed_at { 1.week.ago }
  end

  factory :archived_petition, :parent => :completed_petition do
    archived_at { 1.day.ago }
  end

  factory :contact do
    association :signature
    phone_number { "0300 200 6565" }
    address { "Pierhead St, Cardiff" }
  end

  factory :signature do
    sequence(:name) { |n| "Jo Public #{n}" }
    sequence(:email) { |n| "jo#{n}@public.com" }
    postcode { "CF99 1NA" }
    location_code { "GB-WLS" }
    notify_by_email { "1" }
    state { Signature::VALIDATED_STATE }

    after(:build) do |signature, evaluator|
      signature.petition ||= build(:petition, creator: (signature.creator ? signature : nil))
      build(:contact, signature: signature) if signature.creator?
    end
  end

  factory :pending_signature, :parent => :signature do
    state { Signature::PENDING_STATE }
  end

  factory :fraudulent_signature, :parent => :signature do
    state { Signature::FRAUDULENT_STATE }
  end

  factory :validated_signature, :parent => :signature do
    state { Signature::VALIDATED_STATE }
    validated_at { Time.current }
    seen_signed_confirmation_page { true }

    trait :just_signed do
      seen_signed_confirmation_page { false }
    end

    transient {
      increment { true }
    }

    after(:create) do |signature, evaluator|
      if evaluator.increment && signature.petition
        petition = signature.petition
        last_signed_at = petition.last_signed_at

        if petition.increment_signature_count!
          ConstituencyPetitionJournal.increment_signature_counts_for(petition, last_signed_at)
          CountryPetitionJournal.increment_signature_counts_for(petition, last_signed_at)
        end
      end
    end
  end

  factory :invalidated_signature, :parent => :validated_signature do
    state { Signature::INVALIDATED_STATE }
    invalidated_at { Time.current }
  end

  sequence(:sponsor_email) { |n| "sponsor#{n}@example.com" }

  factory :sponsor, parent: :pending_signature do
    sponsor { true }

    trait :pending do
      state { "pending" }
    end

    trait :validated do
      state { "validated" }
    end

    trait :just_signed do
      seen_signed_confirmation_page { false }
    end
  end

  sequence(:constituency_id) { |n| "W09%06d" % n }

  factory :constituency do
    trait :cardiff_south_and_penarth do
      id { "W09000043" }
      association :region, :south_wales_central
      name_en { "Cardiff South and Penarth" }
      name_cy { "De Caerdydd a Phenarth" }
      example_postcode { "CF119WE" }
    end

    trait :swansea_west do
      id { "W09000019" }
      association :region, :south_wales_west
      name_en { "Swansea West" }
      name_cy { "Gorllewin Abertawe" }
      example_postcode { "SA16UD" }
    end

    sequence(:id) { |n| "W19%06d" % n }
    association :region
    sequence(:name_en) { |n| "Constituency #{n}" }
    sequence(:name_cy) { |n| "Etholaeth #{n}" }
    example_postcode { Faker::Address.postcode.tr(" ", "") }
    population { rand(60000..120000) }
  end

  factory :region do
    trait :south_wales_central do
      id { "W10000007" }
      name_en { "South Wales Central" }
      name_cy { "Canol De Cymru" }
    end

    trait :south_wales_west do
      id { "W10000009" }
      name_en { "South Wales West" }
      name_cy { "Gorllewin De Cymru" }
    end

    sequence(:id) { |n| "W11%06d" % n }
    sequence(:name_en) { |n| "Region #{n}" }
    sequence(:name_cy) { |n| "Rhanbarth #{n}" }
    population { rand(500000..700000) }
  end

  factory :member do
    region_id { nil }
    constituency_id { nil }
    name_en { Faker::Name.name }
    name_cy { Faker::Name.name }
    party_en { "Welsh Labour" }
    party_cy { "Llafur Cymru" }

    trait :region do
      association :region
    end

    trait :constituency do
      association :constituency
    end

    trait :cardiff_south_and_penarth do
      id { 249 }
      constituency_id { "W09000043" }
      name_en { "Vaughan Gething MS" }
      name_cy { "Vaughan Gething AS" }
      party_en { "Welsh Labour" }
      party_cy { "Llafur Cymru" }
    end

    trait :regional_member do
      region_id { "W10000007" }
      name_en { "Bob Jones MS" }
      name_cy { "Bob Jones AS" }
      party_en { "Welsh Conservative Party" }
      party_cy { "Ceidwadwyr Cymreig" }
    end

    trait :constituency_member do
      constituency_id { "W09000043" }
      name_en { "Alice Davies MS" }
      name_cy { "Alice Davies AS" }
      party_en { "Welsh Labour" }
      party_cy { "Llafur Cymru" }
    end
  end

  factory :postcode do
    id { Faker::Address.postcode.tr(" ", "") }
    sequence(:constituency_id) { |n| "W09%06d" % n }

    trait :cardiff_south_and_penarth do
      id { "CF991NA" }
      constituency_id { "W09000043" }
    end

    trait :swansea_west do
      id { "SA11BD" }
      constituency_id { "W09000019" }
    end
  end

  factory :constituency_petition_journal do
    constituency_id { "W09000043" }
    association :petition
  end

  factory :country_petition_journal do
    location_code { "GB-WLS" }
    association :petition
  end

  factory :debate_outcome do
    association :petition, factory: :open_petition
    debated_on { 1.month.from_now.to_date }
    debated { true }

    trait :fully_specified do
      overview { 'Debate on Petition P-05-869: Declare a Climate Emergency and fit all policies with zero-carbon targets' }
      sequence(:transcript_url) { |n|
        "https://record.assembly.wales/Plenary/5667#A51756"
      }
      video_url {
        "http://www.senedd.tv/Meeting/Archive/760dfc2e-74aa-4fc7-b4a7-fccaa9e2ba1c?autostart=True"
      }
      sequence(:debate_pack_url) { |n|
        "https://business.senedd.wales/ieListDocuments.aspx?CId=401&MId=5667"
      }
    end
  end

  factory :note do
    association :petition, factory: :petition
    details { "Petition notes" }
  end

  factory :petition_email, class: "Petition::Email" do
    association :petition, factory: :petition
    subject_en { "Message Subject" }
    body_en { "Message body" }
    subject_cy { "Pwnc Neges" }
    body_cy { "Corff neges" }
    sent_by { "Admin User" }
  end

  factory :petition_statistics, class: "Petition::Statistics" do
    association :petition, factory: :open_petition
  end

  factory :rejection do
    association :petition, factory: :validated_petition
    code { "duplicate" }
  end

  factory :email_requested_receipt do
    association :petition, factory: :open_petition
  end

  factory :feedback do
    comment { "This thing is wrong" }
    petition_link_or_title { "Do stuff" }
    email { "foo@example.com" }
    user_agent { "Mozilla/5.0" }
  end

  factory :invalidation do
    summary { "Invalidation summary" }
    details { "Reasons for invalidation" }

    trait :cancelled do
      cancelled_at { Time.current }
    end

    trait :completed do
      completed_at { Time.current }
    end

    trait :started do
      started_at { Time.current }
    end
  end

  factory :tag do
    sequence(:name) { |n| "Tag #{n}" }
  end

  factory :topic do
    sequence(:code_en) { |n| "topic-#{n}" }
    sequence(:name_en) { |n| "Topic #{n}" }
    sequence(:code_cy) { |n| "pwnc-#{n}" }
    sequence(:name_cy) { |n| "Pwnc #{n}" }
  end

  factory :trending_ip do
    association :petition, factory: :open_petition
    ip_address { "127.0.0.1" }
    country_code { "GB" }
    count { 32 }
    starts_at { 1.hour.ago.at_beginning_of_hour }
  end

  factory :trending_domain do
    association :petition, factory: :open_petition
    domain { "example.com" }
    count { 32 }
    starts_at { 1.hour.ago.at_beginning_of_hour }
  end

  factory :domain do
    sequence(:name) { |n| "example-#{n}.com" }
    strip_characters { "." }
    strip_extension { "+" }
  end

  factory :language do
    translations { Hash.new }

    trait :english do
      locale { "en-GB" }
      name { "English" }

      translations do
        { "en-GB" => { "title" => "Petitions" } }
      end
    end

    trait :welsh do
      locale { "cy-GB" }
      name { "Welsh" }

      translations do
        { "cy-GB" => { "title" => "Deisebau" } }
      end
    end
  end

  factory :rejection_reason do
    code { Faker::Lorem.unique.word.dasherize }
    title { Faker::Lorem.unique.sentence }
    description_en { Faker::Lorem.paragraph }
    description_cy { Faker::Lorem.paragraph }
    hidden { false }

    trait :hidden do
      hidden { true }
    end
  end
end
