module Feed
  class Members < Base
    class Member < Entry
      attribute :id, :string, ".//d:Member_Id"
      attribute :name, :string, ".//d:NameFullTitle"
      attribute :party, :string, ".//d:Party"
      attribute :constituency_id, :string, ".//d:MembershipFrom_Id"
      attribute :date, :date, ".//d:StartDate"
    end

    self.model   = "Members"
    self.columns = "Member_Id,NameFullTitle,Party,MembershipFrom_Id,StartDate"
    self.filter  = "CurrentStatusActive%20eq%20true%20and%20House_Id%20eq%201"
    self.klass   = Member
  end
end
