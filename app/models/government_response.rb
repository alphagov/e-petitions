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
    # this will prevent EmailThresholdResponseJob from sending out emails for the deleted response
    # TODO 'check that email requested at breaks here'
    unless petition.archived? 
      petition.set_email_requested_at_for('government_response')
      petition.update(government_response_at: nil)
    end
  end

  def responded_on
    super || default_responded_on
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
