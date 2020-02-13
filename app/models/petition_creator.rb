require 'postcode_sanitizer'

class PetitionCreator
  extend ActiveModel::Naming
  extend ActiveModel::Translation
  include ActiveModel::Conversion

  STAGES = %w[petition replay_petition creator replay_email]

  PETITION_PARAMS  = [:action, :background, :additional_details]
  SIGNATURE_PARAMS = [:name, :email, :phone_number, :address, :postcode, :location_code, :notify_by_email]
  PERMITTED_PARAMS = [:q, :stage, :move_back, :move_next, petition_creator: PETITION_PARAMS + SIGNATURE_PARAMS]

  attr_reader :params, :errors, :request

  def initialize(params, request)
    @params = params.permit(*PERMITTED_PARAMS)
    @errors = ActiveModel::Errors.new(self)
    @request = request
  end

  def read_attribute_for_validation(attribute)
    public_send(attribute)
  end

  def to_partial_path
    "petitions/create/#{stage}_stage"
  end

  def duplicates
    Petition.current.search(q: action, count: 3).presence
  end

  def stage
    @stage ||= stage_param.in?(STAGES) ? stage_param : STAGES.first
  end

  def save
    if moving_backwards?
      @stage = previous_stage and return false
    end

    unless valid?
      return false
    end

    if done?
      @petition = Petition.new do |p|
        p.action = action
        p.background = background
        p.additional_details = additional_details

        p.build_creator do |c|
          c.name = name
          c.email = email
          c.build_contact do |contact|
            contact.phone_number = phone_number
            contact.address = address
          end
          c.postcode = postcode
          c.location_code = location_code
          c.constituency_id = constituency_id
          c.notify_by_email = notify_by_email
          c.ip_address = request.remote_ip
        end
      end

      @petition.save!
      send_email_to_gather_sponsors(@petition)

      return true
    else
      @stage = next_stage and return false
    end
  end

  def to_param
    if @petition && @petition.persisted?
      @petition.to_param
    else
      raise RuntimeError, "PetitionCreator#to_param called before petition was created"
    end
  end

  def action
    (petition_creator_params[:action] || query_param).to_s.strip
  end

  def action?
    action.present?
  end

  def background
    petition_creator_params[:background].to_s.strip
  end

  def background?
    background.present?
  end

  def additional_details
    petition_creator_params[:additional_details].to_s.strip
  end

  def name
    petition_creator_params[:name].to_s.strip
  end

  def email
    petition_creator_params[:email].to_s.strip
  end

  def phone_number
    petition_creator_params[:phone_number].to_s.tr('^1234567890', '')
  end

  def address
    petition_creator_params[:address].to_s.strip
  end

  def postcode
    PostcodeSanitizer.call(petition_creator_params[:postcode])
  end

  def location_code
    petition_creator_params[:location_code] || "GB"
  end

  def notify_by_email
    petition_creator_params[:notify_by_email] || "0"
  end

  private

  def query_param
    @query_param ||= params[:q].to_s.first(255)
  end

  def stage_param
    @stage_param ||= params[:stage].to_s
  end

  def petition_creator_params
    params[:petition_creator] || {}
  end

  def moving_backwards?
    params.key?(:move_back)
  end

  def stage_index
    STAGES.index(stage)
  end

  def previous_stage
    STAGES[[stage_index - 1, 0].max]
  end

  def next_stage
    STAGES[[stage_index + 1, 3].min]
  end

  def validate_petition
    errors.add(:action, :invalid) if action =~ /\A[-=+@]/
    errors.add(:action, :blank) unless action.present?
    errors.add(:action, :too_long, count: 80) if action.length > 80
    errors.add(:background, :invalid) if background =~ /\A[-=+@]/
    errors.add(:background, :blank) unless background.present?
    errors.add(:background, :too_long, count: 300) if background.length > 300
    errors.add(:additional_details, :invalid) if additional_details =~ /\A[-=+@]/
    errors.add(:additional_details, :too_long, count: 800) if additional_details.length > 800

    if errors.any?
      @stage = "petition"
    end
  end

  def validate_creator
    errors.add(:name, :invalid) if name =~ /\A[-=+@]/
    errors.add(:name, :blank) unless name.present?
    errors.add(:name, :too_long, count: 255) if action.length > 255
    errors.add(:email, :blank) unless email.present?
    errors.add(:phone_number, :blank) unless phone_number.present?
    errors.add(:phone_number, :too_long, count: 31) if phone_number.length > 31
    errors.add(:location_code, :blank) unless location_code.present?
    errors.add(:address, :blank) unless address.present?
    errors.add(:address, :too_long, count: 500) if address.length > 500
    errors.add(:postcode, :too_long, count: 255) if postcode.length > 255

    if email.present?
      email_validator.validate(self)
    end

    if location_code == "GB"
      errors.add(:postcode, :blank) unless postcode.present?

      if postcode.present?
        postcode_validator.validate(self)
      end
    end

    if replay_email?
      @stage = "replay_email"
    elsif errors.any?
      @stage = "creator"
    end
  end

  def validate
    validate_petition

    if errors.empty? && stage_index > 1
      validate_creator
    end
  end

  def valid?
    errors.clear
    validate
    errors.empty?
  end

  def replay_email?
    stage == "replay_email" && errors.keys == [:email]
  end

  def done?
    stage == "replay_email"
  end

  def email_validator
    EmailValidator.new(attributes: [:email])
  end

  def postcode_validator
    PostcodeValidator.new(attributes: [:postcode])
  end

  def constituency
    @constituency ||= Constituency.find_by_postcode(postcode)
  end

  def constituency_id
    constituency.try(:external_id)
  end

  def send_email_to_gather_sponsors(petition)
    GatherSponsorsForPetitionEmailJob.perform_later(petition)
  end
end
