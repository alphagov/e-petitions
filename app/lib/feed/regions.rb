module Feed
  class Regions < Base
    class Region < Entry
      attribute :id, :string, ".//d:Area_Id"
      attribute :name, :string, ".//d:Name"
      attribute :ons_code, :string, ".//d:OnsAreaId"
    end

    self.model   = "Areas"
    self.columns = "Area_Id,Name,OnsAreaId"
    self.filter  = "AreaType_Id eq 8"
    self.orderby = "OnsAreaId"
    self.klass   = Region
  end
end
