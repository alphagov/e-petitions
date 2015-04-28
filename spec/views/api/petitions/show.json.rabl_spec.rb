require 'rails_helper'

describe "api/petitions/show.json.rabl" do
  let(:fields) {{
    :id => '1',
    :signature_counts_by_postal_district => {'SO22' => 2, 'SO21' => 1}
  }}

  context "standard fields" do
    before do
      assign(:petition, double(fields))
      render
    end

    subject { JSON.parse(rendered).values.first }

    it "renders the id" do
      subject['id'].should == "1"
    end

    it "renders the signature counts by post town" do
      subject['postal_districts']['SO22'].should == 2
      subject['postal_districts']['SO21'].should == 1
    end
  end
end
