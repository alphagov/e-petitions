module Staged
  class Sponsors < Staged::Base::Petition
    include Staged::Validations::SponsorDetails

    delegate :sponsors, to: :petition

    def validation_context
      :create
    end

    def valid?
      super && sponsors_valid?
    end

    private

    def sponsors_valid?
      # Make sure we ask all sponsors to validate before returning
      sponsors.map(&:valid?).all?
    end
  end
end
