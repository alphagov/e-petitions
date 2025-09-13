require 'postcode_sanitizer'

class PetitionCreator
  include StagedForm

  CREATOR_ATTRIBUTES = %i[
    name
    email
    email_confirmation
    location_code
    postcode
  ]

  stage :uk_citizenship
  stage :action
  stage :similar_petitions
  stage :background
  stage :additional_details
  stage :creator
  stage :check_and_submit

  attribute :action, :string
  attribute :background, :string
  attribute :additional_details, :string
  attribute :name, :string
  attribute :email, :string
  attribute :email_confirmation, :string
  attribute :postcode, :string
  attribute :location_code, :string, default: "GB"
  attribute :uk_citizenship, :string
  attribute :notify_by_email, :string

  strip_attribute :action, :background, :additional_details
  strip_attribute :name, :email, :email_confirmation

  normalizes :postcode, with: PostcodeSanitizer

  with_options on: [:uk_citizenship, :check_and_submit] do
    validates :uk_citizenship, presence: true, acceptance: true
  end

  with_options on: [:action, :check_and_submit] do
    validates :action, presence: true
    validates :action, format: { without: /\A[-=+@]/ }
    validates :action, length: { maximum: 80 }
  end

  with_options on: [:background, :check_and_submit] do
    validates :background, presence: true
    validates :background, format: { without: /\A[-=+@]/ }
    validates :background, length: { maximum: 300 }
  end

  with_options on: [:additional_details, :check_and_submit] do
    validates :additional_details, format: { without: /\A[-=+@]/ }
    validates :additional_details, length: { maximum: 800 }
  end

  with_options on: [:creator, :check_and_submit] do
    validates :name, presence: true, length: { maximum: 255 }
    validates :name, format: { without: /\A[-=+@]/ }
    validates :name, format: { without: URI.regexp, message: :has_uri }

    validates :email, presence: true, email: true, confirmation: true
    validates :email_confirmation, presence: true, email: true

    validates :location_code, presence: true, format: { with: /\A[A-Z]{2,3}\z/ }

    validates :postcode, presence: true, postcode: true, if: :united_kingdom?
    validates :postcode, length: { maximum: 255 }, unless: :united_kingdom?
    validates :postcode, length: { maximum: 10 }, if: :united_kingdom?
  end

  after_validation on: :uk_citizenship do
    if citizenship_errors? && uk_citizenship.present?
      @stage = "non_citizen"
    end
  end

  after_validation on: :check_and_submit do
    if citizenship_errors?
      @stage = "uk_citizenship"
    elsif action_errors?
      @stage = "action"
    elsif background_errors?
      @stage = "background"
    elsif additional_details_errors?
      @stage = "additional_details"
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

  def citizenship_errors?
    errors.include?(:uk_citizenship)
  end

  def action_errors?
    errors.include?(:action)
  end

  def background_errors?
    errors.include?(:background)
  end

  def additional_details_errors?
    errors.include?(:additional_details)
  end

  def creator_errors?
    (CREATOR_ATTRIBUTES & errors.attribute_names).present?
  end

  def rate_limit
    @rate_limit ||= RateLimit.first_or_create!
  end

  def send_email_to_gather_sponsors(petition)
    GatherSponsorsForPetitionEmailJob.perform_later(petition)
  end
end
