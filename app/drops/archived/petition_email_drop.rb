module Archived
  class PetitionEmailDrop < ApplicationDrop
    def initialize(email)
      @email = email
    end

    with_options to: :@email do
      delegate :subject, :body
    end
  end
end
