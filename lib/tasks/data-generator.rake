# rake data:generate
# Petition state    PET_STATE=rejected    default open
# Petition count    PET_COUNT=20          default 100
# Signature count   SIG_COUNT=25          default 100
# Random response   RANDOM_RESP=true      default false
#                   If true will create 10K sigs for every 5th petition and add response

namespace :data do
  desc "Generate random petitions with signatures. PET_STATE=open, PET_COUNT=100, SIG_COUNT=100"
  task :generate => :environment do
    require 'faker'

    POSTCODES       = ['SE58BB', 'IG110UD', 'IG110FX', 'W1F7HS', 'RM9 8PD'];
    REJECTION_CODES = ["no-action", "irrelevant", "honours", "no-action", "duplicate"]
    HIDDEN_CODES    = ["libellous", "offensive"]
    VALID_STATES    = ['open', 'closed', 'rejected', 'hidden']

    PETITION_STATE  = ENV.fetch('PET_STATE', 'open')
    PETITION_COUNT  = ENV.fetch('PET_COUNT', '100')
    SIGNATURE_COUNT = ENV.fetch('SIG_COUNT', '100')
    RANDOM_RESPONSE = ENV.fetch('RANDOM_RESP', 'false')


    if VALID_STATES.exclude?(PETITION_STATE)
      raise "** #{PETITION_STATE} is not a valid state within #{VALID_STATES.inspect} **"
    end

    ActiveRecord::Base.transaction do
      PETITION_COUNT.to_i.times do |idx|
        @signature_count = SIGNATURE_COUNT

        petition = Petition.create!({
          action: Faker::Lorem.sentence(rand(3..10)).first(80),
          background: Faker::Lorem.sentence(rand(7..22)).first(200),
          additional_details: Faker::Lorem.paragraph(rand(2..20)).first(500),
          creator: Signature.new({
            uk_citizenship: '1',
            name: Faker::Name.name,
            email: Faker::Internet.safe_email,
            location_code: 'GB',
            state: 'validated',
            postcode: POSTCODES.sample,
            creator: true
          })
        })

        # Create the sponsor signatures
        5.times do
          petition.sponsors.create!(
            uk_citizenship: '1',
            name: Faker::Name.name,
            email: Faker::Internet.safe_email("#{Faker::Lorem.characters(rand(10..40))}-#{rand(1..999999)}"),
            location_code: 'GB',
            state: 'validated',
            postcode: POSTCODES.sample
          )
        end

        # Update to specified state requested
        case PETITION_STATE
        when 'open'
          petition.update_attributes(state: 'open', open_at: Time.now)
        when 'closed'
          petition.update_attributes(state: 'closed', open_at: Time.now - 1.year, closed_at: Time.now - 1.day)
        when 'rejected'
          petition.update_attributes(
            state: 'rejected',
            open_at: Time.now - 6.month,
            closed_at: Time.now + 6.month,
            rejection_text: Faker::Lorem.paragraph(rand(10..30)),
            rejection_code: REJECTION_CODES.sample
          )
        when 'hidden'
          petition.update_attributes(
            state: 'hidden',
            open_at: Time.now - 6.month,
            closed_at: Time.now  + 6.month,
            rejection_text: Faker::Lorem.paragraph(rand(10..30)),
            rejection_code: HIDDEN_CODES.sample
          )
        end


        # Should we create a petition with response and 10K signatures
        @should_create_response = (((idx+1) % 5) == 0 && RANDOM_RESPONSE == 'true')
        @signature_count = Site.threshold_for_response + 1 if @should_create_response

        @signature_count.to_i.times do
          signature = petition.signatures.create!(
            uk_citizenship: '1',
            name: Faker::Name.name,
            email: Faker::Internet.safe_email("#{Faker::Lorem.characters(rand(10..40))}-#{rand(1..999999)}"),
            location_code: 'GB',
            postcode: POSTCODES.sample
          )
          signature.validate!
        end

        # Add responses on random petitions when 10,000 signatures
        petition.update_attributes(
          response: Faker::Lorem.paragraph(rand(10..30))
        ) if @should_create_response
      end
    end
  end
end
