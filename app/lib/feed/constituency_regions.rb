module Feed
  class ConstituencyRegions < Base
    class ConstituencyRegion < Entry
      attribute :constituency_id, :string, ".//d:Constituency_Id"
      attribute :region_id, :string, ".//d:Area_Id"
    end

    self.model   = "ConstituencyAreas"
    self.columns = "Area_Id,Constituency_Id"
    self.filter  = "(Area/AreaType_Id eq 8) and ((Constituency/EndDate gt datetime'2015-05-07') or (Constituency/EndDate eq null))"
    self.klass   = ConstituencyRegion
  end
end
