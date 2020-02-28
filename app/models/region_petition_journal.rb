class RegionPetitionJournal < Struct.new(:region, :signature_count)
  delegate :id, :name, to: :region
end
