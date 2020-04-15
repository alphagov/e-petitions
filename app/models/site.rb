require 'bcrypt'
require 'uri'
require 'active_support/number_helper'

class Site < ActiveRecord::Base
  class ServiceUnavailable < StandardError; end

  include ActiveSupport::NumberHelper
  include Translatable

  translate :title, :url, :email_from

  FALSE_VALUES = [nil, false, 0, '0', 'f', 'F', 'false', 'FALSE', 'off', 'OFF'].to_set

  FEATURE_FLAGS = %w[
    disable_constituency_api
    disable_trending_petitions
    disable_invalid_signature_count_check
    disable_daily_update_statistics_job
    disable_plus_address_check
    disable_feedback_sending
  ]

  class << self
    def table_exists?
      @table_exists ||= connection.table_exists?(table_name)
    rescue ActiveRecord::NoDatabaseError => e
      false
    end

    def before_remove_const
      Thread.current[:__site__] = nil
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

    def formatted_threshold_for_moderation
      instance.formatted_threshold_for_moderation
    end

    def formatted_threshold_for_referral
      instance.formatted_threshold_for_referral
    end

    def formatted_threshold_for_debate
      instance.formatted_threshold_for_debate
    end

    def host_en
      instance.host_en
    end
    alias_method :host, :host_en

    def host_with_port_en
      instance.host_with_port_en
    end
    alias_method :host_with_port, :host_with_port_en

    def host_cy
      instance.host_cy
    end

    def host_with_port_cy
      instance.host_with_port_cy
    end

    def constraints_for_public_en
      if table_exists?
        instance.constraints_for_public_en
      else
        default_constraints_for_public_en
      end
    end
    alias_method :constraints_for_public, :constraints_for_public_en

    def constraints_for_public_cy
      if table_exists?
        instance.constraints_for_public_cy
      else
        default_constraints_for_public_cy
      end
    end

    def moderate_host
      instance.moderate_host
    end

    def moderate_host_with_port
      instance.moderate_host_with_port
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

    def port_en
      instance.port_en
    end
    alias_method :port, :port_en

    def port_cy
      instance.port_cy
    end

    def protected?
      instance.protected?
    end

    def login_timeout
      instance.login_timeout
    end

    def reload
      Thread.current[:__site__] = nil
    end

    def touch(*names)
      instance.touch(*names)
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

    def translations_updated_at!(timestamp = Time.current)
      instance.update_all(translations_updated_at: timestamp)
    end

    def translation_enabled?
      ENV['TRANSLATION_ENABLED'] == 'true'
    end

    def moderation_overdue_in_days
      7.days
    end

    def moderation_near_overdue_in_days
      5.days
    end

    def defaults
      {
        title_en:                       default_title_en,
        title_cy:                       default_title_cy,
        url_en:                         default_url_en,
        url_cy:                         default_url_cy,
        moderate_url:                   default_moderate_url,
        email_from_en:                  default_email_from_en,
        email_from_cy:                  default_email_from_cy,
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
        threshold_for_referral:         default_threshold_for_referral,
        threshold_for_debate:           default_threshold_for_debate
      }
    end

    %i[title url email_from].each do |method|
      method_en = :"#{method}_en"
      method_cy = :"#{method}_cy"

      define_method method do
        instance.public_send method
      end

      define_method method_en do
        instance.public_send method_en
      end

      define_method method_cy do
        instance.public_send method_cy
      end
    end

    def urls
      [url_en, url_cy]
    end

    def feedback_address
      instance.feedback_address
    end

    private

    def default_title_en
      ENV.fetch('SITE_TITLE_EN', "Petition the Senedd")
    end
    alias_method :default_title, :default_title_en

    def default_title_cy
      ENV.fetch('SITE_TITLE_CY', "Deisebu'r Senedd")
    end

    def default_scheme
      ENV.fetch('EPETITIONS_PROTOCOL', 'https')
    end

    def default_protocol
      "#{default_scheme}://"
    end

    def default_uri
      default_scheme == 'https' ? URI::HTTPS : URI::HTTP
    end

    def default_url_en
      default_uri.build(default_url_components(default_host_en)).to_s
    end

    def default_url_cy
      default_uri.build(default_url_components(default_host_cy)).to_s
    end

    def default_url_components(host)
      [nil, host, default_port, nil, nil, nil]
    end

    def default_host_en
      ENV.fetch('EPETITIONS_HOST_EN', 'petitions.senedd.wales')
    end
    alias_method :default_host, :default_host_en

    def default_host_cy
      ENV.fetch('EPETITIONS_HOST_CY', 'deisebau.senedd.cymru')
    end

    def default_domain(tld_length = 1)
      ActionDispatch::Http::URL.extract_domain(default_host, tld_length)
    end

    def default_moderate_url
      default_uri.build(default_moderate_url_components).to_s
    end

    def default_moderate_url_components
      [nil, default_moderate_host, default_port, nil, nil, nil]
    end

    def default_moderate_host
      ENV.fetch('MODERATE_HOST', 'moderate.petitions.senedd.wales')
    end

    def default_port
      ENV.fetch('EPETITIONS_PORT', '443').to_i
    end

    def default_email_from_en
      ENV.fetch('EPETITIONS_FROM_EN', %{"Petitions: Senedd" <no-reply@#{default_host_en}>})
    end
    alias_method :default_email_from, :default_email_from_en

    def default_email_from_cy
      ENV.fetch('EPETITIONS_FROM_CY', %{"Deisebau: Senedd" <dim-ateb@#{default_host_cy}>})
    end

    def default_feedback_email
      ENV.fetch('EPETITIONS_FEEDBACK', %{"Petitions: Senedd" <petitions@#{default_domain}>})
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
      ENV.fetch('MINIMUM_NUMBER_OF_SPONSORS', '2').to_i
    end

    def default_maximum_number_of_sponsors
      ENV.fetch('MAXIMUM_NUMBER_OF_SPONSORS', '20').to_i
    end

    def default_threshold_for_moderation
      ENV.fetch('THRESHOLD_FOR_MODERATION', '2').to_i
    end

    def default_threshold_for_moderation_delay
      ENV.fetch('THRESHOLD_FOR_MODERATION_DELAY', '500').to_i
    end

    def default_threshold_for_referral
      ENV.fetch('THRESHOLD_FOR_REFERRAL', '50').to_i
    end

    def default_threshold_for_debate
      ENV.fetch('THRESHOLD_FOR_DEBATE', '5000').to_i
    end

    def default_constraints_for_public_en
      { protocol: default_protocol, host: default_host_en, port: default_port }
    end
    alias_method :default_constraints_for_public, :default_constraints_for_public_en

    def default_constraints_for_public_cy
      { protocol: default_protocol, host: default_host_cy, port: default_port }
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
  else
    class << self
      def threshold_for_referral
        default_threshold_for_referral
      end

      def threshold_for_debate
        default_threshold_for_debate
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

  attr_reader :password

  def authenticate(username, password)
    self.username == username && self.password_digest == password
  end

  def email_protocol
    uri.scheme
  end

  def formatted_threshold_for_moderation
    number_to_delimited(threshold_for_moderation)
  end

  def formatted_threshold_for_referral
    number_to_delimited(threshold_for_referral)
  end

  def formatted_threshold_for_debate
    number_to_delimited(threshold_for_debate)
  end

  def host_en
    uri_en.host
  end
  alias_method :host, :host_en

  def host_with_port_en
    "#{host_en}#{port_string(uri_en)}"
  end
  alias_method :host_with_port, :host_with_port_en

  def host_cy
    uri_cy.host
  end

  def host_with_port_cy
    "#{host_cy}#{port_string(uri_cy)}"
  end

  def port_en
    uri_en.port
  end
  alias_method :port, :port_en

  def protocol_en
    "#{uri_en.scheme}://"
  end
  alias_method :protocol, :protocol_en

  def port_cy
    uri_cy.port
  end

  def protocol_cy
    "#{uri_cy.scheme}://"
  end

  def constraints_for_public_en
    unless database_migrating?
      { protocol: protocol_en, host: host_en, port: port_en }
    end
  end
  alias_method :constraints_for_public, :constraints_for_public_en

  def constraints_for_public_cy
    unless database_migrating?
      { protocol: protocol_cy, host: host_cy, port: port_cy }
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
    BCrypt::Password.new(super)
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

  def translations_updated_at
    super || updated_at
  end

  def feedback_address
    @feedback_address ||= Mail::Address.new(feedback_email).address
  end

  validates :title_en, :title_cy, presence: true, length: { maximum: 50 }
  validates :url_en, :url_cy, presence: true, length: { maximum: 50 }
  validates :moderate_url, presence: true, length: { maximum: 50 }
  validates :email_from_en, :email_from_cy, presence: true, length: { maximum: 100 }
  validates :feedback_email, presence: true, length: { maximum: 100 }
  validates :petition_duration, presence: true, numericality: { only_integer: true }
  validates :minimum_number_of_sponsors, presence: true, numericality: { only_integer: true }
  validates :maximum_number_of_sponsors, presence: true, numericality: { only_integer: true }
  validates :threshold_for_moderation, presence: true, numericality: { only_integer: true }
  validates :threshold_for_moderation_delay, presence: true, numericality: { only_integer: true }
  validates :threshold_for_referral, presence: true, numericality: { only_integer: true }
  validates :threshold_for_debate, presence: true, numericality: { only_integer: true }
  validates :username, presence: true, length: { maximum: 30 }, if: :protected?
  validates :password, length: { maximum: 30 }, confirmation: true, if: :protected?
  validates :login_timeout, presence: true, numericality: { only_integer: true }

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

  def uri_en
    @uri_en ||= URI.parse(url_en)
  end
  alias_method :uri, :uri_en

  def uri_cy
    @uri_cy ||= URI.parse(url_cy)
  end

  def moderate_uri
    @moderate_uri ||= URI.parse(moderate_url)
  end

  def type_cast_feature_flag(value)
    value.in?(FALSE_VALUES) ? false : true
  end
end
