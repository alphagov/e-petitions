module Feed
  class Regions < Base
    class Region < Entry
      attribute :id, :string, ".//d:Area_Id"
      attribute :name, :string, ".//d:Name"
      attribute :ons_code, :string, ".//d:OnsAreaId"
    end

    self.model   = "Areas"
    self.columns = "Area_Id,Name,OnsAreaId"
    self.filter  = "AreaType_Id%20eq%208"
    self.klass   = Region
  end
end
