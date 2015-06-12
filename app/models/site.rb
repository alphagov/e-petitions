require 'bcrypt'

class Site < ActiveRecord::Base
  class ServiceUnavailable < StandardError; end

  class << self
    def before_remove_const
      Thread.current[:__site__] = nil
    end

    def instance
      Thread.current[:__site__] ||= first_or_create
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

    def protected?
      instance.protected?
    end

    def reload
      Thread.current[:__site__] = nil
    end

    def touch(*names)
      instance.touch(*names)
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
    URI.parse(url).scheme
  end

  def password_digest
    BCrypt::Password.new(super)
  end

  def password=(new_password)
    @password = new_password.presence

    if @password
      self.password_digest = BCrypt::Password.create(@password, cost: 10)
    else
      self.password_digest = nil
    end
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
end
