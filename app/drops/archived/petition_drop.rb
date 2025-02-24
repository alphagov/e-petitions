module Archived
  class PetitionDrop < ApplicationDrop
    def initialize(petition)
      @petition = petition
    end

    with_options to: :@petition do
      delegate :action
      delegate :background
      delegate :additional_details
    end

    def url
      routes.archived_petition_url(@petition)
    end
  end
end
