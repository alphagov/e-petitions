module Archived
  class PetitionDrop < ApplicationDrop
    def initialize(petition)
      @petition = petition
    end

    with_options to: :@petition do
      delegate :action
      delegate :background
      delegate :additional_details
      delegate :signature_count
      delegate :scheduled_debate_date
    end

    def creator
      @petition.creator.name
    end

    def url
      routes.archived_petition_url(@petition)
    end

    def response_url
      routes.archived_petition_url(@petition, reveal_response: "yes")
    end
  end
end
