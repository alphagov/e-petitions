require 'bcrypt'
require 'uri'
require 'active_support/number_helper'

class Site < ActiveRecord::Base
  class ServiceUnavailable < StandardError; end
  class PetitionRemoved < StandardError; end

  include ActiveSupport::NumberHelper

  MESSAGE_COLOURS = %w[default grey orange red black]

  FALSE_VALUES = [nil, false, 0, '0', 'f', 'F', 'false', 'FALSE', 'off', 'OFF'].to_set

  FEATURE_FLAGS = %w[
    disable_constituency_api
    disable_trending_petitions
    disable_invalid_signature_count_check
    disable_daily_update_statistics_job
    disable_plus_address_check
    disable_feedback_sending
    disable_collecting_signatures
    disable_petition_creation
  ]

  class << self
    def table_exists?
      @table_exists ||= connection.table_exists?(table_name)
    rescue ActiveRecord::NoDatabaseError => e
      false
    end

    def instance
      Thread.current[:__site__] ||= first_or_create(defaults)
    end

    def authenticate(username, password)
      instance.authenticate(username, password)
    end

    def email_protocol
      instance.email_protocol
    end

    def enabled?
      instance.enabled?
    end

    def formatted_threshold_for_response
      instance.formatted_threshold_for_response
    end

    def formatted_threshold_for_debate
      instance.formatted_threshold_for_debate
    end

    def host
      instance.host
    end

    def host_with_port
      instance.host_with_port
    end

    def constraints_for_public
      if table_exists?
        instance.constraints_for_public
      else
        default_constraints_for_public
      end
    end

    def moderate_host
      instance.moderate_host
    end

    def moderate_host_with_port
      instance.moderate_host_with_port
    end

    def moderate_url
      if table_exists?
        instance.moderate_url
      else
        default_moderate_url
      end
    end

    def constraints_for_moderation
      if table_exists?
        instance.constraints_for_moderation
      else
        default_constraints_for_moderation
      end
    end

    def opened_at_for_closing(time = Time.current)
      instance.opened_at_for_closing(time)
    end

    def closed_at_for_opening(time = Time.current)
      instance.closed_at_for_opening(time)
    end

    def port
      instance.port
    end

    def protected?
      instance.protected?
    end

    def login_timeout
      if table_exists?
        instance.login_timeout
      else
        default_login_timeout
      end
    end

    def reload
      Thread.current[:__site__] = nil
    end

    def reset!(attributes = defaults)
      destroy_all and reload
      create!(attributes)
    end

    def update!(attributes)
      instance.update!(attributes)
    end

    def touch(*names)
      if instance.persisted?
        instance.touch(*names)
      end
    end

    def signature_collection_disabled?
      disable_collecting_signatures?
    end

    def enhanced_email_formatting?
      !!instance.enhanced_email_formatting
    end

    def email_header_style
      instance.email_header_style
    end

    def home_page_message
      instance.home_page_message
    end

    def home_page_message_colour
      instance.home_page_message_colour
    end

    def petition_page_message
      instance.petition_page_message
    end

    def petition_page_message_colour
      instance.petition_page_message_colour
    end

    def feedback_page_message
      instance.feedback_page_message
    end

    def feedback_page_message_colour
      instance.feedback_page_message_colour
    end

    def show_home_page_message?
      instance.show_home_page_message?
    end

    def show_petition_page_message?
      instance.show_petition_page_message?
    end

    def show_feedback_page_message?
      instance.show_feedback_page_message?
    end

    def moderation_delay?
      instance.moderation_delay?
    end

    def moderation_delay_message
      instance.moderation_delay_message
    end

    def disable_signature_counts!
      instance.update!(update_signature_counts: false)
    end

    def enable_signature_counts!(interval: nil)
      updates = { update_signature_counts: true }
      updates[:signature_count_interval] = interval if interval

      instance.update!(updates)
    end

    def last_checked_at!(timestamp = Time.current)
      instance.update_all(last_petition_created_at: timestamp)
    end

    def last_petition_created_at!(timestamp = Time.current)
      instance.update_all(last_petition_created_at: timestamp)
    end

    def signature_count_updated_at!(timestamp = Time.current)
      instance.update_all(signature_count_updated_at: timestamp)
    end

    def moderation_overdue_in_days
      14.days
    end

    def moderation_near_overdue_in_days
      11.days
    end

    def maximum_number_of_signatures
      maximum_number_of_sponsors + 1
    end

    def defaults
      {
        title:                          default_title,
        url:                            default_url,
        moderate_url:                   default_moderate_url,
        email_from:                     default_email_from,
        feedback_email:                 default_feedback_email,
        username:                       default_username,
        password:                       default_password,
        enabled:                        default_enabled,
        protected:                      default_protected,
        login_timeout:                  default_login_timeout,
        petition_duration:              default_petition_duration,
        minimum_number_of_sponsors:     default_minimum_number_of_sponsors,
        maximum_number_of_sponsors:     default_maximum_number_of_sponsors,
        threshold_for_moderation:       default_threshold_for_moderation,
        threshold_for_moderation_delay: default_threshold_for_moderation_delay,
        threshold_for_response:         default_threshold_for_response,
        threshold_for_debate:           default_threshold_for_debate
      }
    end

    private

    def default_title
      ENV.fetch('SITE_TITLE', 'Petition parliament')
    end

    def default_scheme
      ENV.fetch('EPETITIONS_PROTOCOL', 'https')
    end

    def default_protocol
      "#{default_scheme}://"
    end

    def default_url
      if ENV.fetch('EPETITIONS_PROTOCOL', 'https') == 'https'
        URI::HTTPS.build(default_url_components).to_s
      else
        URI::HTTP.build(default_url_components).to_s
      end
    end

    def default_url_components
      [nil, default_host, default_port, nil, nil, nil]
    end

    def default_host
      ENV.fetch('EPETITIONS_HOST', 'petition.parliament.uk')
    end

    def default_domain(tld_length = 1)
      ActionDispatch::Http::URL.extract_domain(default_host, tld_length)
    end

    def default_moderate_url
      if ENV.fetch('EPETITIONS_PROTOCOL', 'https') == 'https'
        URI::HTTPS.build(default_moderate_url_components).to_s
      else
        URI::HTTP.build(default_moderate_url_components).to_s
      end
    end

    def default_moderate_url_components
      [nil, default_moderate_host, default_port, nil, nil, nil]
    end

    def default_moderate_host
      ENV.fetch('MODERATE_HOST', 'moderate.petition.parliament.uk')
    end

    def default_port
      ENV.fetch('EPETITIONS_PORT', '443').to_i
    end

    def default_email_from
      ENV.fetch('EPETITIONS_FROM', %{"Petitions: UK Government and Parliament" <no-reply@#{default_host}>})
    end

    def default_feedback_email
      ENV.fetch('EPETITIONS_FEEDBACK', %{"Petitions: UK Government and Parliament" <petitionscommittee@#{default_domain}>})
    end

    def default_username
      ENV.fetch('SITE_USERNAME', nil).presence
    end

    def default_password
      ENV.fetch('SITE_PASSWORD', nil).presence
    end

    def default_enabled
      !ENV.fetch('SITE_ENABLED', '1').to_i.zero?
    end

    def default_protected
      !ENV.fetch('SITE_PROTECTED', '0').to_i.zero?
    end

    def default_login_timeout
      ENV.fetch('SITE_LOGIN_TIMEOUT', '1800').to_i
    end

    def default_petition_duration
      ENV.fetch('PETITION_DURATION', '6').to_i
    end

    def default_minimum_number_of_sponsors
      ENV.fetch('MINIMUM_NUMBER_OF_SPONSORS', '5').to_i
    end

    def default_maximum_number_of_sponsors
      ENV.fetch('MAXIMUM_NUMBER_OF_SPONSORS', '20').to_i
    end

    def default_threshold_for_moderation
      ENV.fetch('THRESHOLD_FOR_MODERATION', '5').to_i
    end

    def default_threshold_for_moderation_delay
      ENV.fetch('THRESHOLD_FOR_MODERATION_DELAY', '500').to_i
    end

    def default_threshold_for_response
      ENV.fetch('THRESHOLD_FOR_RESPONSE', '10000').to_i
    end

    def default_threshold_for_debate
      ENV.fetch('THRESHOLD_FOR_DEBATE', '100000').to_i
    end

    def default_constraints_for_public
      { protocol: default_protocol, host: default_host, port: default_port }
    end

    def default_constraints_for_moderation
      { protocol: default_protocol, host: default_moderate_host, port: default_port }
    end
  end

  if table_exists?
    column_names.map(&:to_sym).each do |column|
      define_singleton_method(column) do |*args, &block|
        instance.public_send(column, *args, &block)
      end
    end
  end

  FEATURE_FLAGS.each do |feature_flag|
    define_singleton_method(:"#{feature_flag}?") do |*args, &block|
      instance.public_send(feature_flag, *args, &block)
    end

    define_method(:"#{feature_flag}=") do |value|
      write_store_attribute(:feature_flags, feature_flag, type_cast_feature_flag(value))
    end

    define_method(feature_flag) do
      read_store_attribute(:feature_flags, feature_flag)
    end
  end

  store_accessor :feature_flags, :enhanced_email_formatting
  store_accessor :feature_flags, :email_header_style
  store_accessor :feature_flags, :home_page_message
  store_accessor :feature_flags, :home_page_message_colour
  store_accessor :feature_flags, :show_home_page_message
  store_accessor :feature_flags, :petition_page_message
  store_accessor :feature_flags, :petition_page_message_colour
  store_accessor :feature_flags, :show_petition_page_message
  store_accessor :feature_flags, :feedback_page_message
  store_accessor :feature_flags, :feedback_page_message_colour
  store_accessor :feature_flags, :show_feedback_page_message
  store_accessor :feature_flags, :moderation_delay_message

  attr_reader :password

  def enhanced_email_formatting
    super || false
  end

  def enhanced_email_formatting=(value)
    super(type_cast_feature_flag(value))
  end

  def email_header_style
    super || 'white'
  end

  def home_page_message_colour
    super || 'default'
  end

  def show_home_page_message?
    disable_collecting_signatures || show_home_page_message
  end

  def show_home_page_message=(value)
    super(type_cast_feature_flag(value))
  end

  def petition_page_message_colour
    super || 'default'
  end

  def show_petition_page_message?
    disable_collecting_signatures || show_petition_page_message
  end

  def show_petition_page_message=(value)
    super(type_cast_feature_flag(value))
  end

  def feedback_page_message_colour
    super || 'default'
  end

  def show_feedback_page_message?
    show_feedback_page_message
  end

  def show_feedback_page_message=(value)
    super(type_cast_feature_flag(value))
  end

  def moderation_delay?
    return @moderation_delay if defined?(@moderation_delay)
    @moderation_delay = Petition.in_moderation.count >= threshold_for_moderation_delay
  end

  def moderation_delay_message
    super.presence || <<~MESSAGE.squish
      We have a very large number of petitions to check at the moment so it may take
      us longer than usual to check your petition. Thank you for your patience.
    MESSAGE
  end

  def moderation_delay_message=(value)
    super(value.to_s.squish.presence)
  end

  def authenticate(username, password)
    self.username == username && self.password_digest == password
  end

  def email_protocol
    uri.scheme
  end

  def formatted_threshold_for_response
    number_to_delimited(threshold_for_response)
  end

  def formatted_threshold_for_debate
    number_to_delimited(threshold_for_debate)
  end

  def host
    uri.host
  end

  def host_with_port
    "#{host}#{port_string(uri)}"
  end

  def port
    uri.port
  end

  def protocol
    "#{uri.scheme}://"
  end

  def constraints_for_public
    unless database_migrating?
      { protocol: protocol, host: host, port: port }
    end
  end

  def moderate_host
    moderate_uri.host
  end

  def moderate_host_with_port
    "#{moderate_host}#{port_string(moderate_uri)}"
  end

  def moderate_port
    moderate_uri.port
  end

  def moderate_protocol
    "#{moderate_uri.scheme}://"
  end

  def constraints_for_moderation
    unless database_migrating?
      { protocol: moderate_protocol, host: moderate_host, port: moderate_port }
    end
  end

  def password_digest
    super.present? ? BCrypt::Password.new(super) : nil
  end

  def password=(new_password)
    @password = new_password.presence

    if @password
      self.password_digest = BCrypt::Password.create(@password, cost: 10)
    end
  end

  def opened_at_for_closing(time = Time.current)
    opened_at = time.beginning_of_day - petition_duration.months

    if opened_at.day < time.day
      opened_at + 1.day
    else
      opened_at
    end
  end

  def closed_at_for_opening(time = Time.current)
    time.end_of_day + petition_duration.months
  end

  def signature_count_updated_at
    super || Signature.earliest_validation
  end

  validates :title, presence: true, length: { maximum: 50 }
  validates :url, presence: true, length: { maximum: 50 }
  validates :moderate_url, presence: true, length: { maximum: 50 }
  validates :email_from, presence: true, length: { maximum: 100 }
  validates :feedback_email, presence: true, length: { maximum: 100 }
  validates :petition_duration, presence: true, numericality: { only_integer: true }
  validates :minimum_number_of_sponsors, presence: true, numericality: { only_integer: true }
  validates :maximum_number_of_sponsors, presence: true, numericality: { only_integer: true }
  validates :threshold_for_moderation, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 10 }
  validates :threshold_for_moderation_delay, presence: true, numericality: { only_integer: true }
  validates :threshold_for_response, presence: true, numericality: { only_integer: true }
  validates :threshold_for_debate, presence: true, numericality: { only_integer: true }
  validates :username, presence: true, length: { maximum: 30 }, if: :protected?
  validates :password, length: { maximum: 30 }, confirmation: true, if: :protected?
  validates :login_timeout, presence: true, numericality: { only_integer: true }
  validates :home_page_message, presence: true, if: -> { disable_collecting_signatures || show_home_page_message? }
  validates :home_page_message, length: { maximum: 800 }
  validates :home_page_message_colour, inclusion: { in: MESSAGE_COLOURS }, allow_blank: true
  validates :petition_page_message, presence: true, if: -> { disable_collecting_signatures || show_petition_page_message? }
  validates :petition_page_message, length: { maximum: 800 }
  validates :petition_page_message_colour, inclusion: { in: MESSAGE_COLOURS }, allow_blank: true
  validates :feedback_page_message, presence: true, if: -> { show_feedback_page_message? }
  validates :feedback_page_message, length: { maximum: 800 }
  validates :feedback_page_message_colour, inclusion: { in: MESSAGE_COLOURS }, allow_blank: true
  validates :moderation_delay_message, presence: true, length: { maximum: 500 }

  validate if: :protected? do
    errors.add(:password, :blank) unless password_digest?
  end

  before_save if: :update_signature_counts_changed? do
    if update_signature_counts
      UpdateSignatureCountsJob.perform_later
    end
  end

  def update_all(updates)
    if scope.update_all(updates) > 0
      reload
    else
      false
    end
  end

  def to_liquid
    SiteDrop.new(self)
  end

  private

  def scope
    self.class.unscoped.where(id: id)
  end

  def database_migrating?
    ARGV.any?{ |arg| arg =~ /db:migrate/ }
  end

  def port_string(uri)
    standard_port?(uri) ? '' : ":#{uri.port}"
  end

  def standard_port(uri)
    case uri.scheme
      when 'https' then 443
      else 80
    end
  end

  def standard_port?(uri)
    uri.port == standard_port(uri)
  end

  def uri
    @uri ||= URI.parse(url)
  end

  def moderate_uri
    @moderate_uri ||= URI.parse(moderate_url)
  end

  def type_cast_feature_flag(value)
    value.in?(FALSE_VALUES) ? false : true
  end
end
