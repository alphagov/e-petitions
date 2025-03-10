module Archived
  class PetitionMailshotDrop < ApplicationDrop
    def initialize(mailshot)
      @mailshot = mailshot
    end

    with_options to: :@email do
      delegate :subject, :body
    end
  end
end
