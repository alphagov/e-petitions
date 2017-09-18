require 'bcrypt'
require 'uri'
require 'active_support/number_helper'

class Site < ActiveRecord::Base
  class ServiceUnavailable < StandardError; end

  include ActiveSupport::NumberHelper

  FALSE_VALUES = [nil, false, 0, '0', 'f', 'F', 'false', 'FALSE', 'off', 'OFF'].to_set
  FEATURE_FLAGS = %w[disable_constituency_api]

  class << self
    def table_exists?
      @table_exists ||= connection.table_exists?(table_name)
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
      instance.login_timeout
    end

    def reload
      Thread.current[:__site__] = nil
    end

    def touch(*names)
      instance.touch(*names)
    end

    def moderation_overdue_in_days
      7.days
    end

    def moderation_near_overdue_in_days
      5.days
    end

    def defaults
      {
        title:                      default_title,
        url:                        default_url,
        moderate_url:               default_moderate_url,
        email_from:                 default_email_from,
        feedback_email:             default_feedback_email,
        username:                   default_username,
        password:                   default_password,
        enabled:                    default_enabled,
        protected:                  default_protected,
        login_timeout:              default_login_timeout,
        petition_duration:          default_petition_duration,
        minimum_number_of_sponsors: default_minimum_number_of_sponsors,
        maximum_number_of_sponsors: default_maximum_number_of_sponsors,
        threshold_for_moderation:   default_threshold_for_moderation,
        threshold_for_response:     default_threshold_for_response,
        threshold_for_debate:       default_threshold_for_debate
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

  validates :title, presence: true, length: { maximum: 50 }
  validates :url, presence: true, length: { maximum: 50 }
  validates :moderate_url, presence: true, length: { maximum: 50 }
  validates :email_from, presence: true, length: { maximum: 100 }
  validates :feedback_email, presence: true, length: { maximum: 100 }
  validates :petition_duration, presence: true, numericality: { only_integer: true }
  validates :minimum_number_of_sponsors, presence: true, numericality: { only_integer: true }
  validates :maximum_number_of_sponsors, presence: true, numericality: { only_integer: true }
  validates :threshold_for_moderation, presence: true, numericality: { only_integer: true }
  validates :threshold_for_response, presence: true, numericality: { only_integer: true }
  validates :threshold_for_debate, presence: true, numericality: { only_integer: true }
  validates :username, presence: true, length: { maximum: 30 }, if: :protected?
  validates :password, length: { maximum: 30 }, confirmation: true, if: :protected?
  validates :login_timeout, presence: true, numericality: { only_integer: true }

  validate if: :protected? do
    errors.add(:password, :blank) unless password_digest?
  end

  private

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
