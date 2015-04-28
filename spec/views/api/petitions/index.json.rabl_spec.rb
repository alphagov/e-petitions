require 'rails_helper'

describe "api/petitions/index.json.rabl" do
  let(:fields) {{
    :id => '1',
    :title => 'foo',
    :description => "description",
    :creator_signature => double(:name => "Tod Ham", :postal_district => "SO12"),
    :department => double(:name => "Treasury"),
    :created_at => Time.parse("2012-02-02 02:02:02"),
    :closed_at => Time.parse("2013-02-02 02:02:02"),
    :response => "hello, yes",
    :updated_at => Time.parse("2012-03-02 02:02:02"),
    :state => "open",
    :signature_count => 101
  }}

  context "standard fields" do
    before do
      assign(:petitions, [double(fields)])
      render
    end

    subject { JSON.parse(rendered).first.values.first }

    example { subject['title'].should == "foo" }
    example { subject['description'].should == "description" }
    example { subject['creator_name'].should == "Tod Ham" }
    example { subject['department_name'].should == "Treasury" }
    example { subject['created_datetime'].should == "2012-02-02T02:02:02Z" }
    example { subject['closing_datetime'].should == "2013-02-02T02:02:02Z" }
    example { subject['last_update_datetime'].should == "2012-03-02T02:02:02Z" }
    example { subject['signature_count'].should == 101 }
    example { subject['state'].should == "open" }
    example { subject['response'].should == "hello, yes" }
  end

  context "no closing date" do
    before do
      assign(:petitions, [double(fields.merge(:closed_at => nil))])
      render
    end
    example { subject['closing_datetime'].should == nil }
  end
end
