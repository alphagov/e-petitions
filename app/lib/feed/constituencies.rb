module Feed
  class Constituencies < Base
    class Constituency < Entry
      attribute :id, :string, ".//d:Constituency_Id"
      attribute :name, :string, ".//d:Name"
      attribute :ons_code, :string, ".//d:ONSCode"
    end

    self.model   = "Constituencies"
    self.columns = "Constituency_Id,Name,ONSCode"
    self.filter  = "EndDate%20eq%20null"
    self.klass   = Constituency
  end
end
