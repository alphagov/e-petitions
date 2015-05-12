module Staged
  class Sponsors < Staged::Base::Petition
    include Staged::Validations::SponsorDetails

    def sponsors
      @_sponsors ||= []
    end

    def validation_context
      :create
    end

    def valid?
      super && sponsors_valid?
    end

    private

    def sponsors_valid?
      # Ask them all to validate...
      sponsors.each { |sponsor| sponsor.valid? }
      # ...return if any have an error
      sponsors.any? { |sponsor| sponsor.errors.any? }
    end
  end
end
