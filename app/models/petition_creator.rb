require 'domain_autocorrect'
require 'postcode_sanitizer'

class PetitionCreator
  include StagedForm

  CITIZENSHIP_ATTRIBUTES = %i[
    uk_citizenship
  ]

  PETITION_ATTRIBUTES = %i[
    action
    background
    additional_details
  ]

  CREATOR_ATTRIBUTES = %i[
    name
    location_code
    postcode
  ]

  stage :uk_citizenship
  stage :petition
  stage :replay_petition
  stage :creator
  stage :replay_email

  attribute :action, :string
  attribute :background, :string
  attribute :additional_details, :string
  attribute :name, :string
  attribute :email, :string
  attribute :postcode, :string
  attribute :location_code, :string, default: "GB"
  attribute :uk_citizenship, :string
  attribute :notify_by_email, :string

  strip_attribute :action, :background, :additional_details
  strip_attribute :name, :email

  normalizes :postcode, with: PostcodeSanitizer

  with_options on: [:uk_citizenship, :replay_email] do
    validates :uk_citizenship, presence: true, acceptance: true
  end

  with_options on: [:petition, :replay_email] do
    validates :action, :background, presence: true
    validates :action, :background, :additional_details, format: { without: /\A[-=+@]/ }
    validates :action, length: { maximum: 80 }
    validates :background, length: { maximum: 300 }
    validates :additional_details, length: { maximum: 800 }
  end

  with_options on: [:creator, :replay_email] do
    validates :name, presence: true, length: { maximum: 255 }
    validates :name, format: { without: /\A[-=+@]/ }
    validates :name, format: { without: URI.regexp, message: :has_uri }

    validates :email, presence: true, email: true
    validates :location_code, presence: true, format: { with: /\A[A-Z]{2,3}\z/ }

    validates :postcode, presence: true, postcode: true, if: :united_kingdom?
    validates :postcode, length: { maximum: 255 }, unless: :united_kingdom?
    validates :postcode, length: { maximum: 10 }, if: :united_kingdom?
  end

  before_validation on: :creator do
    self.email = DomainAutocorrect.call(email)
  end

  after_validation on: :uk_citizenship do
    if citzenship_errors? && uk_citizenship.present?
      @stage = "non_citizen"
    end
  end

  after_validation on: :replay_email do
    if citzenship_errors?
      @stage = "uk_citizenship"
    elsif petition_errors?
      @stage = "petition"
    elsif creator_errors?
      @stage = "creator"
    end
  end

  def save
    super do
      @petition = Petition.new do |p|
        p.action = action
        p.background = background
        p.additional_details = additional_details

        p.build_creator do |c|
          c.name = name
          c.email = email
          c.postcode = postcode
          c.location_code = location_code
          c.uk_citizenship = uk_citizenship
          c.constituency_id = constituency_id
          c.notify_by_email = notify_by_email
          c.ip_address = request.remote_ip
        end
      end

      unless rate_limit.exceeded?(@petition.creator)
        @petition.save!
        send_email_to_gather_sponsors(@petition)
      end

      true
    end
  end

  def action
    super || query_param
  end

  def to_partial_path
    "petitions/create/#{stage}_stage"
  end

  def duplicates
    Petition.current.by_most_popular.search(q: action, count: 3).presence
  end

  def united_kingdom?
    location_code == "GB"
  end

  private

  def constituency
    @constituency ||= Constituency.find_by_postcode(postcode)
  end

  def constituency_id
    constituency.try(:external_id)
  end

  def citzenship_errors?
    errors.any? { |e| CITIZENSHIP_ATTRIBUTES.include?(e.attribute) }
  end

  def creator_errors?
    errors.any? { |e| CREATOR_ATTRIBUTES.include?(e.attribute) }
  end

  def petition_errors?
    errors.any? { |e| PETITION_ATTRIBUTES.include?(e.attribute) }
  end

  def query_param
    @query_param ||= params[:q].to_s.first(255)
  end

  def rate_limit
    @rate_limit ||= RateLimit.first_or_create!
  end

  def send_email_to_gather_sponsors(petition)
    GatherSponsorsForPetitionEmailJob.perform_later(petition)
  end
end
