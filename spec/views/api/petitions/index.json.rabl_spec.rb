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

    example { expect(subject['title']).to eq("foo") }
    example { expect(subject['description']).to eq("description") }
    example { expect(subject['creator_name']).to eq("Tod Ham") }
    example { expect(subject['department_name']).to eq("Treasury") }
    example { expect(subject['created_datetime']).to eq("2012-02-02T02:02:02Z") }
    example { expect(subject['closing_datetime']).to eq("2013-02-02T02:02:02Z") }
    example { expect(subject['last_update_datetime']).to eq("2012-03-02T02:02:02Z") }
    example { expect(subject['signature_count']).to eq(101) }
    example { expect(subject['state']).to eq("open") }
    example { expect(subject['response']).to eq("hello, yes") }
  end

  context "no closing date" do
    before do
      assign(:petitions, [double(fields.merge(:closed_at => nil))])
      render
    end
    example { expect(subject['closing_datetime']).to eq(nil) }
  end
end
