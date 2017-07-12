require 'rails_helper'

RSpec.describe "Arel array predicates" do
  let(:column) { Petition.arel_table[:tags] }

  describe "#contains" do
    subject { column.contains([1]) }

    it "generates the correct SQL" do
      expect(subject.to_sql).to eq(%["petitions"."tags" @> '{1}'])
    end
  end

  describe "#overlaps" do
    subject { column.overlaps([1]) }

    it "generates the correct SQL" do
      expect(subject.to_sql).to eq(%["petitions"."tags" && '{1}'])
    end
  end
end
