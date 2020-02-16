class RegionPetitionJournal < Struct.new(:region, :signature_count)
  delegate :name, :ons_code, to: :region
end
