require 'active_support/number_helper'

class Parliament < ActiveRecord::Base
  include ActiveSupport::NumberHelper

  CUTOFF_DATE = Date.civil(2015, 5, 7)
  PERIOD_FORMAT = /\A\d{4}-\d{4}\z/

  has_many :petitions, inverse_of: :parliament, class_name: "Archived::Petition"
  has_many :parliament_constituencies
  has_many :constituencies, through: :parliament_constituencies

  class << self
    def instance
      Thread.current[:__parliament__] ||= current_or_create
    end

    def archived(now = Time.current)
      where(arel_table[:archived_at].lteq(now)).order(archived_at: :desc)
    end

    def current
      where(archived_at: nil).order(created_at: :asc)
    end

    def previous(opening_at)
      where(opening_at: ...opening_at).order(opening_at: :desc).first
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

    def closed?(now = Time.current)
      instance.closed?(now)
    end

    def dissolution_at
      instance.dissolution_at
    end

    def dissolution_at?
      instance.dissolution_at?
    end

    def dissolving?(now = Time.current)
      instance.dissolving?(now)
    end

    def registration_closed_at
      instance.registration_closed_at
    end

    def election_date
      instance.election_date
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

    def government_response_heading
      instance.government_response_heading
    end

    def government_response_description
      instance.government_response_description.to_s % { count: Site.formatted_threshold_for_response }
    rescue KeyError => e
      instance.government_response_description
    end

    def government_response_status
      instance.government_response_status
    end

    def parliamentary_debate_heading
      instance.parliamentary_debate_heading
    end

    def parliamentary_debate_description
      instance.parliamentary_debate_description.to_s % { count: Site.formatted_threshold_for_debate }
    rescue KeyError => e
      instance.parliamentary_debate_description
    end

    def parliamentary_debate_status
      instance.parliamentary_debate_status
    end

    def reload
      Thread.current[:__parliament__] = nil
    end

    def reset!(attributes = defaults)
      destroy_all and reload
      create!(attributes)
    end

    def current_or_create
      current.first_or_create(defaults)
    end

    def update!(attributes)
      instance.update!(attributes)
    end

    def defaults
      I18n.t(:defaults, scope: :parliament).transform_values do |value|
        value.respond_to?(:call) ? value.call : value
      end
    end
  end

  validates_presence_of :government, :opening_at
  validates_presence_of :dissolution_heading, :dissolution_message, if: :dissolution_at?
  validates_presence_of :dissolved_heading, :dissolved_message, if: :dissolved?
  validates_length_of :government, maximum: 100
  validates_length_of :dissolution_heading, :dissolved_heading, maximum: 100
  validates_length_of :dissolution_message, :dissolved_message, maximum: 600
  validates_length_of :dissolution_faq_url, maximum: 500
  validates_numericality_of :petition_duration, only_integer: true, allow_blank: true
  validates_numericality_of :petition_duration, greater_than_or_equal_to: 1, allow_blank: true
  validates_numericality_of :petition_duration, less_than_or_equal_to: 12, allow_blank: true

  validate on: :send_emails do
    errors.add(:dissolution_at, :blank) unless dissolution_at?
    errors.add(:dissolution_faq_url, :blank) unless dissolution_faq_url?
    errors.add(:show_dissolution_notification, :not_visible) unless show_dissolution_notification?
    errors.add(:registration_closed_at, :blank) unless registration_closed_at?
    errors.add(:election_date, :blank) unless election_date?
  end

  validate on: :schedule_closure do
    errors.add(:notification_cutoff_at, :blank) unless notification_cutoff_at?
  end

  validate on: :archive_petitions do
    errors.add(:dissolution_at, :blank) unless dissolution_at?

    if dissolution_at?
      errors.add(:dissolution_at, :too_soon) unless dissolution_at < 2.days.ago
    end
  end

  validate on: :archive_parliament do
    errors.add(:dissolution_at, :blank) unless dissolution_at?

    if dissolution_at?
      errors.add(:dissolution_at, :too_soon) unless dissolution_at < 2.days.ago
      errors.add(:dissolution_at, :still_archiving) if dissolved? && archiving?
    end
  end

  validate on: :anonymize_petitions do
    errors.add(:opening_at, :blank) unless opening_at?

    if previous_dissolution_at.present?
      errors.add(:opening_at, :too_soon) unless previous_dissolution_at < 6.months.ago
    else
      errors.add(:opening_at, :previous_blank)
    end
  end

  after_save { Site.touch }

  def name
    "#{period} #{government} government"
  end

  def opened?(now = Time.current)
    opening_at? && opening_at <= now
  end

  def closed?(now = Time.current)
    dissolved?(now) || !opened?(now)
  end

  def sitting?(time)
    if dissolution_at?
      return false if time.after?(dissolution_at)
    end

    opening_at? && time.after?(opening_at)
  end

  def period?
    period.present?
  end

  def previous
    return @previous if defined?(@previous)

    if previous_parliament = self.class.previous(opening_at)
      @previous = self.class.previous(opening_at)
    end
  end

  def previous_dissolution_at
    previous.present? && previous.dissolution_at
  end

  def dissolving?(now = Time.current)
    dissolution_at? && dissolution_at > now
  end

  def dissolved?(now = Time.current)
    dissolution_at? && dissolution_at <= now
  end

  def dissolution_announced?
    dissolution_at? && show_dissolution_notification?
  end

  def dissolution_emails_sent?
    dissolution_emails_sent_at?
  end

  def closure_scheduled?
    closure_scheduled_at?
  end

  def registration_closed?(now = Time.current)
    registration_closed_at? && registration_closed_at <= now
  end

  def archived?(now = Time.current)
    archived_at? && archived_at <= now
  end

  def archiving?
    archiving_started_at? && !archiving_finished?
  end

  def archiving_finished?
    archiving_started_at? && Petition.unarchived.empty?
  end

  def start_archiving!(now = Time.current)
    unless archiving? || archiving_finished?
      ArchivePetitionsJob.perform_later
      update_column(:archiving_started_at, now)
    end
  end

  def start_anonymizing!
    if can_anonymize_petitions?
      Archived::AnonymizePetitionsJob.set(wait_until: midnight).perform_later(midnight.iso8601)
    end
  end

  def schedule_closure!(now = Time.current)
    if dissolution_announced? && !dissolved?
      ClosePetitionsEarlyJob.schedule_for(dissolution_at)
      StopPetitionsEarlyJob.schedule_for(dissolution_at)
      update_column(:closure_scheduled_at, now)
    end
  end

  def send_emails!(now = Time.current)
    if dissolution_at? && !dissolved?
      NotifyPetitionsThatParliamentIsDissolvingJob.perform_later
      update_column(:dissolution_emails_sent_at, now)
    end
  end

  def archive!(now = Time.current)
    if archiving_finished?
      DeletePetitionsJob.perform_later
      update_column(:archived_at, now)
    end
  end

  def can_archive_petitions?
    dissolved? && !archiving_finished? && !archiving?
  end

  def can_archive?
    dissolved? && archiving_finished?
  end

  def can_anonymize_petitions?
    !(dissolving? || dissolved? || archiving?) && Archived::Petition.can_anonymize?
  end

  def formatted_threshold_for_response
    number_to_delimited(threshold_for_response)
  end

  def formatted_threshold_for_debate
    number_to_delimited(threshold_for_debate)
  end

  def show_on_a_map?
    opening_at > CUTOFF_DATE
  end

  def midnight
    @midnight ||= Date.tomorrow.beginning_of_day
  end

  def to_liquid
    ParliamentDrop.new(self)
  end
end
