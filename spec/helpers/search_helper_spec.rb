require 'rails_helper'

describe SearchHelper do
  it "shows HTML for a state count" do
    @petition_search = double(:state_counts => {'open' => 23 })
    expect(search_count_for('open')).to eq("<span class='count'>(23)</span>")
  end

  it "shows 0 for a blank state count" do
    @petition_search = double(:state_counts => Hash.new(0))
    expect(search_count_for('open')).to eq("<span class='count'>(0)</span>")
  end

  it "should show commas for a state count of 1000 or more" do
    @petition_search = double(:state_counts => { 'open' => 1234 })
    expect(search_count_for('open')).to eq("<span class='count'>(1,234)</span>")
  end
end
