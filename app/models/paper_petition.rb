class PaperPetition
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_reader :petition
  delegate :threshold_for_debate, to: :Site

  attribute :action_en, :string
  attribute :action_cy, :string
  attribute :background_en, :string
  attribute :background_cy, :string
  attribute :additional_details_en, :string
  attribute :additional_details_cy, :string
  attribute :locale, :string, default: "en-GB"
  attribute :location_code, :string, default: "GB-WLS"
  attribute :signature_count, :integer
  attribute :submitted_on, :date
  attribute :name, :string
  attribute :email, :string
  attribute :phone_number, :string
  attribute :address, :string
  attribute :postcode, :string

  with_options presence: true do
    validates :action_en, :background_en
    validates :action_cy, :background_cy
    validates :locale, :location_code
    validates :signature_count, :submitted_on
    validates :name, :email, :phone_number
    validates :address, :postcode
  end

  with_options length: { maximum: 100 } do
    validates :action_en, :action_cy
  end

  with_options length: { maximum: 500 } do
    validates :background_en, :background_cy, :address
  end

  with_options length: { maximum: 1100 } do
    validates :additional_details_en, :additional_details_cy
  end

  with_options length: { maximum: 255 } do
    validates :email, :postcode
  end

  with_options format: { with: /\A[^-=+@]/, allow_blank: true } do
    validates :action_en, :background_en, :additional_details_en
    validates :action_cy, :background_cy, :additional_details_cy
    validates :name, :phone_number, :address
  end

  validates :locale, inclusion: { in: %w[en-GB cy-GB] }
  validates :email, email: true
  validates :postcode, postcode: true
  validates :phone_number, length: { maximum: 31 }

  validates :signature_count, numericality: {
    only_integer: true, greater_than_or_equal_to: Site.threshold_for_referral
  }

  def action_en=(value)
    super(value.to_s.strip)
  end

  def action_cy=(value)
    super(value.to_s.strip)
  end

  def background_en=(value)
    super(value.to_s.strip)
  end

  def background_cy=(value)
    super(value.to_s.strip)
  end

  def additional_details_en=(value)
    super(value.to_s.strip)
  end

  def additional_details_cy=(value)
    super(value.to_s.strip)
  end

  def additional_details_en?
    additional_details_en.present?
  end

  def additional_details_cy?
    additional_details_cy.present?
  end

  def name=(value)
    super(value.to_s.strip)
  end

  def email=(value)
    super(value.to_s.downcase.strip)
  end

  def phone_number=(value)
    super(value.to_s.strip)
  end

  def postcode=(value)
    super(PostcodeSanitizer.call(value))
  end

  def save
    return false unless valid?

    @petition = Petition.new(petition_params)
    @signature = @petition.build_creator(signature_params)
    @contact = @signature.build_contact(contact_params)

    @petition.save!
  end

  private

  def petition_params
    {
      state: "closed", submitted_on_paper: true,
      action_en: action_en, background_en: background_en,
      additional_details_en: additional_details_en,
      action_cy: action_cy, background_cy: background_cy,
      additional_details_cy: additional_details_cy,
      locale: locale, signature_count: signature_count,
      submitted_on: submitted_on, open_at: open_at,
      moderation_threshold_reached_at: closed_at,
      referral_threshold_reached_at: closed_at,
      debate_threshold_reached_at: debate_threshold_reached_at,
      closed_at: closed_at, last_signed_at: closed_at,
      referred_at: closed_at,
    }
  end

  def signature_params
    {
      name: name, email: email, postcode: postcode,
      location_code: location_code, locale: locale
    }
  end

  def contact_params
    { address: address, phone_number: phone_number }
  end

  def open_at
    60.days.before(closed_at)
  end

  def closed_at
    submitted_on.noon
  end

  def debate_threshold_reached_at
    signature_count >= threshold_for_debate ? closed_at : nil
  end
end
