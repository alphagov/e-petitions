require 'csv'

class PetitionCSVPresenter
  include CsvHelper
  include DateTimeHelper
  include Rails.application.routes.url_helpers

  def self.fields
    urls + attributes + timestamps + [:notes, :subscriber_count, :subscription_rate]
  end

  def initialize(petition)
    @petition = petition
  end

  def to_csv
    CSV::Row.new(self.class.fields, values).to_s
  end

  attr_reader :petition

  private

  def self.urls
    [:public_url, :admin_url]
  end

  def self.attributes
    [:id,
      :action, :background, :additional_details, :state,
      :creator_name, :creator_email, :signature_count, :rejection_code, :rejection_details,
      :government_response_summary, :government_response_details, :debate_date,
      :debate_transcript_url, :debate_video_url, :debate_pack_url, :debate_overview
    ]
  end

  def self.timestamps
    [
      :created_at, :updated_at, :open_at, :closed_at, :government_response_at, :scheduled_debate_date,
      :response_threshold_reached_at, :debate_threshold_reached_at, :rejected_at, :debate_outcome_at,
      :moderation_threshold_reached_at, :government_response_created_at, :government_response_updated_at
    ]
  end

  def values
    self.class.fields.map {|field| send field }
  end

  def public_url
    petition_url id
  end

  def admin_url
    admin_petition_url id
  end

  def notes
    petition.note.details if petition.note
  end

  def subscriber_count
    if petition.statistics.refreshed?
      csv_escape petition.statistics.subscriber_count
    end
  end

  def subscription_rate
    if petition.statistics.refreshed?
      csv_escape petition.statistics.subscription_rate
    end
  end

  attributes.each do |attribute|
    define_method attribute do
      csv_escape petition.send attribute
    end
  end

  timestamps.each do |timestamp|
    define_method timestamp do
      api_date_format petition.send timestamp
    end
  end
end
