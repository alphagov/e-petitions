class GovernmentResponse < ActiveRecord::Base
  belongs_to :petition, touch: true

  validates :petition, presence: true
  validates :summary, presence: true, length: { maximum: 200 }
  validates :details, length: { maximum: 6000 }, allow_blank: true
  validates :responded_on, presence: true

  after_create do
    Appsignal.increment_counter("petition.responded", 1)
    petition.touch(:government_response_at) unless petition.government_response_at?
  end

  after_destroy do
    unless petition.archived?
      Appsignal.increment_counter("petition.responded", -1)

      # This prevents any enqueued email jobs from being sent
      petition.set_email_requested_at_for("government_response")

      # This removes the petition from the 'Government response' list
      petition.update_columns(government_response_at: nil)
    end
  end

  def responded_on
    super || default_responded_on
  end

  def to_liquid
    GovernmentResponseDrop.new(self)
  end

  private

  def default_responded_on
    if petition && petition.government_response_at
      petition.government_response_at.to_date
    elsif created_at
      created_at.to_date
    elsif new_record?
      Date.current
    end
  end
end
