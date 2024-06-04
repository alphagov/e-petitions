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
    self.filter  = "(CurrentStatusActive eq true) and (House_Id eq 1)"
    self.orderby = "Member_id"
    self.klass   = Member
  end
end
