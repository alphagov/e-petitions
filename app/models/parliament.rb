class Parliament < ActiveRecord::Base
  class << self
    def before_remove_const
      Thread.current[:__parliament__] = nil
    end

    def instance
      Thread.current[:__parliament__] ||= last_or_create
    end

    def government
      instance.government
    end

    def opening_at
      instance.opening_at
    end

    def opened?(now = Time.current)
      instance.opened?(now)
    end

    def dissolution_at
      instance.dissolution_at
    end

    def notification_cutoff_at
      instance.notification_cutoff_at
    end

    def dissolution_heading
      instance.dissolution_heading
    end

    def dissolution_message
      instance.dissolution_message
    end

    def dissolved_heading
      instance.dissolved_heading
    end

    def dissolved_message
      instance.dissolved_message
    end

    def dissolution_faq_url
      instance.dissolution_faq_url
    end

    def dissolution_faq_url?
      instance.dissolution_faq_url?
    end

    def dissolved?(now = Time.current)
      instance.dissolved?(now)
    end

    def dissolution_announced?
      instance.dissolution_announced?
    end

    def registration_closed?
      instance.registration_closed?
    end

    def reload
      Thread.current[:__parliament__] = nil
    end

    def last_or_create
      order(created_at: :desc).first_or_create
    end
  end

  validates_presence_of :government, :opening_at
  validates_presence_of :dissolution_heading, :dissolution_message, if: :dissolution_at?
  validates_presence_of :dissolved_heading, :dissolved_message, if: :dissolved?
  validates_length_of :government, maximum: 100
  validates_length_of :dissolution_heading, :dissolved_heading, maximum: 100
  validates_length_of :dissolution_message, :dissolved_message, maximum: 600
  validates_length_of :dissolution_faq_url, maximum: 500

  after_save { Site.touch }

  def opened?(now = Time.current)
    opening_at? && opening_at <= now
  end

  def period
    if opening_at? && dissolution_at?
      "#{opening_at.year}–#{dissolution_at.year}"
    end
  end

  def period?
    period.present?
  end

  def dissolved?(now = Time.current)
    dissolution_at? && dissolution_at <= now
  end

  def dissolution_announced?
    dissolution_at?
  end

  def registration_closed?(now = Time.current)
    registration_closed_at? && registration_closed_at <= now
  end
end
