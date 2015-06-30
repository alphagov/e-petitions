require 'bcrypt'
require 'uri'

class Site < ActiveRecord::Base
  class ServiceUnavailable < StandardError; end

  class << self
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

    def host
      instance.host
    end

    def host_with_port
      instance.host_with_port
    end

    def petition_closed_at(time = Time.current)
      instance.petition_closed_at(time)
    end

    def port
      instance.port
    end

    def protected?
      instance.protected?
    end

    def reload
      Thread.current[:__site__] = nil
    end

    def touch(*names)
      instance.touch(*names)
    end

    def defaults
      {
        title:                      default_title,
        url:                        default_url,
        email_from:                 default_email_from,
        feedback_email:             default_feedback_email,
        username:                   default_username,
        password:                   default_password,
        enabled:                    default_enabled,
        protected:                  default_protected,
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

    def default_port
      ENV.fetch('EPETITIONS_PORT', '443').to_i
    end

    def default_email_from
      ENV.fetch('EPETITIONS_FROM', "no-reply@#{default_host}")
    end

    def default_feedback_email
      ENV.fetch('EPETITIONS_FEEDBACK', "feedback@#{default_host}")
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
  end

  column_names.map(&:to_sym).each do |column|
    define_singleton_method(column) do |*args, &block|
      instance.public_send(column, *args, &block)
    end
  end

  attr_reader :password

  def authenticate(username, password)
    self.username == username && self.password_digest == password
  end

  def email_protocol
    uri.scheme
  end

  def host
    uri.host
  end

  def host_with_port
    "#{host}#{port_string}"
  end

  def password_digest
    BCrypt::Password.new(super)
  end

  def port
    uri.port
  end

  def password=(new_password)
    @password = new_password.presence

    if @password
      self.password_digest = BCrypt::Password.create(@password, cost: 10)
    else
      self.password_digest = nil
    end
  end

  def petition_closed_at(time = Time.current)
    time.end_of_day + petition_duration.months
  end

  validates :title, presence: true, length: { maximum: 50 }
  validates :url, presence: true, length: { maximum: 50 }
  validates :email_from, presence: true, length: { maximum: 50 }
  validates :petition_duration, presence: true, numericality: { only_integer: true }
  validates :minimum_number_of_sponsors, presence: true, numericality: { only_integer: true }
  validates :maximum_number_of_sponsors, presence: true, numericality: { only_integer: true }
  validates :threshold_for_moderation, presence: true, numericality: { only_integer: true }
  validates :threshold_for_response, presence: true, numericality: { only_integer: true }
  validates :threshold_for_debate, presence: true, numericality: { only_integer: true }
  validates :username, presence: true, length: { maximum: 30 }, if: :protected?
  validates :password, length: { maximum: 30 }, confirmation: true, if: :protected?

  validate if: :protected? do
    errors.add(:password, :blank) unless password_digest?
  end

  private

  def port_string
    standard_port? ? '' : ":#{port}"
  end

  def protocol
    "#{uri.scheme}://"
  end

  def standard_port
    case protocol
      when 'https://' then 443
      else 80
    end
  end

  def standard_port?
    port == standard_port
  end

  def uri
    @uri ||= URI.parse(url)
  end
end
