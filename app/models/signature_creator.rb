require 'domain_autocorrect'
require 'postcode_sanitizer'

class SignatureCreator
  include StagedForm

  SIGNATURE_ATTRIBUTES = %i[
    name
    location_code
    postcode
    uk_citizenship
  ]

  stage :signature
  stage :replay_email

  attribute :name, :string
  attribute :email, :string
  attribute :postcode, :string
  attribute :location_code, :string, default: "GB"
  attribute :uk_citizenship, :string
  attribute :notify_by_email, :boolean

  strip_attribute :name, :email

  normalizes :postcode, with: PostcodeSanitizer

  with_options on: [:signature, :replay_email] do
    validates :name, presence: true, length: { maximum: 255 }
    validates :name, format: { without: /\A[-=+@]/ }
    validates :name, format: { without: URI.regexp, message: :has_uri }

    validates :email, presence: true, email: true
    validates :location_code, presence: true, format: { with: /\A[A-Z]{2,3}\z/ }

    validates :postcode, presence: true, postcode: true, if: :united_kingdom?
    validates :postcode, length: { maximum: 255 }, unless: :united_kingdom?
    validates :postcode, length: { maximum: 10 }, if: :united_kingdom?

    validates :uk_citizenship, acceptance: true
  end

  before_validation on: :signature do
    self.email = DomainAutocorrect.call(email)
  end

  after_validation on: :replay_email do
    if signature_errors?
      @stage = "signature"
    end
  end

  def initialize(petition, params, request)
    super(params, request)

    @petition = petition
  end

  def save
    super do
      @signature = scope.new do |s|
        s.name = name
        s.email = email
        s.postcode = postcode
        s.location_code = location_code
        s.uk_citizenship = uk_citizenship
        s.notify_by_email = notify_by_email
        s.ip_address = request.remote_ip
      end

      @signature.save!
      send_email_to_petition_signer

      break true
    rescue ActiveRecord::RecordNotUnique
      @signature = @signature.find_duplicate!
      send_email_to_petition_signer

      break true
    rescue ActiveRecord::RecordInvalid
      break false
    end
  end

  def to_partial_path
    "signatures/create/#{stage}_stage"
  end

  def united_kingdom?
    location_code == "GB"
  end

  def model_name
    Signature.model_name
  end

  def ip_address
    request.remote_ip
  end

  def scope
    @petition.signatures
  end

  private

  def signature_errors?
    errors.any? { |e| SIGNATURE_ATTRIBUTES.include?(e.attribute) }
  end

  def send_email_to_petition_signer
    unless @signature.email_threshold_reached?
      if @signature.pending?
        EmailConfirmationForSignerEmailJob.perform_later(@signature)
      else
        EmailDuplicateSignaturesEmailJob.perform_later(@signature)
      end
    end
  end
end
