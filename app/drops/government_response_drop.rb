class GovernmentResponseDrop < ApplicationDrop
  def initialize(response)
    @response = response
  end

  with_options to: :@response do
    delegate :petition
    delegate :summary
    delegate :details
  end

  def url
    routes.petition_url(petition, reveal_response: "yes")
  end
end
