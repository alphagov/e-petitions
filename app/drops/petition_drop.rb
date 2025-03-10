class PetitionDrop < ApplicationDrop
  def initialize(petition)
    @petition = petition
  end

  with_options to: :@petition do
    delegate :action
    delegate :background
    delegate :additional_details
    delegate :sponsor_count
    delegate :signature_count
    delegate :scheduled_debate_date
  end

  def creator
    @petition.creator.name
  end

  def url
    routes.petition_url(@petition)
  end

  def new_sponsor_url
    routes.new_petition_sponsor_url(@petition, token: @petition.sponsor_token)
  end

  def response_url
    routes.petition_url(@petition, reveal_response: "yes")
  end
end
