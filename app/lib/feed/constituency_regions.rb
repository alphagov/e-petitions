module Feed
  class ConstituencyRegions < Base
    class ConstituencyRegion < Entry
      attribute :constituency_id, :string, ".//d:Constituency_Id"
      attribute :region_id, :string, ".//d:Area_Id"
    end

    self.model   = "ConstituencyAreas"
    self.columns = "Area_Id,Constituency_Id"
    self.filter  = "Area/AreaType_Id%20eq%208%20and%20Constituency/EndDate%20eq%20null"
    self.klass   = ConstituencyRegion
  end
end
